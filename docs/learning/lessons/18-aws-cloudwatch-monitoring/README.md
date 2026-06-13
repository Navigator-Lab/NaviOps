# Lesson 18 — AWS CloudWatch & Monitoring/Alerting

**Status:** ready for self-study · **Date written:** 2026-06-11
**Gate Rule:** Concept → Real-World Use → Alternatives → Hands-On → Verification → Quiz → Reflection → Search Keywords

> **How to use this lesson:** same as Lessons 03–17. This is the cloud-scale
> version of Lesson 05's `journalctl`/`service_check.sh` and Lesson 06's
> scheduled health checks.

---

## Step 1 — Concept

### What it is

**CloudWatch** is AWS's monitoring and observability service: it collects
**metrics** (numeric time-series data — CPU%, network bytes, disk I/O),
**logs** (via the CloudWatch agent or service integrations), and lets you set
**alarms** that trigger actions (notify via **SNS** — Simple Notification
Service — email/SMS/webhook, or auto-remediate) when metrics cross thresholds.
**Dashboards** visualize metrics/logs in one place.

### Why it exists

Lesson 05 gave you `journalctl` for **one server's** logs; Lesson 06 gave you
scheduled health checks. At cloud scale (many EC2 instances, managed services
like RDS/S3), you need **centralized** metrics/logs and **automatic alerting**
— "tell me the moment CPU hits 90% on any instance, before a human notices the
app is slow."

### What problem it solves

| Problem | CloudWatch solution |
|---|---|
| "Is this EC2 instance's CPU/disk/network healthy right now?" | CloudWatch metrics (auto-collected for EC2 by default) |
| "Alert me if disk usage exceeds 85%" | CloudWatch alarm + SNS notification (extends Lesson 07's `disk_report.sh` threshold) |
| "Centralize logs from multiple instances in one place" | CloudWatch Logs (via CloudWatch agent) |
| "When CPU spikes, automatically run a remediation script" | Alarm → SSM Automation (auto-remediation) |
| "Show me CPU/memory/disk for all my instances on one screen" | CloudWatch Dashboard |

### Three-Level Depth (Lens A)

- **Level 1 — Beginner:** EC2 automatically reports basic metrics (CPU
  utilization, network in/out, disk read/write **operations** — but **not**
  memory or disk **usage** by default — those need the CloudWatch agent
  installed). `aws cloudwatch describe-alarms` lists alarms;
  `aws cloudwatch get-metric-statistics` queries metric data.
- **Level 2 — SysAdmin:** Per [oneuptime's CloudWatch alerting best
  practices](https://oneuptime.com/blog/post/2026-02-13-aws-cloudwatch-alerting-best-practices/view)
  and [drdroid's CloudWatch alerting guide](https://drdroid.io/engineering-tools/guide-for-cloudwatch-alerting-best-practices-and-implementation):
  **threshold selection** should be based on real historical data — examine
  ~2 weeks of metrics to understand normal variation before setting alarm
  thresholds (avoids false positives from normal spikes). **Require multiple
  consecutive breaching data points** before alarming (e.g., "3 out of 3
  periods of 5 minutes above 90% CPU") to reduce alert fatigue from transient
  spikes. Most teams wire alarms to an **SNS topic**, which can fan out to
  email, SMS, PagerDuty, etc. — one alarm, multiple notification channels.
  **Custom metrics**: install the CloudWatch agent to get memory/disk-usage
  metrics (not available by default) — directly extends Lesson 07's
  `disk_report.sh` (`check_disk_usage`) into a centrally-monitored, alertable
  metric. **Composite alarms** combine multiple alarms with AND/OR logic
  (e.g., "alert only if CPU high AND request count high" — avoids
  false-positive alerts during legitimate traffic spikes).
- **Level 3 — Systems/Kernel (Lens D):** The **CloudWatch agent** running on an
  EC2 instance is conceptually similar to the scripts you've already written
  (Lessons 03/04/07/10) — it reads `/proc` (Lesson 04's process info),
  `/sys` (cgroups, Lesson 11), and disk usage (`df`-equivalent, Lesson 07), then
  **pushes** these as metrics to the CloudWatch API on a schedule — the cloud
  equivalent of your `user_audit.sh`/`disk_report.sh` running on a cron/timer
  (Lesson 06) but reporting to a central API instead of local logs. Alarms are
  evaluated by CloudWatch's backend against the metric time-series — when an
  alarm transitions state (OK → ALARM), it publishes to SNS, which is a
  pub/sub messaging service (similar conceptually to how `journald` "publishes"
  log entries that `journalctl` "subscribes" to read).

### Analogy (Lens B)

- **CloudWatch metrics** = a hospital's vital-signs monitors — continuously
  recording heart rate (CPU), blood pressure (network), oxygen levels (disk
  I/O) for every patient (instance), all displayed on a central nurses'
  station screen (dashboard).
- **CloudWatch alarms + SNS** = the monitor's alert system — if a vital sign
  crosses a dangerous threshold **for a sustained period** (not just one
  noisy blip — multiple consecutive breaching periods), it pages the on-call
  doctor (SNS → email/SMS/PagerDuty) — and a "composite alarm" is like "only
  page if heart rate AND blood pressure are both abnormal" (reduces false
  alarms from a single noisy sensor).
- **CloudWatch agent** = a dedicated monitoring device attached to the patient
  that measures things the basic bedside monitor doesn't (memory/disk usage —
  not collected by default, just like basic EC2 metrics don't include
  memory).
- **Auto-remediation (SSM Automation)** = the hospital bed automatically
  adjusting itself (running a fix script) the instant a vital sign crosses a
  threshold, *before* the doctor even arrives — useful for well-understood,
  safe-to-automate fixes (restart a service), risky for anything requiring
  judgment.

The hospital analogy holds well but breaks down for **metric retention/
granularity** (CloudWatch stores high-resolution data for a limited time, then
"rolls up" to lower resolution for longer retention) — hospital vital-sign
histories don't typically have this kind of automatic resolution downsampling
over time.

---

## Step 2 — Real-World Use

### How SysAdmins use this daily

```bash
# View metrics
aws cloudwatch list-metrics --namespace AWS/EC2
aws cloudwatch get-metric-statistics \
  --namespace AWS/EC2 --metric-name CPUUtilization \
  --dimensions Name=InstanceId,Value=<INSTANCE_ID> \
  --start-time 2026-06-10T00:00:00Z --end-time 2026-06-11T00:00:00Z \
  --period 3600 --statistics Average

# Alarms
aws cloudwatch describe-alarms
aws cloudwatch put-metric-alarm \
  --alarm-name high-cpu --metric-name CPUUtilization --namespace AWS/EC2 \
  --statistic Average --period 300 --threshold 80 \
  --comparison-operator GreaterThanThreshold --evaluation-periods 3 \
  --dimensions Name=InstanceId,Value=<INSTANCE_ID> \
  --alarm-actions <SNS_TOPIC_ARN>

# Logs
aws logs describe-log-groups
aws logs tail /var/log/naviops --follow
```

**Real production scenarios:**
1. **CPU/disk alarms with SNS → email** — the cloud equivalent of Lesson 07's
   `disk_report.sh check_high_usage_alert()`, but centrally managed and
   notifying you even when you're not logged into the server.
2. **Centralized logging** — instead of SSHing into each instance to
   `journalctl` (Lesson 05), the CloudWatch agent ships logs centrally;
   `aws logs tail --follow` works like `journalctl -f` but across instances.
3. **Auto-remediation** — an alarm on "service down" metric triggers an SSM
   Automation document that restarts the systemd service (Lesson 05) without
   human intervention.

### Common mistakes

| Mistake | Impact | Fix |
|---|---|---|
| Setting alarm thresholds based on guesswork | Constant false alarms (alert fatigue) or alarms that never fire | Base thresholds on ~2 weeks of real metric history |
| Single-datapoint alarms | One transient spike triggers a page at 3am for nothing | Require multiple consecutive breaching periods (`evaluation-periods`) |
| Assuming memory/disk usage metrics exist by default | Alarms on these metrics silently never trigger (metric doesn't exist) | Install CloudWatch agent for memory/disk metrics |
| No SNS subscription confirmed | Alarm fires but no one is notified | Confirm SNS subscription (check email/confirm link) after creating |
| Auto-remediation for risky actions (e.g., auto-terminate) | A flapping alarm could cause a remediation loop or data loss | Reserve auto-remediation for safe, idempotent actions (restart a service); alert-only for risky ones |

### When NOT to over-engineer

- For a single learning instance, 2-3 alarms (CPU, disk via agent, status
  check) with email-via-SNS is sufficient — composite alarms and
  auto-remediation are valuable to *understand* but not necessary to fully
  build out for a learning project.

### Interview Angle

**Scenario:** "Our team set up a CPU alarm at 80% with a 1-minute evaluation
period. It now fires multiple times a day for transient spikes, and people
have started ignoring the Slack channel. How do you fix this?"

A junior answer says "raise the threshold to 95%" — a guess that papers over
the real issue and might mask a genuine problem later. A senior answer
diagnoses **alert fatigue** as the actual incident: pull ~2 weeks of
`get-metric-statistics` history to see what "normal" actually looks like,
then fix the alarm's `evaluation-periods` (e.g., require 3 consecutive
5-minute breaches instead of 1) so transient spikes don't trigger it — and
separately considers a **composite alarm** (CPU high AND request-count high)
if the real signal is "CPU spikes that correlate with actual load." The
distinction: junior tunes the number, senior tunes the *signal*.

---

## Step 3 — Alternatives

| Topic | Alternative | Note |
|---|---|---|
| CloudWatch (this lesson) | **Prometheus + Grafana** (Lesson 22) | CloudWatch is AWS-native/managed; Prometheus+Grafana is the open-source standard, portable across clouds/on-prem — both are valuable to know |
| SNS for alerting | **PagerDuty/Opsgenie** (subscribed via SNS) | SNS is the AWS-native pub/sub layer; PagerDuty adds on-call scheduling/escalation on top |
| CloudWatch Logs | **ELK/Loki stack** (Lesson 22) | CloudWatch Logs is simplest for AWS-only environments; ELK/Loki are portable/open-source alternatives |

---

## Step 4 — Hands-On Task (build this yourself)

**Goal:** Set up CloudWatch alarms (CPU + disk via agent) with SNS email
notification for an EC2 instance, extending Lesson 07's `disk_report.sh`
threshold logic to the cloud.

### Lens C — Manual → Automated → Why

**Manual (Lesson 07):** `disk_report.sh check_high_usage_alert()` runs when you
remember to SSH in and run it, or via cron (Lesson 06) — but **you only see the
alert if you check the log/email on that one server**.

**Automated (CloudWatch):**
1. Create an SNS topic and subscribe your email:
```bash
aws sns create-topic --name naviops-alerts
aws sns subscribe --topic-arn <TOPIC_ARN> --protocol email --notification-endpoint <YOUR_EMAIL>
# Confirm via the email link AWS sends
```
2. Install/configure the CloudWatch agent on your EC2 instance (Lesson 16) to
   report disk usage as a custom metric.
3. Create alarms:
```bash
# CPU alarm (default metric, no agent needed)
aws cloudwatch put-metric-alarm \
  --alarm-name naviops-high-cpu \
  --metric-name CPUUtilization --namespace AWS/EC2 \
  --statistic Average --period 300 --threshold 80 \
  --comparison-operator GreaterThanThreshold --evaluation-periods 3 \
  --dimensions Name=InstanceId,Value=<INSTANCE_ID> \
  --alarm-actions <SNS_TOPIC_ARN>

# Disk usage alarm (requires CloudWatch agent's custom metric)
aws cloudwatch put-metric-alarm \
  --alarm-name naviops-high-disk \
  --metric-name disk_used_percent --namespace CWAgent \
  --statistic Average --period 300 --threshold 85 \
  --comparison-operator GreaterThanThreshold --evaluation-periods 1 \
  --dimensions Name=InstanceId,Value=<INSTANCE_ID>,Name=path,Value=/ \
  --alarm-actions <SNS_TOPIC_ARN>
```

**Why this matters:** this is Lesson 07's `disk_report.sh`
`check_high_usage_alert()` and Lesson 06's scheduling, reimplemented as
managed AWS services — same logic ("alert when disk > threshold"), now with
centralized notification regardless of which server it happens on.

### What to build, step by step

1. (If your Lesson 16 instance was terminated, launch a fresh Free-Tier
   instance for this lesson — remember to terminate afterward.)
2. Create the SNS topic, subscribe your email, confirm the subscription.
3. Create the CPU alarm (no agent needed — works immediately on default
   metrics).
4. Install the CloudWatch agent, configure it for disk metrics, create the
   disk alarm.
5. **Test the CPU alarm**: run `yes > /dev/null &` (a few times, to spike CPU)
   on the instance, wait for the alarm to transition to ALARM and the email to
   arrive — then `kill` the processes.
6. Document your alarm configuration in `docs/aws/monitoring-design.md`
   (redacted ARNs/instance IDs).
7. Clean up: delete alarms/SNS topic/terminate instance when done (avoid
   ongoing charges).
8. Commit `docs/aws/monitoring-design.md` and any agent config JSON
   (redacted) on `lesson/18-aws-cloudwatch-monitoring`.

---

## Step 5 — Verification

```bash
# Confirm alarms exist and their state
aws cloudwatch describe-alarms --alarm-names naviops-high-cpu naviops-high-disk

# Confirm SNS subscription is confirmed (not "PendingConfirmation")
aws sns list-subscriptions-by-topic --topic-arn <TOPIC_ARN>

# Trigger the CPU alarm intentionally
ssh -i ~/.ssh/<key>.pem <user>@<ip> "yes > /dev/null & yes > /dev/null &"
# Wait ~15 minutes, check email, then:
ssh -i ~/.ssh/<key>.pem <user>@<ip> "pkill yes"

aws cloudwatch describe-alarm-history --alarm-name naviops-high-cpu
```

### Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| Alarm never reaches ALARM state during test | `evaluation-periods`/`period` too long for a quick test, or threshold too high | Temporarily lower threshold/periods for testing, restore afterward |
| No email received | SNS subscription not confirmed | Check spam folder; re-subscribe and confirm |
| Disk alarm metric doesn't exist (`disk_used_percent`) | CloudWatch agent not installed/configured for disk metrics | Install and configure the CloudWatch agent with a metrics config including disk |
| `put-metric-alarm` fails: AccessDenied | IAM permissions missing for `cloudwatch:PutMetricAlarm`/`sns:*` | Add appropriate least-privilege permissions (Lesson 15) |

### Redaction check ✅

Replace instance IDs, SNS topic ARNs (contain account ID), and your email
address with placeholders in committed docs.

---

## Step 6 — Quiz (Interview-Style, Graded)

**Q1.** What metrics does EC2 report to CloudWatch **by default**, and what's
missing that requires the CloudWatch agent? Why do you think AWS designed it
this way?

> **Your answer:**

**Q2.** **Scenario:** Your CPU alarm fires every few minutes throughout the day
for brief spikes that don't actually indicate a problem — your team is
ignoring alerts now ("alert fatigue"). What two changes to the alarm
configuration would you make, and why?

> **Your answer:**

**Q3.** Explain the relationship between a CloudWatch **alarm** and an **SNS
topic**. What happens if you create an alarm with an alarm action pointing to
an SNS topic with no confirmed subscriptions?

> **Your answer:**

**Q4.** How does this lesson's disk-usage alarm relate to Lesson 07's
`disk_report.sh check_high_usage_alert()`? What's the same, and what's
different about how you find out?

> **Your answer:**

**Q5.** What is a composite alarm, and give an example of when you'd use one to
reduce false positives.

> **Your answer:**

**Q6.** What's the risk of configuring **auto-remediation** (e.g.,
auto-restart a service) on an alarm, and how would you decide which alarms are
safe to auto-remediate vs. alert-only?

> **Your answer:**

---

## Step 7 — Reflection

*(Fill in after the quiz)*

- What did you learn?
- What confused you?
- What would you do differently?

---

## Step 8 — Search Keywords For Further Understanding

**Core**
- `cloudwatch metrics alarms sns explained`
- `cloudwatch agent custom metrics disk memory`
- `cloudwatch alarm evaluation periods best practices`
- `composite alarms cloudwatch`

**Tools**
- `aws cloudwatch put-metric-alarm cli examples`
- `aws sns subscribe email cli`
- `cloudwatch logs tail follow`

**Going further (future lessons)**
- `prometheus grafana vs cloudwatch`
- `aws ssm automation auto remediation`
- `cloudwatch logs insights queries`

---

## Lesson Status

- [ ] Hands-on task completed (Step 4)
- [ ] Verification passed (Step 5)
- [ ] Quiz answered + professional-answer comparisons requested (Step 6)
- [ ] Reflection completed (Step 7)
- [ ] Search Keywords reviewed (Step 8)

When complete, run the Update Protocol, then move to **Lesson 19 — Log
Analysis & Incident Response Runbook**.

---

*Lesson 18 written by Navi v28 · 2026-06-11 · WebSearch sources:
[oneuptime AWS CloudWatch Alerting Best Practices](https://oneuptime.com/blog/post/2026-02-13-aws-cloudwatch-alerting-best-practices/view),
[drdroid CloudWatch Alerting Guide](https://drdroid.io/engineering-tools/guide-for-cloudwatch-alerting-best-practices-and-implementation),
[AWS CloudWatch Recommended Alarms](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Best_Practice_Recommended_Alarms_AWS_Services.html),
[AWS CloudWatch Alarms Documentation](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/AlarmThatSendsEmail.html)*
