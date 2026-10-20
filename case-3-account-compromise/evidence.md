# Case 3: all screenshots

Every screenshot from Case 3, with a plain caption. The queries behind them are in [`queries.kql`](queries.kql).

30 screenshots, in the order they were taken. Names match the `E` references in the investigation.

### `case3-01-arthur-assigned-roles`

Arthur's two admin roles.

![Arthur's two admin roles.](img/case3-01-arthur-assigned-roles.png)

### `case3-02-baseline-signins`

Baseline sign-ins for Rambo and Arthur (plus Case 1 leftovers at the top).

![Baseline sign-ins for Rambo and Arthur (plus Case 1 leftovers at the top).](img/case3-02-baseline-signins.png)

### `case3-03-baseline-add-user`

The baseline admin change: Arthur creating a test user from home.

![The baseline admin change: Arthur creating a test user from home.](img/case3-03-baseline-add-user.png)

### `case3-04-users-list-after-attack`

Users after the attack: the new user svc-backup01 (display name backup-sync).

![Users after the attack: the new user svc-backup01 (display name backup-sync).](img/case3-04-users-list-after-attack.png)

### `case3-05-app-registrations-backup-sync`

App registrations after the attack: backup-sync, with an active secret.

![App registrations after the attack: backup-sync, with an active secret.](img/case3-05-app-registrations-backup-sync.png)

### `case3-06-arthur-auth-methods-after-attack`

Arthur's sign-in methods after the attack: authenticator and passkey.

![Arthur's sign-in methods after the attack: authenticator and passkey.](img/case3-06-arthur-auth-methods-after-attack.png)

### `case3-07-foreign-signins`

The foreign sign-ins: six failures, then a success on Arthur, from Brazil.

![The foreign sign-ins: six failures, then a success on Arthur, from Brazil.](img/case3-07-foreign-signins.png)

### `case3-08-arthur-audit-actions`

Everything Arthur's account did, including the Validate Password noise.

![Everything Arthur's account did, including the Validate Password noise.](img/case3-08-arthur-audit-actions.png)

### `case3-09-app-credential-audit`

App and credential activity.

![App and credential activity.](img/case3-09-app-credential-audit.png)

### `case3-10-role-assignments-audit`

When Arthur got his two admin roles.

![When Arthur got his two admin roles.](img/case3-10-role-assignments-audit.png)

### `case3-11-arthur-audit-no-noise`

Arthur's actions with the noise removed.

![Arthur's actions with the noise removed.](img/case3-11-arthur-audit-no-noise.png)

### `case3-12-backdoor-usage-no-rows`

The backdoor user and the app: no sign-ins seen.

![The backdoor user and the app: no sign-ins seen.](img/case3-12-backdoor-usage-no-rows.png)

### `case3-13-incidents-list`

The three incidents raised by the first rule.

![The three incidents raised by the first rule.](img/case3-13-incidents-list.png)

### `case3-14-incident-2`

Incident 2 in detail.

![Incident 2 in detail.](img/case3-14-incident-2.png)

### `case3-15-incident-3`

Incident 3 in detail.

![Incident 3 in detail.](img/case3-15-incident-3.png)

### `case3-16-incident-1`

Incident 1 in detail.

![Incident 1 in detail.](img/case3-16-incident-1.png)

### `case3-17-rule-v1-three-rows`

The first rule run over 24 hours: three rows, one of them a false positive.

![The first rule run over 24 hours: three rows, one of them a false positive.](img/case3-17-rule-v1-three-rows.png)

### `case3-18-rule-v2-test-arthur`

Rule version 2 at the attack time: only the Brazilian sign-in remains.

![Rule version 2 at the attack time: only the Brazilian sign-in remains.](img/case3-18-rule-v2-test-arthur.png)

### `case3-19-rule-v2-test-mike`

Rule version 2 at the Case 1 time: Mike.

![Rule version 2 at the Case 1 time: Mike.](img/case3-19-rule-v2-test-mike.png)

### `case3-20-rule-wizard-lookup-limit`

Sentinel refusing a 7-day lookup that runs every 15 minutes.

![Sentinel refusing a 7-day lookup that runs every 15 minutes.](img/case3-20-rule-wizard-lookup-limit.png)

### `case3-21-analytics-both-rules-enabled`

Both rules in the Analytics list.

![Both rules in the Analytics list.](img/case3-21-analytics-both-rules-enabled.png)

### `case3-22-analytics-v1-disabled-v2-enabled`

Version 1 disabled, version 2 enabled.

![Version 1 disabled, version 2 enabled.](img/case3-22-analytics-v1-disabled-v2-enabled.png)

### `case3-23-arthur-methods-after-containment`

Arthur's methods after containment.

![Arthur's methods after containment.](img/case3-23-arthur-methods-after-containment.png)

### `case3-24-rambo-methods-after-containment`

Rambo's methods after containment: his own authenticator is still there.

![Rambo's methods after containment: his own authenticator is still there.](img/case3-24-rambo-methods-after-containment.png)

### `case3-25-users-after-containment`

Users after containment: the backdoor user is gone.

![Users after containment: the backdoor user is gone.](img/case3-25-users-after-containment.png)

### `case3-26-app-registrations-after-containment`

App registrations after containment: empty.

![App registrations after containment: empty.](img/case3-26-app-registrations-after-containment.png)

### `case3-27-containment-audit-filtered`

The containment steps in the audit log.

![The containment steps in the audit log.](img/case3-27-containment-audit-filtered.png)

### `case3-28-containment-audit-by-krishna`

The same, filtered to the admin who did the cleanup.

![The same, filtered to the admin who did the cleanup.](img/case3-28-containment-audit-by-krishna.png)

### `case3-29-union-locationdetails-error`

A failed query: union changes how LocationDetails behaves.

![A failed query: union changes how LocationDetails behaves.](img/case3-29-union-locationdetails-error.png)

### `case3-30-retest-signins`

The retest from Brazil: old passwords rejected, old sessions revoked.

![The retest from Brazil: old passwords rejected, old sessions revoked.](img/case3-30-retest-signins.png)
