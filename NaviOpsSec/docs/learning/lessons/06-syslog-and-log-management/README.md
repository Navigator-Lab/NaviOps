# Lesson 06 — Syslog & Log Management

**Status:** ✅ ready for self-study (full depth) · **Date written:** 2026-06-20
**Schema:** 12-section SOC (`docs/learning/CLAUDE_TEACHING_RULES.md`)
**Focus:** syslog/rsyslog (facilities/severities), centralized logging, forwarding to the SIEM,
and **log integrity & retention** — getting evidence off the box, reliably and intact.
**Primary artifact:** `infra/configs/rsyslog-forward.conf` (a central-forwarding config).

> **How to use this lesson:** read §1–§7, do §8 (forward logs to a central collector, lab),
> produce §9, answer the quiz, reflect. Then Lesson 07.

---

## §1 — Concept (Scientific Theory)

### What it is
**Syslog** is the long-standing standard (RFC 5424) for system logging: each message has a
**facility** (who produced it — `auth`, `cron`, `kern`, `local0`…) and a **severity** (how
important — `emerg`(0) … `debug`(7)). **rsyslog** (the common Linux implementation) routes messages
by facility/severity to files **and** to remote collectors. **Log management** is the discipline of
collecting, centralizing, retaining, and protecting logs so they're usable evidence.

### Why it exists
Logs on the box that's compromised are **not trustworthy** — an attacker with root can edit or
delete them (T1070). Centralized, off-box logging means the evidence survives the host. It also
makes a SIEM possible: you can't correlate across 100 servers if the logs never leave them.

### Three-Level Depth (Lens A)
- **Level 1 — Beginner:** every log message has a category (facility) and an importance (severity).
  rsyslog files them locally and can also send copies to a central log server. Central = safe +
  searchable.
- **Level 2 — Analyst/SOC:** you configure a host to **forward** `auth`/`kern`/app logs to a
  collector (or directly to the Wazuh agent → manager). You set **retention** (how long to keep)
  and protect **integrity** (append-only, restricted access). Central logging is the SIEM's
  ingestion layer.
- **Level 3 — Adversary/Kernel:** rsyslog forwards over UDP/514 (lossy, spoofable) or TCP/TLS
  (reliable, authenticated). Real-time forwarding is the defense against on-box deletion: the
  message is already gone to the collector before the attacker can `rm` the local file. A **gap**
  in the central stream (host stopped sending) is itself a detection (T1562).

### Two Teaching Approaches (Lens B) — central logging
**Approach 1 (technical):** rsyslog uses rulesets (`facility.severity → action`); actions can be a
file, a remote target (`@host` UDP / `@@host` TCP), or a queue. Centralization + TLS + disk-assisted
queues give reliable, tamper-resistant delivery.

**Approach 2 (analogy):** a bank's cameras don't store footage *only* in the branch — they stream to
a **central vault** in real time. Rob the branch, the footage is already safe off-site. **Where it
breaks down:** if the link is UDP (no guarantee) some "frames" can drop — which is why TCP/TLS +
queuing matters for evidence you'll rely on.

### Visual (ASCII) — central logging pipeline
```
  host01 ─auth,kern,app─►(rsyslog)─@@TLS─┐
  host02 ────────────────►(rsyslog)──────┼─► central collector / Wazuh manager ─► SIEM
  host03 ────────────────►(rsyslog)──────┘        │ retention + integrity (append-only)
                                                   ▼
                                          gap in stream from a host = ALERT (log tampering)
```

---

## §2 — Linux Investigation Commands

```bash
logger -p auth.warning "test message"        # inject a syslog message (test routing)
systemctl status rsyslog                      # is the logger running?
cat /etc/rsyslog.conf /etc/rsyslog.d/*.conf   # rulesets + forwarding config
ss -ulnp | grep 514 ; ss -tlnp | grep 514     # is syslog listening (collector side)?
journalctl -u rsyslog -S -1h                  # rsyslog's own health/errors
grep -c . /var/log/auth.log                    # quick volume check (gap = suspicious)
tcpdump -ni any port 514                       # (lab) watch syslog traffic on the wire
```
| Linux | SIEM equivalent |
|---|---|
| rsyslog forward to collector | Wazuh agent → manager log shipping |
| facility/severity routing | SIEM source/index routing |
| `logger` test | a synthetic log to validate the pipeline |

---

## §3 — Real-World Threat Context & Use Cases

- **Survive host compromise:** forwarded logs are the evidence that an attacker can't delete — the
  reason central logging is non-negotiable in a SOC.
- **Enable correlation:** lateral movement (one credential across many hosts) is only visible when
  all hosts' logs land in one place (Lesson 35).
- **Compliance/retention:** many frameworks require N months of retained logs; log management is
  where that's enforced.
- **Exam framing:** syslog facilities/severities, centralized logging, and log retention/integrity
  appear on Security+/CySA+/BTL1.

---

## §4 — Detection

- **The "logs stopped" detection:** monitor each host's inbound log rate at the collector; a host
  that goes silent (and isn't in maintenance) = possible tampering/compromise (T1562/T1070). This
  is one of the highest-value, lowest-effort SOC detections.
- **Volume anomalies:** a sudden spike (brute force, scan) or drop (truncation) is a signal.
- **Integrity:** logs written append-only to restricted, off-box storage; FIM on the log directory
  (Lesson 24) catches truncation.

---

## §5 — Investigation & Triage

When a host's central logs go quiet, triage: maintenance? network? service crash? or tampering?
Cross-check the host's last-seen, the agent health, and any FIM/audit events. When investigating a
known-compromised host, **trust the central copy over the local file** — the local one may be
altered.

---

## §6 — SOC Perspective

Central logging *is* the SOC's input pipeline; its health is a first-class dashboard ("agents
reporting", "events/sec per source"). A silent source is treated as an incident, not an oversight
(`soc/soc-scenarios.md` #7). Retention settings determine how far back an investigation can reach.

---

## §7 — Incident-Response Perspective

In IR, the central log store is your **evidence of record** (`templates/evidence-package.md`) —
collected, hashed, and trusted because it's off the compromised host. Phase-2 evidence collection
leans on it; Phase-6 lessons-learned often adds the "logs stopped" detection if a gap was missed.

---

## §8 — Practical Lab (build this yourself)

**Goal:** forward a host's logs to a central collector and prove deletion-resistance.

### Lens C — Manual → Automated → Why
- **Manual:** read a log locally.
- **Automated:** rsyslog *continuously* ships it off-box the moment it's written.
- **Why:** automation here is the security control — there's no "remember to copy logs" during an
  incident; they're already safe. Production uses TLS + queues for reliability.

### Steps
1. Set up a collector (lab): a second VM running rsyslog listening on TCP/514 (or use your Wazuh
   manager). Restrict access (firewall to the lab subnet).
2. Write `infra/configs/rsyslog-forward.conf` on the sender (sanitized):
   ```
   # forward auth + all to the lab collector over TCP
   auth,authpriv.*   @@10.0.0.10:514
   *.*               @@10.0.0.10:514
   ```
   Place in `/etc/rsyslog.d/`, restart rsyslog.
3. Test: `logger -p auth.warning "lab test from $(hostname)"` → confirm it appears on the collector.
4. **Prove the point (drill 9):** generate a log event locally, confirm it's on the collector, then
   `: > /var/log/test.log` (truncate locally) — the collector still has it. That's tamper
   resistance, demonstrated.
5. Note how you'd detect the truncation (FIM on the log dir / gap detection at the collector).

### Lens D — the raw artifact
```
<86>1 2026-06-20T02:14:07Z web01 sshd 8123 - - Failed password for admin from 10.0.0.99
# <86> = PRI = facility*8 + severity (auth=10, warning=4 → 10*8+4? note: PRI encodes both).
# Structured syslog (RFC 5424): version, timestamp, host, app, pid — clean fields for the SIEM.
```

---

## §9 — GitHub Artifact (the 6-artifact evidence package)

1. **Script:** `scripts/log_pipeline_check.sh` — verify rsyslog up, forwarding target reachable,
   recent event delivered.
2. **Detection rule/config:** `infra/configs/rsyslog-forward.conf` (committed, sanitized).
3. **Runbook:** `docs/runbooks/runbook-log-gap.md` — "when a host stops sending logs, do X."
4. **Playbook:** `docs/playbooks/central-logging-play.md`.
5. **Incident report + notes:** the tamper-resistance drill (truncated local; collector intact) +
   notes.
6. **SOC ticket:** `SOC-06` (Task: "central logging + tamper-resistance proof") → Closed.

---

## §10 — Portfolio Artifact

- **Resume bullet:** "Configured centralized log forwarding (rsyslog → collector) and demonstrated
  tamper-resistant evidence retention plus a 'logs-stopped' detection for compromised hosts."
- **Interview talking point:** explain *why* central logging matters (defeats on-box log deletion)
  and the "logs stopped = investigate" detection — a senior-sounding answer.
- **Serves:** Security Analyst → SOC T1. **Completes the Wave-1 (Security Analyst) milestone with
  Lesson 17** — write `lessons/<wave-1>/PORTFOLIO.md` when 01–06 + 17 are done.

---

## §11 — Certification Crossover Notes

- **Security+:** logging/monitoring + log management (4.x). **CySA+:** log management/data sources.
  **SC-200:** connectors/ingestion. **BTL1:** SIEM ingestion. Reinforces NaviOps + NaviOpsNetwork
  syslog. Detail: `alignment/CERTIFICATION-MAPPING.md`.

---

## §12 — Security Notes (Lens E — Attacker & Defender)

**🔴 Attacker:** clear/truncate local logs (T1070.002), stop the logging service (T1562.001), or
flood logs to bury an action. On UDP syslog they may even spoof messages.

**🔵 Defender:** real-time off-box forwarding (the message is gone before they can delete it),
TCP/TLS for reliability + authenticity, append-only restricted storage, **alert on a host going
silent**, and FIM on the log directory. Central logging is the single control that most undermines
"cover your tracks."

---

## Quiz (Interview-Style, Graded)

**Q1.** What are syslog facilities and severities, and how does rsyslog use them to route messages?
> **Your answer:**

**Q2.** Why is centralized, off-box logging essential for a SOC — what attack does it defeat?
> **Your answer:**

**Q3.** UDP/514 vs TCP/TLS for forwarding — trade-offs, and which you'd choose for security
evidence?
> **Your answer:**

**Q4.** **Scenario:** a host stops sending logs to the collector at 02:00. Walk through your triage
— benign causes vs attack, and what confirms which.
> **Your answer:**

**Q5.** When investigating a compromised host, why do you trust the central log copy over the local
file?
> **Your answer:**

*(Request the "Professional Answer" comparison under each before moving on.)*

---

## Reflection
*(After the quiz)* — What did you learn? · What confused you? · What would you do differently?

---

## Search Keywords For Further Understanding

**Core**
- `syslog facilities severities rfc 5424`
- `rsyslog forward central log server`
- `centralized logging security benefits`
- `log retention integrity append only`
- `detect host stopped sending logs`

**Tools**
- `rsyslog tls tcp configuration`
- `wazuh agent log forwarding`

**Going further**
- `network security fundamentals` (L07) · `siem fundamentals` (L13) · `file integrity monitoring` (L24)

**Red / Blue (Lens E):**
- 🔴 `clear logs T1070.002`, `disable logging T1562.001`, `syslog spoofing udp`
- 🔵 `real-time off-box logging`, `tls syslog`, `log source silence alert`

---

## Lesson Status
- [ ] §8 lab completed (forwarding configured; tamper-resistance proven)
- [ ] 6-artifact evidence package committed (§9)
- [ ] Quiz answered + professional-answer comparisons (graded)
- [ ] Reflection + Search Keywords reviewed

When complete, run the Update Protocol, then move to **Lesson 07 — Network Security Fundamentals**.

---

*Lesson 06 written by Navi · 2026-06-20 · full-depth. Sources to cite at study time: RFC 5424,
rsyslog docs, NIST SP 800-92 (log management), MITRE T1070/T1562.*
