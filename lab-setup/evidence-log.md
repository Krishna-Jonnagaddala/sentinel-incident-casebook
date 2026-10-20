# Evidence log (rough notes)

Notes I kept while building and attacking the lab. They're rough: a running record of what I did, what the logs showed and the time I read it from the logs. "Analyst" means me. Times are UTC. Home IP addresses are replaced with `<home-ip>`.

The tidy versions are in the case write-ups. This is the raw material behind them, left in because the dead ends are useful too.

---



## Environment
- Tenant: openhuntx.onmicrosoft.com (new Entra ID tenant, Entra ID P2 trial)
- Workspace: law-ir-case-study, rg-ir-casebook, UK West, Microsoft Sentinel enabled
- Entra diagnostic setting `to-law-ir-case-study`: AuditLogs, SignInLogs, NonInteractiveUserSignInLogs, ServicePrincipalSignInLogs, RiskyUsers, UserRiskEvents, ManagedIdentitySignInLogs, MicrosoftGraphActivityLogs

## Lab accounts (fictional)
| Role | Account |
|---|---|
| Admin / investigator | Krishna |
| Phish victim (case 1) | Mike Tyson |
| Finance user (case 3) | Rambo Craig |
| IT admin (case 3) | Arthur Sterling |

## Observed so far
| Time | Source | Event | Screenshot |
|---|---|---|---|
| 16:29:47, 16:29:54 | Entra sign-in log | Mike: two failed sign-ins (wrong password, deliberate) | lab-12 |
| 16:29:59 | Entra sign-in log | Mike: success | lab-12 |
| 16:31:45 | AuditLogs | Rambo: authenticator app (OATH) registration | lab-09 |
| 16:35:49 | AuditLogs | Add service principal: People Profile Event Proxy (initiator: Microsoft Azure AD Internal - Jit Provisioning) | lab-10 |
| 16:36:20 | AuditLogs | Add service principal: Azure RBAC Data Plane (same initiator) | lab-10 |

## Notes
- All lab sign-ins so far come from one residential IP. Redact IP and location in every image and text.
- SigninLogs was empty in Sentinel while the Entra portal already showed sign-ins (lab-11 vs lab-12): export delay.
- Audit entries before the diagnostic setting was saved are not in the workspace.

## Case 1 staging (attacker = analyst on VPN, exit country: Nigeria per logs)
Analyst noted action times only roughly (2-10 min before querying). Logs are the source of truth.
Mike: added a phone passkey (fingerprint) during the staged compromise.

### SigninLogs, first read (case1-02)
| Time (UTC) | User | ResultType | IP country | App | Browser / OS |
|---|---|---|---|---|---|
| 16:55:52 | Mike | 0 success | NG | Azure Portal | Chrome Mobile / Android |
| 16:56:17 | Mike | 50072 (MFA enrolment required) | GB (home IP) | Azure Portal | Chrome / macOS |
| 16:57:05 | Mike | 0 | NG | My Profile | Chrome Mobile / Android |
| 16:57:14 | Mike | 0 | NG | My Signins | Chrome Mobile / Android |
| 16:58:10 | Mike | 0 | GB | Azure Portal | Chrome / macOS |
| 16:58:10 | Mike | 0 | NG | My Signins | Chrome Mobile / Android |
| 16:58:11 | Mike | 0 | NG | My Apps | Chrome Mobile / Android |
| 16:59:45 | Rambo | 50126 (bad password) | NG | My Apps | Chrome Mobile / Android |
| 17:00:11 | Rambo | 50126 (bad password) | NG | My Apps | Chrome Mobile / Android |

Open: no Arthur rows; sign-ins before ~16:55 (incl. Mike's baseline at 16:29) not in workspace.

### AuditLogs, Mike's security-info changes (case1-03, case1-04)
| Time (UTC) | Operation | Actor | Source IP shown |
|---|---|---|---|
| 16:55:41.800 | Get passkey creation options | Mike | 74.178.57.230 |
| 16:55:42.000 | User started security info registration | Mike | 185.111.108.131 (NG, VPN) |
| 16:56:05.000 | User registered security info | Mike | 185.111.108.131 (NG, VPN) |
| 16:56:05.126 | Update user | Device Registration Service | - |
| 16:56:05.881 | User registered security info | Mike | 74.178.57.238 |
Plus bursts of "Add service principal" by Microsoft Azure AD Internal - Jit Provisioning (16:55:02, 16:56:47, 16:57:07), mix of success and failure.
74.178.57.x not yet identified (suspected Microsoft-side). Not confirmed.

### SigninLogs summary by IP (case1-05)
| User | IP | Attempts | Failures | Country |
|---|---|---|---|---|
| Mike | 185.111.108.131 | 5 | 0 | NG |
| Arthur | 185.111.108.131 | 3 | 3 | NG |
| Rambo | 185.111.108.131 | 3 | 3 | NG |
| Mike | home IP (redact) | 2 | 1 | GB |

### Security info registration details (case1-06)
- 16:55:42 started registration, AuthenticationMethodType = Passkey
- 16:56:05.000 registered, method Passkey, InitiatedBy NotAgentic
- 16:56:05.881 registered, InitiatedFrom "My Signins", modified property Fido2AuthenticationMethod.Id

### Mike risk / auth requirement (case1-07)
- All 7 rows: RiskState none, RiskEventTypes_V2 empty, ConditionalAccessStatus notApplied
- NG (VPN) sign-ins: AuthenticationRequirement = singleFactorAuthentication
- GB (home) sign-ins: multiFactorAuthentication
- RiskLevelDuringSignIn: none or hidden. No Identity Protection detection fired.

### Query error (case1-08)
AADNonInteractiveUserSignInLogs.LocationDetails is a string there. Fix: tostring(parse_json(LocationDetails).countryOrRegion).

### Mike non-interactive sign-ins (case1-09)
- 73 rows, all result 0, all from 185.111.108.131 (NG), 16:54:33 onward
- First row 16:54:33.541 Azure Portal -> Microsoft Graph, i.e. ~80 s before first interactive success in SigninLogs (16:55:52)
- Apps: Azure Portal, Azure Resource Manager, My Profile, My Signins, Microsoft Approval Management, Office365 Shell, Azure Copilot
- Open: the interactive sign-in that produced the first token (before 16:54:33) is not in SigninLogs. Recheck for late-arriving rows.

### Recheck for early SigninLogs rows (case1-10)
Same 7 rows as before, window 16:20-17:10. No rows for Mike before 16:55:52 (no 16:29 baseline, no first NG interactive sign-in). Gap persists after the earlier read. Treat as a real SIEM gap unless it later fills.

### Non-interactive summary by app (case1-11), all from 185.111.108.131
| App | Events | First | Last |
|---|---|---|---|
| My Signins | 41 | 16:56:34 | 17:04:41 |
| My Apps | 10 | 16:57:26 | 16:58:47 |
| My Profile | 9 | 16:55:51 | 16:58:52 |
| Azure Portal | 6 | 16:54:33 | 16:58:10 |
| Microsoft Approval Management | 3 | 16:56:33 | 16:59:11 |
| ADIbizaUX | 2 | 16:57:52 | 16:58:10 |
| Azure Resource Manager | 1 | 16:55:55 | 16:55:55 |
| Azure Portal Fx Copilot Web | 1 | 16:55:48 | 16:55:48 |
Total 73. My Signins activity continues to 17:04:41, ~5 min after all other apps stopped.
Mac/GB sign-ins by Mike at 16:56 and 16:58: analyst has not yet confirmed what they were. Mark unconfirmed.

### Mike authentication methods, before containment (case1-12)
- Software OATH token (id shown), Passkey with detail "Google Password Manager"
- Default sign-in method: OATH TOTP; system preferred MFA method: Fido2
- CORRECTION to earlier inference: Mike DID have an OATH token. "No MFA method registered" is NOT supported. Who registered the OATH token and when is unknown (not in AuditLogs seen so far).

### Mike authentication methods, after containment (case1-13)
- "No usable methods"; preferred method now SoftwareOTP (stale). Both OATH token and passkey are gone: containment also removed the legitimate OATH method.
- Clock times of the containment actions: NOT recorded by analyst. Take from AuditLogs.

### Containment in AuditLogs (case1-14, rows 21-44 of 44 visible; first 20 not yet seen), actor Krishna unless noted
| Time (UTC) | Operation | Notes |
|---|---|---|
| 17:12:24.790 | Update StsRefreshTokenValidFrom Timestamp | session revocation; UA Chrome/macOS |
| 17:12:49.097 | Admin deleted security info | InitiatedFrom ADIbizaUX |
| 17:13:04.687 | Admin deleted security info | |
| 17:13:33.890 | Reset user password | actor Microsoft password reset service |
| 17:13:34.008 | Reset password (by admin) | |
| 17:14:00.592 | Admin deleted security info | third deletion (2 methods existed; to explain) |
Also 16:56:46 Settings_GetSettingsAsync x3 by Mike (My Signins page loads). Krishna 'Validate user authentication' 16:59:10 and 17:11:29 = admin sign-ins.

### Last sign-in per IP for Mike (case1-15)
- NG 185.111.108.131: 5 events, last 16:58:11 (interactive). Non-interactive last 17:04:41.
- GB (home): 3 events, last 17:07:23.
IMPORTANT: NG activity ended BEFORE containment (17:12) because the analyst disconnected the VPN. Absence of NG sign-ins after 17:12 does NOT prove containment worked. Needs a post-containment retest from VPN.

### Security-info audit trail (case1-16), complete for 'security info|authentication method|StsRefreshToken|password'
| Time (UTC) | Operation | Actor | Detail |
|---|---|---|---|
| 16:55:42 | User started security info registration | Mike | Passkey |
| 16:56:05.000 | User registered security info | Mike | Passkey |
| 16:56:05.881 | User registered security info | Mike | InitiatedFrom My Signins; Fido2AuthenticationMethod.Id |
| 17:12:49 | Admin deleted security info | Krishna | removed Fido2 (passkey) |
| 17:13:04 | Admin deleted security info | Krishna | removed SoftwareOath |
| 17:13:33-34 | Reset user password / Reset password (by admin) | MS pwd reset svc / Krishna | |
| 17:14:00 | Admin deleted security info | Krishna | no modified property; purpose not established |
- No audit event for registration of Mike's OATH token anywhere in the workspace. Registration time and actor remain UNKNOWN. (Export was working at 16:31 for Rambo's OATH registration.)
- StsRefreshTokenValidFrom rows were not returned by this filter; the 17:12:24 event is from case1-14.

### Post-containment retest, VPN reconnected (case1-17), from 185.111.108.131 (NG), SigninLogs, Azure Portal
| Time (UTC) | ResultType | Meaning |
|---|---|---|
| 17:24:49 | 0 | SUCCESS after containment. Not yet explained. |
| 17:29:10.724 | 50133 | Session invalid due to password expiration / recent password change |
| 17:29:10.726 | 50126 | Invalid username or password |
Needs analyst account of what was done at 17:24:49 (e.g. signed in with the new password?) before any conclusion.

### Retest detail (case1-18), all from 185.111.108.131 (NG), Android Chrome, interactive, Azure Portal, CA notApplied
| Time (UTC) | ResultType | AuthenticationRequirement |
|---|---|---|
| 17:24:49 | 0 success | multiFactorAuthentication |
| 17:29:10.724 | 50133 | singleFactorAuthentication |
| 17:29:10.726 | 50126 | singleFactorAuthentication |
| 17:30:16 | 50126 | singleFactorAuthentication |
17:24:49 is an MFA-required success AFTER all MFA methods were deleted (17:12-17:13). AuthMethods column not yet read. Analyst's account of 17:24 still outstanding.

### Query error (case1-19)
mv-expand on SigninLogs.AuthenticationDetails failed ("expanded expression expected to have dynamic type"): column is a string here. Fix: mv-expand parse_json(AuthenticationDetails). Same class of error as case1-08.

### 17:24:49 sign-in, authentication detail (case1-20)
- Method: OATH verification code; Step: "MFA completed in Azure AD"; Succeeded: true
- Fact: MFA was satisfied by an OATH code ~11 min after the SoftwareOath method was deleted (17:13:04).
- Open: either a new OATH method was registered between 17:14 and 17:24 (no audit event seen yet) or the deletion did not invalidate the old secret. Must query AuditLogs for all Mike events after 17:14.

### AuditLogs for Mike after 17:14 (case1-21), query run after the 17:24 retest
Only two events: 
- 17:14:00.300 Update user, actor "Azure Credential Configuration Endpoint Service", modified property StrongAuthenticationUserDetails (oldValue [], newValue with null phone/email fields)
- 17:14:00.592 Admin deleted security info (Krishna), no modified properties
Fact: NO "User registered security info" or any registration event between 17:14 and 17:24, yet OATH MFA succeeded at 17:24:49 (case1-20).
Status: UNRESOLVED. Hypotheses: (a) new OATH registered but not audited / export lag, (b) deletion at 17:13:04 did not invalidate the secret. 17:14:00 pair looks like the "require re-register MFA" action (inference, unconfirmed).
Next evidence: Mike's Authentication methods page now.

### Mike authentication methods, final check (case1-22)
"No usable methods", default sign-in method: No default, system preferred MFA method: none. So at check time no OATH method exists, yet an OATH-verified MFA succeeded at 17:24:49 (case1-20). Unexplained; carried into the report as remaining uncertainty.
Analyst has not given an account of what was done at 17:24 (asked several times). Report states this plainly.

### Scope checks (case1-23, case1-24), time range last 7 days
- MicrosoftGraphActivityLogs where IPAddress == 185.111.108.131 since 16:50: no results.
- AzureActivity since 16:50: no results.
Both are "no data", not "no activity": no Azure Activity diagnostic setting was ever configured, and zero Graph rows for the IP does not show the session made no Graph calls (table may be empty or lagging). Needs a baseline count of the Graph table and the portal's own Activity log for 16:50-17:10.

Analyst reports (no screenshot): MicrosoftGraphActivityLogs summarize returned nothing; portal Activity log 16:50-17:10 showed nothing. Recorded in investigation.md as analyst statements. Screenshots would let them be cited as evidence.

### Detection test (case1-25)
Rule query returned 1 row: mike@openhuntx.onmicrosoft.com, 185.111.108.131, NG, FirstSignIn 16:55:52.997, FirstRegistration 16:56:05.000, Registrations 2. True positive confirmed. FP rate untested.

### Analytics rule saved (case1-26..28)
Rule "Single-factor sign-in then MFA registration": Scheduled, Enabled, Medium, tactics Initial Access +1, techniques T1078 +1, sub-technique T1078.004, source Custom Content, last modified 2026-10-20 ~18:5x. Scheduling values chosen in the wizard (15 min / 1 h) were not re-verified on screen after saving.

## Case 3 setup and baseline
Arthur Sterling roles (case3-01): Application Administrator, User Administrator, both Direct / Built-in / scope Directory. Time of assignment NOT recorded by analyst; find in AuditLogs ("Add member to role").

### Baseline sign-ins, rambo and arthur, last 3 h (case3-02), 17 rows
Case 1 leftovers (must be excluded from Case 3 by IP 185.111.108.131): rambo 16:59:45, 17:00:11, 17:00:52 and arthur 17:00:14, 17:00:30, 17:00:52, all 50126, NG, My Apps.
Home (GB, lab workstation, redact IP):
| Time (UTC) | User | App | Auth requirement |
|---|---|---|---|
| 17:02:42 | rambo | Azure Portal | multiFactor |
| 17:07:15 | arthur | Azure Portal | multiFactor |
| 18:00:20 | arthur | Azure Portal | singleFactor |
| 18:02:35 | rambo | Microsoft Account Controls V2 | singleFactor |
| 18:03:10 (x2) | rambo | Microsoft Account Controls V2 | singleFactor |
| 18:04:25 | arthur | My Profile | singleFactor |
| 18:05:11 | arthur | Microsoft Account Controls V2 | singleFactor |
| 18:05:13 | rambo | My Profile | singleFactor |
| 18:05:25 | arthur | Microsoft Account Controls V2 | singleFactor |
| 18:06:05 | arthur | Azure Portal | singleFactor |
Observation: normal home sign-ins in this tenant are mostly SINGLE-factor. So "single-factor" does not separate attacker from user here; it weakens the Case 1 rule (false positives for a legitimate user opening Security info from home).

### Legitimate admin change baseline (case3-03)
18:00:55.949 Add user, actor Arthur, target temp.intern. Baseline admin action (home, GB).

## Case 3 attack state and first read (case3-04 .. case3-10)
Analyst statement (no times recorded): VPN Brazil; 2 wrong passwords each for Mike, Rambo, Arthur; correct password for Arthur, asked for 2FA, added a mobile fingerprint (passkey) as extra method; created user svc-backup01; reset Rambo's password; created app registration and client secret; logged out, VPN off. Analyst said laptop private window; logs show Chrome Mobile / Android (the phone).

### Role assignment (case3-10)
17:58:03.768 Add member to role, Krishna -> Arthur, Application Administrator
17:58:18.179 Add member to role, Krishna -> Arthur, User Administrator
(i.e. ~31 min before the baseline began, ~31 min before 18:29 compromise? no: attack 18:26-18:36)

### Foreign sign-ins (case3-07), BR 149.102.234.29, Chrome Mobile 155 / Android, Azure Portal
| Time (UTC) | User | Result |
|---|---|---|
| 18:26:53 | rambo | 50126 |
| 18:27:09 | mike | 50126 |
| 18:27:09 | rambo | 50126 |
| 18:27:18 | mike | 50126 |
| 18:27:31 | arthur | 50126 |
| 18:27:45 | arthur | 50126 |
| 18:29:03 | arthur | success, singleFactor (Azure Portal) |
| 18:29:12 | arthur | success, multiFactor (Microsoft App Access Panel) |
Home (GB, IPv6, macOS Chrome) rows in same result are the analyst's own: arthur 18:09:30; rambo 18:09:51, 18:10:43, 50140 at 18:11:56 and 18:19:44; mike 50140 18:22:28, 50055 (password expired) 18:23:20, 50126 18:23:55, success 18:25:03; rambo 50203 18:35:55 (must register authenticator; during attack window, unexplained by analyst).
Case 1 leftovers: mike 50133/50126/50126 17:29-17:30 from 185.111.108.130 (NG). Correction applied to Case 1: retest failures came from .130, the 17:24:49 success from .131.

### Arthur audit actions, BR 149.102.234.29 (case3-08; rows 1-14 of 38 NOT seen)
18:30:30-18:30:40 Validate Password x14 (target OpenHuntX). 18:31:22.681 Update PasswordProfile svc-backup01; 18:31:22.820 Add user svc-backup01; 18:31:40.255 Reset password (by admin) target rambo, source IP 48.209.202.236 (not the BR address); 18:36:00.261 Create application - Certificates and secrets management; 18:36:00.309 Add application; 18:36:01.876 Add service principal; 18:36:26.822 Update service principal; 18:36:26.870 Update application - Certificates and secrets management; 18:36:26.871 Update application. All backup-sync from BR IP.
### App credential audit (case3-09): same backup-sync events; plus 17:12:49 Delete platform credential (Case 1 passkey removal, 74.178.40.80), exclude from Case 3.

### State screenshots
case3-04 Users: Arthur, "backup-sync" (UPN svc-backup01@, display name copies the app name), "intern" (temp.intern), Krishna, Mike, Rambo. case3-05: one app, backup-sync, created 20/10/2026, certificates & secrets "Current". case3-06 Arthur methods: Software OATH token + Passkey (Google Password Manager); default OATH TOTP; system preferred Fido2.

### Arthur audit actions, noise removed, all 16 rows (case3-11)
| Time (UTC) | Operation | Target | Source IP |
|---|---|---|---|
| 18:00:55.801 / .949 | Update PasswordProfile / Add user | temp.intern | <home-ip> (home, baseline) |
| 18:27:54.380 (x2) | Get passkey creation options | Arthur | 23.98.196.174 |
| 18:29:11.302 | User registered security info | Arthur | 23.98.196.167 |
| 18:29:19.000 | User registered all required security info | Arthur | 149.102.234.29 (BR) |
| 18:29:19.539 | User registered security info | Arthur | 23.98.196.171 |
| 18:31:22.681 / .820 | Update PasswordProfile / Add user | svc-backup01 | 149.102.234.29 |
| 18:31:40.255 | Reset password (by admin) | rambo | 48.209.202.236 |
| 18:36:00.261 .. 18:36:26.871 | app create, service principal, secret (6 events) | backup-sync | 149.102.234.29 |
Timing oddity: passkey creation options logged 18:27:54, ~70 s BEFORE the first successful Arthur sign-in in SigninLogs (18:29:03). Same kind of offset as Case 1 (11 s). Cause not established (sign-in log may be stamped at completion). 23.98.196.x and 48.209.202.236 not identified (suspected Microsoft-side), unverified.

### Use of the backdoor (case3-12)
No SigninLogs / AADNonInteractiveUserSignInLogs / AADServicePrincipalSignInLogs rows for svc-backup01 or backup-sync after 18:30. Persistence created but no use observed so far.
Open: analyst has not yet shown the Sentinel Incidents page (did the Case 1 rule fire on Arthur?) nor explained rambo 50203 at 18:35:55 from the home Mac.

### Incidents page (case3-13)
3 incidents, all "Single-factor sign-in then MFA registration", Medium, category Persistence, source Microsoft Sentinel / Scheduled detection, 1 alert each.
- Incident 1: last activity 6:46 PM, last update 6:51 PM
- Incident 2: last activity 7:31 PM, last update 7:36 PM
- Incident 3: last activity 7:31 PM, last update 7:36 PM
Times are in the portal's display timezone (probably BST = UTC+1; not confirmed). Which user each incident is for NOT yet established (impacted assets column empty / not visible). Hypothesis: 1 = Mike (Case 1), 2/3 = Arthur (Case 3), unverified.

### Analyst statements (not verified by me)
- Arthur sign-in log is stamped when authentication completes (explains passkey-creation audit events appearing ~70 s before the logged sign-in: registration happened inside the sign-in flow).
- The rambo 50203 sign-in at 18:35:55 from the home Mac: analyst "checked the rambo password" (own activity, during attack window).

### Incident details (case3-14 inc 2, case3-15 inc 3, case3-16 inc 1), portal display time (likely BST = UTC+1)
| Incident | First activity | Last activity | Created |
|---|---|---|---|
| 1 | 5:46:18 PM | 6:46:18 PM | 6:51:30 PM |
| 2 | 6:31:18 PM | 7:31:18 PM | 7:36:38 PM |
| 3 | 6:31:18 PM | 7:31:18 PM | 7:36:39 PM |
All: Medium, Active, Unassigned, "Evidence: No evidence found" (no entity mapping, so the incidents do not name the account), 4 MITRE factors (T1098, T1078.004, T1078, Persistence TA0003/TA0110), "ranked as low priority", 1 alert each.
First/last activity = the rule's 1-hour lookback window, not event times.
Inference (BST): inc 1 window 16:46-17:46 UTC contains Mike's 16:55-16:56 registration -> Mike. Inc 2 and 3 window 17:31-18:31 UTC contain Arthur's 18:29 events. Two incidents from one run, 1 second apart = two result rows. Hypothesis: (arthur, BR) and (arthur, home GB) because the rule joins ANY single-factor sign-in in the previous 30 min, not the same IP. UNVERIFIED: need the rule query run over 24 h.

### Rule v1 run over 24 h (case3-17): three rows
| User | SignInIP | Country | FirstSignIn | FirstRegistration | Registrations |
|---|---|---|---|---|---|
| arthur | 149.102.234.29 | BR | 18:29:03 | 18:29:11 | 2 |
| arthur | <home-ip> | GB | 18:00:20 | 18:29:11 | 12 |
| mike | 185.111.108.131 | NG | 16:55:52 | 16:56:05 | 2 |
Confirms the v1 false positive: Arthur's own home sign-in (18:00:20) is paired with the attacker-driven registration at 18:29:11 because v1 matches any single-factor sign-in in the prior 30 min. 3 rows = 3 incidents. v2 written (country-novelty), untested.

### Rule v2 test 1, Arthur (case3-18)
Result: 1 row. arthur, BR, 149.102.234.29, FirstSignIn 18:29:03.701, FirstRegistration 18:29:11.302, Registrations 3. The GB (home) row from v1 is gone. Registrations is 3 not 2 because v2 no longer requires single-factor, so the 18:29:12 MFA sign-in is counted too.
The first line (the `let asof` value) is scrolled out of view in the screenshot; analyst was told to use datetime(2026-10-20 18:40). Test 2 (Mike, asof 17:40) still to run.

### Rule v2 test 2, Mike (case3-19)
`let asof = datetime(2026-10-20 17:40);` visible. 1 row: mike, NG, 185.111.108.131, FirstSignIn 16:55:52.997, FirstRegistration 16:56:05.000, Registrations 2. Caveat: no prior history for Mike in the workspace. Screenshot's bottom status bar shows the subscription ID: crop/blur before publishing.

### Rule wizard limit (case3-20)
Entering Run every 15 minutes with Lookup 7 days is rejected: "When the selected lookup period is greater than, or equal to 2 days, the frequency must be greater than, or equal to 1 hour." Decision: keep 15-minute detection, lookup 1 day, history 1d in the saved query. Trade-off documented in the .kql file.

### Analytics list with v2 saved (case3-21)
Two rules, both Scheduled and Enabled: "New-country sign-in then MFA registration" (Persistence, T1098 +1, T1078.004; last modified 20/10/2026 20:0x portal time) and "Single-factor sign-in then MFA registration" (Initial Access +1, T1078 +1, T1078.004). v1 NOT yet disabled. Entity mapping on v2 not verified on screen.

### Rules (case3-22): v1 "Single-factor sign-in then MFA registration" Disabled; v2 "New-country sign-in then MFA registration" Enabled. Entity mapping on v2 still not confirmed on screen.

### Case 3 containment end state (case3-23 .. case3-26); analyst did not record times, take from AuditLogs
- Arthur methods: "No usable methods", no default, no preferred. So BOTH the attacker's passkey and Arthur's original OATH token are gone (which action removed the OATH not recorded; likely Require re-register MFA). Same trade-off as Case 1.
- Rambo methods: Software OATH token still present (default OATH TOTP, preferred SoftwareOTP). Attacker had not changed Rambo's methods; only the password was reset.
- Users list: 5 users (Arthur, intern/temp.intern, Krishna, Mike, Rambo). svc-backup01 gone. Deleted-users tab not shown (soft delete, restorable ~30 days).
- App registrations > All applications: "There are no applications here". Deleted applications tab not shown.
Retest and audit verification still to do.

### Case 3 containment in AuditLogs (case3-27, case3-28), all actor Krishna unless noted, UTC
| Time | Operation | Target |
|---|---|---|
| 19:07:40.877 | Update StsRefreshTokenValidFrom Timestamp (revoke sessions) | Arthur |
| 19:07:40.878 | Update user | Arthur |
| 19:07:52.709 | Admin deleted security info | Arthur |
| 19:07:54.918 | Delete platform credential (no actor shown) | - |
| 19:07:54.920 | Admin deleted security info | Arthur |
| 19:08:02.424 | Reset password (by admin) | Arthur |
| 19:08:45.942 | Update StsRefreshTokenValidFrom Timestamp | Rambo |
| 19:08:45.943 | Update user | Rambo |
| 19:08:56.515 | Reset password (by admin) | Rambo |
| 19:09:29.855 | Delete user | svc-backup01 |
| 19:10:10.356 | Remove service principal | backup-sync |
| 19:10:10.407 | Delete application | backup-sync |
Two deletions of security info on Arthur (19:07:52 and 19:07:54) explain why both the passkey and his original OATH token are gone: they were deleted explicitly, not by Require re-register MFA. Correction to earlier note.
Time from attacker's first success (18:29:03) to first containment action (19:07:40) = 38 min 37 s. Lab artefact: analyst waited for logs before containing.
Retest (VPN Brazil) results still to come.

### Query error (case3-29)
union SigninLogs, AADNonInteractiveUserSignInLogs then project LocationDetails -> "Failed to resolve scalar expression named 'LocationDetails'". Cause (inference): column is dynamic in SigninLogs and string in the non-interactive table, so union splits it into typed columns. Fix: project the country inside each table before the union. Retest results not yet read.

### Case 3 retest (case3-30), 7 rows, UTC
| Time | Table | User | Result | IP / country | Note |
|---|---|---|---|---|---|
| 19:11:25 | non-interactive | arthur | 50133 session invalid (password change) | home IPv6, GB | home browser session, not the attacker's |
| 19:11:31 | non-interactive | arthur | 50173 grant expired, revoked | home IPv6, GB | same |
| 19:16:48 | interactive | arthur | 50126 bad password | 149.102.234.112, BR | old password, VPN |
| 19:16:55 | interactive | arthur | 50126 bad password | home IPv6, GB | analyst from the Mac (not asked for) |
| 19:19:04 | interactive | rambo | 50126 bad password | 149.102.234.112, BR | old password, VPN |
| 19:32:45 | non-interactive | rambo | 50133 | <home-ip>, GB | home browser session |
| 19:33:14 | non-interactive | rambo | 50173 grant revoked | <home-ip>, GB | home browser session |
No successful sign-in from BR after containment. No svc-backup01 row (a sign-in to a deleted/non-existent account may simply not be logged; not verified). No BR non-interactive row, so a reload of the attacker's own session is NOT evidenced; revocation is evidenced on the home sessions only. BR address now .112 (was .29).

## Case 2 lab setup (Windows endpoint)
- Decision trail: Defender for Endpoint P2 (GBP 4.80/month) considered but the spare laptop is Windows 11 Home (not supported), so not used; Azure VM chosen. Spot VM rejected (eviction risk).
- VM win-endpoint01: Windows Server 2025 Datacenter Gen2, Standard D2alds_v6 (2 vCPU, 4 GiB, USD 0.207/h), UK West, own resource group win-endpoint01_group_83995645, Standard SSD, no Spot, auto-shutdown 02:00 GMT, NSG win-endpoint01-nsg, user labadmin. Created 21:52 UTC. Public IP redacted later. (case2-00)
- First RDP attempt failed with 0x704 because the NSG had only default rules incl. 65500 DenyAllInBound (case2-00b, case2-00c). Fix: inbound allow rule for RDP from the analyst's own IPv4 only.
- Connected via Windows App at about 22:11 VM time (case2-01).
- Audit policy enabled (case2-02): Process Creation (Success and Failure), Other Object Access Events (Success and Failure), registry ProcessCreationIncludeCmdLine_Enabled = 1.
- Telemetry pipeline (Windows Security Events via AMA connector + DCR dcr-win-security) NOT yet confirmed.

### Windows Security Events via AMA connector (case2-03, case2-04)
Before: Disconnected, rule table "No results". After creating the DCR: status Connected, rule dcr-win-security (created by Sentinel, filter AllEvents). "Last log received" still "--" at screenshot time. SecurityEvent table not yet checked.

### Agent on the VM (case2-05)
Extensions on win-endpoint01: AzureMonitorWindowsAgent, version 1.45.0.0 (latest 1.45.0.0), Provisioning succeeded, automatic upgrade Disabled. Installed by the DCR creation. Data arrival in SecurityEvent still to confirm.

### Case 2 baseline on the VM (case2-06, case2-07), analyst did not record clock times
Commands run as win-endpoint01\labadmin in an elevated PowerShell: whoami, ipconfig /all, Get-Process (first 5), schtasks /create /tn "DailyLogCleanup" /tr "C:\Windows\System32\cleanmgr.exe /sagerun:1" /sc daily /st 03:00 /ru SYSTEM -> "SUCCESS: The scheduled task ... has been created." The follow-up schtasks /query printed no output in the screenshot (cut off or not yet shown).
VM clock appears to be UTC (DHCP lease obtained 9:53:37 PM on 2026-10-20, matching the 21:52 UTC creation time).
Background processes seen: AzureArcSysTray (Azure Arc agent present by default on Server 2025), AMAExtHealthMonitor (Azure Monitor Agent), AggregatorHost, conhost. Treat as benign noise.
Baseline task: DailyLogCleanup, SYSTEM, daily 03:00, cleanmgr.exe. Legitimate-looking admin persistence to contrast with the attack.

### Telemetry confirmed (case2-08 heartbeat, case2-09 counts, case2-10 baseline rows)
- Heartbeat: Azure Monitor Agent, 2 beats, last 22:21:11 UTC.
- SecurityEvent by EventID (all times UTC, 2026-10-20): 4688 x19 (22:17:02-22:21:19), 4799 x8, 4702 x6, 4673 x5, 4624 x3, 4627 x3, 4672 x3, 4698 x1 (22:19:30.607).
- Baseline captured, correcting my earlier guess that it predated the agent: the first "No results" was ingestion lag. Baseline rows (case2-10): whoami.exe 22:19:29.986, ipconfig.exe /all 22:19:30.048, schtasks.exe /create /tn DailyLogCl... 22:19:30.535, 4698 (task created) 22:19:30.607, all account win-endpoint01\labadmin.
- Earlier rows are agent/system noise: AzureMonitorAgentExtension, AMAExtHealthMonitor, MetricsExtension, MonAgent*, conhost, WmiApSrv, WmiPrvSE, VSSVC, svchost -k swprv; account WORKGROUP\win-endpoint01$.

## Case 2 attack, Block A (execution), VM clock UTC (case2-11)
- 22:24:07 start (Get-Date), 22:24:50 end. No error, no Defender prompt visible in the screenshot.
- Steps: $enc = base64 UTF-16LE of `whoami /all > C:\Users\Public\o.txt; net user >> ...; net localgroup administrators >> ...`; Set-Content C:\Users\Public\invoice_update.cmd with `@echo off` + `powershell.exe -NoP -W Hidden -Enc $enc`; cmd.exe /c C:\Users\Public\invoice_update.cmd.
- Expected 4688 chain: powershell.exe (labadmin) -> cmd.exe -> powershell.exe -NoP -W Hidden -Enc -> whoami.exe / net.exe / net1.exe.
- Block B (persistence: task OneDriveSyncHelper, Run key OneDriveSync, local admin helpdesk01) not yet run.

### Block B and payload check (case2-12). SENSITIVE: lab password visible in this screenshot, blur before publishing
- Payload check: Get-Content C:\Users\Public\o.txt shows USER INFORMATION, win-endpoint01\labadmin, SID ...-500 -> the hidden encoded PowerShell ran and wrote its output.
- Block B started 22:25:58 (Get-Date). End Get-Date was typed but not executed in the screenshot; take the end from the logs.
- schtasks /create /tn OneDriveSyncHelper /tr C:\Users\Public\invoice_update.cmd /sc onlogon /ru SYSTEM /f -> SUCCESS
- reg add HKCU\...\Run /v OneDriveSync ... /d C:\Users\Public\invoice_update.cmd /f -> completed successfully
- net user helpdesk01 <lab password> /add -> warning that password >14 chars, analyst answered y, completed
- net localgroup administrators helpdesk01 /add -> completed
No Defender block or prompt seen.

### Case 2 attack in SecurityEvent (case2-13: rows 2-26 of 26, first row scrolled out; case2-14: 4698 raw), account win-endpoint01\labadmin, UTC
| Time | EventID | What |
|---|---|---|
| 22:24:08.354 | 4688 | whoami.exe /all, parent powershell.exe |
| 22:24:08.417 / .449 | 4688 | net.exe user; net1 user |
| 22:24:08.474 / .495 | 4688 | net.exe localgroup administrators; net1 |
| 22:24:16.833 | 4688 | powershell.exe, parent C:\Windows\explorer.exe (a new PowerShell launched from Explorer) |
| 22:24:16.847 | 4688 | conhost.exe |
| 22:24:21.596 | 4688 | cmd.exe /c C:\Users\Public\invoice..., parent powershell.exe |
| 22:24:21.619 | 4688 | powershell.exe -NoP -W Hidden -Enc dwBoAG8AYQBtAGkAIAAvAGEAbABsAC... parent cmd.exe |
| 22:24:21.937 .. 22:24:22.031 | 4688 | whoami /all, net user, net localgroup administrators (+ net1), parent powershell.exe (the encoded payload) |
| 22:25:58.417 | 4688 | schtasks.exe /create /tn OneDriveS... |
| 22:25:58.469 | 4698 | task created (OneDriveSyncHelper) |
| 22:25:58.506 | 4688 | reg.exe add HKCU\Software\Micros... (Run key) |
| 22:25:58.548 / .566 | 4688 | net user helpdesk01 Lab-Only-... /add (password in the command line), net1 |
| 22:26:01.009 | 4720 | user account created: helpdesk01 |
| 22:26:01.057 | 4732 | member added to Users |
| 22:26:01.113 / .133 | 4688 | net localgroup administrators helpdesk01 ..., net1 |
| 22:26:01.156 | 4732 | member added to Administrators |
OPEN: the 22:24:08 chain (parent powershell.exe) appears ~13 s before the logged cmd.exe launch and ~1 s after the Get-Date at 22:24:07, and an Explorer-launched powershell.exe starts at 22:24:16. Analyst has not explained either. 4698 EventData is raw XML (case2-14); TaskName/TaskContent not yet extracted. Command lines are truncated in the grid.
Baseline 4698 22:19:30.607 and attack 4698 22:25:58.469 are the only two task-creation events.

### 4698 task details (case2-15)
22:19:30.607 TaskName \DailyLogCleanup (baseline), author win-endpoint01\labadmin, URI \DailyLogCleanup.
22:25:58.469 TaskName \OneDriveSyncHelper, author win-endpoint01\labadmin, date 2026-10-20T22:25:58, URI \OneDriveSyncHelper. TaskContent truncated in the grid (action/trigger not read).

### Key command lines (case2-16), account labadmin
| Time | Parent | CommandLine |
|---|---|---|
| 22:24:07.876 | cmd.exe | powershell.exe -NoP -W Hidden -Enc dwBoAG8AYQBtAGkAIAAv... |
| 22:24:21.619 | cmd.exe | powershell.exe -NoP -W Hidden -Enc dwBoAG8AYQBtAGkAIAAv... (same) |
| 22:25:58.417 | powershell.exe | "C:\Windows\system32\schtasks.exe" /create /tn OneDriveSyncHelper /tr C:\Users\Public\invoice_update.cmd /sc onlogon /ru SYSTEM /f |
| 22:25:58.506 | powershell.exe | "C:\Windows\system32\reg.exe" add HKCU\Software\Microsoft\Windows\CurrentVersion\Run /v OneDriveSync /t REG_SZ /d C:\Users\Public\invoice_update.cmd /f |
NEW FACT: the encoded PowerShell was launched TWICE, 22:24:07.876 and 22:24:21.619, both with parent cmd.exe, each followed by the same whoami/net discovery chain (22:24:08 and 22:24:21). With the Explorer-launched powershell.exe at 22:24:16.833 between them. Analyst account of this: pending. The analyst's screenshot case2-11 shows a single run in one window.
The net user / net localgroup command lines were not matched by the has_any filter because the 4688 line is "net.exe" user ... (not the contiguous string "net user"); they are in case2-13.

### Persistence proof after restart (case2-17 counts, case2-18 rows 47-71 of 71), UTC
Analyst restarted the VM (no Sign out option on Server edition shown), then RDP'd back in. Time of the analyst's re-login not noted; from the log:
| Time | EventID | Account | Detail |
|---|---|---|---|
| 22:32:35.822 | 4624 | win-endpoint01\labadmin | LogonType 3 (network) |
| 22:32:37.196 | 4624 | win-endpoint01\labadmin | LogonType 10 (RemoteInteractive, RDP) |
| 22:32:37.757 | 4688 | WORKGROUP\win-endpoint01$ (SYSTEM) | C:\Windows\SYSTEM32\cmd.exe /c ""C:\Users\Public\invoice_update.cmd"" (scheduled task OneDriveSyncHelper, 0.56 s after the RDP logon) |
| 22:32:43.080 | 4688 | SYSTEM | powershell.exe -NoP -W Hidden -Enc dwBoAG8... |
| 22:34:12.321 | 4688 | win-endpoint01\labadmin | parent explorer.exe: cmd.exe /c ""C:\Users\Public\invoice_update.cmd"" (Run key OneDriveSync) |
| 22:34:13.121 | 4688 | win-endpoint01\labadmin | powershell.exe -NoP -W Hidden -Enc ... |
Both persistence mechanisms fired: task as SYSTEM at logon, Run key as labadmin via explorer.exe ~95 s later. Parent of the SYSTEM cmd.exe is truncated in the grid (not read). Many 4624 LogonType 5 NT AUTHORITY\SYSTEM rows are service logons from the restart (noise). Case2-17 (at ~22:31) shows 4688 x36, 4673 x16, 4627/4672/4624 x9 etc: events were flowing right after the restart.
Open: analyst's explanation of the double execution at 22:24:07.876 / 22:24:21.619 still missing.

### Case 2 containment on the VM (case2-19), VM clock UTC
- 22:36:02 start, 22:36:04 end (Get-Date).
- schtasks /delete /tn OneDriveSyncHelper /f -> SUCCESS deleted
- reg delete HKCU\...\Run /v OneDriveSync /f -> completed
- net localgroup administrators helpdesk01 /delete -> completed; net user helpdesk01 /delete -> completed
- Remove-Item invoice_update.cmd, o.txt -> no error
Verification: schtasks /query OneDriveSyncHelper -> "ERROR: The system cannot find the file specified."; reg query ... OneDriveSync -> "unable to find the specified registry key or value"; net user helpdesk01 -> "The user name could not be found."; Test-Path invoice_update.cmd -> False; schtasks /query DailyLogCleanup -> still present, Ready, next run 10/21/2026 3:00:00 AM (baseline task intentionally kept).
Next: restart + re-login, confirm nothing launches invoice_update.cmd; check 4699 / 4726 / 4733 in the log.

### Recovery check after the second restart (case2-20, case2-21, case2-22), UTC
- Re-login (case2-20): 4624 labadmin LogonType 3 at 22:37:49.858 and LogonType 10 at 22:37:51.219. The analyst wrote "20:37" for restart and return; the log says 22:37:51, so the analyst's number was presumably typed on a different clock or mistyped.
- Nothing launched the script (case2-21): query for 4688 with CommandLine has invoice_update or -Enc, TimeGenerated > 22:37 -> "No results found". Caveat: only as complete as ingestion at query time; the first persistence test fired within 1 s of logon, so absence is informative, but a very late event could be missed.
- Removal in the log (case2-22): 22:36:02.905 schtasks /delete /tn OneDriveSyncHelper /f; 22:36:02.933 4699 (task deleted); 22:36:02.960 reg delete ... /v OneDriveSync /f; 22:36:03.028 4733 member removed (target Administrators); 22:36:03.097 4733 (target Users) and 4726 user account deleted (helpdesk01); 22:36:10.506 schtasks /query OneDriveSyncHelper; 22:36:10.559 reg query ...Run /v OneDriveSync; 22:36:11.552 schtasks /query DailyLogCleanup.
- Noise: 22:38:35 SYSTEM cmd.exe/reg.exe query hklm\...\softwareinventorylogging /v collectionstate /reg:64 (built-in Windows telemetry).
- net.exe user /delete and net localgroup /delete 4688 rows not matched by my has_any filter ("net user" is not contiguous in "net.exe" user ...), the 4726/4733 events cover them.
- Detection rule written: detections/encoded-powershell-then-persistence.kql, untested.

### Analyst statement on the double execution
"I don't remember what I did" about the two launches of the encoded PowerShell at 22:24:07.876 and 22:24:21.619 (and the Explorer-launched powershell.exe at 22:24:16.833). Recorded as UNEXPLAINED in the report. Hypotheses (not tested): Block A pasted twice; a second PowerShell window opened from Explorer.

### Rule syntax error (case2-23)
Detection draft failed to parse: "A syntax error ... Query could not be parsed at 'to' on line [2,5]". Cause: `to` is a reserved word in KQL (used in `range ... to ...`). Variables renamed to tstart / tend in detections/encoded-powershell-then-persistence.kql. Tests A and B not yet run on the fixed version.

### Rule tests (case2-24 attack window, case2-25 baseline window), tstart/tend visible
Test A tstart 22:23 tend 22:30: 1 row. win-endpoint01, labadmin, FirstEncoded 22:24:07.876, FirstPersistence 22:25:58.417, PersistenceEvents [4688,4698,4720], Count 8.
Test B tstart 22:15 tend 22:22: "No results found". The baseline window contains no encoded PowerShell, so it only shows that the legitimate scheduled-task creation does not alert alone.
