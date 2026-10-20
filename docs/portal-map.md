# Portal map: where do I click?

Microsoft spreads this across several portals, and the menus move around. This is where I found everything. Menu names can change, so if one has moved, search for the name at the top of the portal.

## The four places you'll use

| Portal | Address | What I used it for |
|---|---|---|
| **Azure portal** | portal.azure.com | Subscription, VM, Log Analytics, Sentinel, Entra ID |
| **Microsoft 365 admin center** | admin.microsoft.com | Seeing users and licences, the Marketplace page for Defender for Endpoint |
| **Microsoft Defender portal** | security.microsoft.com | Sentinel analytics rules and incidents (this is where they opened for me), Settings, Trials |
| **Windows App** (on a Mac) | App Store | Remote Desktop into the VM |

## Azure portal

Use the search bar at the top for anything below.

| I want to... | Go to |
|---|---|
| Check my subscription is active, or see credit | **Subscriptions** → your subscription. Credits: **Cost Management → Credits** |
| Set a spending alert | **Cost Management → Budgets** |
| Create or find a resource group | **Resource groups** |
| Create the log workspace | **Log Analytics workspaces → Create** |
| Turn Sentinel on | **Microsoft Sentinel → Create** → pick the workspace → Add |
| Run queries | **Microsoft Sentinel** → your workspace → **General → Logs** (switch to KQL mode) |
| See incidents | Sentinel → **Threat management → Incidents** (opens in the Defender portal for me) |
| Install a connector solution | Sentinel → **Content management → Content hub** |
| Connect a data source | Sentinel → **Configuration → Data connectors** |
| Create or edit a detection rule | Sentinel → **Configuration → Analytics** (opened in the Defender portal for me) |
| See data collection rules | **Monitor → Data Collection Rules** |
| Create a VM | **Virtual machines → Create → Azure virtual machine** |
| Find the VM's public IP | VM → **Overview** (Primary NIC public IP) |
| Open remote desktop to my IP only | VM → **Networking → Network settings → Create port rule → Inbound port rule** |
| Check the agent is installed | VM → **Settings → Extensions + applications** |
| Reset a forgotten VM password | VM → **Help → Reset password** |
| Stop the VM so it stops costing money | VM → **Stop** (this releases the compute) |
| Delete the whole VM set-up | **Resource groups** → the VM's group → **Delete resource group** |

## Microsoft Entra ID (inside the Azure portal)

Search **Microsoft Entra ID**. Check the Overview shows your tenant's domain (`something.onmicrosoft.com`), so you know you're in the right tenant.

| I want to... | Go to |
|---|---|
| Start the Entra ID P2 trial | **Licenses → All products → Try / Buy** |
| Assign a licence | **Licenses → All products** → the licence → **Assign** (users need a usage location first) |
| Create a user | **Users → New user → Create new user** |
| Give someone an admin role | The user → **Assigned roles → Add assignments** |
| Send logs to Sentinel | **Monitoring & health → Diagnostic settings → Add diagnostic setting** |
| See the raw sign-in log | **Monitoring & health → Sign-in logs** (compare with Sentinel when the workspace looks empty) |
| See the raw audit log | **Monitoring & health → Audit logs** |
| See a user's sign-in methods | The user → **Authentication methods** |
| Contain a compromised user | The same page: **Revoke sessions**, **Reset password**, delete the methods you don't trust, **Require re-register multifactor authentication** |
| See apps and their secrets | **App registrations** → the app → **Certificates & secrets** |
| Delete a user or app | Users → select → Delete. App registrations → the app → Delete. Both are kept for about 30 days (see **Deleted users**, **Deleted applications**) |

## Microsoft 365 admin center

| I want to... | Go to |
|---|---|
| See users and which licences they hold | **Users → Active users** |
| Look at what a licence costs | **Marketplace**, then search for the product |
| Turn off auto-renew on something I bought | **Billing → Your products** → the product → recurring billing |

## Defender portal and "XDR"

Quick version of what these are:

- **Microsoft Sentinel** is a SIEM. It collects logs from lots of places and lets you search them and alert on them. It's where all the KQL in this repo runs.
- **Microsoft Defender XDR** is Microsoft's own security product family (endpoints, email, identities, cloud apps). Its alerts and incidents live in the Defender portal.
- Microsoft is merging the two, so Sentinel's incidents and analytics pages now open in the Defender portal. When I clicked **Analytics** or **Incidents** from Sentinel, I ended up in `security.microsoft.com`. That's why some of my screenshots show the Defender portal, not the Azure one.

| I want to... | Go to |
|---|---|
| See incidents from my detection rules | **Incidents** |
| Create or look at detection rules | **Microsoft Sentinel → Configuration → Analytics** (use "Show navigation" to open the whole left menu) |
| See which Defender features my tenant has | **Settings**. If there's no **Endpoints** entry, you don't have Defender for Endpoint |
| Look for free trials | **Trials** (left menu) |

### The Defender for Endpoint detour

I looked at Defender for Endpoint to get proper endpoint data from a spare laptop. It didn't work out:

- My tenant had no Endpoints settings, so no Defender for Endpoint ([screenshot](../lab-setup/img/lab-29-defender-settings-no-endpoints.png)).
- The Marketplace page sells Defender for Endpoint P2 at £4.80 per user per month, with no free trial ([screenshot](../lab-setup/img/lab-30-m365-marketplace-defender-endpoint-p2.png)).
- My spare laptop ran Windows 11 **Home**, which Defender for Endpoint can't onboard.

So I used a small Azure VM and Windows Security events instead. If you have a Pro or Enterprise machine and a licence, Defender for Endpoint gives you richer tables (`DeviceProcessEvents` and friends), and the same cases would work with those.

## On a Mac: Windows App

Install **Windows App** from the App Store. Click **+ → Add PC**, enter the VM's public IP, then choose the user `labadmin` when it asks for credentials. Accept the certificate warning. Screenshots are in [lab-setup/04-windows-vm-and-agent.md](../lab-setup/04-windows-vm-and-agent.md).
