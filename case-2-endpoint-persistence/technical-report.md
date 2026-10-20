# Case 2: technical incident report

**Incident:** hidden encoded PowerShell execution with triple persistence on a Windows server
**Host:** `win-endpoint01` (Windows Server 2025 Datacenter, Azure UK West); telemetry through the Azure Monitor Agent to Sentinel workspace `law-ir-case-study`
**Window:** 2026-10-20 22:24 to 22:38 UTC
**Detail and evidence references:** [investigation.md](investigation.md)

## Summary
`win-endpoint01\labadmin` ran `C:\Users\Public\invoice_update.cmd`, which launched `powershell.exe -NoP -W Hidden -Enc …` (account discovery) twice. The same script was registered for persistence by a scheduled task running as SYSTEM at logon, an HKCU Run value, and a new local administrator `helpdesk01`. The persistence executed after a restart. It was removed at 22:36:02 and confirmed gone after a second restart.

## Indicators
| Type | Value |
|---|---|
| File | `C:\Users\Public\invoice_update.cmd`, `C:\Users\Public\o.txt` |
| Command line | `powershell.exe -NoP -W Hidden -Enc dwBoAG8AYQBtAGkAIAAvAGEAbABsACAAPgAg…` (decodes to `whoami /all`, `net user`, `net localgroup administrators`, output to `o.txt`) |
| Scheduled task | `\OneDriveSyncHelper`, `/sc onlogon /ru SYSTEM`, action `invoice_update.cmd` |
| Registry | `HKCU\Software\Microsoft\Windows\CurrentVersion\Run`, value `OneDriveSync` |
| Account | `helpdesk01`, created 22:26:01 (4720), added to Administrators (4732) |
| Parent chain | `explorer`/`powershell` → `cmd.exe` → `powershell.exe -Enc` → `whoami`, `net`, `net1` |

## Findings
1. Execution: 22:24:07.876 and 22:24:21.619, both with parent `cmd.exe`; discovery commands follow each. Two launches 14 seconds apart are unexplained, as is an Explorer-launched `powershell.exe` at 22:24:16.833.
2. Persistence, 22:25:58 – 22:26:01: task creation (4688 and 4698), Run key (`reg.exe add`), local user and group changes (4688, 4720, 4732).
3. Sensitive data in logs: the `net user helpdesk01 <password> /add` command line stores the password.
4. Persistence confirmed working: after logon at 22:32:37.196 SYSTEM ran the script at 22:32:37.757 and the encoded PowerShell at 22:32:43.080; `labadmin` ran it via `explorer.exe` at 22:34:12.321.
5. No analytic rule or alert fired.

## Response actions (UTC)
| Time | Action |
|---|---|
| 22:36:02.905 | `schtasks /delete /tn OneDriveSyncHelper /f` (4699 at 22:36:02.933) |
| 22:36:02.960 | `reg delete HKCU\…\Run /v OneDriveSync /f` |
| 22:36:03.028 – .097 | `helpdesk01` removed from Administrators and Users (4733), deleted (4726) |
| 22:36:02 – 22:36:04 | Script and output deleted |

## Verification
- Local: task, Run value and user not found; `Test-Path` False; `DailyLogCleanup` still present.
- Log: 4699, 4733 x2, 4726 present.
- After a restart and RDP logon at 22:37:51: no 4688 with `invoice_update` or `-Enc`.

## Gaps
- No network, file or registry telemetry; Defender's log not collected.
- Other persistence locations not swept.
- `labadmin` credentials and sessions not reset.
- A Run key written by a PowerShell cmdlet or API would produce no 4688 and is not covered.
- The recovery check reflects ingestion at query time.

## Detection
`detections/encoded-powershell-then-persistence.kql`: encoded PowerShell followed within 30 minutes on the same host by 4698, 4720, or a `schtasks`/`reg` creation command line. Test A (22:23 – 22:30): one row. Test B (22:15 – 22:22, baseline only): none. False-positive rate not measured; not yet saved as a scheduled rule.
