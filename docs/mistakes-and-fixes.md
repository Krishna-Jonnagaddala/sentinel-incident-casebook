# Mistakes and fixes

Everything that went wrong in this project, in the order it happened, with what fixed it. If you hit the same thing, you'll save yourself some time.

## Setting up

| What happened | Why | Fix |
|---|---|---|
| Sentinel showed no data an hour after I turned on the Entra export | Sign-in logs arrive much later than audit logs at the start | Compare with **Entra ID → Monitoring & health → Sign-in logs**. If rows are there, wait. See [`lab-11`](../lab-setup/img/lab-11-signinlogs-empty-export-delay.png) and [`lab-12`](../lab-setup/img/lab-12-entra-signin-logs-source.png) |
| Entries before the diagnostic setting existed weren't in the workspace | Export only starts when you switch it on | Turn it on before you do anything you'll want to investigate |
| Sign-in data for Case 1 was missing before 16:55 | Same export gap | Written up as a limitation. Recording a baseline *after* the export works avoids it |
| VM size `Standard_D2s_v3` was blocked: `NotAvailableForSubscription` | New subscriptions have size and region limits | Open **See all sizes** and pick one marked Supported, or change the region. See [`lab-14`](../lab-setup/img/lab-14-vm-size-unavailable.png) |
| The Azure Spot box was ticked when I reached that part of the form | I hadn't noticed it | Untick it. Spot VMs can be switched off by Azure at any time, in the middle of an investigation |
| Remote Desktop failed with error `0x704` | The network security group only had the default rules, which include "deny all inbound" | Add one inbound rule for port 3389 from your own IPv4 address. See [`case2-00b`](../case-2-endpoint-persistence/img/case2-00b-nsg-no-rdp-rule.png) |
| The portal's "My IP address" option might fill in an IPv6 address | The VM's public address is IPv4 | Use "IP Addresses" and type your IPv4 (`curl -4 ifconfig.me`) |
| Defender for Endpoint wouldn't work on my spare laptop | Windows 11 Home can't be onboarded | Used an Azure Windows Server VM instead |

## Writing queries

| What happened | Why | Fix |
|---|---|---|
| `Path expression countryOrRegion source must be scalar of type 'dynamic'` | In `AADNonInteractiveUserSignInLogs`, `LocationDetails` is stored as text | `tostring(parse_json(LocationDetails).countryOrRegion)` ([`case1-08`](../case-1-phishing/img/case1-08-noninteractive-query-error.png)) |
| `mv-expand: expanded expression expected to have dynamic type` | `AuthenticationDetails` is text in `SigninLogs` | `mv-expand AuthDetail = parse_json(AuthenticationDetails)` ([`case1-19`](../case-1-phishing/img/case1-19-mvexpand-error.png)) |
| `Failed to resolve scalar expression named 'LocationDetails'` after a `union` | After a union of two tables where one column has different types, it splits into separate columns | Read the country inside each table first, then `union` ([`case3-29`](../case-3-account-compromise/img/case3-29-union-locationdetails-error.png)) |
| `Query could not be parsed at 'to'` | `to` is a reserved word in KQL | Name the variables `tstart` and `tend` ([`case2-23`](../case-2-endpoint-persistence/img/case2-23-rule-syntax-error-reserved-word.png)) |
| `SecurityEvent` empty right after setup | Ingestion delay on first data | Check `Heartbeat`, then wait 10-20 minutes. I guessed wrongly that my events had happened before the agent started; they hadn't |
| The `net user` filter missed rows | The log says `net.exe user`, not `net user` | Search for the parts you're sure of |
| 14 "Validate Password" rows looked like guessing | The new-user form checks password strength as you type | Check the initiator and timing before deciding. Filter the noise out |

## Detections

| What happened | Why | Fix |
|---|---|---|
| The Sentinel rule wizard said: with a lookup of 2 days or more the rule must run at most once an hour | Sentinel limits how often longer lookbacks can run | Used a 1-day lookup and a 15-minute schedule instead ([`case3-20`](../case-3-account-compromise/img/case3-20-rule-wizard-lookup-limit.png)) |
| My first rule paired a registration with *any* single-factor sign-in in the previous 30 minutes | That also matched the admin's own home sign-in, so one attack raised two incidents | Version 2: only trigger when the sign-in came from a country the user hasn't used before ([`case3-17`](../case-3-account-compromise/img/case3-17-rule-v1-three-rows.png)) |
| The incidents didn't say who they were about | I skipped the entity mapping step | Map the user column to an Account entity when you create the rule |
| "Single-factor" turned out not to be a good signal | Normal sign-ins from home were also single-factor in this tenant | Check how *your* normal traffic looks before you pick a condition |

## Understanding the evidence

| What happened | What I learned |
|---|---|
| In Case 1, I first said the attacker got in because Mike had no MFA method | The "before containment" screenshot showed he had an authenticator. I corrected it. Having an MFA method isn't the same as being asked for it |
| An MFA code worked after I'd deleted the method (Case 1) | I never explained it. Both guesses are in the report, marked as untested |
| I didn't write down the time of my own actions | Use the logs for time, or let the script print the clock |
| The script ran twice 14 seconds apart in Case 2 | I don't remember why. It's listed as unexplained |
| Empty Graph and Azure Activity results | Empty doesn't mean nothing happened. It can mean not collected |
