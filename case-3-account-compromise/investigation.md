# Case 3: Admin account compromise with identity changes

Lab: Microsoft Sentinel workspace `law-ir-case-study`, Entra ID tenant `openhuntx`.
All times UTC, 2026-10-20. Screenshots are cited as **[E#]**; the index is at the bottom.

## Read this first: what is real and what is staged

- **Staged:** the attacker is me, on an Android phone behind a VPN exiting in Brazil. I knew Arthur's password, so the "password guessing" is six deliberate wrong attempts followed by the right one. I completed the MFA prompt myself, so an MFA bypass was not simulated.
- **Staged:** I gave Arthur User Administrator and Application Administrator myself, 31 minutes before the baseline began [E1].
- **Real:** every sign-in, directory change and containment action below was generated in the tenant and read back from the workspace.
- I did not write down the clock times of my own actions. The logs give the times. I also first noted that I used a laptop for the attack; the logs show Chrome Mobile on Android, so my note was wrong and the logs are what I cite.

Facts, inferences and unknowns are labelled.

## 1. Trigger and telemetry

**Trigger:** the Case 1 analytics rule raised three incidents, two of them for Arthur's account [E12]. They did not name the account (no entity mapping), and one of the two was a false positive on Arthur's own home sign-in. That is documented under section 9.

Telemetry used: SigninLogs, AADNonInteractiveUserSignInLogs, AADServicePrincipalSignInLogs, AuditLogs.

**Baseline recorded before the attack** (Arthur and Rambo from the lab workstation, GB, macOS Chrome): Arthur signed in at 18:00:20 and created a legitimate test user `temp.intern` at 18:00:55 [E2, E3]. That is what a normal admin change looks like here: home country, one change, no failed attempts before it.

**Gaps**
- MicrosoftGraphActivityLogs returned nothing in Case 1 and was not queried again; Azure Activity is not connected. What the session did after authenticating is therefore known only through directory audit events.
- Source addresses on some audit events (`23.98.196.x`, `48.209.202.236`) are not the VPN address. I think they are Microsoft-side but have not verified it.

## 2. Timeline

| Time | Event | Type | Ref |
|---|---|---|---|
| 17:58:03, 17:58:18 | Krishna adds Arthur to Application Administrator, then User Administrator | Fact (lab setup) | E1 |
| 18:00:20 | Arthur signs in from home (GB, macOS, single-factor) | Fact (baseline) | E2 |
| 18:00:55 | Arthur creates `temp.intern` from the home address | Fact (baseline) | E3 |
| 18:26:53 – 18:27:45 | Six failed sign-ins, two each for rambo, mike and arthur, from `149.102.234.29` (BR), Chrome Mobile on Android | Fact | E4 |
| 18:27:54 | "Get passkey creation options" for Arthur (logged before the sign-in below) | Fact | E8 |
| 18:29:03 | Arthur signs in successfully from BR, single-factor | Fact | E4 |
| 18:29:12 | Second Arthur sign-in from BR with an MFA requirement, success | Fact | E4 |
| 18:29:11 – 18:29:19 | Security info registered on Arthur, "all required security info" at 18:29:19 | Fact | E8 |
| 18:30:30 – 18:30:40 | 14 "Validate Password" events by Arthur from BR | Fact; inference: password strength checks while filling in the new-user form | E7 |
| 18:31:22 | User `svc-backup01` created (display name `backup-sync`) | Fact | E8, E5 |
| 18:31:40 | Rambo's password reset by admin, actor Arthur | Fact | E8 |
| 18:35:55 | Rambo sign-in from the home workstation fails with 50203 | Fact; my own activity (I checked Rambo's password) | E4 |
| 18:36:00 – 18:36:26 | App `backup-sync` created, service principal added, client secret added | Fact | E8, E6 |
| 18:36:38, 18:36:39 | Two incidents created by the analytics rule (portal time 7:36 PM, probably BST) | Fact; time zone inferred | E12 |
| 19:07:40 | Arthur's sessions revoked | Containment | E9 |
| 19:07:52 – 19:07:54 | Arthur's passkey and authenticator removed | Containment | E9 |
| 19:08:02 | Arthur's password reset | Containment | E9 |
| 19:08:45, 19:08:56 | Rambo's sessions revoked, password reset | Containment | E9 |
| 19:09:29 | `svc-backup01` deleted | Containment | E9 |
| 19:10:10 | `backup-sync` service principal removed and application deleted | Containment | E9 |
| 19:16:48, 19:19:04 | Retest from BR: Arthur and Rambo old passwords rejected (50126) | Fact | E10 |

## 3. Investigation questions and KQL

**Q1. Where did the activity come from, and did it fit Arthur?**
```kql
SigninLogs
| where TimeGenerated > ago(6h)
| where IPAddress !in ("185.111.108.131", "<home-ip>")
| project TimeGenerated, UserPrincipalName, ResultType, ResultDescription, IPAddress,
          Country = tostring(LocationDetails.countryOrRegion), AppDisplayName,
          Browser = tostring(DeviceDetail.browser), OS = tostring(DeviceDetail.operatingSystem),
          AuthenticationRequirement, RiskLevelDuringSignIn, RiskState
| order by TimeGenerated asc
```
Answer: Brazil, a mobile browser, six failures then a success; Arthur's baseline is the UK on a Mac [E4].

**Q2. What did Arthur's account do in the directory?**
```kql
AuditLogs
| where TimeGenerated > ago(6h)
| where tostring(InitiatedBy.user.userPrincipalName) =~ "arthur@openhuntx.onmicrosoft.com"
| where OperationName != "Validate Password"
| project TimeGenerated, OperationName, Result,
          Target = coalesce(tostring(TargetResources[0].userPrincipalName), tostring(TargetResources[0].displayName)),
          SourceIP = tostring(InitiatedBy.user.ipAddress)
| order by TimeGenerated asc
```
Answer: one authentication method added, one new user, one password reset, one new application with a secret [E8].

**Q3. Which roles did Arthur hold, and since when?**
```kql
AuditLogs | where OperationName has "role" | project TimeGenerated, OperationName, Actor = tostring(InitiatedBy.user.userPrincipalName), Target = tostring(TargetResources[0].userPrincipalName), Details = tostring(TargetResources[0].modifiedProperties)
```
Answer: User Administrator and Application Administrator, since 17:58 [E1].

**Q4. Was the persistence ever used?**
```kql
union SigninLogs, AADNonInteractiveUserSignInLogs, AADServicePrincipalSignInLogs
| where TimeGenerated > datetime(2026-10-20 18:30)
| where UserPrincipalName has "svc-backup01" or ServicePrincipalName has "backup-sync" or AppDisplayName has "backup-sync"
| project TimeGenerated, Type, UserPrincipalName, ServicePrincipalName, ResultType, IPAddress
```
Answer: no rows. Not used, as far as the workspace shows [E11].

**Q5. Was containment effective?**
```kql
SigninLogs
| where TimeGenerated > datetime(2026-10-20 19:11)
| where UserPrincipalName has_any ("arthur@", "rambo@", "svc-backup01")
| project TimeGenerated, Type, UserPrincipalName, ResultType, ResultDescription, IPAddress,
          Country = tostring(LocationDetails.countryOrRegion), AppDisplayName
| union (
    AADNonInteractiveUserSignInLogs
    | where TimeGenerated > datetime(2026-10-20 19:11)
    | where UserPrincipalName has_any ("arthur@", "rambo@", "svc-backup01")
    | project TimeGenerated, Type, UserPrincipalName, ResultType, ResultDescription, IPAddress,
              Country = tostring(parse_json(LocationDetails).countryOrRegion), AppDisplayName )
| order by TimeGenerated asc
```
Answer: see section 8 [E10]. My first version of this query failed because `LocationDetails` has a different type in the two tables after a `union`; I fixed it by reading the country inside each table first. The failed run is in the evidence folder [E13].

## 4. Affected accounts, devices and resources

| Item | Status | Basis |
|---|---|---|
| Arthur Sterling (IT admin) | **Compromised** | Foreign sign-in after failures, new method, directory changes [E4, E8] |
| `svc-backup01` | **Backdoor user created by the attacker** | Created 18:31:22; display name copied from the app name [E5, E8] |
| `backup-sync` app + secret | **Persistence created by the attacker** | Created 18:36:00; secret added 18:36:26 [E6, E8] |
| Rambo Craig (finance) | **Password reset by the attacker**; no attacker sign-in seen | Reset 18:31:40; Rambo's only methods untouched [E8, E14] |
| Mike Tyson | Probed | Two failed attempts [E4] |
| Attacker device | Android, Chrome Mobile 155, from `149.102.234.29` (BR) | SigninLogs |

## 5. Evidence for the conclusion

Conclusion: **Arthur's account was used by someone else to create persistence and take over a finance account.**

1. Six wrong passwords across three accounts in 52 seconds, then one success on the admin [E4].
2. Country and device change: UK Mac in the baseline, Brazil Android in the attack [E2, E4].
3. A new authentication method was registered inside the first sign-in flow [E8].
4. Within seven minutes the account created a user, reset a colleague's password and registered an app with a secret [E8]. In the baseline, the same account made one change, at home, with no failures before it [E3].
5. The new user was given the display name `backup-sync`, the same as the app [E5].

## 6. Alternative explanations

| Alternative | Verdict | Why |
|---|---|---|
| Arthur doing real admin work from abroad | **Not ruled out from logs alone** | In a real case I would call Arthur and check the change calendar. Against it: the failed-password run beforehand, a new method added in the same sign-in, and a backdoor name that copies an app. In this lab I know it was me. |
| The `temp.intern` creation | **Different, and benign** | Home country, one action, no failures [E3]. |
| 14 "Validate Password" events were guessing | **Ruled out (inference)** | They are logged as successes under the new-user flow from the same session; I read them as password strength checks while the form is filled. |
| Addresses `23.98.196.x` and `48.209.202.236` are a second attacker | **Not established** | I think they are Microsoft-side processing but have not verified it. |
| Microsoft or a scheduled task created the app | **Ruled out** | The actor is Arthur from the VPN address [E8]. |

## 7. Observed, inferred, unknown

**Observed:** everything marked Fact in the timeline.
**Inferred:**
- The Brazilian sign-ins are the attacker (lab ground truth).
- The audit sign-in order is explained by sign-in logs being stamped when authentication completes (my own statement, not verified).
- Display name `backup-sync` on the user is deliberate camouflage.

**Unknown:**
- Which MFA method completed the 18:29:12 sign-in.
- Anything the session did that is not a directory change (Graph and Azure Activity are not available).
- Whether the secret was ever used elsewhere.
- What the `23.98.196.x` and `48.209.202.236` addresses are.

## 8. Containment, recovery checks, remaining uncertainty

**Done**, in this order [E9]: revoke Arthur's sessions; remove both his authentication methods; reset his password; revoke Rambo's sessions and reset his password; delete `svc-backup01`; remove the `backup-sync` service principal and delete the application (which removes its secret).

**Time to contain:** 38 minutes from the first attacker success (18:29:03) to the first action (19:07:40). That is a lab delay while I waited for logs, not a target.

**Recovery checks**
- Old passwords rejected from BR: Arthur 19:16:48, Rambo 19:19:04, both 50126 [E10]. Pass.
- Old tokens rejected: Arthur and Rambo's browser sessions at home returned 50133 and 50173 ("grant … revoked") at 19:11 and 19:32 [E10]. Pass for those sessions. **The attacker's own session was not reloaded in a way the logs show**, so revocation of that exact session is not demonstrated.
- No successful sign-in from BR after containment [E10]. Pass.
- Directory: `svc-backup01` and `backup-sync` gone [E5, E6 compared with end state]. Pass.
- A sign-in attempt as `svc-backup01` left no row in the workspace. I cannot tell whether I did not try it or whether failed sign-ins to deleted accounts are not logged. Unverified.

**Remaining**
- Deleted users and applications stay recoverable for about 30 days; permanent deletion was not done.
- Arthur and Rambo must re-enrol MFA (Arthur lost his original authenticator along with the attacker's passkey).
- Arthur still holds both admin roles.
- Enforce MFA, move admin roles to just-in-time activation, and restrict app secret creation.

## 9. Detection improvement

Case 3 exposed a false positive in the Case 1 rule. It paired a registration with any single-factor sign-in in the previous 30 minutes, and on this data it matched Arthur's own home sign-in at 18:00:20 as well as the Brazilian one, so one attack raised two incidents [E12, E15].

The replacement, [`detections/new-country-signin-then-mfa-registration-v2.kql`](../detections/new-country-signin-then-mfa-registration-v2.kql), flags a registration only after an interactive sign-in from a country the user has not signed in from before. Tested against fixed times:
- 18:40: one row, Arthur from BR; the home row is gone [E16].
- 17:40: one row, Mike from NG (but only because Mike has no earlier history in the workspace) [E17].

It is saved as a scheduled rule and v1 is disabled but kept [E18]. Limits: lookup shortened to one day because Sentinel requires hourly runs for longer lookbacks; it has not fired on a live event; entity mapping was not confirmed on screen; false-positive rate on normal traffic is unmeasured.

## Evidence index

| ID | File | Shows |
|---|---|---|
| E1 | [case3-01](img/case3-01-arthur-assigned-roles.png), [case3-10](img/case3-10-role-assignments-audit.png) | Arthur's roles and the role-assignment audit events |
| E2 | [case3-02](img/case3-02-baseline-signins.png) | Baseline sign-ins |
| E3 | [case3-03](img/case3-03-baseline-add-user.png) | Baseline `temp.intern` creation |
| E4 | [case3-07](img/case3-07-foreign-signins.png) | Foreign sign-ins and failures |
| E5 | [case3-04](img/case3-04-users-list-after-attack.png) | Users list after the attack |
| E6 | [case3-05](img/case3-05-app-registrations-backup-sync.png) | App registration with an active secret |
| E7 | [case3-08](img/case3-08-arthur-audit-actions.png) | Arthur's audit actions, with noise |
| E8 | [case3-11](img/case3-11-arthur-audit-no-noise.png) | Arthur's audit actions, noise removed |
| E9 | [case3-27](img/case3-27-containment-audit-filtered.png), [case3-28](img/case3-28-containment-audit-by-krishna.png) | Containment audit trail |
| E10 | [case3-30](img/case3-30-retest-signins.png) | Retest sign-ins |
| E11 | [case3-12](img/case3-12-backdoor-usage-no-rows.png) | No use of the backdoor user or app |
| E12 | [case3-13](img/case3-13-incidents-list.png) to [case3-16](img/case3-16-incident-1.png) | Incidents raised by the Case 1 rule |
| E13 | [case3-29](img/case3-29-union-locationdetails-error.png) | Failed query and fix |
| E14 | [case3-06](img/case3-06-arthur-auth-methods-after-attack.png), [case3-24](img/case3-24-rambo-methods-after-containment.png) | Authentication methods (Arthur after attack, Rambo after containment) |
| E15 | [case3-17](img/case3-17-rule-v1-three-rows.png) | v1 rule run: three rows |
| E16 | [case3-18](img/case3-18-rule-v2-test-arthur.png) | v2 test, Arthur |
| E17 | [case3-19](img/case3-19-rule-v2-test-mike.png) | v2 test, Mike |
| E18 | [case3-21](img/case3-21-analytics-both-rules-enabled.png), [case3-22](img/case3-22-analytics-v1-disabled-v2-enabled.png) | Rules list; v1 disabled |
