# 4. Windows VM and agent (Case 2 only)

Case 2 needs a Windows machine whose logs reach Sentinel. I used a small Windows Server VM in Azure. This guide covers creating it, getting in, connecting it to Sentinel, and switching on the logging the case needs.

## A. Create the VM

**Virtual machines → Create → Azure virtual machine.** The tabs below show what I chose.

### Basics

- **Name:** `win-endpoint01`. **Region:** UK West (same as the workspace, though it doesn't have to be).
- **Image:** Windows Server 2025 Datacenter, x64 Gen2. Not Windows 11 (it needs a business licence on Azure) and not Server Core (no desktop).

![Image list](img/lab-13-vm-image-choice.png)

- **Size:** you want at least 2 vCPU and 4 GiB of memory. My first pick was blocked for my subscription, which is common on new accounts:

![NotAvailableForSubscription](img/lab-14-vm-size-unavailable.png)

Open **See all sizes** and choose one marked **Supported**:

![Sizes list](img/lab-15-vm-sizes-b-series.png)

I ended up with `Standard_D2alds_v6` (2 vCPU, 4 GiB). If the Spot box is ticked, **untick it**: Spot VMs can be switched off by Azure at any moment. And don't open Remote Desktop to the whole internet, which is the other warning on this screen:

![Spot ticked, RDP open to all addresses: don't do either](img/lab-16-vm-spot-and-rdp-warning.png)

- **Username:** I used `labadmin`. **Password:** your own, strong, and not one you use anywhere else.
- **Inbound ports:** None. We'll add one rule afterwards.

### Disks

Change the OS disk type to **Standard SSD**. It's much cheaper than Premium and the lab doesn't need the speed.

![Disks tab](img/lab-17-vm-disks-tab.png)

### Networking

- **Public inbound ports: None.**
- Tick **Delete public IP and NIC when VM is deleted**, so nothing's left billing you afterwards.

![Networking tab](img/lab-18-vm-networking-tab.png)

![Network security group Basic, with no inbound ports](img/lab-23-vm-nic-security-group-basic.png)

### Management

Tick **Enable auto-shutdown** and pick a time (mine was 02:00). It's your safety net if you forget to stop the VM.

![Management tab](img/lab-19-vm-management-tab.png)

### Monitoring and Advanced

Boot diagnostics off. Leave everything on Advanced alone. The monitoring agent gets installed later by Sentinel, not here.

![Monitoring tab](img/lab-20-vm-monitoring-tab.png)

![Advanced tab](img/lab-21-vm-advanced-tab.png)

### Review and create

Check the hourly price. Mine was **USD 0.207 per hour**, which looks alarming as a monthly figure and isn't, because you only pay for the hours the VM runs. Spot is off, ports are none.

![Review and price](img/lab-22-vm-review-and-price.png)

![Deployment running](img/lab-24-vm-deployment-in-progress.png)

![Deployment complete](img/lab-25-vm-deployment-complete.png)

## B. Get in with Remote Desktop

The VM page shows its public IP:

![VM overview (IP and subscription ID blacked out)](../case-2-endpoint-persistence/img/case2-00-vm-overview.png)

### My first attempt failed

Error `0x704`. The network security group only had Azure's default rules, and one of them is "deny all inbound":

![Only the default rules, including DenyAllInBound](../case-2-endpoint-persistence/img/case2-00b-nsg-no-rdp-rule.png)

![Remote Desktop error 0x704](../case-2-endpoint-persistence/img/case2-00c-rdp-error-0x704.png)

### The fix: one rule, for your IP only

**VM → Networking → Network settings → Create port rule → Inbound port rule.** The form starts with defaults you shouldn't keep (source Any, port 8080). Set:

| Field | Value |
|---|---|
| Source | **IP Addresses** |
| Source IP addresses | your **IPv4** address (find it with `curl -4 ifconfig.me`) |
| Service | **RDP** (this sets the port to 3389 and TCP) |
| Action | Allow |
| Priority | 1000 |
| Name | `rdp-my-ip` |

![The inbound rule form, before changing the defaults](img/lab-28-nsg-add-inbound-rule-form.png)

Your home IP can change. If Remote Desktop stops working one day, edit this rule.

### Connect

On a Mac, install **Windows App** and add the PC:

![Windows App: Add PC](img/lab-26-windows-app-add-pc-menu.png)

![The Add PC window: put the public IP in PC name](img/lab-27-windows-app-add-pc-window.png)

Sign in as `labadmin` with your password, and accept the certificate warning (it's a self-signed one). You should land on Server Manager:

![Windows Server desktop](../case-2-endpoint-persistence/img/case2-01-vm-desktop.png)

## C. Switch on the logging the case needs

Run [`01-turn-on-logging.ps1`](../scripts/case2-windows-vm/01-turn-on-logging.ps1) on the VM, in PowerShell as Administrator. It turns on process creation logging with the full command line. Without it, the Windows log doesn't say what a process was started with.

![auditpol shows Success and Failure for both](../case-2-endpoint-persistence/img/case2-02-auditpol-enabled.png)

## D. Connect the VM to Sentinel

1. **Sentinel → Content management → Content hub.** Search **Windows Security Events**, select it, **Install**.
2. **Configuration → Data connectors**, search **Windows Security Events via AMA**, **Open connector page**. Status will say Disconnected, and the rules table is empty:

![Connector disconnected, no rule yet](../case-2-endpoint-persistence/img/case2-03-connector-disconnected-no-dcr.png)

3. **Create data collection rule.** Name `dcr-win-security`. On the Resources tab, tick `win-endpoint01`. On the Collect tab, choose **All Security Events**. **Create.**
4. Creating the rule also installs the Azure Monitor Agent on the VM. Give it 5 to 10 minutes. The page should now say Connected:

![Connected, with the rule listed](../case-2-endpoint-persistence/img/case2-04-connector-connected-dcr.png)

5. On the VM page, **Settings → Extensions + applications** should show `AzureMonitorWindowsAgent` as "Provisioning succeeded":

![Agent installed](../case-2-endpoint-persistence/img/case2-05-ama-extension-installed.png)

## E. Prove the data is arriving

```kql
Heartbeat
| where Computer has "win-endpoint01"
| summarize Last = max(TimeGenerated), Beats = count() by Category
```

![The agent is reporting](../case-2-endpoint-persistence/img/case2-08-heartbeat.png)

```kql
SecurityEvent
| summarize Events = count(), Latest = max(TimeGenerated) by EventID
| order by Events desc
```

![Security events by ID](../case-2-endpoint-persistence/img/case2-09-securityevent-by-eventid.png)

If `SecurityEvent` says "No results" at first, wait 10 to 20 minutes. It was only ingestion delay for me.

When you can see `4688` rows, you're ready for [Case 2](../case-2-endpoint-persistence/README.md).

Next: [Cost and clean-up](05-cost-and-cleanup.md).
