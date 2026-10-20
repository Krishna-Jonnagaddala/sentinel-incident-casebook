# Lab setup: all screenshots

Every screenshot from building the lab. The step-by-step guides that use them are in [`README.md`](README.md).

30 screenshots, in the order they were taken. Names match the `E` references in the investigation.

### `lab-01-licensed-users`

The four lab users, each with Entra ID P2 (Microsoft 365 admin center).

![The four lab users, each with Entra ID P2 (Microsoft 365 admin center).](img/lab-01-licensed-users.png)

### `lab-02-workspace-review`

Creating the Log Analytics workspace: review page.

![Creating the Log Analytics workspace: review page.](img/lab-02-workspace-review.png)

### `lab-03-workspace-deployed`

Workspace deployed.

![Workspace deployed.](img/lab-03-workspace-deployed.png)

### `lab-04-resource-group`

The workspace in its resource group (subscription ID blacked out).

![The workspace in its resource group (subscription ID blacked out).](img/lab-04-resource-group.png)

### `lab-05-sentinel-empty-overview`

Sentinel switched on: nothing in it yet.

![Sentinel switched on: nothing in it yet.](img/lab-05-sentinel-empty-overview.png)

### `lab-06-diag-settings-list`

The Entra diagnostic setting, saved.

![The Entra diagnostic setting, saved.](img/lab-06-diag-settings-list.png)

### `lab-07-diag-setting-categories`

The categories ticked in the diagnostic setting.

![The categories ticked in the diagnostic setting.](img/lab-07-diag-setting-categories.png)

### `lab-08-first-ingest-union-count`

First check of the workspace: audit logs only.

![First check of the workspace: audit logs only.](img/lab-08-first-ingest-union-count.png)

### `lab-09-first-auditlogs`

The first audit events.

![The first audit events.](img/lab-09-first-auditlogs.png)

### `lab-10-add-service-principal-benign`

Two 'Add service principal' events initiated by Microsoft, not an attacker.

![Two 'Add service principal' events initiated by Microsoft, not an attacker.](img/lab-10-add-service-principal-benign.png)

### `lab-11-signinlogs-empty-export-delay`

Sentinel showing no sign-ins yet.

![Sentinel showing no sign-ins yet.](img/lab-11-signinlogs-empty-export-delay.png)

### `lab-12-entra-signin-logs-source`

The Entra portal's own sign-in log: the sign-ins are there, so it was just delay.

![The Entra portal's own sign-in log: the sign-ins are there, so it was just delay.](img/lab-12-entra-signin-logs-source.png)

### `lab-13-vm-image-choice`

Choosing the VM image.

![Choosing the VM image.](img/lab-13-vm-image-choice.png)

### `lab-14-vm-size-unavailable`

A VM size blocked for the subscription (NotAvailableForSubscription).

![A VM size blocked for the subscription (NotAvailableForSubscription).](img/lab-14-vm-size-unavailable.png)

### `lab-15-vm-sizes-b-series`

The list of VM sizes.

![The list of VM sizes.](img/lab-15-vm-sizes-b-series.png)

### `lab-16-vm-spot-and-rdp-warning`

A form with Spot ticked and Remote Desktop open to everyone: neither is a good idea.

![A form with Spot ticked and Remote Desktop open to everyone: neither is a good idea.](img/lab-16-vm-spot-and-rdp-warning.png)

### `lab-17-vm-disks-tab`

The Disks tab: Standard SSD.

![The Disks tab: Standard SSD.](img/lab-17-vm-disks-tab.png)

### `lab-18-vm-networking-tab`

The Networking tab.

![The Networking tab.](img/lab-18-vm-networking-tab.png)

### `lab-19-vm-management-tab`

The Management tab: auto-shutdown.

![The Management tab: auto-shutdown.](img/lab-19-vm-management-tab.png)

### `lab-20-vm-monitoring-tab`

The Monitoring tab.

![The Monitoring tab.](img/lab-20-vm-monitoring-tab.png)

### `lab-21-vm-advanced-tab`

The Advanced tab.

![The Advanced tab.](img/lab-21-vm-advanced-tab.png)

### `lab-22-vm-review-and-price`

Review and price (USD 0.207 per hour).

![Review and price (USD 0.207 per hour).](img/lab-22-vm-review-and-price.png)

### `lab-23-vm-nic-security-group-basic`

Network security group Basic with no inbound ports.

![Network security group Basic with no inbound ports.](img/lab-23-vm-nic-security-group-basic.png)

### `lab-24-vm-deployment-in-progress`

VM deployment in progress.

![VM deployment in progress.](img/lab-24-vm-deployment-in-progress.png)

### `lab-25-vm-deployment-complete`

VM deployment complete.

![VM deployment complete.](img/lab-25-vm-deployment-complete.png)

### `lab-26-windows-app-add-pc-menu`

Windows App on a Mac: the Add PC menu.

![Windows App on a Mac: the Add PC menu.](img/lab-26-windows-app-add-pc-menu.png)

### `lab-27-windows-app-add-pc-window`

The Add PC window.

![The Add PC window.](img/lab-27-windows-app-add-pc-window.png)

### `lab-28-nsg-add-inbound-rule-form`

The inbound security rule form (before changing the defaults).

![The inbound security rule form (before changing the defaults).](img/lab-28-nsg-add-inbound-rule-form.png)

### `lab-29-defender-settings-no-endpoints`

The Defender portal's Settings: no Endpoints entry, so no Defender for Endpoint.

![The Defender portal's Settings: no Endpoints entry, so no Defender for Endpoint.](img/lab-29-defender-settings-no-endpoints.png)

### `lab-30-m365-marketplace-defender-endpoint-p2`

The Microsoft 365 Marketplace page for Defender for Endpoint P2 (GBP 4.80 per user per month).

![The Microsoft 365 Marketplace page for Defender for Endpoint P2 (GBP 4.80 per user per month).](img/lab-30-m365-marketplace-defender-endpoint-p2.png)
