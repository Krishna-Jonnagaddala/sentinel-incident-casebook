# 5. Cost and clean-up

None of this is expensive if you pay attention. Here's what costs money, and how to switch it all off.

## What costs what

I didn't keep a running total of what I spent, so I can only give you the prices the portal showed me.

| Item | Price shown | Notes |
|---|---|---|
| Windows Server VM (`Standard_D2alds_v6`, UK West) | USD 0.207 per hour while running | Stopping it (Deallocate) stops this. The review page's monthly figure is for running 24/7 |
| VM disk (Standard SSD) | about USD 10.56 per month if it exists all month | A few cents for a few days |
| Public IP | about USD 3.65 per month | Same, for a few days |
| Log Analytics / Sentinel | Charged per GB ingested | This lab produced very little. I didn't track the exact charge |
| Entra ID P2 | Free trial | Check the trial's end date on the Licenses page |
| Defender for Endpoint P2 | GBP 4.80 per user per month (Marketplace page) | I looked at it and didn't use it. It can't onboard Windows Home |

The Review page's estimate had a "one or more costs did not load" warning, so treat the monthly numbers as rough.

## Three things I did to stay safe on cost

1. **Auto-shutdown** on the VM (02:00), in case I forgot.
2. **Standard SSD** instead of Premium.
3. **Delete public IP and NIC with the VM**, so nothing's left behind.

Do one more thing: set a **budget alert** (**Cost Management → Budgets**), at something like USD 10, so you hear about a surprise before it's a big one.

## When you've finished Case 2

You don't need the VM any more once you have your screenshots and your log queries are done. Everything you'll want is already in the workspace.

1. **Resource groups** → the VM's group (mine was `win-endpoint01_group_83995645`, created automatically).
2. Look at what's listed: the VM, its disk, public IP, network interface, virtual network, network security group.
3. **Delete resource group**, type its name, confirm.

**Don't delete the group that holds your Sentinel workspace** (`rg-ir-casebook`) until you've finished with all three cases. That's where your evidence is.

## When you've finished everything

- Export or screenshot what you want to keep. Deleting the workspace deletes the logs.
- Disable or delete the analytics rules (**Sentinel → Configuration → Analytics**).
- Delete the test users. Deleted users and apps stay recoverable for about 30 days (**Entra ID → Users → Deleted users**, **App registrations → Deleted applications**). If you need them gone sooner, permanently delete them there.
- If you used the Entra P2 trial, let it expire or remove the licences.
- If you bought anything (a Defender licence, for example), turn off recurring billing: **Billing → Your products** in the Microsoft 365 admin center.
- Check **Cost Management** the day after, to confirm the charges have stopped.
