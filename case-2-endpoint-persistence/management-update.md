# Case 2: management update

**Status:** contained on the server. A few checks and clean-up actions are still open.
**Severity (lab assessment):** medium to high. A server ran hidden commands and set itself up to run them again at every logon, with administrator rights.

**What happened.** A script saved in a folder that any user can write to launched a hidden PowerShell command. That command listed the accounts and administrators on the server. The same script was then set to run again every time someone logs on, in two ways, and a new administrator account called `helpdesk01` was created. One of the persistence items was named to look like OneDrive.

**How far it went.** One server. I can show the script running, the persistence being created, and the persistence working after a restart. I cannot show whether anything left the server, because there is no network logging, and I did not check for other hiding places beyond the three I know about.

**What we did.** Removed the scheduled task, the logon setting and the new administrator account, and deleted the script. A restart afterwards confirmed nothing runs any more. The legitimate maintenance task was left alone.

**What we could not explain.** The script ran twice, 14 seconds apart, and I do not remember why. It does not change the conclusion.

**Why it was not caught.** Nothing alerted. The server logged what happened, but no rule was looking for it, and Windows' own antivirus log is not collected, so I do not know whether it noticed.

**What we need.**
1. Approve a new alert for "hidden encoded PowerShell followed by new persistence", already written and tested on this incident.
2. Collect registry changes and antivirus alerts from servers, so persistence is visible however it is created.
3. Stop passwords appearing in command-line logs (the new administrator's password was readable in the log).
4. A sweep of the other places malware hides on this server, and a password reset for the administrator account used.

*Note: this was a lab exercise on a disposable server. The "attacker" was the analyst, and the payload was harmless.*
