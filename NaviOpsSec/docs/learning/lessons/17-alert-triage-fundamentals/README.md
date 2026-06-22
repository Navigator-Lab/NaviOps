# Lesson 17 — Alert Triage Fundamentals

**Status:** ✅ ready for self-study (full depth) · **Date written:** 2026-06-20
**Schema:** 12-section SOC (`docs/learning/CLAUDE_TEACHING_RULES.md`)
**Focus:** the core T1 skill — TP/FP, severity, scope, the triage decision tree, enrichment,
escalate-vs-close, and beating alert fatigue.
**Primary artifact:** `docs/playbooks/triage-playbook.md`.

> **How to use this lesson:** read §1–§7, do §8 (triage a queue of mixed alerts), produce §9, quiz,
> reflect. Then Lesson 18. **This + Lessons 01–06 completes the Wave-1 (Security Analyst)
> milestone** — write `lessons/<wave-1>/PORTFOLIO.md`.

---

## §1 — Concept (Scientific Theory)

### What it is
**Triage** is the rapid judgment that turns an alert into a decision: is it a **true positive**? how
**severe**? what's the **scope**? then **escalate**, **handle**, or **close+tune**. It's the
highest-volume, most-defining T1 skill — a SOC's effectiveness is largely its triage quality
(`soc/alert-triage.md`).

### Why it exists
Alerts vastly outnumber incidents. Without fast, consistent triage you either drown (chase every
alert deeply) or miss the real one (rubber-stamp them all). Triage is the funnel that spends
expensive deep-investigation time only on what's real (the SOC funnel, Lesson 03).

### Three-Level Depth (Lens A)
- **Level 1 — Beginner:** for each alarm, decide: real or false? how bad? who handles it?
- **Level 2 — Analyst/SOC:** run the decision tree — TP/FP → severity (CIA + asset) → scope (one or
  many) → enrich (intel/baseline/context) → decide (close+tune / handle / escalate). Acknowledge
  fast to stop the SLA clock. Document facts vs assessment.
- **Level 3 — Adversary/Kernel:** the hard calls are **benign true positives** (real but authorized
  — your own scanner) vs **malicious TPs**, and spotting the **false negative** hiding in alert
  fatigue. Good triage uses enrichment (the alert's fields + intel + the host/user baseline) to
  decide with evidence, not vibes.

### Two Teaching Approaches (Lens B) — triage
**Approach 1 (technical):** a classification function over an alert: features = {rule fidelity,
fields, asset criticality, intel match, baseline deviation}; output = {FP-close, handle, escalate} +
severity. Tuning shifts the function to reduce FP without raising FN.

**Approach 2 (analogy):** the **ER triage nurse**. A flood of patients (alerts); seconds each;
sort by urgency (severity), spot the real emergency (TP) among the worried-well (FP), and route —
treat now, wait, or rush to surgery (escalate). **Where it breaks down:** alerts can be *adversarial*
(an attacker deliberately generating noise to bury the real one) — nurses don't face patients trying
to hide.

### Visual (ASCII) — the triage decision tree
```
 ALERT ─► acknowledge (stop SLA clock)
   │
   ├─ TRUE positive? ── no ──► CLOSE-FP  ──► tune the rule (so it won't refire)
   │     │ yes (or benign-TP → close w/ note)
   │     ▼
   ├─ SEVERITY (CIA + asset criticality)  → Sev1..4
   │     ▼
   ├─ SCOPE: one host/user  ──► HANDLE in shift
   │         many / spreading ──► ESCALATE (T2/IR) with full note
   │     ▼
   └─ ENRICH (intel, baseline, recent changes) feeds every step above
```

---

## §2 — Linux Investigation Commands

Triage = a fast first-look (the workflow from Lesson 16), then a decision:
```bash
bash scripts/log_triage.sh                 # consistent first-pass (auth/login/proc/net)
grep -F -f docs/detections/ioc-ips.txt /var/log/auth.log   # enrich: known-bad source?
last | grep <user> ; getent passwd <user>  # baseline: is this user/login normal?
ss -tunap | grep <ip>                       # scope: is the suspect IP still connected?
```
| Triage step | Linux | Wazuh |
|---|---|---|
| first look | `log_triage.sh` | the alert + its fields |
| enrich | `grep -f ioc` | intel match / VT panel |
| scope | `ss`, `ioc_sweep.sh` | search all agents for the indicator |
| baseline | `last`, history | user/host behavior analytics |

---

## §3 — Real-World Threat Context & Use Cases

- **The shift queue:** triage is most of the T1 day — speed + consistency are everything.
- **The escalation call:** escalate the right things (`soc/escalation-matrix.md`) — too early wastes
  T2, too late lets it spread.
- **Tuning the FPs:** every FP closed *without* a tuning action will refire forever — triage feeds
  detection engineering (Lesson 26).
- **Exam framing:** triage, severity, and escalation are core CySA+/Security+/BTL1/SC-200 (incident
  triage) topics.

---

## §4 — Detection

Triage is downstream of detection but *shapes* it: the FP/TP feedback from triage is the input to
tuning (raise threshold, add context, allowlist) — closing the detection loop. A SOC where triage
never feeds rule tuning is a SOC drowning in its own false positives.

---

## §5 — Investigation & Triage

This lesson *is* the triage half; investigation (Lessons 21–24) is the deep dive triage decides to
do. The art: **triage to the right depth** — enough to decide, not a full investigation on every
alert. The decision tree + a documented playbook keep that consistent.

---

## §6 — SOC Perspective

Triage quality = SOC quality. Severity sets escalation + SLA (`soc/soc-metrics-sla.md`); the case
records the decision (`soc/case-management.md`); alert fatigue is the constant enemy
(`soc/alert-triage.md`). "Walk me through how you triage an alert" is the most common SOC interview
question — your playbook is the answer.

---

## §7 — Incident-Response Perspective

Triage is IR Phase 1 (detect/confirm) + the gate to Phases 2+. A correct, fast triage decision
(especially the escalation call) sets MTTR. The triage note becomes the start of the incident
timeline if it escalates.

---

## §8 — Practical Lab (build this yourself)

**Goal:** write a triage playbook and run a mixed alert queue through it.

### Lens C — Manual → Automated → Why
- **Manual:** judge each alert ad-hoc.
- **Automated:** a decision-tree playbook + `log_triage.sh` enrichment so every analyst triages
  identically and fast.
- **Why:** consistency + speed = lower MTTR + fewer missed TPs; production adds SOAR auto-enrichment
  to pre-fill the triage context.

### Steps
1. Write `docs/playbooks/triage-playbook.md`: the decision tree (TP/FP→severity→scope→decide), the
   severity rubric (CIA + asset), and the escalation triggers.
2. Generate a **mixed queue** (lab): a brute force (drill 2), a single failed login, a port scan
   (drill 3), and a benign vuln-scan-style burst from your own box (the FP). 4 alerts.
3. Triage each through the playbook: write the TP/FP call (with reasoning), severity, scope, and
   decision. Tune the FP (note the rule change).
4. Open a `SOC-17` case per real alert; escalate the brute-force-with-success per the matrix (write
   the escalation note).
5. Record mock metrics (acknowledge time, decisions) — your MTTD/MTTR baseline.

### Lens D — the raw artifact
The triage call hinges on a tiny detail in the raw event: a `Failed password` storm is Sev3 —
*until* one `Accepted password` from the same IP appears, flipping it to Sev2 + escalate. Triage is
reading that detail fast and acting on it.

---

## §9 — GitHub Artifact (the 6-artifact evidence package)

1. **Script:** `scripts/log_triage.sh` (the enrichment first-look used in triage).
2. **Detection rule/config:** the FP tuning you applied (rule change note in `docs/detections/`).
3. **Runbook:** `docs/runbooks/runbook-triage.md` — per-alert triage steps.
4. **Playbook:** `docs/playbooks/triage-playbook.md` (the deliverable).
5. **Incident report + notes:** the worked mixed-queue (4 alerts triaged, 1 escalated, 1 FP tuned) +
   notes.
6. **SOC ticket:** `SOC-17` (Task: "triage playbook + worked queue") → Closed.

---

## §10 — Portfolio Artifact

- **Resume bullet:** "Authored a SOC alert-triage playbook (TP/FP, severity, scope, escalation) and
  worked a mixed alert queue end-to-end, tuning false positives and escalating confirmed
  intrusions."
- **Interview talking point:** walk your triage decision tree on the spot — the #1 SOC interview
  question — and reference your worked queue.
- **Serves:** Security Analyst → SOC T1 (Stages 1–2). **Completes the Wave-1 milestone** (write
  `PORTFOLIO.md`).

---

## §11 — Certification Crossover Notes

- **Security+:** IR/triage (4.x). **CySA+:** triage + IR. **SC-200:** incident triage in Sentinel.
  **BTL1:** triage. Detail: `alignment/CERTIFICATION-MAPPING.md`.

---

## §12 — Security Notes (Lens E — Attacker & Defender)

**🔴 Attacker:** generate noise to induce alert fatigue + bury the real action (T1499-ish noise,
decoy activity), and operate just under severity thresholds to be triaged as low-priority.

**🔵 Defender:** tune relentlessly (high-signal alerts resist fatigue), enrich to make TP/FP fast,
correlate so the buried TP surfaces, and never close an FP without tuning. The disciplined decision
tree is what keeps the buried Sev1 from being rubber-stamped as Sev4.

---

## Quiz (Interview-Style, Graded)

**Q1.** Walk your alert-triage decision tree from alert to decision.
> **Your answer:**

**Q2.** Distinguish true positive, false positive, benign true positive, and false negative — with
an example of each.
> **Your answer:**

**Q3.** How do you set severity, and what role do CIA + asset criticality play?
> **Your answer:**

**Q4.** **Scenario:** 30 alerts, one analyst, one is a confirmed successful login after brute force.
How do you prioritize, and what do you do with that one?
> **Your answer:**

**Q5.** Why must every closed false positive include a tuning action, and what's the risk if it
doesn't?
> **Your answer:**

*(Request the "Professional Answer" comparison under each before moving on.)*

---

## Reflection
*(After the quiz)* — What did you learn? · What confused you? · What would you do differently?

---

## Search Keywords For Further Understanding

**Core**
- `alert triage decision tree soc`
- `true positive false positive benign triage`
- `alert severity scoping`
- `alert fatigue tuning`
- `when to escalate security incident`

**Tools**
- `soc triage playbook example`
- `wazuh alert enrichment`

**Going further**
- `failed ssh login detection` (L18) · `detection engineering tuning` (L26) · `incident response` (L28)

**Red / Blue (Lens E):**
- 🔴 `alert fatigue exploitation`, `decoy noise`, `under-threshold operation`
- 🔵 `high-signal alerting`, `enrichment-driven triage`, `fp tuning loop`

---

## Lesson Status
- [ ] §8 lab completed (triage playbook + mixed queue worked; FP tuned; one escalated)
- [ ] 6-artifact evidence package committed (§9)
- [ ] Quiz answered + professional-answer comparisons (graded)
- [ ] Reflection + Search Keywords reviewed
- [ ] **Wave-1 PORTFOLIO.md** written (01–06 + 17 done)

When complete, run the Update Protocol, then move to **Lesson 18 — Failed SSH Login Detection**.

---

*Lesson 17 written by Navi · 2026-06-20 · full-depth. Sources to cite at study time: SANS SOC
triage, NIST SP 800-61, CySA+ incident-triage objectives.*
