# Lesson 23 — Security Monitoring & Threat Detection (Wazuh)

**Status:** ready for self-study · **Date written:** 2026-06-11
**Gate Rule:** Concept → Real-World Use → Alternatives → Hands-On → Verification → Quiz → Reflection → Search Keywords

> **How to use this lesson:** same as Lessons 03–22. This lesson **centralizes
> and extends Lesson 10's `auditd`/AIDE** (per-host security tooling) into a
> fleet-wide SIEM, the security-monitoring parallel to Lesson 22's
> Prometheus/Grafana (metrics) — same centralization idea, applied to security
> events.

---

## Step 1 — Concept

### What it is

**SIEM (Security Information and Event Management)** centralizes security
logs/events from many hosts, correlates them against detection rules, and
surfaces alerts. **Wazuh** is an open-source SIEM/XDR (Extended Detection and
Response) platform combining: **HIDS** (host-based intrusion detection —
analyzes logs/processes for suspicious activity), **FIM** (File Integrity
Monitoring — alerts on changes to critical files), **vulnerability detection**
(scans installed packages for known CVEs), and **SCA** (Security
Configuration Assessment — checks hosts against hardening baselines, like
Lesson 10's CIS-benchmark-style checks, but automated/continuous).

### Why it exists

Lesson 10 gave you `auditd` (logs security-relevant kernel events on **one**
host) and AIDE (file-integrity checks on **one** host, run manually/via cron).
At fleet scale, you need: events from **all** hosts in **one place**
(Lesson 22's centralization argument, applied to security logs), **automated
correlation** (one failed SSH login isn't an alert; 50 in a minute from
different usernames is a brute-force attempt), and **continuous** baseline
checking (not "run AIDE when you remember").

### What problem it solves

| Problem | Solution |
|---|---|
| "Someone's brute-forcing SSH on one of my servers — how would I know?" | Wazuh HIDS rule: N failed logins in M minutes → alert |
| "A critical config file (`/etc/passwd`, `/etc/ssh/sshd_config`) was modified — by what/whom?" | Wazuh FIM (extends Lesson 10's AIDE, continuously, with attribution) |
| "Is any installed package on my fleet vulnerable to a known CVE?" | Wazuh vulnerability detection module |
| "Are all my hosts still meeting the hardening baseline from Lesson 10?" | Wazuh SCA — continuous compliance checking |
| "I have auditd logs on 5 servers — where do I even look during an incident?" | Wazuh centralizes + correlates — directly feeds Lesson 19's "Detection" stage |

### Three-Level Depth (Lens A)

- **Level 1 — Beginner:** Wazuh has a **manager** (central server — receives
  events, applies rules, stores alerts, provides a dashboard) and **agents**
  (lightweight processes installed on each monitored host, sending logs/
  events to the manager). The Wazuh dashboard shows alerts, grouped by
  severity, host, and rule.
- **Level 2 — SysAdmin:** Per [Wazuh's official platform
  overview](https://wazuh.com/platform/overview/) and [Sadashiv Pole's
  complete Wazuh guide](https://medium.com/@sadashivpole/wazuh-complete-guide-to-hids-siem-and-enterprise-threat-detection-120d376bfbc0):
  **FIM** monitors specified directories (e.g., `/etc`, `/usr/bin`) and
  alerts on content/permission/ownership/attribute changes — and (unlike bare
  AIDE) attributes the change to a **user/process** where possible — directly
  extending Lesson 10's AIDE concept with **who did it**, in near-real-time
  rather than "next scheduled AIDE run." **SCA** runs policy checks (often
  CIS-benchmark-based) against each agent continuously, producing a
  pass/fail score per host — this *is* Lesson 10's `hardening_audit.sh`
  concept, but vendor-maintained, continuously scheduled, and centrally
  reported across the fleet. Wazuh's **ruleset** correlates raw events into
  alerts with severity levels — e.g., "5 failed SSH logins from the same IP
  within 10 minutes" → a single brute-force alert (vs. 5 separate raw log
  lines you'd have to notice yourself in `journalctl`/`auditd`, Lesson 19's
  "find the failure signature" made automatic).
- **Level 3 — Systems/Kernel (Lens D):** The Wazuh **agent** on Linux ingests
  the **same underlying data sources** you've already worked with directly:
  `auditd` events (Lesson 10 — kernel audit subsystem via netlink), syslog/
  `journald` (Lesson 05), and the filesystem itself (FIM uses inotify or
  periodic scanning, similar to AIDE's checksum-database approach from Lesson
  10). Architecturally, Wazuh's agent→manager pattern is the **security
  analog of Lesson 22's Node Exporter→Prometheus** (an agent exposes/ships
  data, a central server collects/correlates/alerts) — but **push**-based
  (agents send to the manager) rather than Prometheus's pull model, because
  security events are inherently event-driven (you can't "poll" for "did a
  brute-force attempt happen since I last asked" as cleanly as polling a
  gauge).

### Analogy (Lens B)

- **Wazuh manager + agents** = a building's central security office (manager)
  receiving live feeds from cameras/sensors in every room (agents) — instead
  of a guard in each room writing in their own private logbook (Lesson 10's
  per-host `auditd`/AIDE) that no one reviews unless something already went
  wrong.
- **FIM** = a sensor on a display case in a museum — if the case is opened or
  the item moved (file changed), it alerts immediately and (with badge-reader
  integration) records *who* opened it — vs. AIDE's "compare today's
  inventory checklist to yesterday's" (detects the change, but only when you
  run the check, with less attribution).
- **Correlation rules (brute-force detection)** = the security office noticing
  "the same person's badge was rejected at this door 50 times in 2 minutes" —
  a single rejected badge swipe is normal (someone fumbled their card); 50 in
  2 minutes is an attack — the **pattern**, not any single event, is the
  signal.
- **SCA** = a continuous fire-marshal inspection running automatically every
  day across every room, instead of a one-time inspection when the building
  opened (Lesson 10's one-off `hardening_audit.sh` run).

The "central security office" analogy holds well but breaks down for
**vulnerability detection** (CVE scanning) — there's no clean physical
analog for "this brand of door lock (software package/version) has a known
manufacturing defect (CVE) that criminals know how to exploit, here's the
list of every door in the building using that lock model."

---

## Step 2 — Real-World Use

### How SysAdmins use this daily

```bash
# On the Wazuh manager
sudo systemctl status wazuh-manager
sudo /var/ossec/bin/agent_control -l         # list connected agents

# On an agent host
sudo systemctl status wazuh-agent
sudo /var/ossec/bin/agent-auth -m <MANAGER_IP>   # register agent with manager

# Query alerts (via API or dashboard)
curl -k -u <user>:<pass> "https://<MANAGER_IP>:55000/security/user/authenticate"
```

**Real production scenarios:**
1. **SSH brute-force detection** — Wazuh's default ruleset already includes
   rules for repeated authentication failures; an alert fires automatically —
   directly feeding Lesson 19's "Detection" stage without a human noticing log
   lines first.
2. **Unauthorized config change** — FIM alerts when `/etc/sudoers` or
   `/etc/ssh/sshd_config` changes outside a known maintenance window — the
   alert includes which user/process made the change.
3. **Continuous compliance** — SCA dashboard shows "Server X: 92% compliant
   with CIS benchmark, failing checks: <list>" — turns Lesson 10's one-time
   `hardening_audit.sh` into an ongoing score you track over time.

### Common mistakes

| Mistake | Impact | Fix |
|---|---|---|
| Deploying Wazuh with default rules and never tuning | Alert fatigue from noisy default rules (same lesson as Lesson 18/22's alert-fatigue theme) | Tune/disable rules that don't apply to your environment; adjust thresholds |
| FIM monitoring too broad a scope (e.g., entire `/`) | Massive alert volume, performance overhead, hard to find signal | Scope FIM to genuinely critical paths (`/etc`, `/usr/bin`, `/usr/sbin`, application configs) |
| No one reviews the Wazuh dashboard | Same as Lesson 19 Q5's "detection without anyone watching" — alerts fire into the void | Integrate with Lesson 19's runbook — Wazuh alerts should trigger the incident-response process |
| Treating SCA failures as "fix later" indefinitely | Hardening drifts over time; the continuous-compliance benefit is wasted | Track SCA score over time; treat regressions as action items (Lesson 19's postmortem pattern) |
| Running Wazuh manager on the same host it's protecting | If that host is compromised, the SIEM itself is compromised | Run the manager on a separate, more tightly controlled host |

### When NOT to over-engineer

- For a single learning lab (1-2 VMs), a single Wazuh manager + 1-2 agents is
  plenty to learn FIM/SCA/HIDS concepts — multi-manager clustering and
  high-availability Wazuh deployments are enterprise-scale concerns beyond
  this lesson's scope.

### Interview Angle

**Scenario:** "We deployed Wazuh six months ago with the default ruleset.
The dashboard now shows 800+ alerts per day and the on-call team has
stopped looking at it. How would you fix this?"

A junior answer focuses on the surface fix — "turn off some rules" or "add
more people to watch the dashboard." A senior answer recognizes this as
**alert fatigue** (the same failure mode as un-tuned CloudWatch alarms or
PromQL alerts without a `for` duration) and treats it as a tuning problem,
not a staffing problem: triage which rule IDs generate the bulk of volume,
determine if they're false positives or genuinely low-severity noise for
this environment, and either disable/adjust thresholds for rules that don't
apply (e.g., FIM on a path that legitimately changes often) or re-route
low-severity alerts to a non-paging channel. Critically, a senior candidate
ties this back to FIM scope discipline — alerting on all of `/` instead of
`/etc` and `/usr/bin` is a common root cause — and connects unreviewed
alerts to Lesson 19's "detection without response" failure mode.

---

## Step 3 — Alternatives

| Topic | Alternative | Note |
|---|---|---|
| Wazuh (this lesson) | ELK/Elastic Security, Splunk, OSSEC (Wazuh's origin) | Wazuh is a fork/successor of OSSEC with a modern stack; Elastic Security and Splunk are common enterprise alternatives (Splunk is commercial/expensive) |
| Wazuh FIM | Bare AIDE (Lesson 10) | AIDE remains valuable for a single host or as a lightweight check; Wazuh FIM is the centralized, attributed, continuous version |
| Self-hosted Wazuh manager | Wazuh Cloud (managed) | Self-hosting is the learning path here; managed offerings remove operational overhead at a cost |

---

## Step 4 — Hands-On Task (build this yourself)

**Goal:** Deploy a Wazuh manager (single-node, via the official Docker
Compose or installation script) and one Wazuh agent on your lab VM; configure
FIM on critical paths, and trigger + observe a brute-force detection alert.

### Lens C — Manual → Automated → Why

**Manual (Lesson 10):** `aide --check` run manually/via cron — you only see
results in a log file on that one host, with no attribution and no
correlation across hosts.

**Automated (Wazuh FIM, conceptual `ossec.conf` snippet on the agent):**
```xml
<ossec_config>
  <syscheck>
    <directories check_all="yes" realtime="yes">/etc</directories>
    <directories check_all="yes" realtime="yes">/usr/bin,/usr/sbin</directories>
    <frequency>43200</frequency>
  </syscheck>
</ossec_config>
```

**Why this matters:** per [dev.to's Wazuh FIM
walkthrough](https://dev.to/samueladeduntan/file-integrity-monitoring-with-wazuh-siem-tool-5c98)
and [Sathinsha's FIM lab](https://medium.com/@sathinsha/file-integrity-monitoring-using-wazuh-lab-a4f6a48e95cb),
`realtime="yes"` means changes to `/etc` are detected **immediately** (via
inotify) rather than at the next scheduled AIDE run — and the alert in the
Wazuh dashboard shows which file changed, what changed (permissions/content/
ownership), and when — turning Lesson 10's "did something change since
yesterday's AIDE run?" into "something changed 30 seconds ago, here's
exactly what."

### What to build, step by step

1. Deploy a single-node Wazuh stack (manager + indexer + dashboard) — per
   [Wazuh's official docs](https://wazuh.com/), the Docker Compose
   "single-node" deployment is the simplest for a lab. Note resource
   requirements (Wazuh's full stack is heavier than previous lessons' tools —
   document any resource constraints you hit).
2. Install the Wazuh agent on your lab VM, register it with the manager
   (`agent-auth`).
3. Confirm the agent shows "Active" in the Wazuh dashboard.
4. Configure FIM (`syscheck` block in `ossec.conf`) to monitor `/etc` and
   `/usr/bin` with `realtime="yes"`.
5. **Trigger a FIM alert**: as a test, modify a file in `/etc` (e.g., add a
   comment line to `/etc/hosts`) — confirm a FIM alert appears in the
   dashboard within seconds.
6. **Trigger a brute-force alert**: from another host, attempt several SSH
   logins with a wrong password against your lab VM — confirm Wazuh's
   default ruleset generates an authentication-failure alert (and ideally a
   correlated "multiple failures" alert).
7. Review the **SCA** results for your agent — compare against your Lesson
   10 `hardening_audit.sh` findings: do they agree?
8. Document your setup, the FIM/brute-force test results, and SCA findings in
   `docs/security/wazuh-design.md` (redacted IPs/hostnames).
9. Commit configs (no credentials) and the design doc on
   `lesson/23-security-monitoring-threat-detection-wazuh`.

---

## Step 5 — Verification

```bash
# Agent connectivity
sudo /var/ossec/bin/agent_control -l   # agent should show "Active"

# FIM test
echo "# wazuh fim test $(date)" | sudo tee -a /etc/hosts
# Check Wazuh dashboard: Security Events -> filter by rule group "syscheck"
# Should show an alert for /etc/hosts within ~realtime

# Brute-force test (from another host)
for i in {1..6}; do ssh wronguser@<LAB_VM_IP> "exit" 2>/dev/null; done
# Check Wazuh dashboard: Security Events -> filter by rule group "authentication_failures"
```

### Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| Agent shows "Disconnected" / "Never connected" | Agent not registered, or manager unreachable (firewall, Lesson 09/21) | Re-run `agent-auth`; confirm manager port (1514/1515) reachable from agent |
| FIM alert doesn't appear after editing `/etc/hosts` | `realtime="yes"` not set, or `/etc` not in monitored `<directories>` | Confirm `ossec.conf` syscheck block, restart `wazuh-agent` |
| Brute-force alert doesn't fire | Default ruleset threshold not reached, or SSH logs not being read by Wazuh agent (`<localfile>` config) | Confirm agent's `ossec.conf` includes the SSH/auth log source for your distro |
| Wazuh stack won't start / out of memory | Wazuh's full stack (manager+indexer+dashboard) is resource-heavy for small lab VMs | Note this in your reflection — document the minimum viable resources you found, this is a real operational consideration |
| Dashboard login fails | Default credentials not yet changed, or indexer not fully started (takes a few minutes) | Wait for all containers/services healthy; check default credentials per the Wazuh quickstart |

### Redaction check ✅

Wazuh dashboard/API credentials, manager IPs, and agent registration keys
must use placeholders in `docs/security/wazuh-design.md` — never commit real
credentials or registration keys.

---

## Step 6 — Quiz (Interview-Style, Graded)

**Q1.** How does Wazuh's FIM improve on Lesson 10's bare AIDE? Name two
specific improvements.

> **Your answer:**

**Q2.** **Scenario:** Your Wazuh dashboard shows hundreds of low-severity
alerts per day and your team has started ignoring it. What's this called (you
saw this term in Lessons 18/22), and what would you do to fix it?

> **Your answer:**

**Q3.** Explain the difference between a single raw log line ("failed SSH
login from 203.0.113.5") and a Wazuh **correlation rule** alert
("brute-force attempt detected"). Why does the correlation matter more than
the raw event?

> **Your answer:**

**Q4.** How does Wazuh's agent→manager architecture compare to Lesson 22's
Node Exporter→Prometheus architecture? What's architecturally different
(push vs. pull) and why does that difference make sense for security events
vs. metrics?

> **Your answer:**

**Q5.** What is SCA (Security Configuration Assessment), and how does it
relate to Lesson 10's `hardening_audit.sh`? What's the key advantage of SCA
being continuous rather than one-time?

> **Your answer:**

**Q6.** Tie this lesson back to Lesson 19's incident-response runbook: where
in the incident lifecycle (detection → ... → postmortem) do Wazuh alerts fit,
and what would change in your `service-down.md` runbook if Wazuh were
deployed?

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
- `wazuh siem hids fim sca explained`
- `wazuh agent manager architecture`
- `file integrity monitoring vs aide`
- `siem correlation rules brute force detection`

**Tools**
- `wazuh docker single node deployment`
- `ossec.conf syscheck configuration`
- `wazuh agent-auth registration`

**Going further (future lessons)**
- `multi service docker compose security monitoring`
- `siem incident response integration`
- `wazuh terraform deployment automation`

---

## Lesson Status

- [ ] Hands-on task completed (Step 4)
- [ ] Verification passed (Step 5)
- [ ] Quiz answered + professional-answer comparisons requested (Step 6)
- [ ] Reflection completed (Step 7)
- [ ] Search Keywords reviewed (Step 8)

When complete, run the Update Protocol, then move to **Lesson 24 —
Multi-Service Docker Compose + Monitoring**.

---

*Lesson 23 written by Navi v28 · 2026-06-11 · WebSearch sources:
[Wazuh Official Platform Overview](https://wazuh.com/platform/overview/),
[Sadashiv Pole — Wazuh: Complete Guide to HIDS, SIEM, and Enterprise Threat Detection](https://medium.com/@sadashivpole/wazuh-complete-guide-to-hids-siem-and-enterprise-threat-detection-120d376bfbc0),
[dev.to File Integrity Monitoring with Wazuh SIEM Tool](https://dev.to/samueladeduntan/file-integrity-monitoring-with-wazuh-siem-tool-5c98),
[Sathinsha File Integrity Monitoring Using Wazuh — Lab](https://medium.com/@sathinsha/file-integrity-monitoring-using-wazuh-lab-a4f6a48e95cb)*
