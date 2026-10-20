# 1. Azure subscription and workspace

Everything lives in Azure, so you need a subscription first. Then a place to keep the logs (a Log Analytics workspace), and Sentinel on top of it.

## Subscription

You need an active Azure subscription in the same tenant as your lab users. Go to **Subscriptions** in the Azure portal and check the status says **Active**.

- If you've never had Azure, start a free account.
- If you've used the free offer before (I had, on another account), a pay-as-you-go subscription works. Don't open extra free accounts to get around this; it breaks the sign-up rules and the new account can be suspended halfway through your lab.
- **Make sure the subscription is in the same directory as your lab users.** I started in one directory, then moved to a fresh tenant and rebuilt the workspace there, because the Entra log export can't send logs across directories. If your workspace doesn't appear in the dropdown when you set up the export, a directory mismatch is the likely reason.

I haven't included a screenshot of the Subscriptions page because it shows the subscription ID.

## Resource group

A resource group is a folder for related Azure things. I made one called `rg-ir-casebook` and put the workspace in it.

## Log Analytics workspace

1. Search for **Log Analytics workspaces** and click **Create**.
2. Resource group `rg-ir-casebook`, name `law-ir-case-study`, a region near you (I used **UK West**), pricing tier **Pay-as-you-go**.
3. **Review + create → Create.**

![Review page for the workspace](img/lab-02-workspace-review.png)

![Deployment complete](img/lab-03-workspace-deployed.png)

![The workspace in its resource group](img/lab-04-resource-group.png)

(The subscription ID is blacked out in that last one.)

## Turn on Microsoft Sentinel

1. Search for **Microsoft Sentinel** and click **Create**.
2. Pick `law-ir-case-study` and click **Add**.
3. Wait for the overview page. Mine showed zero events, alerts and incidents, which is right for a new workspace.

![Sentinel overview with nothing in it yet](img/lab-05-sentinel-empty-overview.png)

Next: [Entra tenant, users and licences](02-entra-tenant-users-licences.md).
