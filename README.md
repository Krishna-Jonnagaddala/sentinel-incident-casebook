# Microsoft Incident Investigation Casebook

Three incident investigations, worked end to end in a Microsoft Sentinel and Entra ID lab, written for people who are new to the SOC.

Most training material stops at "here's the alert". This repo shows what comes after: the questions you ask, the queries you write, how you decide what's true, how far it went, how you stop it and check it stopped, and how you explain it to different people. Every step is here: the clicks, the KQL, the PowerShell, the screenshots, and the mistakes.

You can read it, or rebuild the lab and do all three cases yourself.

## Where to start

| If you want to... | Go to |
|---|---|
| Understand how to read this repo | [`docs/start-here.md`](docs/start-here.md) |
| See an investigation in two minutes | [Case 1 README](case-1-phishing/README.md) |
| Rebuild the lab | [`lab-setup/`](lab-setup/README.md) |
| Find a click in Azure, Entra, Sentinel or Defender | [`docs/portal-map.md`](docs/portal-map.md) |
| Look up a term or an event code | [`docs/glossary.md`](docs/glossary.md) |
| Copy a query | [`queries/`](queries/README.md) |
| See how things went wrong | [`docs/mistakes-and-fixes.md`](docs/mistakes-and-fixes.md) |

## The three cases

| Case | The situation | What you'll practise | Needs |
|---|---|---|---|
| [**1. Phishing, then suspicious account activity**](case-1-phishing/README.md) | A user types their password into a fake page. Then their account signs in from another country. | Spotting a foreign sign-in, reading MFA and risk fields, finding persistence (a passkey), containing it, testing the containment | Entra ID logs |
| [**2. Suspicious endpoint execution with persistence**](case-2-endpoint-persistence/README.md) | A script on a Windows server starts hidden, encoded PowerShell and sets itself up to run again. | Process creation logs, reading a command line, telling normal from suspicious scheduled tasks, proving persistence with a restart | A Windows VM |
| [**3. Admin account compromise with identity changes**](case-3-account-compromise/README.md) | An IT admin's password is guessed. The account then creates a user, resets a password and registers an app. | Baselines, admin roles, "admin or attacker?", finding every way back in, and fixing a detection that gave a false positive | Entra ID logs |

I'd read them in the order 1, 3, 2. Case 3 builds on Case 1, and Case 2 needs a VM.

Every case includes:

- the story and what it teaches,
- the full investigation with a timeline,
- a one-page update for managers and a technical report,
- every query, with notes,
- a step-by-step guide to run it yourself,
- every screenshot, with a caption,
- a detection I built and tested.

## What you'll be able to do

- Read Entra ID sign-in and audit logs and tell a normal sign-in from a suspicious one.
- Write KQL to answer one question at a time, and recover when a query fails.
- Work out what an attacker added to an account or a machine, and what each thing is for.
- Build a timeline, label each line as **fact, inference or unknown**, and say why you ruled something out.
- Contain an incident in the right order, then test that the containment worked.
- Write a detection, test it on real data, and find out where it's wrong.
- Explain the same incident to a manager and to another analyst.

## What's in the repo

```
README.md                    this page
docs/                        start-here, portal map, glossary, method, mistakes and fixes
lab-setup/                   step-by-step guides to build the lab, with screenshots
case-1-phishing/             README, investigation, reports, queries, how to reproduce, screenshots
case-2-endpoint-persistence/ (same)
case-3-account-compromise/   (same)
queries/                     the KQL index and the lab checks
scripts/                     the PowerShell used on the Windows VM
detections/                  the three detection rules, and how to save one in Sentinel
```

## What's real and what's staged

It's a lab, so it matters that you know.

- **Real:** the Entra ID tenant, the Sentinel workspace, the Windows VM, and every log, query and screenshot. Everything in the cases happened in the lab and was read back from the workspace.
- **Staged:** I'm the attacker in all three cases (a phone behind a VPN for Cases 1 and 3, a script on the VM for Case 2). The victims are made-up accounts. I knew the passwords, so credential theft and MFA bypass weren't simulated; I completed MFA prompts myself.
- **Not simulated:** a phishing email. The tenant has no mailboxes, so Case 1 starts from a user report.
- **Harmless payload:** Case 2's hidden command only lists accounts.

I didn't write down the time of my own actions as I went, so every time in the cases comes from the logs. Where my memory and the logs disagree, the logs win, and the text says so.

## Limits you should know about

- I couldn't measure false positives. The workspace only held a few hours of data.
- Case 1 has no sign-in data before the compromise (an export gap), and one sign-in after containment that I couldn't explain.
- Case 2 has a script run I can't account for, and a blind spot (a Run key written another way wouldn't show up).
- Some logs weren't collected (Graph activity, Azure Activity, Windows Defender's own log), so "no rows" there doesn't mean "nothing happened".

These are written up as open questions in each case.

## Cost

The one meaningful cost was the Windows VM, at USD 0.207 an hour while running, for a few hours. Everything else was free trials or pennies per GB of logs. Details, and how to switch it all off, are in [`lab-setup/05-cost-and-cleanup.md`](lab-setup/05-cost-and-cleanup.md).

## Screenshots and privacy

Screenshots come from my own tenant and VM. I blacked out my home IP addresses, locations, subscription IDs, my surname, my account name in the portal's top bar, and a throwaway lab password. VPN addresses, the tenant name and the fictional users are left visible because they're part of the evidence.

## A warning

Use this in your own tenant, on your own machines. Don't point any of it at systems that aren't yours. Case 2's script creates an administrator account, so run it only on a machine you can delete afterwards.
