# Start here

You've just started in security operations, or you're about to. You've heard words like SIEM, KQL and "incident", and you want to see what an investigation actually looks like from the inside. This page tells you how to use the rest of the repo.

## What this is

Three investigations that I ran in my own Microsoft lab. For each one I:

1. made something suspicious happen on purpose,
2. found it again in the logs, the way an analyst would,
3. worked out how far it went,
4. stopped it and checked that it was really stopped,
5. wrote it up twice: once for managers, once for other technical people,
6. built a detection so the same thing gets caught next time.

Everything is written down: the exact clicks, the exact queries, the exact commands, the screenshots, and the mistakes. You can read it like a book, or follow it step by step and do the same in your own tenant.

## What an investigation looks like

It's less mysterious than it sounds. It's a loop:

| Step | What you're doing | Where it is in each case |
|---|---|---|
| 1. Start | An alert, a report, or a hunch. Write down what you know and what you don't. | "Trigger and telemetry" |
| 2. Baseline | What does normal look like for these accounts and machines? | "Baseline" |
| 3. Ask questions | One question at a time. Each gets a query. | "Investigation questions and KQL" |
| 4. Build the timeline | Put the events in order, with the exact time. | "Timeline" |
| 5. Work out the scope | Which accounts, devices and resources are involved? | "Affected accounts, devices and resources" |
| 6. Argue against yourself | What else could explain this? | "Alternative explanations" |
| 7. Contain | Stop it. | "Containment" |
| 8. Check | Did the stop actually work? Try to break it. | "Recovery checks" |
| 9. Report | Short version for managers. Detail for analysts. | `management-update.md`, `technical-report.md` |
| 10. Improve | Make a detection or a process change so you catch it faster next time. | "Detection improvement" |

## Facts, inferences and unknowns

This is the habit I'd most like you to pick up. Every claim in the cases is one of three things:

- **Fact:** the log shows it. ("At 16:56:05 a passkey was registered on Mike's account.")
- **Inference:** a sensible conclusion that the log doesn't show directly. ("The passkey probably belongs to the attacker's phone, because its detail says Google Password Manager.")
- **Unknown:** I don't know, and I say so. ("I can't explain why an MFA code worked after I deleted the method.")

Read the unknowns. A report with no unknowns usually means someone didn't look hard enough.

## Which case to read first

I'd go in this order:

1. **[Case 1: phishing, then suspicious account activity](../case-1-phishing/README.md).** The easiest to follow. Identity logs only (Entra ID).
2. **[Case 3: admin account compromise](../case-3-account-compromise/README.md).** Same logs as Case 1, harder question: how do you tell an admin doing their job from an attacker using an admin's account? It also fixes a mistake from Case 1.
3. **[Case 2: endpoint execution with persistence](../case-2-endpoint-persistence/README.md).** A Windows server. Needs a VM and a little more setup.

## How each case folder is laid out

| File | Read it when you want to... |
|---|---|
| `README.md` | get the story in two minutes |
| `investigation.md` | see the full case: timeline, queries, evidence, what I ruled out |
| `management-update.md` | see how to explain it to someone non-technical |
| `technical-report.md` | see the version for another analyst |
| `reproduce.md` | run the same attack in your own lab, step by step |
| `queries.kql` | copy every query I used, in order, with notes |
| `evidence.md` | look at every screenshot with a caption |
| `img/` | the screenshots themselves |

## If you want to rebuild the lab

Go to [`lab-setup/`](../lab-setup/README.md). It walks through the Azure subscription, the Entra ID tenant, Sentinel, sending the logs across, and the Windows VM. It also says what each part cost, and how to switch it all off.

Other pages that help:

- [`portal-map.md`](portal-map.md): "where do I click?" for the Azure portal, Entra ID, Sentinel and the Defender portal.
- [`glossary.md`](glossary.md): the terms and event codes, in plain words.
- [`method.md`](method.md): my checklist for working a case.
- [`mistakes-and-fixes.md`](mistakes-and-fixes.md): everything that went wrong, and what fixed it.

## A word of warning

This is a lab. The "attacker" is me, the "victims" are made-up accounts, and the Windows payload only lists user accounts. Please do the same: use your own tenant and your own machines, and nothing else. Don't try any of this on systems that aren't yours.
