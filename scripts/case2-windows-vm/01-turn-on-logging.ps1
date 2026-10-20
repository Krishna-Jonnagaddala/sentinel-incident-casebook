# Step 1: turn on the Windows logging that the case needs.
# Run this on the VM, in PowerShell opened as Administrator, BEFORE you do anything else.
# Without it, Windows does not record what a process was started with, and the whole case
# would show nothing useful.

# Log every process that starts (event 4688), successes and failures.
auditpol /set /subcategory:"Process Creation" /success:enable /failure:enable

# Log scheduled task creation (event 4698) and similar object access events.
auditpol /set /subcategory:"Other Object Access Events" /success:enable /failure:enable

# Put the full command line into the 4688 events. This is the setting that makes
# "powershell.exe -NoP -W Hidden -Enc ..." visible in Sentinel.
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\Audit" /v ProcessCreationIncludeCmdLine_Enabled /t REG_DWORD /d 1 /f

# Check it worked. You should see "Success and Failure" for both lines.
auditpol /get /subcategory:"Process Creation","Other Object Access Events"
