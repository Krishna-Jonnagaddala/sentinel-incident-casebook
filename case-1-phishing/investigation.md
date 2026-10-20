# Case 1: Phishing victim, then suspicious activity on the account

Lab: Microsoft Sentinel workspace `law-ir-case-study`, Entra ID tenant `openhuntx` (P2 trial).
All times UTC, 2026-10-20. Screenshots are cited as **[E#]**; the index is at the bottom.

## Read this first: what is real and what is staged

This is a lab. The "attacker" is me, on an Android phone behind a VPN exiting in Nigeria. That has consequences for what the case can claim:

- **Staged:** the phishing email itself. The tenant has no mailboxes and no email telemetry, so there is no message to inspect. The case starts from a user report that Mike entered his password on a fake sign-in page. Everything after that is real telemetry.
- **Staged:** the attacker already had Mike's password. MFA bypass (token theft, push fatigue) was not simulated.
- **Real:** every sign-in, audit event and containment action below was generated in the tenant and read back from the workspace.
- **I did not record the clock time of my own actions as I went.** The logs are the source of truth for timing.

Facts, inferences and unknowns are labelled in each section.

## 1. Trigger and available telemetry

**Trigger:** a user report (simulated): Mike Tyson, Accounts Payable Analyst, says he typed his password into a fake document-sharing page.

**No alert fired.** The workspace had zero incidents. Identity Protection raised nothing: `RiskState = none` and `RiskEventTypes_V2` empty on every sign-in [E7]. That is itself a finding (see section 9).

Telemetry exported to the workspace: SigninLogs, AADNonInteractiveUserSignInLogs, AuditLogs, ServicePrincipalSignInLogs, ManagedIdentitySignInLogs, RiskyUsers, UserRiskEvents, MicrosoftGraphActivityLogs.

**Known gaps in the telemetry**
- SigninLogs has nothing for Mike before 16:55:52, though the Entra portal shows sign-ins from 16:28 [E1]. I rechecked later and the gap remained.
- AuditLogs has no event for the registration of Mike's authenticator (OATH) token, although export was working at 16:31.
- Email telemetry does not exist in this lab.

## 2. Timeline

| Time | Event | Type | Ref |
|---|---|---|---|
| 16:28–16:30 | Mike signs in from the lab workstation (GB), including two deliberate wrong-password attempts | Fact (portal only, not in Sentinel) | E1 |
| 16:54:33 | First sign-in from `185.111.108.131` (NG): non-interactive token use, Azure Portal to Microsoft Graph | Fact | E4 |
| 16:55:42 | Passkey registration started on Mike's account | Fact | E6 |
| 16:55:52 | First interactive success from NG: Chrome Mobile on Android, single-factor | Fact | E2, E7 |
| 16:56:05 | Passkey registered; `InitiatedFrom: My Signins`; Fido2 method added | Fact | E6 |
| 16:56:17 | Sign-in from Chrome on macOS (GB), error 50072 (MFA enrolment required) | Fact; actor unconfirmed | E2 |
| 16:56:34 – 17:04:41 | 41 non-interactive events against My Signins from NG | Fact | E5 |
| 16:58:10 | Sign-in from Chrome on macOS (GB), success, MFA required | Fact; actor unconfirmed | E2 |
| 16:59:45, 17:00:11 | Failed sign-ins (50126) as **rambo** from NG | Fact | E2 |
| about 17:00 | Three failed sign-ins as **arthur** from NG | Fact (counts from summary) | E3 |
| 17:12:24 | Sessions revoked by admin | Containment | E9 |
| 17:12:49 | Passkey deleted | Containment | E9 |
| 17:13:04 | OATH token deleted | Containment | E9 |
| 17:13:33–34 | Password reset by admin | Containment | E9 |
| 17:14:00 | Further `Update user` (StrongAuthenticationUserDetails) and a third "Admin deleted security info" | Containment (purpose inferred) | E12 |
| 17:24:49 | Retest from NG: success, MFA completed with an OATH code | Fact; unexplained | E11 |
| 17:29:10 | Retest: 50133 (session invalid, password changed) and 50126 (bad password) | Fact | E11 |
| 17:30:16 | Retest: 50126 | Fact | E11 |

## 3. Investigation questions and KQL

**Q1. Where did Mike's account sign in from, and did it look normal?**
```kql
SigninLogs
| where UserPrincipalName =~ "mike@openhuntx.onmicrosoft.com"
| project TimeGenerated, ResultType, IPAddress, Country = tostring(LocationDetails.countryOrRegion),
          AppDisplayName, Browser = tostring(DeviceDetail.browser), OS = tostring(DeviceDetail.operatingSystem),
          AuthenticationRequirement
| order by TimeGenerated asc
```
Answer: two countries, two devices, overlapping within 25 seconds (16:55:52 NG, 16:56:17 GB) [E2].

**Q2. Did anything change on the account?**
```kql
AuditLogs
| where OperationName in ("User registered security info", "User started security info registration")
| project TimeGenerated, OperationName, Actor = tostring(InitiatedBy.user.userPrincipalName),
          Details = tostring(AdditionalDetails), Modified = tostring(TargetResources[0].modifiedProperties)
| order by TimeGenerated asc
```
Answer: a passkey (Fido2) was registered from My Signins, from the NG address [E6].

**Q3. What did the foreign session do?**
```kql
AADNonInteractiveUserSignInLogs
| where TimeGenerated > ago(24h) and UserPrincipalName =~ "mike@openhuntx.onmicrosoft.com"
| summarize Events = count(), First = min(TimeGenerated), Last = max(TimeGenerated) by AppDisplayName, IPAddress
| order by Events desc
```
Answer: 73 events in 8 apps, 41 against My Signins, from 16:54:33 to 17:04:41 [E4, E5].

**Q4. Did it spread to other accounts?**
```kql
SigninLogs
| where TimeGenerated > ago(24h)
| summarize Attempts = count(), Failures = countif(ResultType != "0"),
            Countries = make_set(tostring(LocationDetails.countryOrRegion)) by UserPrincipalName, IPAddress
| order by Attempts desc
```
Answer: the same NG address made 3 failed attempts each against rambo and arthur; none succeeded [E3].

**Q5. Did Microsoft's own risk scoring or Conditional Access see it?**
```kql
SigninLogs
| where UserPrincipalName =~ "mike@openhuntx.onmicrosoft.com"
| project TimeGenerated, IPAddress, RiskLevelDuringSignIn, RiskState, RiskEventTypes_V2,
          ConditionalAccessStatus, AuthenticationRequirement
```
Answer: no risk detection, no Conditional Access applied, and the NG sign-ins were single-factor [E7].

**Q6. Was containment effective?**
```kql
union SigninLogs, AADNonInteractiveUserSignInLogs
| where TimeGenerated > datetime(2026-10-20 17:12)
| where UserPrincipalName =~ "mike@openhuntx.onmicrosoft.com"
| project TimeGenerated, Type, ResultType, ResultDescription, IPAddress, AppDisplayName
| order by TimeGenerated asc
```
Answer: partly; see section 8.

Two of my queries failed first and had to be fixed, both because a column is a string rather than a dynamic type in that table: `LocationDetails` in AADNonInteractiveUserSignInLogs and `AuthenticationDetails` in SigninLogs. The fix is `parse_json()`. The failed runs are kept in the evidence folder.

## 4. Affected accounts, devices and resources

| Item | Status | Basis |
|---|---|---|
| Mike Tyson | **Compromised** | Foreign session, new passkey, no MFA challenge [E2, E6, E7] |
| Rambo Craig | Probed, no success seen | 3 failures from the same address [E3] |
| Arthur Sterling | Probed, no success seen | 3 failures from the same address [E3] |
| Attacker device | Android, Chrome Mobile 155, via NG address `185.111.108.131` | SigninLogs |
| Resources touched | Azure Portal, Azure Resource Manager, My Signins, My Profile, My Apps, Microsoft Graph | [E5] |

**Scope of what the session did: not established.**
- MicrosoftGraphActivityLogs returned no rows for the attacker address [E14]. I then checked whether the table holds any data at all and it showed nothing (my statement; no screenshot kept), so the empty result says the logging produced nothing, not that no Graph calls were made.
- Azure Activity was never connected to the workspace, so the workspace cannot see subscription changes [E15]. Checking the portal's own Activity log for 16:50 to 17:10 also showed nothing (my statement; no screenshot kept).
- So the only activity I can show is sign-in and authentication-method activity. I cannot rule out data access.

## 5. Evidence for the conclusion

Conclusion: **Mike's account was accessed by someone other than Mike, who then registered a passkey to keep access.**

1. Two countries and two devices within 25 seconds [E2]. (Inference: this is not one person travelling.)
2. The passkey was registered from the foreign session, and its detail is "Google Password Manager", consistent with an Android phone [E6, E8]. (Fact for the first part; inference for the device.)
3. The foreign sign-ins did not require MFA, so a password was enough [E7]. (Fact.)
4. The same address then tried two other accounts and failed [E3]. (Fact; inference: credential testing.)

## 6. Alternative explanations I ruled out (or could not)

| Alternative | Verdict | Why |
|---|---|---|
| Mike himself on a VPN or a second device | **Not fully ruled out from logs alone** | In a real case I would call Mike. The pattern argues against it: different OS and browser, a new security method added, and probing of two colleagues. In this lab I know the answer, because it was me. |
| "Add service principal" events were the attacker installing an app | **Ruled out** | Initiator is "Microsoft Azure AD Internal – Jit Provisioning", the targets are Microsoft apps (People Profile Event Proxy, Azure RBAC Data Plane), and they began before the foreign sign-in [lab-10]. |
| Failed sign-ins for rambo and arthur were typos | **Ruled out** | Same source address and device as the compromised session, two accounts, bad passwords, within minutes [E3]. |
| The passkey was registered by Mike | **Ruled out** | `InitiatedFrom: My Signins` from the NG address during the foreign session [E6]. |
| Identity Protection would have caught it | **Disproved** | No detection fired [E7]. |

## 7. Observed, inferred, unknown

**Observed:** everything in the timeline marked Fact.
**Inferred:**
- The NG sign-ins are the attacker (lab ground truth).
- The AuditLogs entries from `74.178.57.x` addresses are Microsoft-side processing, not a third party. Not verified.
- The 17:14:00 pair is the "Require re-register MFA" action. Not confirmed.

**Unknown:**
- Who registered Mike's OATH token, and when. No audit event exists for it.
- What the Mac sign-ins at 16:56:17 and 16:58:10 were. I did not note my own actions.
- What Graph and Azure activity the attacker session performed (both sources empty or not collected).
- Why an OATH code was accepted at 17:24:49 (section 8).

## 8. Containment, recovery checks, remaining uncertainty

**Done**, in this order [E9, E10, E13]: revoke sessions; delete the passkey and the OATH token; reset the password; require MFA re-registration (inferred from the 17:14:00 events).

**Recovery checks**
- Old session rejected: 17:29:10 returned 50133 "session is not valid due to password expiration or recent password change" [E11]. Pass.
- Old password rejected: 50126 at 17:29:10 and 17:30:16 [E11]. Pass.
- Account state: no authentication methods remain, no default method [E13]. Pass.
- **Not passed, not understood:** at 17:24:49 a sign-in from the NG address succeeded and MFA was completed with an OATH verification code [E11]. The OATH token had been deleted at 17:13:04 and no registration appears in AuditLogs between 17:14 and 17:24 [E12], and the methods page showed none afterwards [E13]. Possible explanations: a new OATH method was registered without an audit entry; or the earlier deletion did not invalidate the old secret on the phone's authenticator. I have not tested either. I also did not note what I did on the phone at that time, so I cannot say whether this sign-in used the new password.

**Remaining recommended actions** (not yet done in the lab)
- Re-run the 17:24 test after re-enrolling MFA, to see whether an old code is accepted.
- Connect the Azure Activity log to the workspace and find out why MicrosoftGraphActivityLogs is empty, so a repeat of this case has that visibility.
- Enforce MFA for all users through Conditional Access or security defaults.
- Review the other two accounts for any successful sign-in from the same address.

## 9. Detection improvement

No alert fired on a foreign, single-factor sign-in followed by a new authentication method. See [`detections/case1-new-signin-then-mfa-registration.kql`](../detections/case1-new-signin-then-mfa-registration.kql). Status: run against this data and it flags Mike once (first sign-in 16:55:52, first registration 16:56:05, two registrations) [E16]. It is now saved as a scheduled analytics rule, enabled, severity Medium, mapped to Initial Access / T1078.004 and one Persistence technique [E17]. False-positive rate is **untested**: the workspace has only hours of history and no normal baseline.

**Later correction (found in Case 3):** this version pairs a registration with *any* single-factor sign-in in the previous 30 minutes, not the one it came from. On Case 3 data it raised a false positive on an admin's own home sign-in, and one attack produced two incidents. In this tenant normal home sign-ins are also mostly single-factor, so that condition does not separate attacker from user. It is replaced by a country-novelty version, [`detections/new-country-signin-then-mfa-registration-v2.kql`](../detections/new-country-signin-then-mfa-registration-v2.kql), and the original rule is disabled but kept.

## Evidence index

| ID | File | Shows |
|---|---|---|
| E1 | [lab-12](../lab-setup/img/lab-12-entra-signin-logs-source.png) | Entra portal sign-ins, including 16:28 baseline |
| E2 | [case1-02](img/case1-02-signinlogs-mike-rambo-arthur.png) | SigninLogs for the three accounts |
| E3 | [case1-05](img/case1-05-signin-summary-by-ip.png) | Sign-ins summarised by user and IP |
| E4 | [case1-09](img/case1-09-mike-noninteractive-signins.png) | Mike's non-interactive sign-ins |
| E5 | [case1-11](img/case1-11-noninteractive-summary-by-app.png) | Non-interactive sign-ins by app |
| E6 | [case1-06](img/case1-06-security-info-registration-details.png) | Passkey registration details |
| E7 | [case1-07](img/case1-07-mike-risk-and-auth-requirement.png) | Risk, Conditional Access and auth requirement |
| E8 | [case1-12](img/case1-12-mike-auth-methods-before-containment.png) | Mike's methods before containment |
| E9 | [case1-14](img/case1-14-containment-auditlogs.png), [case1-16](img/case1-16-security-info-audit-trail.png) | Containment audit trail |
| E10 | [case1-13](img/case1-13-mike-auth-methods-after-containment.png) | Methods immediately after containment |
| E11 | [case1-17](img/case1-17-post-containment-retest-signins.png), [case1-18](img/case1-18-retest-signin-detail.png), [case1-20](img/case1-20-1724-mfa-method.png) | Post-containment retest |
| E12 | [case1-21](img/case1-21-audit-after-1714.png) | Audit events after 17:14 |
| E13 | [case1-22](img/case1-22-mike-auth-methods-final.png) | Methods, final check |
| E14 | [case1-23](img/case1-23-graph-activity-no-rows.png) | Graph activity query, no rows |
| E15 | [case1-24](img/case1-24-azureactivity-no-rows.png) | Azure Activity query, no rows |
| E16 | [case1-25](img/case1-25-detection-test-result.png) | Detection query run on Case 1 data |
| E17 | [case1-28](img/case1-28-rule-saved-enabled.png) | Rule saved and enabled in Analytics |
