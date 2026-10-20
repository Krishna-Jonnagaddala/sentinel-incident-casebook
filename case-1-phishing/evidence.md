# Case 1: all screenshots

Every screenshot from Case 1, with a plain caption. The queries behind them are in [`queries.kql`](queries.kql).

28 screenshots, in the order they were taken. Names match the `E` references in the investigation.

### `case1-01-mike-job-title-set`

Mike's profile before the attack: job title set to Accounts Payable Analyst.

![Mike's profile before the attack: job title set to Accounts Payable Analyst.](img/case1-01-mike-job-title-set.png)

### `case1-02-signinlogs-mike-rambo-arthur`

First look at SigninLogs. Nigeria on an Android phone and the UK on a Mac, seconds apart.

![First look at SigninLogs. Nigeria on an Android phone and the UK on a Mac, seconds apart.](img/case1-02-signinlogs-mike-rambo-arthur.png)

### `case1-03-auditlogs-all-24h`

AuditLogs for the last 24 hours. The security info changes start at 16:55.

![AuditLogs for the last 24 hours. The security info changes start at 16:55.](img/case1-03-auditlogs-all-24h.png)

### `case1-04-auditlogs-with-ip`

The same audit query with the source IP added.

![The same audit query with the source IP added.](img/case1-04-auditlogs-with-ip.png)

### `case1-05-signin-summary-by-ip`

Sign-ins summarised by account and IP: one Nigerian address failing against Rambo and Arthur.

![Sign-ins summarised by account and IP: one Nigerian address failing against Rambo and Arthur.](img/case1-05-signin-summary-by-ip.png)

### `case1-06-security-info-registration-details`

The passkey registration, with the method details.

![The passkey registration, with the method details.](img/case1-06-security-info-registration-details.png)

### `case1-07-mike-risk-and-auth-requirement`

Risk and authentication requirement: no risk detected, and the foreign sign-ins needed only a password.

![Risk and authentication requirement: no risk detected, and the foreign sign-ins needed only a password.](img/case1-07-mike-risk-and-auth-requirement.png)

### `case1-08-noninteractive-query-error`

A query that failed: LocationDetails is stored as text in this table (see the fix in queries.kql).

![A query that failed: LocationDetails is stored as text in this table (see the fix in queries.kql).](img/case1-08-noninteractive-query-error.png)

### `case1-09-mike-noninteractive-signins`

73 background sign-ins from the foreign session.

![73 background sign-ins from the foreign session.](img/case1-09-mike-noninteractive-signins.png)

### `case1-10-mike-signins-recheck-early-rows`

Re-running the sign-in query over a fixed window to see whether early rows had arrived late. They hadn't.

![Re-running the sign-in query over a fixed window to see whether early rows had arrived late. They hadn't.](img/case1-10-mike-signins-recheck-early-rows.png)

### `case1-11-noninteractive-summary-by-app`

The foreign session grouped by app: most of it is the security info page.

![The foreign session grouped by app: most of it is the security info page.](img/case1-11-noninteractive-summary-by-app.png)

### `case1-12-mike-auth-methods-before-containment`

Mike's sign-in methods before containment: an authenticator and the new passkey.

![Mike's sign-in methods before containment: an authenticator and the new passkey.](img/case1-12-mike-auth-methods-before-containment.png)

### `case1-13-mike-auth-methods-after-containment`

Mike's methods straight after containment: no usable methods.

![Mike's methods straight after containment: no usable methods.](img/case1-13-mike-auth-methods-after-containment.png)

### `case1-14-containment-auditlogs`

The audit log of the containment steps.

![The audit log of the containment steps.](img/case1-14-containment-auditlogs.png)

### `case1-15-mike-last-signin-by-ip`

Last sign-in per address. The Nigerian activity had stopped before containment, so this proved nothing yet.

![Last sign-in per address. The Nigerian activity had stopped before containment, so this proved nothing yet.](img/case1-15-mike-last-signin-by-ip.png)

### `case1-16-security-info-audit-trail`

The full security info audit trail, including the deletions.

![The full security info audit trail, including the deletions.](img/case1-16-security-info-audit-trail.png)

### `case1-17-post-containment-retest-signins`

The retest: events after containment.

![The retest: events after containment.](img/case1-17-post-containment-retest-signins.png)

### `case1-18-retest-signin-detail`

Retest detail: one sign-in at 17:24:49 that needed MFA and succeeded.

![Retest detail: one sign-in at 17:24:49 that needed MFA and succeeded.](img/case1-18-retest-signin-detail.png)

### `case1-19-mvexpand-error`

A second failed query: AuthenticationDetails is text here too.

![A second failed query: AuthenticationDetails is text here too.](img/case1-19-mvexpand-error.png)

### `case1-20-1724-mfa-method`

The 17:24:49 sign-in completed MFA with an OATH verification code. I couldn't explain this.

![The 17:24:49 sign-in completed MFA with an OATH verification code. I couldn't explain this.](img/case1-20-1724-mfa-method.png)

### `case1-21-audit-after-1714`

Audit events after 17:14: no new method registered.

![Audit events after 17:14: no new method registered.](img/case1-21-audit-after-1714.png)

### `case1-22-mike-auth-methods-final`

Final check of Mike's methods: still none.

![Final check of Mike's methods: still none.](img/case1-22-mike-auth-methods-final.png)

### `case1-23-graph-activity-no-rows`

Graph activity query: no rows. Not the same as 'nothing happened'.

![Graph activity query: no rows. Not the same as 'nothing happened'.](img/case1-23-graph-activity-no-rows.png)

### `case1-24-azureactivity-no-rows`

Azure Activity query: no rows. That log isn't connected in this lab.

![Azure Activity query: no rows. That log isn't connected in this lab.](img/case1-24-azureactivity-no-rows.png)

### `case1-25-detection-test-result`

The first detection query run on this case: one row, Mike.

![The first detection query run on this case: one row, Mike.](img/case1-25-detection-test-result.png)

### `case1-26-rule-wizard-general`

Creating the analytics rule: the General tab.

![Creating the analytics rule: the General tab.](img/case1-26-rule-wizard-general.png)

### `case1-27-rule-wizard-logic`

Creating the analytics rule: the rule logic and schedule.

![Creating the analytics rule: the rule logic and schedule.](img/case1-27-rule-wizard-logic.png)

### `case1-28-rule-saved-enabled`

The saved rule, enabled in the Analytics list.

![The saved rule, enabled in the Analytics list.](img/case1-28-rule-saved-enabled.png)
