# Case 3: technical incident report

**Incident:** privileged account compromise with persistence through a new user, a new authentication method and an application secret
**Environment:** Entra ID tenant `openhuntx`, Sentinel workspace `law-ir-case-study`
**Window:** 2026-10-20 18:26 to 19:19 UTC
**Detail and evidence references:** [investigation.md](investigation.md)

## Summary
`arthur@openhuntx.onmicrosoft.com` (User Administrator and Application Administrator) was signed into from `149.102.234.29` (BR, Chrome Mobile 155 on Android) after six failed password attempts across three accounts. The session registered a new authentication method on Arthur, created `svc-backup01`, reset the password of `rambo@`, and created application `backup-sync` with a client secret.

## Indicators
| Type | Value |
|---|---|
| Source IP | 149.102.234.29 (BR, VPN exit in this lab); retest attempts from 149.102.234.112 |
| User agent | Chrome Mobile 155.0.0 on Android |
| Created user | svc-backup01@openhuntx.onmicrosoft.com, display name `backup-sync` |
| Created app | `backup-sync`, client secret added 18:36:26 |
| Altered account | rambo@ password reset 18:31:40 |
| Spray pattern | 50126 x2 each against rambo, mike, arthur, 18:26:53 to 18:27:45 |

## Findings
1. Initial access 18:29:03: password-only sign-in as Arthur; a second sign-in at 18:29:12 satisfied an MFA requirement. The method used was not read.
2. Persistence: new authentication method (events from 18:27:54, "all required security info" at 18:29:19); user `svc-backup01` 18:31:22; application and service principal 18:36:00; secret 18:36:26.
3. Account takeover capability: rambo's password reset by admin at 18:31:40. No sign-in as rambo from the attacker address.
4. Detection: the Case 1 rule raised two incidents (created 18:36:38 and 18:36:39 UTC) with no entity, one on a legitimate home sign-in.
5. No sign-in by `svc-backup01` or the `backup-sync` app in SigninLogs, AADNonInteractiveUserSignInLogs or AADServicePrincipalSignInLogs after 18:30.

## Response actions (UTC)
| Time | Action |
|---|---|
| 19:07:40 | Arthur: sessions revoked |
| 19:07:52, 19:07:54 | Arthur: two security-info deletions (plus Delete platform credential) |
| 19:08:02 | Arthur: password reset |
| 19:08:45, 19:08:56 | Rambo: sessions revoked, password reset |
| 19:09:29 | `svc-backup01` deleted |
| 19:10:10 | `backup-sync` service principal removed, application deleted |

## Verification
- 19:16:48 arthur and 19:19:04 rambo from BR: 50126 (old password).
- 19:11:25 / 19:11:31 arthur and 19:32:45 / 19:33:14 rambo, home sessions: 50133 and 50173 (revoked grant).
- No successful sign-in from BR after 19:07:40.

## Gaps
- Attacker session reload not demonstrated; revocation shown on home sessions.
- No row for a sign-in attempt as `svc-backup01`.
- Graph activity and Azure Activity not available.
- `23.98.196.x` and `48.209.202.236` unidentified.
- Deleted objects soft-deleted only.

## Detection
`detections/new-country-signin-then-mfa-registration-v2.kql` replaces the Case 1 rule (which is disabled, not deleted). Tested at fixed times against Arthur (one row, BR) and Mike (one row, NG). Not yet fired on a live event; entity mapping not confirmed on screen.
