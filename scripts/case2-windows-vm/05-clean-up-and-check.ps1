# Step 5: remove everything the attack added, then check it is really gone.
# Leaves the baseline task (DailyLogCleanup) alone on purpose: it is the legitimate one.

Get-Date -Format "yyyy-MM-dd HH:mm:ss"      # write this time down

schtasks /delete /tn "OneDriveSyncHelper" /f
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v OneDriveSync /f
net localgroup administrators helpdesk01 /delete
net user helpdesk01 /delete
Remove-Item C:\Users\Public\invoice_update.cmd, C:\Users\Public\o.txt -Force

Get-Date -Format "yyyy-MM-dd HH:mm:ss"      # write this time down

# Check. Each of the first four should say it cannot be found (or print False).
schtasks /query /tn "OneDriveSyncHelper"
reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v OneDriveSync
net user helpdesk01
Test-Path C:\Users\Public\invoice_update.cmd
# This one should still be there:
schtasks /query /tn "DailyLogCleanup"

# Last check: restart the VM, log in, wait 10 minutes, and make sure nothing starts the script again
# (query 9 in ../../case-2-endpoint-persistence/queries.kql).
