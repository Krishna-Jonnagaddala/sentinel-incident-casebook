# Case 1: management update

**Status:** contained, with one open question.
**Severity (lab assessment):** medium. One account compromised, no evidence of spread.

**What happened.** A staff member's account (Mike Tyson, Accounts Payable) was signed into from another country using only his password. The person who got in registered their own passkey on his account so they could return, then tried the same address against two colleagues' accounts and failed.

**How far it went.** One account was taken over. Two others were probed and held. I have not yet checked what the intruder looked at or changed inside Microsoft 365 and Azure, so I cannot rule out data access.

**What we did.** Signed the account out everywhere, removed the added passkey and the existing authenticator, reset the password and forced a fresh MFA set-up. The old password and the old session were both rejected afterwards.

**What we could not explain.** About ten minutes after clean-up, a sign-in from the intruder's address completed MFA with a one-time code even though the account then had no authenticator. This needs a follow-up test before we can say the clean-up is complete.

**Why it was not caught.** Nothing alerted. The sign-in did not trigger Microsoft's risk detection, and the account was not forced to use MFA, so a password alone was enough.

**What we need.**
1. Require MFA for every account.
2. Approve a new alert for "sign-in followed by new authentication method".
3. Time for one more containment test and a review of the intruder's activity in Microsoft 365 and Azure.

*Note: this was a lab exercise. The attacker was the analyst, and the phishing email was simulated.*
