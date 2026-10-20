# Detections

Three detection rules came out of the cases. Each one is a KQL query plus the notes I wrote in its header: what it needs, how I tested it, and where it will go wrong.

| Rule | From | What it catches | State |
|---|---|---|---|
| [`case1-new-signin-then-mfa-registration.kql`](case1-new-signin-then-mfa-registration.kql) | Case 1 | A single-factor sign-in followed by a new sign-in method on the same account | **Replaced.** It raised a false positive in Case 3. Kept (and disabled) so you can see why |
| [`new-country-signin-then-mfa-registration-v2.kql`](new-country-signin-then-mfa-registration-v2.kql) | Case 3 | A sign-in from a country the user hasn't used before, followed within 30 minutes by a new sign-in method | Saved as a scheduled rule. Tested at fixed times against Cases 1 and 3 |
| [`encoded-powershell-then-persistence.kql`](encoded-powershell-then-persistence.kql) | Case 2 | Encoded PowerShell followed within 30 minutes on the same machine by a scheduled task, a new local user or a Run key | Tested against the attack window and a baseline window. Not saved as a rule |

## How good are they?

Be honest about what "tested" means here:

- I ran each one against the data from my own lab and checked that it found the attack I'd staged.
- I did **not** measure false positives on normal traffic, because the workspace only held a few hours of data.
- Where I know it'll go wrong, the file header says so (new accounts, deployment tools that use encoded commands, a Run key written without `reg.exe`).

Treat them as a starting point. Run them over your own data and tune them.

## Testing a rule at fixed times

You can't wait for an attack every time. Rules 2 and 3 have variables at the top (`asof`, or `tstart` and `tend`) that you can set to the time of your own attack:

1. Paste the rule into **Sentinel → Logs**.
2. Replace `let asof = now();` (or `tstart`/`tend`) with a fixed time, like `let asof = datetime(2026-10-20 18:40);`.
3. Run it. Do you get your attack, and nothing else?
4. Put the live version back before saving it as a rule.

## Saving a query as a Sentinel rule

1. **Sentinel → Configuration → Analytics → Create → Scheduled query rule.** This opens in the Defender portal.
2. **General:** a name that says what it does, a description, severity, and the MITRE techniques. (Mine: T1078.004 Valid Accounts: Cloud Accounts, and T1098 Account Manipulation.)
3. **Set rule logic:** paste the query, **without the comment lines**.
   - **Run query every:** 15 minutes.
   - **Lookup data from the last:** match what the query needs. Sentinel won't allow a lookup of 2 days or more to run more often than every hour. That's why rule 2 uses 1 day instead of 7.
   - Alert threshold: greater than 0.
4. **Alert enhancement → Entity mapping.** Map the user column to an **Account** entity (FullName), and the IP column to an **IP** entity. **Don't skip this.** Without it the incident doesn't say who it's about. I skipped it the first time.
5. Keep clicking Next, then **Review + create → Save.**
6. Check it's **Enabled** in the Analytics list.

Screenshots of the process are in [`case-1-phishing/img/`](../case-1-phishing/img/) (`case1-26` to `case1-28`) and [`case-3-account-compromise/img/`](../case-3-account-compromise/img/) (`case3-20` to `case3-22`).
