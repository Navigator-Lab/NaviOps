# Lesson 26 — Network Incident Response

**Status:** ✅ ready for self-study (full depth) · **Date written:** 2026-06-20
**Schema:** 12-section (`docs/learning/CLAUDE_TEACHING_RULES.md`)
**Focus:** the IR lifecycle, RCA (5 Whys / fault-domain isolation), runbook format, the 8 NOC scenarios.
**Primary artifact:** `docs/runbooks/incident-template.md`.

> **How to use this lesson:** this consolidates everything — it's the *method* for handling a
> network incident end-to-end and documenting it. Read §1–§7, formalize the incident template,
> then run a full incident with it. This is the heart of the NOC capstone (35).

---

## §1 — Concept (Scientific Theory)

### What it is
**Network Incident Response** is the structured process of handling a network problem from
detection to closure: **detect → triage → contain → diagnose (RCA) → fix → recover → document →
review**. It combines the troubleshooting method (Lesson 18), monitoring (Lessons 21–25), and the
NOC operational modules (`docs/learning/noc/`) into one repeatable discipline that produces a
documented incident every time.

### Why it exists
Ad-hoc firefighting wastes time, loses evidence, repeats mistakes, and produces no learning. A
defined IR process makes outcomes consistent: faster restoration (lower MTTR), preserved evidence
(real RCA), clear communication, and a **post-incident review** that prevents recurrence. It's the
difference between "we fixed it somehow" and "here's the timeline, root cause, and the fix that
ensures it won't happen again."

### The lifecycle (network-flavored)
| Phase | What | Tools/refs |
|---|---|---|
| **Detect** | an alert/report (Lessons 21–25) | monitoring, logs |
| **Triage** | severity + scope; acknowledge | `noc/alert-handling.md`, severity rubric |
| **Contain** | stop the bleeding (restore-first) | reroute/failover/block (Lessons 15/31) |
| **Diagnose (RCA)** | find the true cause | bottom-up (L18), fault-domain isolation, 5 Whys (`noc/rca.md`) |
| **Fix** | apply the correction | the relevant lesson's fix |
| **Recover** | confirm full restoration | re-verify with the same checks that detected it |
| **Document** | the incident report | this lesson's template |
| **Review** | blameless PIR + prevention | `noc/rca.md`, `noc/outage-management.md` |

### Restore-first vs root-cause-first
A core IR judgment: **restore service first** (failover/reroute/roll back) even before you fully
understand *why* — but **preserve evidence** (captures, logs, counters) before it rolls off, so you
can do RCA after. Chasing root cause while customers are down is the classic mistake
(`noc/outage-management.md`).

### Three-Level Depth (Lens A)
- **Level 1 — Beginner:** when something breaks, follow the same steps every time: notice it, size
  it up, stop the damage, find the cause, fix it, confirm it's better, and write down what
  happened so it doesn't happen again.
- **Level 2 — NetOps/NOC:** you run the lifecycle under time pressure, communicate on a cadence,
  escalate per the matrix (`noc/escalation-matrix.md`), and produce a runbook with a real RCA.
  You distinguish the **fix** (restore now) from the **root cause** (prevent recurrence), and you
  map every incident to one of the **8 NOC scenarios** (`noc/noc-scenarios.md`).
- **Level 3 — Systems (Lens D):** RCA is **fault-domain isolation** — bisecting the path/stack by
  OSI layer (Lesson 18) until the failing domain is bounded — plus **5 Whys** to get past the
  symptom to the systemic cause (e.g. "the change wasn't tested against DNS" → add a test gate).
  The output is causal, not just descriptive.

### Two Teaching Approaches (Lens B) — the IR lifecycle & RCA

**Approach 1 (technical):** an incident is a state machine: NEW → (triaged: sev+scope) →
(contained: service restored or worked-around) → (diagnosed: root cause via bottom-up + 5 Whys) →
(fixed + recovered: verified) → (closed + reviewed: prevention items assigned). Each transition
captures evidence (timestamps, commands, outputs) that becomes the incident report.

**Approach 2 (analogy):** IR is **emergency-room medicine**.
- **Triage** = the ER nurse sizing up severity (a Sev1 outage = a trauma case; a Sev3 = a sprain).
- **Contain/stabilize** = stop the bleeding *before* the full diagnosis (restore service / put the
  patient on oxygen) — you stabilize first, diagnose second.
- **Preserve evidence** = draw blood / order scans *now*, before the situation changes.
- **RCA** = the diagnosis (not "they're in pain" but "appendicitis") — and the **5 Whys** /
  blameless review is the *why it happened* so it's prevented.
- **The chart** = the incident report — a complete, factual record the next shift can act on.
- **Where it breaks down:** ER treats one patient; a NOC may juggle several incidents and a noisy
  alert stream at once, so dedup/correlation and an incident commander matter — the scale the ER
  analogy understates (`noc/outage-management.md`).

### Visual (ASCII) — the IR lifecycle

```
  DETECT ─► TRIAGE ─► CONTAIN ─────────► DIAGNOSE(RCA) ─► FIX ─► RECOVER ─► DOCUMENT ─► REVIEW
   alert/   sev+      restore-first +     bottom-up +     apply  verify     incident    blameless
   report   scope     PRESERVE evidence   5 Whys +        the    with same  report      PIR +
            +ack      (don't lose it)     fault-domain    fix    checks     (template)  prevention
                                                                                          items
  every incident maps to one of the 8 NOC scenarios (noc/noc-scenarios.md)
```

---

## §2 — Linux Networking Commands (the IR toolkit, consolidated)

```bash
# Detect/verify (Lessons 18, 21): the same checks detect AND confirm recovery
ping/mtr/dig/nc -vz/curl                 # reachability/latency/DNS/port/service
net_diag.sh ; latency_monitor.sh         # your own diagnostics (Lessons 01/17/21)
# Preserve evidence (Lessons 19, 20): capture BEFORE changing anything
sudo tcpdump -nni any -w /tmp/incident-$(date +%s).pcap '<bpf>'   # capture (redact, don't commit raw)
journalctl --since "30 min ago" > /tmp/incident-journal.txt        # logs (Lesson 25)
ip -s link ; nft list ruleset ; ip route                            # state snapshots
# Contain (Lessons 15, 31): block a source / failover
nft add rule inet filter input ip saddr <attacker> drop            # contain (security IR)
# Document: build the runbook from the captured evidence
```

**Cisco/CCNA mapping:** IR is process, not a device command — but the device-side evidence
(`show logging`, `show interfaces`, `show ip route`) feeds the same lifecycle. The 7-step
troubleshooting method (Lesson 18) is the diagnose phase.

---

## §3 — Real-World Use Cases

**Production scenarios:**
1. **Major outage (Sev1):** declare, contain (failover), communicate on a cadence, RCA, recover,
   PIR — the full `noc/outage-management.md` flow.
2. **Recurring problem:** repeated link flaps → a **Problem** ticket (Lesson 23/ticketing) drives
   RCA to a permanent fix, not endless incident tickets.
3. **Security incident:** detect (IDS/SIEM, Lesson 28) → contain (block + isolate) → eradicate →
   recover → report — same lifecycle, security flavor (capstone 36).
4. **Post-change incident:** a change broke something → roll back (contain) → RCA → add a test
   gate (prevention).

**How NOC engineers use it:** this *is* the NOC's core deliverable beyond watching dashboards —
running incidents to closure and producing the runbook. Interviews ask "walk me through an
incident you handled" — this lesson's output is your answer.

**When NOT to:** don't skip documentation "because it's fixed" (you lose the learning); don't chase
RCA while service is down (restore first); don't blame people (blameless PIR).

**Exam framing (Net+):** the troubleshooting methodology + documentation + change/incident
management are Network Operations + Troubleshooting domains.

---

## §4 — Troubleshooting Section (IR-process failure modes)

| Symptom of bad IR | Impact | Fix |
|---|---|---|
| No evidence preserved | can't do RCA | capture/snapshot before changing |
| RCA = the symptom | recurs | 5 Whys to the systemic cause |
| Service down during long RCA | extended outage | restore-first, RCA after |
| No communication | stakeholders panic | regular cadence updates |
| No documentation | no learning, repeats | runbook every incident |
| Blame culture | causes hidden | blameless PIR |

**Redaction check:** incident reports + captures must be sanitized (lab/RFC-1918, no raw pcap).

---

## §5 — Common Mistakes

| Mistake | Impact | Fix |
|---|---|---|
| Changing things before capturing evidence | no RCA, can't roll back | snapshot first |
| Treating the fix as the root cause | recurrence | distinguish fix vs root cause |
| Skipping the post-incident review | no improvement | always PIR + prevention items |
| One-person heroics, no comms | chaos, no continuity | roles + cadence (`noc/outage-management.md`) |
| Reusing a stale runbook blindly | wrong steps | keep runbooks current |
| No prevention item | same incident next month | every RCA yields an owned action |

---

## §6 — NOC Perspective

> NOC Technician focus (Stage 1, `ROADMAP.md`).

IR *is* the NOC's reason to exist. Everything in `docs/learning/noc/` converges here:
alert-handling (detect/triage), escalation-matrix (when to hand off), ticketing (the record),
shift-handover (carrying an open incident), RCA (the diagnosis), SLA (MTTD/MTTR measurement), and
outage-management (Sev1 coordination). Mastering the lifecycle + producing clean runbooks is what
separates a Tier-1 who "closes tickets" from one who's promotable.

---

## §7 — Incident-Response Perspective

This lesson *is* the IR perspective, formalized. Its deliverable — the **incident template** — is
used by §7 of *every other lesson*. The RCA methods (`noc/rca.md`) and the restore-first principle
(`noc/outage-management.md`) are the throughline. Every troubleshooting drill (1–8) becomes a
full IR exercise here: not just "fix it," but detect→...→review with a documented runbook.

---

## §8 — Practical Lab (build this yourself)

**Goal:** formalize `docs/runbooks/incident-template.md`, then run a **complete incident** (any
drill) through the full lifecycle and produce a real runbook.

### Lens C — Manual → Automated → Why
- **Manual:** handle an incident ad hoc.
- **Automated:** an "incident kickoff" helper that snapshots state (`net_diag.sh`, `journalctl`,
  `nft list ruleset`, `ip route`) to a timestamped evidence folder the moment an incident starts.
- **Why:** the #1 IR failure is losing evidence; a one-command evidence-capture run at incident
  start guarantees you can do RCA. Mature teams automate evidence collection.

### Steps
1. Write `docs/runbooks/incident-template.md` (the canonical format from `docs/runbooks/README.md`):
   severity/status/ticket/commit, symptom, diagnosis (bottom-up + evidence), root cause (RCA),
   fix, verification, prevention + detection-gap.
2. Build an "incident kickoff" evidence-capture script (snapshots the state above to
   `/tmp/incident-<ts>/`).
3. **Run a complete incident:** pick a drill (e.g. drill 1 DNS outage or drill 6 routing), then
   walk the **full lifecycle**: detect (monitor/alert) → triage (sev/scope) → contain → diagnose
   (capture evidence, RCA) → fix → recover (re-verify) → document (fill the template) → review
   (PIR + prevention item).
4. Produce the finished `docs/runbooks/incident-<scenario>.md` with a real timeline + RCA + a
   prevention item.

### Lens D — RCA depth
In your runbook, show the **5 Whys** explicitly for the root cause and the **fault-domain
isolation** (which OSI layer/path segment) — make the RCA causal, not descriptive.

---

## §9 — GitHub Artifact (evidence 5-tuple)

1. **Script:** the incident-kickoff evidence-capture script.
2. **Config/doc:** `docs/runbooks/incident-template.md` (the canonical template).
3. **Drill:** a full drill run end-to-end through the lifecycle.
4. **NAVI ticket:** `NAVI-26` (Incident: the full lifecycle exercise, with the PIR).
5. **Incident report:** `docs/runbooks/incident-<scenario>.md` (the complete, real runbook — the
   portfolio centerpiece).

---

## §10 — Portfolio Artifact

- **Resume bullet:** "Defined the network incident-response lifecycle and runbook standard; ran
  incidents end-to-end (detect→contain→RCA→recover→document→review) with evidence preservation and
  blameless post-incident reviews."
- **Interview talking point:** walk a real incident from your runbooks (restore-first, evidence,
  RCA via 5 Whys, prevention) — the most compelling NOC interview answer.
- **Serves:** NOC Technician + Network Operations (Stages 1–2); the method behind the NOC capstone
  (35) and security capstone (36).

---

## §11 — RHCSA Crossover Notes

Mostly **N/A for RHCSA** as a topic, but the evidence toolkit (`journalctl`, `ss`, `ip`, log
review) and structured troubleshooting are RHEL-admin skills, and the documentation discipline
applies to any sysadmin role. The sibling NaviOps platform's IR lessons share this template.

---

## §12 — Security Notes (Lens E — Attacker & Defender)

> Frameworks: [MITRE ATT&CK](https://attack.mitre.org/), the security IR lifecycle (NIST SP 800-61).

**🔴 Attacker:** during a security incident the adversary actively works against your IR —
**destroying evidence** (`T1070`), **disabling logging/monitoring** (`T1562`), and moving fast.
Slow or evidence-careless IR lets them entrench. Attackers also cause *diversionary* outages.

**🔵 Defender:** the same lifecycle applies to security incidents (capstone 36) with extra steps:
**preserve forensic evidence first** (off-box logs from Lesson 25, captures from Lesson 20),
**contain** (isolate/block, Lesson 15), **eradicate**, **recover**, and **report** mapped to MITRE
ATT&CK. The blameless PIR + prevention loop is how detections improve (Lesson 28). Verify your IR
can reconstruct a timeline from off-box evidence even if a host's local logs are wiped (lab).

---

## Quiz (Interview-Style, Graded)

**Q1.** List the network incident-response lifecycle phases in order.
> **Your answer:**

**Q2.** Explain "restore-first" vs "root-cause-first" and when each applies. What must you do
*before* you start changing things?
> **Your answer:**

**Q3.** Difference between the **fix** and the **root cause**? Give an example using 5 Whys.
> **Your answer:**

**Q4.** **Scenario:** A Sev1 outage is ongoing. Walk through how you'd run it — containment,
communication, evidence, RCA, and the post-incident review.
> **Your answer:**

**Q5.** What goes in a good incident report, and why is the prevention item essential?
> **Your answer:**

**Q6.** Why is a *blameless* post-incident review more effective than assigning blame?
> **Your answer:**

*(After you answer, request the "Professional Answer" comparison under each — graded before Lesson 27.)*

---

## Reflection
*(Fill in after the quiz)* — What did you learn? · What confused you? · What would you do differently?

---

## Search Keywords For Further Understanding

**Core**
- `incident response lifecycle`
- `root cause analysis 5 whys`
- `restore first vs root cause`
- `blameless postmortem`
- `incident report runbook format`

**Tools**
- `evidence preservation incident`
- `mttr mttd incident metrics`
- `major incident management`

**Going further (future lessons)**
- `network security detection` (L28) · `security capstone IR` (L36) · `nist 800-61 incident handling`

**Red / Blue (Lens E):**
- 🔴 `anti-forensics clear logs T1070`, `disable monitoring during attack T1562`
- 🔵 `forensic evidence preservation`, `nist incident response lifecycle`, `detection improvement loop`

---

## Lesson Status
- [ ] §8 lab completed (incident template + full lifecycle run)
- [ ] §4 drill done (any drill, full IR lifecycle)
- [ ] Evidence committed (§9)
- [ ] Quiz answered + professional-answer comparisons (graded)
- [ ] Reflection + Search Keywords reviewed

When complete, run the Update Protocol, then move to **Lesson 27 — Network Documentation**.

---

*Lesson 26 written by Navi · 2026-06-20 · full-depth. Sources to cite when worked: NIST SP 800-61
(incident handling), CompTIA Network+ N10-009, Google SRE (postmortems), MITRE ATT&CK T1070/T1562.*
