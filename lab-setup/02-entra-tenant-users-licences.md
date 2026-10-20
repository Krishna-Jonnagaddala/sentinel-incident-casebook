# 2. Entra tenant, users and licences

The cases use fictional users in a fresh Entra ID tenant. You need a licence level high enough for the sign-in logs to be exportable, and for risk data to show.

## Check which tenant you're in

Open **Microsoft Entra ID**. The Overview page shows the tenant's domain, something like `yourname.onmicrosoft.com`. Mine is `openhuntx.onmicrosoft.com`. Make sure it's the tenant you mean to use.

## Entra ID P2 trial

Exporting the sign-in logs needs Entra ID P1 or P2. I used the free P2 trial.

1. **Entra ID → Licenses → All products → Try / Buy.**
2. Start the **Microsoft Entra ID P2** trial.

If the trial isn't offered in your tenant, you'll need a P1 or P2 licence another way. Case 2 doesn't use Entra ID at all, so you can still do that one.

## Users

I made four. You can make the same, or your own.

| Role | Sign-in name |
|---|---|
| Admin (you) | `krishna@openhuntx.onmicrosoft.com` |
| Phish victim | `mike@openhuntx.onmicrosoft.com` |
| Finance user | `rambo@openhuntx.onmicrosoft.com` |
| IT admin | `arthur@openhuntx.onmicrosoft.com` |

**Entra ID → Users → New user → Create new user.** Use fake names and passwords you can remember. You'll sign in as these people.

## Assign the licence

Give **Microsoft Entra ID P2** to all four. A user needs a **usage location** (like United Kingdom) before a licence can be assigned. If the licence step errors, open the user, go to **Properties → Edit**, set the location, save, and try again.

Here's how the finished list looked in the Microsoft 365 admin center:

![Four users, each with Microsoft Entra ID P2](img/lab-01-licensed-users.png)

## Admin roles (for Case 3)

Case 3 needs an IT admin who can create users, reset passwords and register apps. I gave Arthur two roles: **User Administrator** and **Application Administrator**.

**Entra ID → Users → Arthur → Assigned roles → Add assignments.** Choose "active", not "eligible".

![Arthur's two roles](../case-3-account-compromise/img/case3-01-arthur-assigned-roles.png)

Note the time you do this. The audit log records it (`Add member to role`), and the case uses that time.

Next: [Send Entra logs to Sentinel](03-send-entra-logs-to-sentinel.md).
