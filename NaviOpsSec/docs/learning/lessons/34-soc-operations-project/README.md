# Lesson 34 — SOC Operations Project

**Status:** ✅ ready for self-study (full depth) · **Date written:** 2026-06-20
**Schema:** 12-section SOC (`docs/learning/CLAUDE_TEACHING_RULES.md`) · **Type:** Project
**Focus:** operate a simulated **SOC shift** — triage a mixed alert queue, prioritize under SLA,
escalate, manage cases, and hand over. Exercises every `soc/` module at once.
**Full plan:** [`capstones/34-soc-operations-project.md`](../../capstones/34-soc-operations-project.md).

> Read §1–§7, execute §8 (the shift), produce §9, quiz, reflect. Then Lesson 35 (capstone).

---

## §1 — Concept (Scientific Theory)
This project integrates the *operational* layer: alert triage (L17), escalation (`soc/escalation-
matrix.md`), case management (`soc/case-management.md`), shift handover (`soc/shift-handover.md`), and
metrics (`soc/soc-metrics-sla.md`). It proves you can *run the SOC*, not just analyze one alert — the
day-to-day reality of a SOC analyst.

**Lens A:** *Beginner* — handle a whole shift of alarms: sort them, work the urgent ones, pass on the
big ones, log everything, brief the next shift. *Analyst* — triage a mixed queue (real + noise),
prioritize by severity/SLA, escalate per the matrix, document each case, write the handover + metrics.
*Adversary/Kernel* — the hard part is **prioritization under load** + not letting the buried Sev1 hide
in the Sev4 noise (alert fatigue).

**Lens B (a shift):** *technical* — concurrent case management against an SLA with prioritization +
escalation + continuity (handover). *Analogy* — a **busy ER shift**: many patients, triage by urgency,
treat or refer, chart everything, hand off to the next doctor with no dropped patients. *Breaks down:*
some "patients" (alerts) are adversarial decoys — prioritization must resist being gamed.

```
 mixed queue (real + noise) → triage+prioritize (SLA) → escalate/handle/close+tune → CASES
        → shift handover (open items + NEXT) + METRICS (handled/escalated/FP/MTTD-MTTR)
```

---

## §2 — Linux Investigation Commands
```bash
bash scripts/log_triage.sh                 # consistent first-look per alert
grep -F -f docs/detections/ioc-ips.txt ... # enrich during triage
# case + metrics tracking is documentation (soc/case-management.md, shift-handover.md)
```

---

## §3 — Real-World Threat Context & Use Cases
This *is* the SOC analyst's day. "Walk me through a shift / how do you prioritize / how do you hand
over" are top interview questions — answered by having actually done it. Applied across all SOC-ops
objectives (CySA+/SC-200/BTL1).

## §4 — Detection
The shift *consumes* detections (Lessons 18–24) as its queue; the project tests whether your
detections are triage-friendly (actionable, right severity) under real load — feedback to detection
engineering (every FP tuned during the shift).

## §5 — Investigation & Triage
The whole project is triage at scale: each alert through the decision tree (TP/FP→severity→scope→
decide), to the right depth, under SLA. Escalate the right ones with complete notes; close FPs *with*
tuning.

## §6 — SOC Perspective
This *is* the SOC perspective, integrated: tiers, queue, SLA, escalation, cases, handover, metrics —
every `soc/` module exercised together. The deliverables (cases + handover + metrics) are what a SOC
runs on.

## §7 — Incident-Response Perspective
The shift is where IR *starts* — T1 triage + the escalation decision feed the IR lifecycle. One queue
item should escalate into a full incident (handed to the capstone, Lesson 35).

---

## §8 — Practical Lab (the project)
Execute [`capstones/34-soc-operations-project.md`](../../capstones/34-soc-operations-project.md):
1. Generate a **mixed queue** (lab): brute force, port scan, new user, a vuln-scan FP, a noisy app —
   real incidents + noise, varied severities.
2. Run the shift: triage each (TP/FP, severity, scope), open a `SOC-NN` case, investigate to depth,
   decide (close+tune / handle / escalate).
3. Prioritize in SLA/severity order; escalate the qualifying ones with proper notes.
4. Manage cases (timeline + resolution each).
5. Write the shift-handover note + the shift metrics.

**Lens C:** `log_triage.sh` gives a consistent per-alert first-look so the shift is repeatable.
**Lens D:** the buried Sev1 is a detail in one alert among many — the shift tests whether you catch it.

---

## §9 — GitHub Artifact (the 6-artifact evidence package)
1. **Script:** `scripts/log_triage.sh` (shift first-look). 2. **Detection/config:** the FP tunings
applied during the shift. 3. **Runbook:** the shift runbook. 4. **Playbook:** triage + escalation
plays. 5. **Incident report + notes:** the case set + the shift-handover note + metrics. 6. **SOC
ticket:** `SOC-34` master + the per-alert cases → Closed. (Rubric in the plan.)

## §10 — Portfolio Artifact
- **Resume bullet:** "Operated a simulated SOC shift: triaged a mixed alert queue, prioritized under
  SLA, escalated per the matrix, managed cases end-to-end, and delivered a metrics-backed handover."
- **Interview talking point:** "walk me through your shift / how do you prioritize / how do you hand
  over" — answered from real practice. **Serves:** SecOps Engineer / SOC T1–T2 (Stages 2–5).

## §11 — Certification Crossover Notes
Applied SOC-operations across CySA+/SC-200/BTL1. Detail: `alignment/CERTIFICATION-MAPPING.md`.

## §12 — Security Notes (Lens E)
**🔴** attackers generate noise + decoys to induce fatigue + bury the real action, and strike during
thin/handover windows. **🔵** disciplined prioritization + tuning + clean handovers + metrics keep the
buried Sev1 from being missed and close the off-hour gaps.

---

## Quiz (Interview-Style, Graded)
**Q1.** Walk me through how you'd run a SOC shift from start to handover.
> **Your answer:**

**Q2.** 40 alerts, one analyst, one SLA — how do you prioritize?
> **Your answer:**

**Q3.** What makes a good shift-handover note?
> **Your answer:**

**Q4.** **Scenario:** mid-shift you realize a "low" alert from 2 hours ago was actually the start of
an intrusion. What do you do?
> **Your answer:**

**Q5.** Which SOC metrics would you report at end of shift, and why?
> **Your answer:**

*(Request the "Professional Answer" comparison under each before moving on.)*

---

## Reflection
*(After the project)* — What did you learn? · What confused you? · What would you do differently?

## Search Keywords For Further Understanding
- `soc shift operations triage queue` · `alert prioritization sla` · `soc shift handover` · `soc
  metrics mttd mttr` · 🔴 `decoy noise alert fatigue` · 🔵 `prioritization tuning clean handover`

---

## Lesson Status
- [ ] Project executed (mixed queue worked; cases + handover + metrics produced)
- [ ] 6-artifact evidence package committed (§9) · [ ] Quiz graded · [ ] Reflection + keywords

When complete, run the Update Protocol, then move to **Lesson 35 — Security Analyst Capstone**.

---
*Lesson 34 written by Navi · 2026-06-20 · full-depth. Plan: `capstones/34-soc-operations-project.md`.*
