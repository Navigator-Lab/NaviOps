# Lesson 19 — Log Analysis & Incident Response Runbook

**Status:** ready for self-study · **Date written:** 2026-06-11
**Gate Rule:** Concept → Real-World Use → Alternatives → Hands-On → Verification → Quiz → Reflection → Search Keywords

> **How to use this lesson:** same as Lessons 03–18. This lesson is a
> **synthesis** lesson — it ties together `journalctl` (05), `auditd` (10),
> CloudWatch Logs (18), and grep/awk text processing into a structured
> incident-response process.

---

## Step 1 — Concept

### What it is

**Log analysis** is the practice of extracting meaningful patterns (errors,
failure signatures, anomalies) from logs to diagnose problems. An **incident
response runbook** is a version-controlled, scenario-specific guide that walks
a responder through: **detection → triage → containment → eradication →
recovery → verification → postmortem**.

### Why it exists

When something breaks at 2am, you don't want to be inventing your
troubleshooting process from scratch under pressure. A runbook captures
**institutional knowledge** — "we've seen this failure before, here's exactly
what to check and in what order" — turning a stressful, error-prone scramble
into a calm, repeatable checklist. **Blameless postmortems** exist because
punishing people for incidents teaches them to hide problems — the goal is
fixing the **system** that allowed the incident, not finding someone to blame.

### What problem it solves

| Problem | Solution |
|---|---|
| "Service X is down — where do I even start?" | A runbook with a decision tree for this exact scenario |
| "I fixed it, but I don't remember the exact commands I used last time" | Runbooks are documented, version-controlled, repeatable |
| "We keep having the same incident every few months" | Postmortems identify root causes and produce action items |
| "Logs from 5 different sources — where's the actual error?" | Systematic log analysis: find the **failure signature** first |

### Three-Level Depth (Lens A)

- **Level 1 — Beginner:** `grep -i error /var/log/syslog`,
  `journalctl -u myapp --since '1 hour ago' | grep -i error` — find error
  messages in logs. `awk '{print $1}'` extracts fields (e.g., timestamps, IPs)
  for counting/summarizing.
- **Level 2 — SysAdmin:** Per [Rootly's incident response runbook
  guide](https://rootly.com/incident-response/runbooks) and
  [uptimelabs' runbook best practices](https://uptimelabs.io/learn/what-is-an-incident-response-runbook/):
  effective runbooks use **decision trees and checklists, not prose** — "IF
  symptom X, CHECK Y, IF Y shows Z, DO action A." The incident lifecycle:
  **Detection** (alert fires — Lesson 18), **Triage** (how bad, who's
  affected, page who?), **Containment** (stop the bleeding — e.g., roll back a
  deploy, block an IP), **Eradication** (fix the root cause), **Recovery**
  (restore normal service), **Verification** (confirm it's actually fixed —
  Lesson 17's "test your backups" mindset applied to fixes), **Postmortem**
  (blameless write-up: timeline, root cause, action items). When analyzing
  logs across multiple sources (app logs, `journalctl`, `auditd`, CloudWatch
  Logs), the systematic approach is: **find the failure signature first**
  (the repeating error/exit code/status pattern), then work backward in time
  from there to find the triggering event.
- **Level 3 — Systems/Kernel (Lens D):** Many real incidents trace back to
  concepts from earlier lessons at the kernel/systems level: **OOM kills**
  (Lesson 11/12 — `dmesg | grep -i "killed process"`, the kernel's OOM-killer
  terminates a process when memory pressure is critical — `docker inspect`
  shows `OOMKilled: true`), **zombie processes** (Lesson 04 — accumulating
  zombies can exhaust the process table), **disk full** (Lesson 06/07 — a
  process can't write logs/data, often cascades into other failures),
  **file descriptor exhaustion** (`lsof | wc -l` vs. `ulimit -n` — a process
  leaking file descriptors eventually can't open new connections/files). A
  "5 Whys" root-cause analysis for "the website went down" might trace:
  service crashed → OOM killed → memory leak in app → introduced in last
  deploy → no memory limit was set on the container (Lesson 11's `--memory`
  flag) → **action item**: set resource limits AND add a memory-usage alarm
  (Lesson 18).

### Analogy (Lens B)

- **Runbook** = a pilot's pre-flight/emergency checklist — when an engine
  warning light comes on, pilots don't brainstorm from scratch; they follow a
  printed checklist developed from analyzing **previous incidents**, executed
  calmly under pressure.
- **Failure signature** = a doctor looking for the specific symptom pattern
  that narrows down a diagnosis from "patient feels unwell" (vague) to "this
  specific combination of symptoms matches condition X" (specific) — before
  prescribing treatment.
- **Blameless postmortem** = an aviation accident investigation: the goal is
  "what sequence of system/process failures allowed this, and how do we
  prevent recurrence" — not "whose fault was it" (which causes people to hide
  near-misses, making the system as a whole less safe).
- **5 Whys** = peeling an onion — "why did the site go down?" → "the app
  crashed" → "why?" → "out of memory" → "why?" → "memory leak in v2.3" →
  "why?" → "new caching code doesn't expire entries" → "why wasn't this
  caught?" → "no memory alarm, no load testing in CI" — each layer reveals a
  **process** gap, not just a code bug.

The pilot-checklist analogy holds well but breaks down for **postmortem action
item tracking** — a pilot's checklist doesn't have an equivalent of "and now
file 3 follow-up tickets to prevent this exact scenario, with owners and
deadlines, tracked until closed."

---

## Step 2 — Real-World Use

### How SysAdmins use this daily

```bash
# Find error patterns across logs
journalctl -u myapp --since '1 hour ago' -p err

# Find the failure signature - count occurrences of each error type
journalctl -u myapp --since '1 hour ago' | grep -i error | awk -F: '{print $NF}' | sort | uniq -c | sort -rn

# Check for OOM kills (Lesson 11/12 connection)
dmesg | grep -i "killed process"
journalctl -k | grep -i "out of memory"

# Check auditd for security-relevant events around the incident time (Lesson 10)
ausearch -ts today -te now

# CloudWatch Logs Insights query (Lesson 18)
aws logs start-query --log-group-name /naviops/app \
  --start-time <epoch> --end-time <epoch> \
  --query-string 'fields @timestamp, @message | filter @message like /ERROR/ | sort @timestamp desc | limit 50'
```

**Real production scenarios:**
1. **"The site is down" page at 2am** — runbook: check CloudWatch alarm that
   fired (18) → SSH in → `systemctl status` (05) → `journalctl -u <service> -p
   err --since '15 min ago'` → identify failure signature → containment
   (restart service / rollback) → verify (curl health endpoint) → postmortem
   the next day.
2. **Recurring incident pattern** — three incidents in a month all show the
   same `OOMKilled` signature → 5 Whys → action item: add `--memory` limit
   (Lesson 11) + CloudWatch memory alarm (Lesson 18).
3. **Security incident** — unusual `auditd` entries on `/etc/passwd` (Lesson
   10) found during a routine log review → containment (isolate host, rotate
   credentials) → eradication → postmortem feeds into Lesson 23 (security
   monitoring).

### Common mistakes

| Mistake | Impact | Fix |
|---|---|---|
| Jumping to fixes before finding the failure signature | Fix the wrong thing, incident continues or recurs | Find the repeating error pattern first, then trace backward |
| No runbook — improvising every incident | Slow, inconsistent response; tribal knowledge lost when people leave | Write runbooks for your top recurring scenarios |
| Blame-focused postmortems | People hide mistakes/near-misses → less visibility into real risk | Blameless: focus on system/process gaps, not individuals |
| Postmortem with no action items / no follow-up | Same incident recurs | Every postmortem produces tracked action items with owners |
| Treating "service is back up" as "done" | Root cause not fixed — recurs later | Verification step must address root cause, not just symptom |

### When NOT to over-process

- Not every blip needs a full postmortem — reserve them for incidents with
  real impact (per your team's severity definitions) or **recurring** minor
  issues (the 3rd time the same thing happens, write it up).

### Interview Angle

**Scenario:** "A service is crash-looping. `journalctl -u <service>` is
scrolling hundreds of lines a minute. Walk me through what you do in the first
five minutes."

A junior answer starts reading from the top of the log, scrolling endlessly,
hoping to spot "the" error — slow and easy to miss the actual signature in the
noise. A senior answer goes straight to finding the **failure signature**:
`journalctl -u <service> -p err --since '15 min ago' | grep -i error | awk
-F: '{print $NF}' | sort | uniq -c | sort -rn` to surface the most frequent
repeating error, then checks `dmesg | grep -i "killed process"` for OOM kills
(a very common crash-loop cause) before touching the service itself. Only
after identifying the signature do they decide on containment (`systemctl
stop` to break the loop) — fixing blind, before you know the pattern, risks
fixing the wrong thing while the incident continues.

---

## Step 3 — Alternatives

| Topic | Alternative | Note |
|---|---|---|
| Manual `grep`/`awk`/`journalctl` (this lesson) | **Centralized log platforms** (ELK, Loki, CloudWatch Logs Insights, Lesson 22) | Manual tools are foundational and always available; centralized platforms scale across many hosts |
| Markdown runbooks in git | **Runbook automation platforms** (incident.io, Rootly, PagerDuty) | Per [incident.io's 2026 guide](https://incident.io/blog/runbook-automation-tools-2026-the-complete-guide), modern platforms add human-in-the-loop automation and auto-generated timelines — markdown runbooks in git are the right starting point and remain valuable even alongside tooling |
| 5 Whys | **Fishbone (Ishikawa) diagrams**, fault tree analysis | 5 Whys is simplest and sufficient for most junior-level incidents; other techniques for more complex multi-factor incidents |

---

## Step 4 — Hands-On Task (build this yourself)

> ▶ **Do this on the lab**: start the environment first — `./infra/bootstrap.sh up` (once: `pull`), then
> `docker exec -it naviops-web bash`. **Node:** naviops-web + monitoring stack. **Artifact:** read Grafana/Nagios; build `scripts/alert_triage.sh`.
> Reference solution (after you try): `docs/learning/reference-solutions/` (gitignored answer key).

**Goal:** Write `docs/runbooks/service-down.md` — a runbook for "a NaviOps
service/script is failing" — and practice a simulated incident + blameless
postmortem.

### Lens C — Manual → Automated → Why

**Manual:** every incident, you re-derive "what should I check first?" from
scratch.

**"Automated" (the runbook itself, `docs/runbooks/service-down.md`):**
```markdown
# Runbook: Service Down / Failing

## Detection
- CloudWatch alarm fired (Lesson 18) OR `systemctl status <service>` shows failed (Lesson 05)

## Triage
1. `systemctl status <service>` - is it failed, or crash-looping?
2. `journalctl -u <service> -p err --since '15 min ago'` - find the failure signature
3. Check resource exhaustion:
   - `dmesg | grep -i "killed process"` (OOM)
   - `df -h` (disk full, Lesson 07)
   - `free -h` (memory)

## Containment
- If crash-looping: `systemctl stop <service>` to stop the loop while you investigate
- If disk full: clear space per Lesson 06/07 (don't delete logs needed for the postmortem!)

## Eradication / Recovery
- Apply the fix matching the failure signature (see "Known Failure Signatures" below)
- `systemctl start <service>`
- Verify: `systemctl status`, `curl <health-endpoint>`, `journalctl -f` for a few minutes

## Known Failure Signatures
| Signature | Likely Cause | Fix |
|---|---|---|
| `OOMKilled` / dmesg "Killed process" | Memory limit exceeded | Increase limit or fix leak; add CloudWatch memory alarm |
| `Permission denied` on startup | File ownership/permissions changed | `chown`/`chmod` per Lesson 04 |
| `bind: address already in use` | Port conflict / previous instance still running | `ss -tlnp` (Lesson 08) to find the conflicting process |

## Postmortem template
- **Timeline**: when detected, when contained, when resolved
- **Root cause**: (5 Whys)
- **Impact**: what was affected, for how long
- **Action items**: (owner, deadline) - what prevents recurrence
```

**Why this matters:** per [Rootly's runbook guide](https://rootly.com/incident-response/runbooks),
this format (decision tree + known-signatures table) is exactly what real SRE
teams maintain — and writing one **forces you to consolidate everything you've
learned in Lessons 04-18** into an actionable reference.

### What to build, step by step

1. Write `docs/runbooks/service-down.md` per the structure above, tailored to
   one of your actual `/scripts` or systemd services from earlier lessons.
2. **Simulate an incident**: deliberately break something (e.g., `chmod 000`
   a script your systemd service needs, or fill `/tmp` to trigger a disk-based
   failure) on your lab VM.
3. Follow your own runbook to detect, triage, contain, and recover — note
   where the runbook was helpful and where it was missing a step.
4. Write a blameless postmortem in `docs/runbooks/postmortems/2026-06-11-simulated-incident.md`
   using the template — include your "5 Whys" and at least one action item.
5. Update `docs/runbooks/service-down.md` based on what you learned (this is
   the real-world "runbooks evolve from incidents" loop).
6. Commit on `lesson/19-log-analysis-incident-response`.

---

## Step 5 — Verification

```bash
# Confirm the runbook's commands actually work on your system
systemctl status <service>
journalctl -u <service> -p err --since '15 min ago'
dmesg | grep -i "killed process" || echo "no OOM kills found"
df -h
free -h

# Confirm the simulated incident and recovery
# (re-run the break -> detect -> fix -> verify cycle once more, timing yourself)
```

### Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| `journalctl -p err` shows nothing but service is clearly broken | Error logged at a different priority level, or to a different log entirely (app-specific log file) | Check `journalctl` without `-p` filter, and any app-specific log paths |
| Can't reproduce the simulated incident | Fix was already applied / state reverted unexpectedly | Re-verify the "break" step actually took effect before troubleshooting |
| Postmortem "5 Whys" stops too early (e.g., "why? - a bug" with no further whys) | Surface-level analysis | Keep asking "why did THAT happen" until you reach a process/systemic factor |

### Redaction check ✅

Runbooks/postmortems should use placeholder hostnames/IPs if they reference
your specific lab environment.

---

## Step 6 — Quiz (Interview-Style, Graded)

**Q1.** Walk through the incident lifecycle stages (detection → ... →
postmortem). What's the difference between "containment" and "eradication"?

> **Your answer:**

**Q2.** **Scenario:** A service is crash-looping. `journalctl -u <service>`
shows hundreds of lines. How do you efficiently find the actual failure
signature instead of reading every line?

> **Your answer:**

**Q3.** Why are postmortems "blameless"? What's the risk of a blame-focused
postmortem culture, concretely?

> **Your answer:**

**Q4.** Perform a "5 Whys" for this scenario: "A cron job (Lesson 06) that
backs up the database failed last night, and no one noticed until this
morning." Write out at least 4 "whys" and at least one action item.

> **Your answer:**

**Q5.** How does Lesson 18's CloudWatch alarm relate to the "Detection" stage
of the incident lifecycle? What would detection look like *without* it?

> **Your answer:**

**Q6.** Why should a runbook be a **decision tree/checklist** rather than
prose? Give a concrete example from your `service-down.md`.

> **Your answer:**

---

## Step 7 — Reflection

*(Fill in after the quiz)*

- What did you learn?
- What confused you?
- What would you do differently?

---

## NOC Angle

> NOC Technician focus (Stage 1, `ROADMAP.md`).

Incident handling, **documentation, and escalation** are exactly what NOC interviews probe. Learn the ticketing flow (**ServiceNow/Remedy**), a **severity classification** rubric (Sev1–Sev4), and clean **shift-handover notes** so the next analyst resumes with zero re-explanation — the same 'zero re-explanation' discipline NaviOps' `docs/` uses. This is your strongest NOC-hiring evidence.

## Lens E — Attacker & Defender (Red / Blue)

> Red/Blue framing (Gate Rule **Lens E**, D14). Build *both* mindsets: know how the
> tools in this lesson are abused, and how a defender detects and stops them.
> Frameworks: [GTFOBins](https://gtfobins.github.io/) · [MITRE ATT&CK](https://attack.mitre.org/) · [LOLBAS](https://lolbas-project.github.io/).

**🔴 Attacker (how it's abused — Step 2):** This lesson *is* detection, so know the evasion: attackers clear/`>` logs, timestomp, inject misleading entries, and live-off-the-land to blend with normal admin activity. ATT&CK **T1070** (Indicator Removal), **T1027** (Obfuscation). Recognize the attacks in the logs: `Failed password` bursts (brute force), many ports from one IP (scan), new SUID, odd `sudo`.

**🔵 Defender (detect & harden — Step 5):** Hunt with `grep`/`awk`: failed SSH (`grep 'Failed password' /var/log/auth.log | awk '{print $11}' | sort | uniq -c | sort -rn`), brute force (repeat sources), port scans. **Centralize + make logs immutable**, then run the IR lifecycle (detect → contain → eradicate → recover → report) and map observed TTPs to ATT&CK.

## Step 8 — Search Keywords For Further Understanding

**Core**
- `incident response runbook template sysadmin`
- `blameless postmortem 5 whys root cause analysis`
- `journalctl grep awk log analysis failure signature`
- `oom killer dmesg troubleshooting`

**Tools**
- `cloudwatch logs insights query examples`
- `auditd ausearch incident investigation`
- `mtr traceroute network incident diagnosis`

**Going further (future lessons)**
- `prometheus alertmanager runbook links`
- `wazuh siem incident detection`
- `aws systems manager automation runbook`

---

**Red / Blue (Lens E — study attacker & defender in parallel):**
- 🔴 **Red (attacker):** `clear logs anti-forensics`, `MITRE ATT&CK T1070 indicator removal`, `timestomp linux timestamps`, `living off the land detection evasion`
- 🔵 **Blue (defender):** `failed ssh detection grep awk`, `brute force log analysis auth.log`, `immutable centralized logging`, `incident response lifecycle`

## Lesson Status

- [ ] Hands-on task completed (Step 4)
- [ ] Verification passed (Step 5)
- [ ] Quiz answered + professional-answer comparisons requested (Step 6)
- [ ] Reflection completed (Step 7)
- [ ] Search Keywords reviewed (Step 8)

When complete, run the Update Protocol, then move to **Lesson 20 — Terraform
Fundamentals**.

---

*Lesson 19 written by Navi v28 · 2026-06-11 · WebSearch sources:
[Rootly Incident Response Runbooks Guide](https://rootly.com/incident-response/runbooks),
[uptimelabs Incident Response Runbook Best Practices](https://uptimelabs.io/learn/what-is-an-incident-response-runbook/),
[incident.io Runbook Automation Tools 2026](https://incident.io/blog/runbook-automation-tools-2026-the-complete-guide),
[Sajja Sudhakararao Incident Response Runbook Template for DevOps](https://medium.com/@sajjasudhakarrao/incident-response-runbook-template-for-devops-a-calm-workflow-that-reduces-mttr-e6f44e26398c)*
