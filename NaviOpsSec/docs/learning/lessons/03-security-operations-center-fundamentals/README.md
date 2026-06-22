# Lesson 03 — SOC Fundamentals

**Status:** ✅ ready for self-study (full depth) · **Date written:** 2026-06-20
**Schema:** 12-section SOC (`docs/learning/CLAUDE_TEACHING_RULES.md`)
**Focus:** how a SOC is structured and operated — tiers/roles, the alert queue, MTTD/MTTR, the
shift model, escalation, and the analyst's day.
**Primary artifact:** the `soc/` modules (you operate them) + `scripts/log_triage.sh` tie-in.

> **How to use this lesson:** read §1–§7, do §8 (walk a mock alert through the full SOC flow),
> produce §9, answer the quiz, reflect. Then Lesson 04.

---

## §1 — Concept (Scientific Theory)

### What it is
A **Security Operations Center (SOC)** is the people + process + technology function that operates
the detect→triage→investigate→respond→improve loop continuously (often 24/7). It's organized in
**tiers**:
- **Tier 1 (Analyst):** monitors the alert queue, triages (TP/FP, severity), does basic
  investigation, closes false positives, escalates the rest.
- **Tier 2 (Investigator):** deep investigation, scoping, containment decisions, host/network
  forensics.
- **Tier 3 / IR / Detection Engineering:** major-incident response, threat hunting, malware
  analysis, and building/tuning the detections.
- **SOC Lead/Manager:** coordination, stakeholder comms, major-incident command.

### Why it exists
Alerts arrive faster than any one person can investigate deeply. The tiered model is **triage at
scale**: cheap, fast judgment up front (T1) so expensive, deep work (T2/T3) is spent only on what's
real. Without it, analysts either burn out chasing noise or miss the real incident in the flood.

### The metrics that define "good"
- **MTTD** (mean time to detect): attacker action → alert. Lower = less dwell.
- **MTTR** (mean time to respond/resolve): alert → contained/closed. Lower = less impact.
- **Dwell time**: total time the attacker is present before eviction — the headline breach number.
- Plus alert volume, FP rate, escalation rate, ATT&CK coverage (`soc/soc-metrics-sla.md`).

### Three-Level Depth (Lens A)
- **Level 1 — Beginner:** a SOC is the team (and room) that watches for attacks all day and
  responds. Junior analysts triage; seniors investigate and hunt.
- **Level 2 — Analyst/SOC:** the day is an **alert queue** + a **ticket board**. You acknowledge
  (stop the SLA clock), triage, investigate to the right depth, and either close+tune or escalate
  with a proper handover. Shifts hand over open cases (`soc/shift-handover.md`).
- **Level 3 — Adversary/Kernel:** the SOC's effectiveness is a function of **detection coverage**
  (do you even have a rule for this technique?) and **MTTD/MTTR**. Attackers exploit coverage gaps
  (false negatives) and dwell time — which is why hunting (L25) and detection engineering (L26)
  exist to shrink both.

### Two Teaching Approaches (Lens B) — the tiered SOC
**Approach 1 (technical):** a funnel — many alerts in at T1, filtered by triage to fewer real
incidents at T2, to rare major incidents at T3/IR. Each tier has a defined scope, SLA, and
escalation trigger.

**Approach 2 (analogy):** the **hospital ER** again. T1 = triage nurse (fast intake, who's urgent).
T2 = ER doctors (diagnosis + treatment). T3/IR = specialists + the trauma team (the major cases).
The manager runs the floor and talks to families (stakeholders). **Where it breaks down:** the ER
doesn't *engineer* better detection of patients — a SOC actively builds new detections from each
incident.

### Visual (ASCII) — the SOC funnel
```
   1000s of events ─► [ SIEM rules ] ─► 100s of ALERTS
                                            │  T1 triage (TP/FP, severity)
                                            ▼
                                       10s of INCIDENTS
                                            │  T2 investigate + contain
                                            ▼
                                        1-2 MAJOR incidents ─► T3 / IR
   every closed incident ──► lessons learned ──► new/tuned detection (feeds the top)
```

---

## §2 — Linux Investigation Commands

A T1's "first look" is the §2 toolkit from Lesson 01, run fast and consistently — that's why
`log_triage.sh` exists. The SOC adds *consistency under time pressure*:
```bash
bash scripts/log_triage.sh        # one-command first-pass triage (auth/login/proc/net)
journalctl -S -30m -p warning     # what changed in the last 30 min
last -n 20 ; lastb -n 20          # recent good + bad logins at a glance
```
| Linux | SIEM equivalent |
|---|---|
| `log_triage.sh` first look | the SIEM alert + its enrichment panel |
| manual correlation | SIEM correlation/aggregation rules (Lesson 15) |

---

## §3 — Real-World Threat Context & Use Cases

- **The shift:** you arrive, read the handover, take the queue, work alerts by severity/SLA,
  escalate per the matrix, update tickets, and write the handover at the end (`soc/shift-handover.md`).
- **Internal vs MSSP SOC:** in-house defends one org; an MSSP defends many clients — same loop,
  more tenant context. Junior roles exist in both.
- **When the SOC mustn't over-react:** a planned pentest or a maintenance window can look like an
  attack — the SOC suppresses/annotates known activity rather than escalating it.
- **Exam framing:** SOC tiers/roles, MTTD/MTTR, escalation, and the IR-team structure are tested
  on Security+/CySA+/BTL1.

---

## §4 — Detection

The SOC *consumes* detections; this lesson is about operating them well:
- **Alert quality** determines SOC quality. A detection must be actionable: what/where/how-bad +
  a runbook link (`soc/alert-triage.md`).
- **Coverage** (do we have a rule for this technique?) is the SOC's strategic detection question,
  measured against ATT&CK (Lesson 10) and improved by detection engineering (Lesson 26).
- The feedback loop — **every incident yields a new/tuned detection** — is what makes a SOC
  improve instead of drown.

---

## §5 — Investigation & Triage

This lesson *is* the triage discipline at the org level. The T1 decision tree
(`soc/alert-triage.md`): alert → TP/FP? → severity → scope → enrich → decide (close+tune / handle /
escalate). The judgment call that defines a good T1: **escalate the right things** — not too early
(wastes T2), not too late (lets it spread). The triggers are in `soc/escalation-matrix.md`.

---

## §6 — SOC Perspective

The whole lesson. Internalize: the **tiers** and who owns what; the **queue + SLA** (acknowledge
fast, work by severity); the **ticket lifecycle** (`SOC-NN`, `soc/case-management.md`); the
**handover** (`soc/shift-handover.md`); and the **metrics** you're judged on (MTTD/MTTR/FP-rate,
`soc/soc-metrics-sla.md`). This is the operational backbone every later lesson plugs into.

---

## §7 — Incident-Response Perspective

The SOC is where IR *starts*: T1 detects + triages, escalation hands a confirmed incident to T2/IR
who run the lifecycle (`workflows/ir-workflow.md`). Knowing the **escalation triggers** (successful
login, code execution, persistence, multi-host, critical asset) is what makes you hand off at the
right moment with a complete escalation note (`soc/escalation-matrix.md`).

---

## §8 — Practical Lab (build this yourself)

**Goal:** run a mock alert through the entire SOC flow so the process is muscle memory.

### Lens C — Manual → Automated → Why
- **Manual:** triage a mock alert by hand, writing each decision.
- **Automated:** `log_triage.sh` gives you the consistent first-look every time — automation makes
  triage *repeatable* across analysts and shifts.
- **Why:** SOCs live or die on consistency; a runbook + a triage script means two analysts reach
  the same decision on the same alert.

### Steps
1. Take a mock alert: *"Wazuh: 12 failed SSH logins from 10.0.0.99 on web01, 02:05–02:09Z."*
2. Run the full flow on paper: acknowledge → TP/FP reasoning → severity (CIA + asset) → scope →
   decision → (if escalating) write the escalation note (`soc/escalation-matrix.md` template).
3. Open a `SOC-03` case with a timeline + resolution (`soc/case-management.md`).
4. Write a shift-handover note that includes this case as an open item (`soc/shift-handover.md`).
5. Compute the mock metrics: time-to-acknowledge, time-to-decision (the seed of MTTD/MTTR).

### Lens D — the raw artifact
The "alert" is just a correlated set of the raw lines you saw in Lesson 01 §8:
```
Jun 20 02:05..02:09 web01 sshd: Failed password for ... from 10.0.0.99   (×12)
```
A SOC's value-add is turning 12 raw lines into one triaged, ticketed, escalated-or-closed
*decision*.

---

## §9 — GitHub Artifact (the 6-artifact evidence package)

1. **Script:** `scripts/log_triage.sh` referenced as the T1 first-look (extend with a
   time-window flag).
2. **Detection rule/config:** N/A (operational lesson) — instead the severity rubric you adopt.
3. **Runbook:** `docs/runbooks/runbook-triage-flow.md` — the T1 triage flow, step by step.
4. **Playbook:** `docs/playbooks/escalation-play.md` — when/how to escalate (from the matrix).
5. **Incident report + notes:** the `SOC-03` mock case worked end-to-end + a shift-handover note.
6. **SOC ticket:** `SOC-03` (Task: "operate the SOC flow on a mock alert") → Closed.

---

## §10 — Portfolio Artifact

- **Resume bullet:** "Operated the full SOC triage flow (acknowledge → triage → severity →
  escalate/close → ticket → handover) with documented runbooks and SLA-aware metrics."
- **Interview talking point:** describe SOC tiers, MTTD/MTTR, and *when you'd escalate* — then show
  your triage runbook + a worked case. SOC interviews probe "walk me through your shift."
- **Serves:** Security Analyst → SOC T1 (Stages 1–2).

---

## §11 — Certification Crossover Notes

- **Security+:** Security operations (4.x), IR roles. **CySA+:** security operations + governance.
  **BTL1:** SOC + IR process. **SC-200:** managing a SOC / incidents in Sentinel-Defender (analog).
  Detail: `alignment/CERTIFICATION-MAPPING.md`.

---

## §12 — Security Notes (Lens E — Attacker & Defender)

**🔴 Attacker:** attackers bank on SOC weaknesses — **dwell time** (operate slowly under the
radar), **alert fatigue** (hide in the noise), and **coverage gaps** (use a technique you don't
detect, T1562 impair defenses). They also attack during off-hours/holidays betting on thin shifts.

**🔵 Defender:** counter with tuned, high-signal detections (fight fatigue), broad ATT&CK coverage
(close gaps), good handovers (no off-hour blind spots), and metrics that *measure* MTTD/dwell so
you know if you're winning. A SOC that measures itself improves; one that doesn't, drowns.

---

## Quiz (Interview-Style, Graded)

**Q1.** Describe the SOC tiers and what each does. What distinguishes a T1 from a T2?
> **Your answer:**

**Q2.** Define MTTD and MTTR. Why does a SOC track both, and how would lowering a detection
threshold affect each (and the FP rate)?
> **Your answer:**

**Q3.** What is "dwell time" and why is it the headline breach metric?
> **Your answer:**

**Q4.** **Scenario:** you're T1 with 30 alerts in the queue and one analyst. How do you decide what
to work first, and when do you escalate?
> **Your answer:**

**Q5.** What goes in a good shift-handover note, and why does it matter to an attacker's success?
> **Your answer:**

**Q6.** Why is "every incident produces a new detection" the habit that separates an improving SOC
from a drowning one?
> **Your answer:**

*(Request the "Professional Answer" comparison under each before moving on.)*

---

## Reflection
*(After the quiz)* — What did you learn? · What confused you? · What would you do differently?

---

## Search Keywords For Further Understanding

**Core**
- `soc tiers tier 1 tier 2 tier 3 roles`
- `mttd mttr dwell time security metrics`
- `soc alert queue triage workflow`
- `security incident escalation matrix`
- `soc shift handover best practices`

**Tools**
- `wazuh alert dashboard soc`
- `siem alert triage process`

**Going further**
- `linux logs auditing` (L04) · `siem fundamentals` (L13) · `alert triage` (L17) · `detection engineering` (L26)

**Red / Blue (Lens E):**
- 🔴 `attacker dwell time low and slow`, `impair defenses T1562`, `alert fatigue exploitation`
- 🔵 `detection coverage att&ck`, `soc metrics mttd mttr`, `tuning false positives`

---

## Lesson Status
- [ ] §8 lab completed (mock alert through the full SOC flow; case + handover written)
- [ ] 6-artifact evidence package committed (§9)
- [ ] Quiz answered + professional-answer comparisons (graded)
- [ ] Reflection + Search Keywords reviewed

When complete, run the Update Protocol, then move to **Lesson 04 — Linux Logs & Auditing**.

---

*Lesson 03 written by Navi · 2026-06-20 · full-depth. Sources to cite at study time: NIST SP
800-61r2, SANS SOC fundamentals, CompTIA CySA+ CS0-003 security-operations domain.*
