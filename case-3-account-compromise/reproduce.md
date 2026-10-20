# Case 3: redo it yourself

**Before you start:** finish [lab steps 1 to 3](../lab-setup/README.md). Check sign-ins are reaching Sentinel ([`../queries/lab-checks.kql`](../queries/lab-checks.kql)).

**You'll need:** a VPN with an exit in a country that isn't yours (and ideally isn't the one you used for Case 1, so the two cases don't share addresses), and a browser in a private window.

**Write the clock time next to every step.**

## Part 0: give Arthur admin rights

1. **Entra ID → Users → Arthur → Assigned roles → Add assignments.**
2. Add **User Administrator** and **Application Administrator**, as active roles.
3. Screenshot the Assigned roles page.

In my lab I did this about 30 minutes before the baseline. The audit log records the exact time.

## Part 1: baseline

At home (no VPN), over about half an hour:

1. Sign in as **Arthur** at `portal.azure.com`. Complete any MFA prompt.
2. As Arthur, create one **legitimate** user: **Users → New user → Create new user**. I called mine `temp.intern`.
3. Sign in as **Rambo** at `myaccount.microsoft.com`, open **Security info**, sign out.
4. Sign in as **Arthur** again 10 to 15 minutes later, look at the Entra ID overview, sign out.

Wait 30 minutes. Then run queries 1 to 3 in [`queries.kql`](queries.kql). That's your baseline: home country, a Mac browser, one admin change, no failures before it.

## Part 2: the attack

On the phone or a second machine, behind the VPN, in a private window:

1. VPN on. Note the country.
2. **Spray:** try a wrong password twice each for Mike, Rambo and Arthur at `portal.azure.com`.
3. **Compromise:** sign in as **Arthur** with his real password. Note any MFA prompt and complete it.
4. **Persistence on Arthur:** at `myaccount.microsoft.com`, **Security info → Add sign-in method**. Add a passkey.
5. **Backdoor user:** **Entra ID → Users → New user → Create new user**, named `svc-backup01`. If you want to copy my camouflage, give it the display name `backup-sync`.
6. **Take over a finance account:** **Users → Rambo → Reset password.**
7. **App persistence:** **Entra ID → App registrations → New registration** (name it `backup-sync`), then **Certificates & secrets → New client secret.**
8. VPN off.

**While you do this, don't sign in as Arthur or Rambo from your normal browser.** Any sign-in from home in the middle of the attack becomes something you have to explain.

**Before you clean up, take three screenshots:** the Users list (showing the new user), App registrations (showing the new app and its secret), and Arthur's Authentication methods page (showing the passkey). Cleaning up destroys them.

Wait 30 to 60 minutes.

## Part 3: investigate

Work through [`queries.kql`](queries.kql) from query 4 onwards. You should find:

- six failed sign-ins across three accounts, then a success on Arthur, from the VPN country,
- one authentication method registered in the same sign-in,
- a new user, a password reset and a new app with a secret, all from Arthur's account,
- no sign-in by the new user or the app afterwards.

Now run the rule from Case 1 over 24 hours (query 8). It should flag Arthur twice: once for the VPN sign-in (right), once for his own home sign-in (wrong). That's the false positive.

## Part 4: contain, then test

In this order, writing the time of each:

1. **Arthur:** **Entra ID → Users → Arthur → Authentication methods.** **Revoke sessions**, then delete the passkey you didn't register yourself, then **Reset password.**
2. **Rambo:** **Revoke sessions**, then **Reset password.**
3. **Users:** delete `svc-backup01`.
4. **App registrations:** delete `backup-sync`. That removes its secret too.
5. Screenshot the end state: Arthur's methods, the Users list, App registrations.

**The retest, from the VPN:**
1. Try Arthur's old password. It should fail.
2. Try Rambo's old password (the one the attacker set). It should fail.
3. If an old browser session is open, reload the portal. It should sign you out.
4. VPN off. Wait 20 minutes, then run query 11.

Deleted users and apps stay recoverable for about 30 days. If you want them gone, permanently delete them under **Deleted users** and **Deleted applications**.

## Part 5: fix the detection

Replace the Case 1 rule with [`new-country-signin-then-mfa-registration-v2.kql`](../detections/new-country-signin-then-mfa-registration-v2.kql). Test it at fixed times, as in query 9, and check the home row has gone.

In Sentinel, create a scheduled rule from it with:
- **Run query every:** 15 minutes
- **Lookup data from the last:** 1 day (Sentinel won't let a lookup of 2 days or more run more often than hourly)
- **Entity mapping:** Account → FullName → `User`; IP → Address → `SignInIP`. **Don't skip this**, or the incident won't say who it's about.

Disable the old rule. Don't delete it: the contrast is useful.
