# Case 1: technical incident report

**Incident:** unauthorised access to a user account with persistence via passkey registration
**Environment:** Entra ID tenant `openhuntx`, Sentinel workspace `law-ir-case-study`
**Window:** 2026-10-20 16:54 to 17:30 UTC
**Source of truth:** SigninLogs, AADNonInteractiveUserSignInLogs, AuditLogs. Full reasoning and evidence references are in [investigation.md](investigation.md).

## Summary
`mike@openhuntx.onmicrosoft.com` was accessed from `185.111.108.131` (NG) using Chrome Mobile on Android, with single-factor authentication. The session registered a FIDO2 passkey (stored in Google Password Manager) on the account and ran 73 non-interactive sign-ins across 8 applications. The same address then failed three password attempts against each of `rambo@` and `arthur@`.

## Indicators
| Type | Value |
|---|---|
| Source IP | 185.111.108.131 (NG, VPN exit in this lab) |
| Source IP (retest failures 17:29–17:30) | 185.111.108.130, same /24; 17:24:49 success was from .131 |
| User agent | Chrome Mobile 155.0.0 on Android |
| Persistence | Fido2 authentication method on Mike, via My Signins, 16:56:05 |
| Probing | 50126 x3 against rambo, x3 against arthur |

## Findings
1. Initial access: first non-interactive token use 16:54:33. The first interactive sign-in that produced it is not in SigninLogs (export gap).
2. Persistence: passkey registered 16:56:05; the foreign sign-ins carried `singleFactorAuthentication` and `ConditionalAccessStatus = notApplied`.
3. Discovery/lateral attempt: failed sign-ins against two other accounts from the same address, 16:59–17:00.
4. No Identity Protection detection, no Sentinel incident.

## Response actions (UTC)
| Time | Action |
|---|---|
| 17:12:24 | Sessions revoked (`Update StsRefreshTokenValidFrom Timestamp`) |
| 17:12:49 | Fido2 method deleted |
| 17:13:04 | SoftwareOath method deleted |
| 17:13:33–34 | Password reset by admin |
| 17:14:00 | Further `Update user` (StrongAuthenticationUserDetails) and `Admin deleted security info` |

## Verification
- 17:29:10: 50133 (session invalid after password change); 50126 (old password).
- 17:30:16: 50126.
- Authentication methods page: no usable methods, no default.

## Open issue
17:24:49: interactive sign-in from the same address succeeded, `AuthenticationRequirement = multiFactorAuthentication`, MFA completed by "OATH verification code". No registration event in AuditLogs between 17:14:00 and 17:24:49. Not resolved. Next test: re-enrol MFA, then retry with a code from the old authenticator entry.

## Gaps
- MicrosoftGraphActivityLogs returned nothing (table appears empty) and Azure Activity is not connected, so post-authentication activity of the session is unknown.
- No audit event for the original OATH registration on Mike.
- SigninLogs missing before 16:55:52.

## Detection
`detections/case1-new-signin-then-mfa-registration.kql`: single-factor interactive success followed by a security-info registration for the same user within 30 minutes. Run on this data: flags Mike once. False-positive rate untested (no baseline). Superseded after Case 3 by `detections/new-country-signin-then-mfa-registration-v2.kql`: v1 raised a false positive on an admin's own home sign-in. v1 is disabled, not deleted.
