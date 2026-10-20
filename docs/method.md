# How I worked each case

This is the routine I settled into. It isn't official, it's what worked. Use it as a checklist.

## Before the attack

- **Check your data is flowing.** Run the queries in [`queries/lab-checks.kql`](../queries/lab-checks.kql). Don't start anything until you can see sign-ins (or Security events) arriving.
- **Record a baseline.** Sign in normally a few times. Do a normal admin task. In Case 3 I did this properly and it made the later comparison easy. In Case 1 I didn't, and it left a hole in the report.
- **Keep a clock.** Every time I wrote down "about ten minutes ago" I regretted it. Use the logs for times, and when you do something deliberately, write the time next to it. (The Case 2 scripts print the time for you.)

## While you investigate

1. **Write down what you know and what you don't**, before you open a single query.
2. **Ask one question at a time.** "Where did this account sign in from?" "Did anything change on it?" "Did it spread?" Each question gets a query and an answer. Keep both.
3. **Put the events in order.** Copy the exact timestamps from the logs. If two things look wrong, check whether they're really two things.
4. **Label every claim:** fact, inference, or unknown.
5. **Look for an explanation that isn't "attacker".** What would an admin doing normal work look like? What would Microsoft's own background activity look like? Write down why you rejected each one, or that you couldn't.
6. **Check who started it.** Many "add app" and "add service principal" events are Microsoft itself. The initiator column tells you.

## When something's empty

Empty results are the thing I got wrong most. An empty result can mean:

- it didn't happen,
- it happened but the logs haven't arrived yet (ingestion delay),
- it happened but you aren't collecting that log at all.

Only the first one is good news. For every empty result I tried to find out which of the three it was. Where I couldn't, the report says "scope not established" and not "nothing happened".

## Containment

- Cut off access first, then remove what the attacker added. (Revoke sessions before deleting methods and resetting passwords.)
- Write down the time of every step.
- Don't remove the legitimate things by accident. In Case 2, I left the real scheduled task in place on purpose.
- **Then test it.** Containment you haven't tested is a guess. I tried to sign in with the old password, reused old sessions, and restarted the VM to see if anything came back.

## Reporting

- **Management update:** what happened, how far, what you did, what you couldn't explain, what you need. No jargon. Half a page.
- **Technical report:** the same facts with indicators, exact times, exact actions, and the gaps.
- **Detection improvement:** one concrete thing that would have caught it sooner. Test it against the real data, and say how.

## Habits that paid off

- Save the failed queries. They're the best teaching material in the repo (see [mistakes-and-fixes.md](mistakes-and-fixes.md)).
- Keep screenshots as you go, with the query visible. I couldn't have written the evidence sections otherwise.
- When you're unsure, write "unknown". Nobody ever got hurt by that line.
