# Case 2: redo it yourself

**Use a machine you can throw away.** Step D creates an administrator account. An Azure VM you delete afterwards is ideal.

## A. Build the VM and connect it

Follow [lab step 4](../lab-setup/04-windows-vm-and-agent.md). By the end:
- the VM runs and you can reach it over Remote Desktop,
- the agent is installed,
- `SecurityEvent` in Sentinel has rows ([`../queries/lab-checks.kql`](../queries/lab-checks.kql)).

Don't carry on until you can see `4688` events.

## B. Turn on the logging (if you haven't)

[`01-turn-on-logging.ps1`](../scripts/case2-windows-vm/01-turn-on-logging.ps1). It turns on process creation logging **with the command line**. This is the setting the whole case depends on.

![auditpol showing both settings enabled](img/case2-02-auditpol-enabled.png)

## C. Record a baseline

[`02-baseline.ps1`](../scripts/case2-windows-vm/02-baseline.ps1). Normal admin commands, plus a harmless scheduled task called `DailyLogCleanup`.

![The baseline commands](img/case2-06-baseline-commands.png)

Look in Sentinel afterwards. You'll see these commands (`4688`) and the task creation (`4698`) among a lot of noise from the agent and from Windows itself:

![The baseline in the log](img/case2-10-baseline-4688-4698.png)

## D. The "attack"

### D1. Execution

[`03-execution.ps1`](../scripts/case2-windows-vm/03-execution.ps1). A script in `C:\Users\Public` runs a hidden, encoded PowerShell that lists accounts.

![Block A run](img/case2-11-block-a-execution.png)

### D2. Persistence

[`04-persistence.ps1`](../scripts/case2-windows-vm/04-persistence.ps1). A scheduled task, a Run key and a new administrator. **Use a throwaway password.** It will appear in the log.

![Block B run, with the throwaway password blacked out](img/case2-12-block-b-persistence-and-payload-check.png)

### D3. Prove it works

Restart the VM (Start → Power → Restart), log back in, and wait a few minutes. Don't run anything else. The task and the Run key should each start the script.

## E. Investigate

Work through [`queries.kql`](queries.kql). Wait 10 to 20 minutes first, for the events to arrive.

You should find:
- the encoded PowerShell, with `cmd.exe` as its parent,
- discovery commands (`whoami`, `net user`, `net localgroup`) right after it,
- a `schtasks /create` and a `4698`,
- a `reg add` writing to the Run key,
- a `4720` (user created) and two `4732`s (added to Users and Administrators),
- after the restart: SYSTEM and then your user running the script.

## F. Contain and check

[`05-clean-up-and-check.ps1`](../scripts/case2-windows-vm/05-clean-up-and-check.ps1). Removes everything, leaves the baseline task, checks it's gone.

![Cleanup and verification on the VM](img/case2-19-containment-and-verification.png)

Then restart again, log in, wait, and run queries 8 and 9 in [`queries.kql`](queries.kql). You want `4699`, `4726` and `4733` for the removal, and **no results** for anything launching the script.

![The removal events](img/case2-22-removal-events-4699-4726-4733.png)

## G. Test the detection

Run query 10 in [`queries.kql`](queries.kql) at two fixed windows: one covering the attack (expect one row), one covering only the baseline (expect nothing). The query has the details.

## H. Clean up

[Lab step 5](../lab-setup/05-cost-and-cleanup.md): delete the resource group that holds the VM. Nothing here needs to stay running.
