# 3. Send Entra logs to Sentinel

Entra ID keeps its own logs, but you can't search them across tables in Sentinel until you tell Entra to send them there. That's a **diagnostic setting**.

## Create it

1. **Microsoft Entra ID → Monitoring & health → Diagnostic settings → Add diagnostic setting.**
2. Name it `to-law-ir-case-study`.
3. Tick these categories:
   - AuditLogs
   - SignInLogs
   - NonInteractiveUserSignInLogs
   - ServicePrincipalSignInLogs
   - ManagedIdentitySignInLogs
   - RiskyUsers
   - UserRiskEvents
   - MicrosoftGraphActivityLogs
4. Tick **Send to Log Analytics workspace**, pick your subscription and `law-ir-case-study`.
5. **Save.**

![The saved setting](img/lab-06-diag-settings-list.png)

![The ticked categories (open the setting with Edit)](img/lab-07-diag-setting-categories.png)

Do this **before** you do anything you want to investigate. The export only sends events from the moment you turn it on. Anything earlier is gone from Sentinel (though it stays in the Entra portal).

## Make some activity

Open a private browser window for each sign-in:

1. Sign in as each test user once.
2. Sign in as one user with a wrong password twice, then correctly.
3. Change a property of a user (for example a job title), so there's an audit entry.

## Check it arrived

Open **Sentinel → Logs** and run:

```kql
union SigninLogs, AuditLogs
| summarize Events = count() by Type
```

(All the set-up queries are in [`../queries/lab-checks.kql`](../queries/lab-checks.kql).)

Don't panic if you only see `AuditLogs` at first:

![Only audit logs after the first few minutes](img/lab-08-first-ingest-union-count.png)

![The first audit events](img/lab-09-first-auditlogs.png)

Two of those first events were "Add service principal" with no human behind them. The initiator is "Microsoft Azure AD Internal - Jit Provisioning". That's Microsoft adding its own apps, not an attacker:

![Add service principal, initiated by Microsoft](img/lab-10-add-service-principal-benign.png)

`SigninLogs` was empty for a good while. Before assuming it's broken, check the Entra portal's own sign-in log (**Entra ID → Monitoring & health → Sign-in logs**). If the sign-ins are there, it's just delay:

![Sentinel: no sign-ins yet](img/lab-11-signinlogs-empty-export-delay.png)

![Entra portal: the sign-ins are there](img/lab-12-entra-signin-logs-source.png)

Wait for the sign-ins to appear in Sentinel before you carry on. Next, if you're doing Case 2: [Windows VM and agent](04-windows-vm-and-agent.md). Otherwise go straight to [Case 1](../case-1-phishing/README.md).
