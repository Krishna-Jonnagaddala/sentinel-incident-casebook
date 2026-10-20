# Case 1: Phishing victim, then suspicious account activity

**Level:** the easiest of the three. **Logs used:** Entra ID sign-in and audit logs only. **Needs:** lab steps 1 to 3.

## The story in two minutes

A member of staff, Mike, says he typed his password into a fake "shared document" page. A few minutes later, someone signs in to his account from Nigeria, on an Android phone. They didn't need anything but his password: no MFA prompt, no block, and Microsoft's own risk scoring said nothing.

Once in, they open the security info page and register a **passkey**. That's the part that matters: a passkey on the account means they can get back in even after Mike changes his password. They also try the same address against two colleagues and fail.

I caught it by comparing where Mike signs in from normally with where this session came from. Then I contained it: signed everything out, deleted the methods I didn't trust, reset the password. I tested the result from the same VPN, and one thing still didn't add up: an MFA code was accepted after the method had been deleted. That's still unexplained, and it's in the report.

(In the lab, the "attacker" is me on a phone behind a VPN. The phishing email itself wasn't simulated: the tenant has no mailboxes, so the case starts from the report.)

## What you'll learn

- **How to spot a foreign sign-in** by comparing country, device and browser against a baseline.
- **Look at `AuthenticationRequirement`.** `singleFactorAuthentication` means a password was enough. In this tenant nothing forced MFA, so the attacker walked in.
- **A registered passkey is persistence.** Resetting a password doesn't remove it.
- **Check who initiated an event.** The "Add service principal" events looked like an attacker. They were Microsoft.
- **Empty results aren't good news by themselves.** I found three different reasons a query came back empty.
- **Containment needs testing**, and sometimes the test finds something you can't explain.

## Quick facts

| | |
|---|---|
| Victim account | `mike@` (Accounts Payable) |
| Attacker | Android phone, Chrome Mobile, VPN exit in Nigeria (`185.111.108.131`) |
| First sign-in | 16:54:33 UTC (background token use); first interactive success 16:55:52 |
| Persistence | A FIDO2 passkey registered at 16:56:05 |
| Probing | 3 failed attempts each on `rambo@` and `arthur@` |
| Alert from Microsoft's risk scoring | None |
| Contained | 17:12:24 to 17:14:00 UTC |
| Detection built | Sign-in followed by a new authentication method (replaced later by a better version in [Case 3](../case-3-account-compromise/README.md)) |

## Read it

| File | What it is |
|---|---|
| [`investigation.md`](investigation.md) | The full case: trigger, timeline, questions, evidence, what I ruled out, containment, uncertainty |
| [`management-update.md`](management-update.md) | The short version for non-technical readers |
| [`technical-report.md`](technical-report.md) | The version for another analyst |
| [`reproduce.md`](reproduce.md) | How to run this attack yourself, step by step |
| [`queries.kql`](queries.kql) | Every query I used, in order, with notes (including the ones that failed) |
| [`evidence.md`](evidence.md) | All 28 screenshots with captions |
| [`img/`](img/) | The screenshots |

## Five screenshots that tell the story

**Two countries, two devices, seconds apart** ([`case1-02`](img/case1-02-signinlogs-mike-rambo-arthur.png)):

![SigninLogs: Nigeria on Android and the UK on a Mac](img/case1-02-signinlogs-mike-rambo-arthur.png)

**The passkey registration** ([`case1-06`](img/case1-06-security-info-registration-details.png)):

![Passkey registration details](img/case1-06-security-info-registration-details.png)

**Nothing flagged it, and a password was enough** ([`case1-07`](img/case1-07-mike-risk-and-auth-requirement.png)):

![No risk detections, single-factor sign-ins](img/case1-07-mike-risk-and-auth-requirement.png)

**Mike's methods before containment** ([`case1-12`](img/case1-12-mike-auth-methods-before-containment.png)):

![An authenticator and a passkey](img/case1-12-mike-auth-methods-before-containment.png)

**The sign-in I couldn't explain** ([`case1-20`](img/case1-20-1724-mfa-method.png)):

![MFA completed with an OATH code after the method was deleted](img/case1-20-1724-mfa-method.png)

## Still open

- Why did an MFA code work at 17:24:49, after the authenticator was deleted at 17:13?
- What did the foreign session do beyond signing in? The Graph and Azure Activity logs gave nothing to look at.
- Who registered Mike's authenticator in the first place? There's no audit record of it.
- What were Mike's two sign-ins from the home Mac at 16:56 and 16:58?
