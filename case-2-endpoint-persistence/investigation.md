# Case 2: Suspicious endpoint execution with persistence

Lab: Windows Server 2025 VM `win-endpoint01` (Azure, UK West) sending Windows Security events to Sentinel workspace `law-ir-case-study` through the Azure Monitor Agent.
All times UTC, 2026-10-20, taken from the logs. Screenshots are cited as **[E#]**; the index is at the bottom.

## Read this first: what is real and what is staged

- **Staged:** I am both the "user" and the "attacker". I created `invoice_update.cmd` myself with `Set-Content` and ran everything as `win-endpoint01\labadmin`. How such a file would arrive on a machine (a download, an email attachment) was not simulated.
- **Staged:** the payload only gathers information (`whoami /all`, `net user`, `net localgroup administrators`). Nothing here is malware, and nothing leaves the machine.
- **Real:** every process, task, registry and account event below was generated on the VM and read back from the workspace.
- I did not write down the times of my actions, and I do not remember what happened at 22:24:07 to 22:24:21 (see section 7). The logs are the source of truth for timing.

Facts, inferences and unknowns are labelled.

## 1. Trigger and telemetry

**No alert fired.** The workspace has no analytics rule that looks at Windows process or task events, so this case starts as a hunt through the endpoint telemetry, not from an incident.

**Telemetry:** `SecurityEvent` from the Windows Security Events via AMA connector, collection rule `dcr-win-security` set to All Security Events [E2]. I turned on Process Creation auditing with command line (4688) and Other Object Access Events (4698) on the VM first [E1].

**Baseline recorded first** [E3]: at 22:19:30 `labadmin` ran `whoami`, `ipconfig /all`, and created a legitimate scheduled task `\DailyLogCleanup` (daily 03:00, `cleanmgr.exe /sagerun:1`, as SYSTEM). That is the "normal admin" reference.

**Noise to filter out:** processes run by `WORKGROUP\win-endpoint01$` and Azure Monitor Agent components (`AzureMonitorAgentExtension`, `MonAgent*`, `AMAExtHealthMonitor`), `conhost`, `WmiApSrv`, `VSSVC`, built-in SYSTEM telemetry such as `reg query … softwareinventorylogging` [E6, E11].

**Gaps**
- No network, file or registry telemetry. I did not enable registry auditing.
- Windows Defender's own log is not collected, so I cannot say whether Defender saw any of this.
- No endpoint product such as Defender for Endpoint is onboarded.

## 2. Timeline

| Time | Event | Type | Ref |
|---|---|---|---|
| 22:19:29 – 22:19:30 | `whoami`, `ipconfig /all`, task `\DailyLogCleanup` created (4698 at 22:19:30.607) | Fact (baseline) | E3 |
| **22:24:07.876** | `powershell.exe -NoP -W Hidden -Enc dwBoAG8…` launched by `cmd.exe` | Fact | E8 |
| 22:24:08 | `whoami /all`, `net user`, `net localgroup administrators` (parent `powershell.exe`) | Fact | E6 |
| 22:24:16.833 | A new `powershell.exe` started by `explorer.exe` | Fact; unexplained | E6 |
| **22:24:21.596 – .619** | `cmd.exe /c C:\Users\Public\invoice_…` then the same hidden encoded PowerShell again | Fact | E6, E8 |
| 22:24:21 – 22:24:22 | The same discovery commands a second time | Fact | E6 |
| **22:25:58.417** | `schtasks /create /tn OneDriveSyncHelper /tr C:\Users\Public\invoice_update.cmd /sc onlogon /ru SYSTEM /f` | Fact | E8 |
| 22:25:58.469 | **4698**: task `\OneDriveSyncHelper` created | Fact | E7 |
| 22:25:58.506 | `reg.exe add HKCU\…\Run /v OneDriveSync … invoice_update.cmd` | Fact | E8 |
| 22:25:58.548 | `net user helpdesk01 <password> /add` (password in the command line) | Fact | E6 |
| 22:26:01.009 | **4720**: user `helpdesk01` created | Fact | E6 |
| 22:26:01.156 | **4732**: `helpdesk01` added to **Administrators** | Fact | E6 |
| 22:32:37.196 | RDP logon (4624 type 10) after a restart | Fact | E9 |
| **22:32:37.757** | SYSTEM runs `cmd.exe /c ""C:\Users\Public\invoice_update.cmd""` (the task) | Fact | E9 |
| 22:32:43.080 | SYSTEM runs the hidden encoded PowerShell | Fact | E9 |
| **22:34:12.321** | `labadmin`, parent `explorer.exe`, runs `invoice_update.cmd` (the Run key) | Fact | E9 |
| 22:36:02 – 22:36:11 | Containment: task deleted (4699), Run key deleted, `helpdesk01` removed from groups (4733) and deleted (4726) | Containment | E10, E11 |
| 22:37:49 – 22:37:51 | Restart and RDP logon; no further launches of the script | Fact | E12 |

## 3. Investigation questions and KQL

**Q1. What ran, and what started it?**
```kql
SecurityEvent
| where TimeGenerated > datetime(2026-10-20 22:23)
| where EventID in (4688, 4698, 4720, 4732)
| where Account !startswith "WORKGROUP"
| project TimeGenerated, EventID, Account, ParentProcessName, NewProcessName, CommandLine, TargetUserName, MemberName
| order by TimeGenerated asc
```
Answer: a script in `C:\Users\Public` launched hidden encoded PowerShell, which ran account discovery [E6].

**Q2. Which command lines are suspicious, in full?**
```kql
SecurityEvent
| where TimeGenerated > datetime(2026-10-20 22:23)
| where EventID == 4688 and Account !startswith "WORKGROUP"
| where CommandLine has_any ("-Enc", "schtasks", "reg", "net user", "net localgroup")
| project TimeGenerated, ParentProcessName, CommandLine
| order by TimeGenerated asc
```
Answer: encoded PowerShell twice; `schtasks /create` as SYSTEM on logon; a Run key; both pointing at the same script [E8].

**Q3. What was the scheduled task?**
```kql
SecurityEvent
| where EventID == 4698 and TimeGenerated > datetime(2026-10-20 22:00)
| extend x = parse_xml(EventData)
| mv-expand d = x.EventData.Data
| where tostring(d["@Name"]) in ("TaskName", "TaskContent")
| project TimeGenerated, Name = tostring(d["@Name"]), Value = tostring(d["#text"])
| order by TimeGenerated asc
```
Answer: `\DailyLogCleanup` at 22:19:30 (baseline) and `\OneDriveSyncHelper` at 22:25:58 [E7]. The task content is cut off in the grid, so the action and trigger come from the `schtasks` command line, not from the XML.

**Q4. Did the persistence actually run?**
```kql
SecurityEvent
| where TimeGenerated > datetime(2026-10-20 22:30)
| where EventID in (4688, 4624)
| where CommandLine has_any ("invoice_update", "-Enc") or EventID == 4624
| project TimeGenerated, EventID, Account, LogonType, ParentProcessName, NewProcessName, CommandLine
| order by TimeGenerated asc
```
Answer: yes, both, after the restart [E9].

**Q5. Is it gone?**
```kql
SecurityEvent
| where TimeGenerated > datetime(2026-10-20 22:35)
| where EventID in (4699, 4726, 4733) or (EventID == 4688 and CommandLine has_any ("schtasks", "reg", "net user", "net localgroup"))
| project TimeGenerated, EventID, Account, TargetUserName, CommandLine
| order by TimeGenerated asc
```
Answer: yes [E11, E12].

Two queries failed first and were fixed: the task-creation lookup before the data had arrived (a plain "no results" from ingestion delay, not from a mistake in the query), and my first draft of the detection, which used `to` as a variable name and failed to parse because it is a reserved word [E15].

## 4. Affected accounts, devices and resources

| Item | Status | Basis |
|---|---|---|
| Host `win-endpoint01` | **Affected** | All events above |
| Account `labadmin` | Used for execution and persistence | 4688 account field |
| Account `helpdesk01` | **Created by the activity, local administrator** | 4720, 4732 |
| Scheduled task `\OneDriveSyncHelper` | **Persistence**, SYSTEM, at logon | 4698, command line |
| Registry value `HKCU\…\Run\OneDriveSync` | **Persistence** | `reg.exe add` command line |
| Files `C:\Users\Public\invoice_update.cmd`, `o.txt` | Script and discovery output | Command lines; `o.txt` was read on the VM |

**Not reviewed:** network connections, other persistence locations (services, WMI, startup folder), and whether the discovery output was moved anywhere.

## 5. Evidence for the conclusion

Conclusion: **a script in a world-writable folder ran hidden, encoded PowerShell to enumerate local accounts and administrators, and the same script was then wired in as persistence three ways: a task running as SYSTEM at logon, a Run key, and a new local administrator.**

1. Hidden window, no profile, encoded command, parent `cmd.exe` [E8]. (Fact.)
2. Discovery commands directly after it [E6]. (Fact; the content of the payload I know because I wrote it. An analyst without that knowledge would decode the string with `[Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($s))`, which I did not run on the VM.)
3. Persistence created within two minutes of the execution, pointing at the same script [E8, E7].
4. A name chosen to look like OneDrive. I did not check whether OneDrive is installed on the server, so the camouflage is an inference.
5. The persistence ran on its own after a restart, once as SYSTEM and once as the user [E9].

## 6. Alternative explanations

| Alternative | Verdict | Why |
|---|---|---|
| Legitimate admin maintenance | **Rejected, with a caveat** | The baseline task looks different: system binary in System32, a clear name, a daily trigger, no hidden encoded PowerShell beforehand [E3]. The caveat: the same account `labadmin` made both. The logs alone cannot separate the attacker from the admin by account. |
| A management or deployment agent using `-EncodedCommand` | **Not ruled out in general** | Here the parent is `cmd.exe` running a script from `C:\Users\Public`, not an agent process. |
| Azure Monitor Agent or Windows built-in telemetry | **Ruled out** | Those processes are run by `WORKGROUP\win-endpoint01$` and have different command lines [E11]. |
| Defender or another product responded | **Unknown** | Defender's log is not collected. |

## 7. Observed, inferred, unknown

**Observed:** everything marked Fact in the timeline.
**Inferred:** the OneDrive-style name is camouflage; the first run of the payload and the second run came from the same script.
**Unknown:**
- **The double execution.** The encoded PowerShell ran at 22:24:07.876 and again at 22:24:21.619, with an Explorer-launched `powershell.exe` at 22:24:16.833 between them. I do not remember what I did. Possible but untested explanations: I pasted the first block twice, or opened a second PowerShell window.
- Whether Defender detected anything.
- Whether any other persistence exists (not swept).
- Whether a Run key written by a PowerShell cmdlet instead of `reg.exe` would appear at all (see section 9).

## 8. Containment, recovery checks, remaining uncertainty

**Done** at 22:36:02 – 22:36:04 [E10]: deleted the task, deleted the Run value, removed `helpdesk01` from Administrators and deleted it, removed the script and its output. The baseline task was left in place on purpose.

**Recovery checks**
- Local verification: task, Run value and user report "not found", `Test-Path` returns False, `DailyLogCleanup` still present [E10].
- In the log: 4688 for the commands, **4699** (task deleted), **4733** (removed from Administrators and Users), **4726** (user deleted) [E11]. Pass.
- Restart test: after a restart and RDP logon at 22:37:51 nothing launched the script [E12]. Pass, with one caveat: it reflects what had reached the workspace when I queried.

**Remaining**
- Reset `labadmin`'s password and review other sessions (not done; in a real case this account would be treated as compromised).
- Sweep other persistence locations (services, WMI subscriptions, startup folder).
- Add registry auditing or an endpoint sensor so Run keys are visible however they are written.
- Stop logging passwords: the `net user … <password>` command line, including the password, is stored in the log.

## 9. Detection improvement

Nothing alerted. [`detections/encoded-powershell-then-persistence.kql`](../detections/encoded-powershell-then-persistence.kql) flags encoded PowerShell followed within 30 minutes on the same computer by a scheduled-task, local-user or Run-key creation. Tested with fixed windows:
- 22:23 to 22:30 (the attack): **one row**, `win-endpoint01`, first encoded 22:24:07, first persistence 22:25:58, events 4688, 4698 and 4720 [E13].
- 22:15 to 22:22 (baseline only): **no rows** [E14]. That window contains no encoded PowerShell, so it shows only that the legitimate task does not alert by itself.

Limits: false-positive rate is unmeasured; management tools that use `-EncodedCommand` will trigger it; a Run key written without `reg.exe` produces no 4688 and is missed; it is not yet saved as a scheduled rule.

## Evidence index

| ID | File | Shows |
|---|---|---|
| E1 | [case2-02](img/case2-02-auditpol-enabled.png) | Process creation and object-access auditing enabled |
| E2 | [case2-04](img/case2-04-connector-connected-dcr.png), [case2-05](img/case2-05-ama-extension-installed.png) | Connector and collection rule; agent installed |
| E3 | [case2-06](img/case2-06-baseline-commands.png), [case2-07](img/case2-07-baseline-schtasks-created.png), [case2-10](img/case2-10-baseline-4688-4698.png) | Baseline commands and their log rows |
| E4 | [case2-11](img/case2-11-block-a-execution.png) | Block A: the execution |
| E5 | [case2-12](img/case2-12-block-b-persistence-and-payload-check.png) | Block B: persistence commands, payload output |
| E6 | [case2-13](img/case2-13-attack-timeline-4688-4698-4720-4732.png) | Attack timeline in SecurityEvent |
| E7 | [case2-15](img/case2-15-4698-taskname-taskcontent.png) | Task names from event 4698 |
| E8 | [case2-16](img/case2-16-key-commandlines.png) | Full command lines |
| E9 | [case2-17](img/case2-17-events-after-restart.png), [case2-18](img/case2-18-persistence-fired-at-logon.png) | Persistence firing after the restart |
| E10 | [case2-19](img/case2-19-containment-and-verification.png) | Containment and local verification |
| E11 | [case2-22](img/case2-22-removal-events-4699-4726-4733.png) | Removal events 4699, 4726, 4733 |
| E12 | [case2-20](img/case2-20-relogon-4624.png), [case2-21](img/case2-21-no-script-after-restart.png) | Re-login time; no script launches afterwards |
| E13 | [case2-24](img/case2-24-rule-test-a-attack-window.png) | Detection test, attack window |
| E14 | [case2-25](img/case2-25-rule-test-b-baseline-window.png) | Detection test, baseline window |
| E15 | [case2-23](img/case2-23-rule-syntax-error-reserved-word.png) | Syntax error and fix |
