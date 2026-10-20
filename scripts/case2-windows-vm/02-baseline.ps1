# Step 2: do some normal admin things, so you have something to compare the attack against.
# Wait until data is arriving in Sentinel (see ../../queries/lab-checks.kql) before you run this,
# or the events will not be captured.

Get-Date -Format "yyyy-MM-dd HH:mm:ss"      # write this time down

whoami
ipconfig /all
Get-Process | Select-Object -First 5

# A harmless, normal-looking scheduled task: a system program, a clear name, a daily time.
schtasks /create /tn "DailyLogCleanup" /tr "C:\Windows\System32\cleanmgr.exe /sagerun:1" /sc daily /st 03:00 /ru SYSTEM
schtasks /query /tn "DailyLogCleanup"
# If you need to run it again, add /f to the create line so it overwrites the task.
