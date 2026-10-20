# Case 3: management update

**Status:** contained. Follow-up actions open.
**Severity (lab assessment):** high. An IT administrator's account was taken over and used to create ways back in.

**What happened.** After several wrong-password attempts on three accounts, someone signed in as Arthur Sterling, our IT admin, from Brazil. Within seven minutes the account had added a new sign-in method for itself, created a hidden extra user called `svc-backup01`, reset a finance colleague's password, and registered an application with a secret key.

**How far it went.** The admin account and the two things it created are confirmed. The finance account's password was changed by the intruder, but I found no sign-in to that account by the intruder. A second colleague's account was tried and held. I could not see what the intruder looked at, because the logging for that is not switched on in this environment. I also found no sign that the hidden user or the application was ever used.

**What we did.** Signed both accounts out everywhere, removed the sign-in methods, reset both passwords, deleted the hidden user and the application. Afterwards the old passwords were rejected, and the old sign-ins stopped working. Arthur has to set up his authenticator again, because the clean-up removed his own along with the intruder's.

**What took too long.** 38 minutes passed between the intruder getting in and the first clean-up step. In this exercise that was waiting for logs, but the alert we had also named no account and raised a duplicate, so it would have cost time in real life too.

**What we changed.** The alert that fired is replaced by a better version that only triggers when someone signs in from a new country and then adds a sign-in method. It is tested on this incident. It has not yet run on live traffic.

**What we need.**
1. Require MFA for every account, and extra protection for admin accounts.
2. Give admin roles only when needed, not permanently.
3. Limit who can create application secrets.
4. Turn on audit logging for Microsoft 365 and Azure activity, so that next time we can see what an intruder did after getting in.

*Note: this was a lab exercise. The attacker was the analyst.*
