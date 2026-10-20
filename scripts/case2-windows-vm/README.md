# PowerShell scripts for Case 2

These are the commands I typed on the Windows Server VM, split into five steps. Run them in order,
in PowerShell opened as Administrator.

| File | What it does |
|---|---|
| `01-turn-on-logging.ps1` | Makes Windows record process creation (with command line) and scheduled task creation |
| `02-baseline.ps1` | Normal admin activity, so the attack has something to be compared against |
| `03-execution.ps1` | The "attack", part 1: a script starts hidden, encoded PowerShell |
| `04-persistence.ps1` | The "attack", part 2: a scheduled task, a Run key and a new admin account |
| `05-clean-up-and-check.ps1` | Removes it all and checks it is gone |

Two rules:
- **Only run these on a machine you can throw away.** Step 4 creates an administrator account.
- Each script prints the time. Write it down. I did not, and I wished I had.

The full walk-through, with screenshots, is in [`../../case-2-endpoint-persistence/reproduce.md`](../../case-2-endpoint-persistence/reproduce.md).
