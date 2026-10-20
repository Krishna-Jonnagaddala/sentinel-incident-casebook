# Case 1: redo it yourself

Follow this in your own lab and you'll produce the same evidence I did.

**Before you start:** finish [lab steps 1 to 3](../lab-setup/README.md), and check that sign-ins reach Sentinel (see [`../queries/lab-checks.kql`](../queries/lab-checks.kql)).

**You'll need:** a phone (or a second machine) with a commercial VPN. Choose an exit country that isn't yours. A different browser or private window helps too.

**Keep a notepad open.** Write the clock time next to every step. I didn't, and I had to rebuild my own timeline from the logs.

## Part A: baseline (normal behaviour)

1. In your usual browser, in a private window, sign in as **Mike** at `myaccount.microsoft.com`. Complete any password change or MFA registration it asks for. Sign out.
2. Try Mike with a wrong password twice, then the correct one.
3. Sign in as **Rambo** and **Arthur** once each.
4. As the admin, change Mike's job title (**Entra ID → Users → Mike → Edit properties**). This creates an audit entry.
5. Wait for it all to reach Sentinel (sign-ins can take 30 to 60 minutes) and look at it with query 4 in [`queries.kql`](queries.kql). **This is your baseline.**

My baseline sign-ins ([`lab-12`](../lab-setup/img/lab-12-entra-signin-logs-source.png) shows them in the Entra portal) came from my home address in the UK. They only appeared in the Entra portal, not in Sentinel, because I turned the export on late. That's the gap in my case.

## Part B: the "attack"

Everything here is on the phone, behind the VPN, in a private window.

1. Turn on the VPN, with an exit in another country. Note which.
2. Sign in as **Mike** at `myaccount.microsoft.com`, with his password. Note any MFA prompt.
3. **Security info → Add sign-in method.** Add a passkey on your phone (a fingerprint). Note the time.
4. Open `portal.azure.com` as Mike, look at the Entra ID overview, close it. Open `myapps.microsoft.com`.
5. Try to sign in as **Rambo** with a wrong password, and as **Arthur** with a wrong password, three times each.
6. Turn the VPN off.

**While you do this, don't sign in as these users from your normal browser.** I did, by accident, and ended up with two sign-ins I couldn't explain.

Wait 30 to 60 minutes.

## Part C: investigate

Work through [`queries.kql`](queries.kql) in order. The first few tell you where the account signed in from, what changed on it, and whether anything noticed. Write down which result is a **fact**, which is an **inference**, and which is **unknown** as you go (see [`../docs/method.md`](../docs/method.md)).

You should find:
- the same account signing in from two countries at the same time,
- a passkey registered from the foreign session,
- foreign sign-ins that only needed a password,
- no risk detection,
- three failed attempts each on the other two accounts.

## Part D: contain, then test

Before you change anything, **screenshot Mike's Authentication methods page** so you have the "before":

**Entra ID → Users → Mike → Authentication methods.**

Then, in this order, and write the time of each:

1. **Revoke sessions** (top bar of that page).
2. Delete the passkey. Delete the authenticator too if you don't trust it.
3. **Reset password.**
4. **Require re-register multifactor authentication.**

Screenshot the "after".

**Now test it, from the VPN:**
1. Turn the VPN on again.
2. If the phone browser is still on Mike's security page, reload it. It should send you back to sign-in.
3. Try the old password. It should fail.
4. Turn the VPN off. Wait 20 minutes, then query (queries 14 and 15 in [`queries.kql`](queries.kql)).

I got the expected failures, plus one successful MFA sign-in I couldn't explain. If you get something odd, don't hide it. Write it down as an open question.

## Part E: build the detection

Create the rule from [`../detections/case1-new-signin-then-mfa-registration.kql`](../detections/case1-new-signin-then-mfa-registration.kql). The click-by-click is in [`../detections/README.md`](../detections/README.md). Note that this version has a flaw, which Case 3 exposes. The better version is [`new-country-signin-then-mfa-registration-v2.kql`](../detections/new-country-signin-then-mfa-registration-v2.kql).

## What to write down

| Thing | Why |
|---|---|
| The time of each step | The logs give times, but you need to know which log row was *you* |
| Which device and VPN country you used | To recognise yourself later |
| Any prompt you saw | MFA behaviour is a key finding |
| Every error and failed query | They teach more than the working ones |
