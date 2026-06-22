# Lesson 13 — SIEM Fundamentals

**Status:** ✅ ready for self-study (full depth) · **Date written:** 2026-06-20
**Schema:** 12-section SOC (`docs/learning/CLAUDE_TEACHING_RULES.md`)
**Focus:** what a SIEM does end-to-end — collection → normalization → correlation → alerting →
dashboards — the log pipeline, use cases, and SIEM vs plain log management.
**Primary artifact:** `docs/learning/siem-architecture.md` (the pipeline, drawn for the lab).

> **How to use this lesson:** read §1–§7, do §8 (diagram the pipeline + trace one event through it),
> produce §9, quiz, reflect. Then Lesson 14 (deploy Wazuh).

---

## §1 — Concept (Scientific Theory)

### What it is
A **SIEM** (Security Information and Event Management) is the system that **centralizes** logs from
everywhere, **normalizes** them into common fields, **correlates** across sources, **alerts** on
detection logic, and presents **dashboards** + search. It's the SOC's nerve center — the place an
analyst lives.

The pipeline:
```
 collect → parse/normalize (decoders) → enrich → correlate (rules) → alert → dashboard/search → store
```

### Why it exists
Logs scattered across 100 hosts in 20 formats are useless under pressure. A SIEM solves three
problems at once: **one place** to look (centralization), **one language** to search
(normalization), and **automatic detection** (correlation rules + alerts) so humans don't read
every line. It turns "we have logs" into "we get told when something's wrong."

### SIEM vs log management
Log management *stores + searches* logs. A SIEM adds **detection** (correlation rules), **alerting**,
and **security context** (threat intel, ATT&CK). Wazuh is technically SIEM + XDR (it also does FIM,
inventory, and active response on endpoints via agents).

### Three-Level Depth (Lens A)
- **Level 1 — Beginner:** a SIEM is a giant searchable inbox for all your logs that buzzes you when
  it spots something bad.
- **Level 2 — Analyst/SOC:** you write/tune **rules** that fire **alerts**, build **dashboards** for
  situational awareness, and **search** during investigations. Detection quality = rule quality;
  signal = normalization quality (a rule can't match a field the parser didn't extract).
- **Level 3 — Adversary/Kernel:** the make-or-break stages are **normalization** (a decoder must
  extract the right fields from each log format) and **correlation** (combine events across
  time/sources — "failed×N then accepted from same IP"). Garbage parsing → no detection. Wazuh does
  this with **decoders** (extract fields) + **rules** (match + correlate), Lesson 15.

### Two Teaching Approaches (Lens B) — the SIEM pipeline
**Approach 1 (technical):** an ETL + rules engine for security events: extract (collect), transform
(normalize/enrich), load (index/store), then a streaming rules engine evaluates each normalized
event (and aggregates) to emit alerts.

**Approach 2 (analogy):** a **mailroom + security desk** for a huge building. Mail (logs) arrives
from every floor in every format; the mailroom sorts + labels it into standard envelopes
(normalization); the security desk reads the labels against a watchlist (rules) and raises an alarm
(alert) when something matches; the lobby screens (dashboards) show the building's status.
**Where it breaks down:** a SIEM also *correlates* across senders ("3 floors reported the same odd
visitor") — more than a mailroom does.

### Visual (ASCII) — the pipeline
```
 hosts/net ─logs─► [COLLECT] ─► [NORMALIZE: decoders → fields] ─► [ENRICH: intel/geo]
                                                                       │
   dashboards/search ◄─ [STORE/INDEX] ◄─ [ALERT] ◄─ [CORRELATE: rules + frequency] ◄┘
```

---

## §2 — Linux Investigation Commands

Before/around the SIEM, you still verify on the box (Linux-first):
```bash
# what the SIEM ingests (the raw side)
tail -f /var/log/auth.log                       # the source event
# Wazuh side (Lesson 14 stands this up; commands previewed)
tail -f /var/ossec/logs/alerts/alerts.json       # the alert side (post-pipeline)
/var/ossec/bin/wazuh-logtest                      # feed a log line → see decode + rule match
jq '.rule.level, .rule.description' /var/ossec/logs/alerts/alerts.json | head  # parse alerts
```
| Pipeline stage | Linux/Wazuh artifact |
|---|---|
| collect | agent reads `auth.log` etc. |
| normalize | decoder → JSON fields (`wazuh-logtest`) |
| correlate/alert | rule → `alerts.json` |
| search/dashboard | Wazuh dashboard / OpenSearch |

---

## §3 — Real-World Threat Context & Use Cases

- **Detection at scale:** the only practical way to watch many hosts for many techniques at once.
- **Investigation pivot:** search all sources by an IOC/user/time in one query (vs grepping 100
  boxes).
- **Correlation wins:** "failed logins + a successful login + a new process from one IP" = one
  high-confidence alert the SIEM assembles from three sources.
- **Use cases (detections) are the product:** a SIEM is only as good as its rules/use-cases
  (Lessons 15, 18–24, 26).
- **Exam framing:** SIEM architecture, correlation, and SIEM-vs-log-management are on
  Security+/CySA+/SC-200/BTL1.

---

## §4 — Detection

- **A "use case" = a detection.** Each is collection (right log) + normalization (right fields) +
  a rule + an alert + a runbook. The platform builds many (Lessons 18–24).
- **Correlation rules** combine events (sequence/frequency/cross-source) — higher fidelity than
  single-event matches. (Wazuh frequency rules, Lesson 15/19.)
- **Coverage** of use cases is measured against ATT&CK (Lesson 10). Gaps = blind spots.
- **The pipeline is the dependency:** no detection without correct collection + normalization
  first.

---

## §5 — Investigation & Triage

The SIEM is your triage + investigation cockpit: the alert arrives with normalized fields +
enrichment; you pivot by searching the same store for related events (same host/user/IP/time). The
Linux-first skill (Lessons 04–05) is your fallback + validation when the SIEM didn't parse
something or you need ground truth on the box.

---

## §6 — SOC Perspective

The SIEM *is* the SOC's primary tool — the alert queue, dashboards, and search all live here. SOC
maturity = use-case coverage + tuning + dashboard quality. Pipeline health (are sources reporting?
Lesson 06) is monitored as a first-class concern. Everything in `soc/` operates on top of the SIEM.

---

## §7 — Incident-Response Perspective

The SIEM accelerates every IR phase: detect (the alert), investigate (search + correlate across the
estate), scope (IOC search everywhere at once), and document (export the timeline). Its retained,
off-box data is trusted evidence (Lesson 06). The capstone (Lesson 35) is run through the SIEM.

---

## §8 — Practical Lab (build this yourself)

**Goal:** understand the pipeline by tracing one event from raw log to alert (conceptually now,
hands-on in Lesson 14).

### Lens C — Manual → Automated → Why
- **Manual:** you grep a log on one host (Lesson 05).
- **Automated:** the SIEM does that grep continuously, across every host, with correlation, and
  alerts you — automation of detection itself.
- **Why:** humans can't watch 100 hosts; the SIEM scales the analyst. Production tunes the pipeline
  for signal (good decoders) and the rules for fidelity (low FP).

### Steps
1. Draw the pipeline for *your* lab in `docs/learning/siem-architecture.md`: which hosts/log
   sources → agent → manager (normalize+correlate) → dashboard. Mark each stage.
2. Pick one event you care about (failed SSH login). Write out how it flows: raw `auth.log` line →
   decoder extracts {srcip, user, result} → rule 5710 matches → alert level 5 → dashboard.
3. List 5 "use cases" (detections) you'll build (failed-login, brute-force, new-user, port-scan,
   FIM) — your SIEM roadmap (ties to Lessons 18–24).
4. Note where Linux-first fallback applies (SIEM down / unparsed log).
5. Define the pipeline-health checks you'll watch (agents up, events/sec, last-seen).

### Lens D — the raw artifact
```
RAW:    Jun 20 02:14 web01 sshd: Failed password for admin from 10.0.0.99
NORMALIZED (decoder): {srcuser:"admin", srcip:"10.0.0.99", program:"sshd"}
ALERT (rule 5710): level 5, "sshd: authentication failed", groups:[authentication_failed]
# The decoder turning the line into FIELDS is what makes the rule (and search) possible.
```

---

## §9 — GitHub Artifact (the 6-artifact evidence package)

1. **Script:** `scripts/alert_parse.sh` — `jq` over `alerts.json` to summarize alerts by level/rule
   (works once Wazuh is up).
2. **Detection rule/config:** `docs/learning/siem-architecture.md` (the pipeline + use-case roadmap).
3. **Runbook:** `docs/runbooks/runbook-siem-pipeline.md` — verify the pipeline is healthy.
4. **Playbook:** the "trace an event through the pipeline" play (for debugging a missed detection).
5. **Incident report + notes:** N/A drill yet — instead the event-trace write-up + notes.
6. **SOC ticket:** `SOC-13` (Task: "SIEM architecture + use-case roadmap") → Closed.

---

## §10 — Portfolio Artifact

- **Resume bullet:** "Documented an end-to-end SIEM pipeline (collection → normalization →
  correlation → alerting) and a prioritized detection use-case roadmap mapped to ATT&CK."
- **Interview talking point:** explain the SIEM pipeline and *why normalization is the make-or-break
  stage* — a sharper answer than "a SIEM collects logs."
- **Serves:** SOC T1 (Stage 2). Sets up Wazuh (Lesson 14).

---

## §11 — Certification Crossover Notes

- **Security+:** SIEM/monitoring (4.x). **CySA+:** SIEM + correlation. **SC-200:** Sentinel
  architecture (analog). **BTL1:** SIEM. Detail: `alignment/CERTIFICATION-MAPPING.md`.

---

## §12 — Security Notes (Lens E — Attacker & Defender)

**🔴 Attacker:** target the pipeline — disable the agent / stop logging (T1562), avoid sources the
SIEM ingests, or flood it to bury the real event. A blind SIEM is the goal.

**🔵 Defender:** monitor pipeline health (agent up, events flowing), alert on sources going silent
(Lesson 06), ensure broad source coverage (no blind sources), and tune for signal so floods don't
work. The SIEM you can't trust to be *receiving* events isn't detecting anything.

---

## Quiz (Interview-Style, Graded)

**Q1.** Walk the SIEM pipeline end-to-end and say what each stage does.
> **Your answer:**

**Q2.** Why is normalization the make-or-break stage — what happens to a detection if a field isn't
parsed?
> **Your answer:**

**Q3.** SIEM vs log management — what does a SIEM add, and what extra does Wazuh (XDR) bring?
> **Your answer:**

**Q4.** **Scenario:** a detection you expected didn't fire on a real event. How do you debug it
through the pipeline?
> **Your answer:**

**Q5.** Why is monitoring SIEM pipeline health itself a security concern?
> **Your answer:**

*(Request the "Professional Answer" comparison under each before moving on.)*

---

## Reflection
*(After the quiz)* — What did you learn? · What confused you? · What would you do differently?

---

## Search Keywords For Further Understanding

**Core**
- `siem architecture collection normalization correlation`
- `siem vs log management`
- `log normalization parsing security`
- `siem correlation rules use cases`
- `wazuh xdr siem overview`

**Tools**
- `wazuh logtest decoder rule`
- `jq parse alerts json`

**Going further**
- `wazuh deployment` (L14) · `wazuh rules` (L15) · `detection engineering` (L26)

**Red / Blue (Lens E):**
- 🔴 `disable agent T1562`, `log source evasion`, `siem flooding`
- 🔵 `pipeline health monitoring`, `source coverage`, `normalization quality`

---

## Lesson Status
- [ ] §8 lab completed (pipeline diagrammed; event traced; use-case roadmap)
- [ ] 6-artifact evidence package committed (§9)
- [ ] Quiz answered + professional-answer comparisons (graded)
- [ ] Reflection + Search Keywords reviewed

When complete, run the Update Protocol, then move to **Lesson 14 — Wazuh Deployment**.

---

*Lesson 13 written by Navi · 2026-06-20 · full-depth. Sources to cite at study time: Wazuh
documentation (architecture), Gartner SIEM definition, NIST SP 800-92, CySA+ SIEM objectives.*
