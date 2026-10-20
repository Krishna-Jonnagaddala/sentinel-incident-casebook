# Glossary

Words and codes you'll meet in the cases, explained the way I wish someone had explained them to me.

## Words

| Term | Plain meaning |
|---|---|
| **SIEM** | A system that collects logs from many places and lets you search them and set alerts. Sentinel is Microsoft's. |
| **Microsoft Sentinel** | Microsoft's SIEM. It sits on top of a Log Analytics workspace. |
| **Log Analytics workspace** | The database where the logs are stored. You search it with KQL. |
| **KQL (Kusto Query Language)** | The query language for that database. Each line takes the output of the line before, joined by `\|`. |
| **Tenant** | Your organisation's own copy of Microsoft's identity system. Mine is called `openhuntx`. |
| **Entra ID** | Microsoft's identity service (it used to be called Azure AD). Users, sign-ins, roles and apps live here. |
| **UPN** | User principal name: the sign-in name, like `mike@openhuntx.onmicrosoft.com`. |
| **MFA** | Multi-factor authentication: a password plus something else (a code, a phone prompt, a passkey). |
| **Authentication method** | One of the "something else" options a user has registered. |
| **Passkey / FIDO2** | A sign-in method stored on a device (a phone, a security key), unlocked with a fingerprint or PIN. An attacker who registers one on your account gets a way in that survives a password reset. |
| **OATH / authenticator app** | The six-digit rotating code from an app on your phone. |
| **Conditional Access** | Rules like "require MFA from outside the office". If none apply, a password alone can be enough. |
| **Identity Protection / risk detections** | Microsoft's automatic scoring of risky sign-ins. It didn't flag anything in my cases. |
| **Session revocation** | Telling Entra "every login this user already has is no longer valid". |
| **Service principal / app registration** | An identity for an application. A registration can have a **client secret**, which works like a password for the app. |
| **Diagnostic setting** | The switch in Entra ID that sends its logs to a workspace. |
| **Data collection rule (DCR)** | The switch that tells the Azure Monitor Agent which logs to collect from a machine and where to send them. |
| **Azure Monitor Agent (AMA)** | A small program on the VM that reads Windows logs and sends them to the workspace. |
| **Ingestion delay** | The time between something happening and its appearing in the workspace. Sometimes minutes, sometimes more. Empty results soon after an action usually mean this. |
| **Persistence** | Anything an attacker sets up so they get back in later: a scheduled task, a Run key, a new account, a registered method. |
| **Baseline** | What normal looks like. You can't call something unusual until you know what usual is. |
| **Containment** | Stopping the problem: blocking access, removing what the attacker added. |
| **IOC (indicator)** | A concrete thing to look for: an IP address, a file name, a command line. |
| **False positive** | An alert that fired on something harmless. |
| **Password spray** | Trying a few passwords against many accounts, so no single account gets locked out. |

## Windows event IDs used in Case 2

These come from the `SecurityEvent` table.

| ID | Meaning |
|---|---|
| 4624 | Someone logged on. `LogonType 10` is Remote Desktop, `3` is network, `5` is a service. |
| 4688 | A process started. With the right setting it includes the full command line. This is the most useful one. |
| 4698 / 4699 | A scheduled task was created / deleted. |
| 4720 / 4726 | A user account was created / deleted. |
| 4732 / 4733 | A member was added to / removed from a local group (for example Administrators). |

## Entra sign-in result codes seen in the cases

Found in `SigninLogs`, column `ResultType`. `0` means success.

| Code | Meaning |
|---|---|
| 0 | Success |
| 50126 | Wrong username or password |
| 50072 | The user must register for MFA |
| 50203 | The user hasn't registered an authenticator app and must |
| 50055 | The password has expired |
| 50133 | The session is no longer valid because the password changed |
| 50173 | The token was revoked, a new sign-in is needed |
| 50140 | "Keep me signed in" prompt interrupted the sign-in |

## Tables used

| Table | What's in it |
|---|---|
| `SigninLogs` | People signing in interactively |
| `AADNonInteractiveUserSignInLogs` | Background sign-ins: apps using a stored token on someone's behalf |
| `AADServicePrincipalSignInLogs` | Apps signing in as themselves |
| `AuditLogs` | Changes to the directory: users, roles, methods, apps |
| `SecurityEvent` | Windows Security log from the VM |
| `Heartbeat` | "I'm alive" pings from the agent |

## MITRE ATT&CK labels I used on the rules

| ID | Name |
|---|---|
| T1078 / T1078.004 | Valid Accounts / Cloud Accounts |
| T1098 | Account Manipulation |
| Persistence (TA0003) | The tactic group for staying in |
