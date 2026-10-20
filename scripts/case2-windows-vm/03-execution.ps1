# Step 3 (the attack, part 1): a script that starts a hidden, encoded PowerShell command.
# Nothing in here is malware. The hidden command only lists accounts and writes the result
# to a text file. This is a harmless copy of what real attackers do.

Get-Date -Format "yyyy-MM-dd HH:mm:ss"      # write this time down

# This is the text  "whoami /all > C:\Users\Public\o.txt; net user >> C:\Users\Public\o.txt;
# net localgroup administrators >> C:\Users\Public\o.txt"  converted to the format that
# PowerShell's -EncodedCommand switch expects (UTF-16 text turned into base64).
$enc = "dwBoAG8AYQBtAGkAIAAvAGEAbABsACAAPgAgAEMAOgBcAFUAcwBlAHIAcwBcAFAAdQBiAGwAaQBjAFwAbwAuAHQAeAB0ADsAIABuAGUAdAAgAHUAcwBlAHIAIAA+AD4AIABDADoAXABVAHMAZQByAHMAXABQAHUAYgBsAGkAYwBcAG8ALgB0AHgAdAA7ACAAbgBlAHQAIABsAG8AYwBhAGwAZwByAG8AdQBwACAAYQBkAG0AaQBuAGkAcwB0AHIAYQB0AG8AcgBzACAAPgA+ACAAQwA6AFwAVQBzAGUAcgBzAFwAUAB1AGIAbABpAGMAXABvAC4AdAB4AHQA"

# To see what a string like that really says, decode it:
#   [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($enc))

# Save the "invoice" script in a folder that any user can write to (C:\Users\Public).
Set-Content -Path C:\Users\Public\invoice_update.cmd -Value "@echo off`r`npowershell.exe -NoP -W Hidden -Enc $enc"

# Run it.
cmd.exe /c C:\Users\Public\invoice_update.cmd

Get-Date -Format "yyyy-MM-dd HH:mm:ss"      # write this time down

# Check the hidden command did its job (the first lines are your own account details):
Get-Content C:\Users\Public\o.txt | Select-Object -First 8
