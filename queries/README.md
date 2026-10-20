# Queries

All the KQL from the project, in one place. Every query was run in **Sentinel → Logs**.

## Where each set lives

| File | What's in it |
|---|---|
| [`lab-checks.kql`](lab-checks.kql) | Quick checks that your set-up works: which tables have data, whether sign-ins and Security events are arriving, whether the agent is alive. Run these first |
| [`../case-1-phishing/queries.kql`](../case-1-phishing/queries.kql) | 19 queries: foreign sign-ins, the passkey, risk and MFA requirement, containment, the retest, the first detection |
| [`../case-3-account-compromise/queries.kql`](../case-3-account-compromise/queries.kql) | 11 queries: baseline, the attack, admin changes, containment, the second detection |
| [`../case-2-endpoint-persistence/queries.kql`](../case-2-endpoint-persistence/queries.kql) | 10 queries: process creation, scheduled tasks, persistence after a restart, cleanup, the third detection |
| [`../detections/`](../detections/) | The three detection rules on their own |

Each file explains what a query answers and what I found. Several include the **failed first version** and the fix.

## "I want to answer ... which query?"

| Question | Table | Query |
|---|---|---|
| Is my data arriving? | all | [`lab-checks.kql`](lab-checks.kql) |
| Where does this account sign in from? | `SigninLogs` | Case 1, query 4 |
| Did the sign-in need MFA? | `SigninLogs` | Case 1, query 7 |
| Did Microsoft flag it as risky? | `SigninLogs` | Case 1, query 7 |
| What changed on this account? | `AuditLogs` | Case 1, queries 6 and 12 |
| Was a new sign-in method registered? | `AuditLogs` | Case 1, query 6 |
| Did the attack spread to other accounts? | `SigninLogs` | Case 1, query 5 |
| What background activity did a session do? | `AADNonInteractiveUserSignInLogs` | Case 1, queries 8 and 10 |
| What did an admin account do? | `AuditLogs` | Case 3, query 5 |
| Was an app or secret created? | `AuditLogs` | Case 3, query 6 |
| Was a new user or app ever used? | sign-in tables | Case 3, query 7 |
| Did my containment work? | sign-in tables | Case 1 query 14, Case 3 query 11 |
| What ran on the Windows machine? | `SecurityEvent` | Case 2, queries 4 and 5 |
| What was the scheduled task? | `SecurityEvent` | Case 2, query 6 |
| Did persistence survive a restart? | `SecurityEvent` | Case 2, query 7 |
| Was the cleanup recorded? | `SecurityEvent` | Case 2, query 8 |

## Five things I learned about writing these

1. **Many columns are text, not structured data.** If you get "must be scalar of type dynamic", wrap the column in `parse_json()`.
2. **After a `union`, a column with different types in each table splits in two.** Read what you need from each table first, then union.
3. **Some words are reserved.** `to` is one. Don't use it as a variable name.
4. **Filter noise out early.** `where Account !startswith "WORKGROUP"` removed most of the Windows noise in Case 2.
5. **Use exact times while you investigate.** `between (datetime(...) .. datetime(...))` is easier to reason about than `ago(...)`.

## Using the files

The queries reference my lab (`openhuntx.onmicrosoft.com`, `win-endpoint01`, the dates of my runs). Change those to yours. Any `<home-ip>` is a placeholder for your own address.
