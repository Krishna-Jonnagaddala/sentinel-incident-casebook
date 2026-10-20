# Lab setup

How I built the lab, step by step, with screenshots. Do these in order and you'll have the same environment I used for all three cases.

## What you end up with

```
  Your Entra ID tenant ("openhuntx")           Windows Server VM ("win-endpoint01")
  users, sign-ins, roles, apps                  Windows Security log
            |                                              |
            | diagnostic setting                           | Azure Monitor Agent + data collection rule
            v                                              v
        Log Analytics workspace ("law-ir-case-study")  <--- Microsoft Sentinel sits on top
            |
            v
   You search it with KQL (Sentinel > Logs) and write detection rules (Sentinel > Analytics)
```

## The steps

| # | Guide | You'll have at the end |
|---|---|---|
| 1 | [Azure subscription and workspace](01-azure-subscription-and-workspace.md) | A resource group, a Log Analytics workspace, Sentinel switched on |
| 2 | [Entra tenant, users and licences](02-entra-tenant-users-licences.md) | Four users with Entra ID P2, and an admin role for Case 3 |
| 3 | [Send Entra logs to Sentinel](03-send-entra-logs-to-sentinel.md) | Sign-in and audit logs flowing, and how to prove it |
| 4 | [Windows VM and agent](04-windows-vm-and-agent.md) | A Windows Server VM sending Security events (needed for Case 2 only) |
| 5 | [Cost and clean-up](05-cost-and-cleanup.md) | What it cost, and how to switch it all off |

Cases 1 and 3 only need steps 1 to 3. Case 2 needs all four.

## What you need before you start

- A Microsoft account that can create an Azure subscription (a free account or pay-as-you-go).
- A card for the subscription. Nothing here is expensive, but the sign-up asks for one.
- A Mac or Windows machine with a browser. For Case 2, a Remote Desktop client (I used Windows App on a Mac).
- A phone with a browser and an authenticator-capable setup, if you want to act as the "attacker" the way I did. I used my phone on a commercial VPN, with an exit country far from my own.

## The accounts in my lab

| Role | Name | Used in |
|---|---|---|
| Admin and investigator | Krishna | Setup, containment |
| Phish victim | Mike Tyson | Case 1 |
| Finance user | Rambo Craig | Case 3 |
| IT admin | Arthur Sterling | Case 3 |

All made up, except the admin account, which is mine.

## Other files in this folder

- [`img/`](img/): every setup screenshot.
- [`evidence-log.md`](evidence-log.md): my running notes while building and attacking the lab, with the timestamps I read from the logs. It's rough, but it's the raw material behind the case write-ups.
