# Case 2: all screenshots

Every screenshot from Case 2, with a plain caption. The queries are in [`queries.kql`](queries.kql) and the commands in [`../scripts/case2-windows-vm/`](../scripts/case2-windows-vm/).

29 screenshots, in the order they were taken. Names match the `E` references in the investigation.

### `case2-00-vm-overview`

The VM's overview page (IP and subscription ID blacked out).

![The VM's overview page (IP and subscription ID blacked out).](img/case2-00-vm-overview.png)

### `case2-00b-nsg-no-rdp-rule`

The network security group before I added a Remote Desktop rule: only Azure's defaults, including DenyAllInBound.

![The network security group before I added a Remote Desktop rule: only Azure's defaults, including DenyAllInBound.](img/case2-00b-nsg-no-rdp-rule.png)

### `case2-00c-rdp-error-0x704`

Remote Desktop failing with error 0x704 because of that.

![Remote Desktop failing with error 0x704 because of that.](img/case2-00c-rdp-error-0x704.png)

### `case2-01-vm-desktop`

Logged in: the Windows Server desktop.

![Logged in: the Windows Server desktop.](img/case2-01-vm-desktop.png)

### `case2-02-auditpol-enabled`

Process creation and object access auditing switched on.

![Process creation and object access auditing switched on.](img/case2-02-auditpol-enabled.png)

### `case2-03-connector-disconnected-no-dcr`

The Sentinel connector page before any collection rule exists: Disconnected.

![The Sentinel connector page before any collection rule exists: Disconnected.](img/case2-03-connector-disconnected-no-dcr.png)

### `case2-03b-data-connectors-list`

The connectors list in Sentinel.

![The connectors list in Sentinel.](img/case2-03b-data-connectors-list.png)

### `case2-04-connector-connected-dcr`

After creating the collection rule: Connected, with dcr-win-security listed.

![After creating the collection rule: Connected, with dcr-win-security listed.](img/case2-04-connector-connected-dcr.png)

### `case2-05-ama-extension-installed`

The Azure Monitor Agent installed on the VM.

![The Azure Monitor Agent installed on the VM.](img/case2-05-ama-extension-installed.png)

### `case2-06-baseline-commands`

The baseline: ordinary admin commands on the VM.

![The baseline: ordinary admin commands on the VM.](img/case2-06-baseline-commands.png)

### `case2-07-baseline-schtasks-created`

The baseline scheduled task being created.

![The baseline scheduled task being created.](img/case2-07-baseline-schtasks-created.png)

### `case2-08-heartbeat`

Heartbeat: the agent is talking to the workspace.

![Heartbeat: the agent is talking to the workspace.](img/case2-08-heartbeat.png)

### `case2-09-securityevent-by-eventid`

Security events arriving, by event ID.

![Security events arriving, by event ID.](img/case2-09-securityevent-by-eventid.png)

### `case2-10-baseline-4688-4698`

The baseline in the log: whoami, ipconfig, schtasks (4688) and the task creation (4698).

![The baseline in the log: whoami, ipconfig, schtasks (4688) and the task creation (4698).](img/case2-10-baseline-4688-4698.png)

### `case2-11-block-a-execution`

Block A: the script that starts hidden, encoded PowerShell.

![Block A: the script that starts hidden, encoded PowerShell.](img/case2-11-block-a-execution.png)

### `case2-12-block-b-persistence-and-payload-check`

Block B: the persistence commands, plus the output file from the hidden command. The lab password is blacked out.

![Block B: the persistence commands, plus the output file from the hidden command. The lab password is blacked out.](img/case2-12-block-b-persistence-and-payload-check.png)

### `case2-13-attack-timeline-4688-4698-4720-4732`

The whole attack in order: 4688, 4698, 4720, 4732.

![The whole attack in order: 4688, 4698, 4720, 4732.](img/case2-13-attack-timeline-4688-4698-4720-4732.png)

### `case2-14-4698-eventdata-raw`

The scheduled task event (4698) as raw XML.

![The scheduled task event (4698) as raw XML.](img/case2-14-4698-eventdata-raw.png)

### `case2-15-4698-taskname-taskcontent`

The same event turned into rows: task name and content.

![The same event turned into rows: task name and content.](img/case2-15-4698-taskname-taskcontent.png)

### `case2-16-key-commandlines`

The full command lines: encoded PowerShell, schtasks, reg add.

![The full command lines: encoded PowerShell, schtasks, reg add.](img/case2-16-key-commandlines.png)

### `case2-17-events-after-restart`

Event counts after the restart.

![Event counts after the restart.](img/case2-17-events-after-restart.png)

### `case2-18-persistence-fired-at-logon`

After the restart: SYSTEM runs the script at logon (the task), and the user runs it through explorer.exe (the Run key).

![After the restart: SYSTEM runs the script at logon (the task), and the user runs it through explorer.exe (the Run key).](img/case2-18-persistence-fired-at-logon.png)

### `case2-19-containment-and-verification`

The cleanup and its verification, on the VM.

![The cleanup and its verification, on the VM.](img/case2-19-containment-and-verification.png)

### `case2-20-relogon-4624`

My logon after the second restart: 22:37:51.

![My logon after the second restart: 22:37:51.](img/case2-20-relogon-4624.png)

### `case2-21-no-script-after-restart`

After the second restart, nothing launched the script.

![After the second restart, nothing launched the script.](img/case2-21-no-script-after-restart.png)

### `case2-22-removal-events-4699-4726-4733`

The cleanup recorded in the log: 4699, 4726, 4733.

![The cleanup recorded in the log: 4699, 4726, 4733.](img/case2-22-removal-events-4699-4726-4733.png)

### `case2-23-rule-syntax-error-reserved-word`

A detection query that failed to parse because 'to' is a reserved word.

![A detection query that failed to parse because 'to' is a reserved word.](img/case2-23-rule-syntax-error-reserved-word.png)

### `case2-24-rule-test-a-attack-window`

Detection test on the attack window: one row.

![Detection test on the attack window: one row.](img/case2-24-rule-test-a-attack-window.png)

### `case2-25-rule-test-b-baseline-window`

Detection test on the baseline window: no rows.

![Detection test on the baseline window: no rows.](img/case2-25-rule-test-b-baseline-window.png)
