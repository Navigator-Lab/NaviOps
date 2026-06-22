# Lesson 32 — Wazuh Detection Project

**Status:** ✅ ready for self-study (full depth) · **Date written:** 2026-06-20
**Schema:** 12-section SOC (`docs/learning/CLAUDE_TEACHING_RULES.md`) · **Type:** Project
**Focus:** engineer a tested, tuned **detection set** (rules + decoders + FIM + active response)
covering **≥5 MITRE ATT&CK techniques**, with a coverage map + a portable Sigma rule.
**Full plan:** [`capstones/32-wazuh-detection-project.md`](../../capstones/32-wazuh-detection-project.md).

> Read §1–§7, execute §8 (the project), produce §9, quiz, reflect. Then Lesson 33.

---

## §1 — Concept (Scientific Theory)
This project is detection engineering (Lesson 26) at scale: take everything from Lessons 15, 18–24,
27 and produce a **coherent, tested, ATT&CK-mapped detection set** — your detection-engineering
portfolio piece. It proves you can *build coverage*, not just one rule.

**Lens A:** *Beginner* — write a bunch of good, tested alarms for the common attacks. *Analyst* —
author rules/decoders/FIM/active-response for ≥5 techniques across ≥2 tactics, test each
(`wazuh-logtest` + real telemetry), tune FPs, and map coverage. *Adversary/Kernel* — the engineering
goal is durable (TTP-keyed), tested, tuned detections with measured coverage — resilient to evasion +
log drift.

**Lens B (a detection set):** *technical* — a version-controlled, tested ruleset with documented
coverage + FP analysis. *Analogy* — outfitting the **whole building with the right sensors in the
right places**, each tested, with a map showing what's covered + the gaps. *Breaks down:* coverage is
never 100% — you prioritize by threat model + intel (Lessons 08–10).

```
 ≥5 ATT&CK techniques → rules + decoders + FIM + active-response → TEST each → TUNE FPs → COVERAGE MAP
        └────────── +1 authored as Sigma → convert → portable ──────────┘
```

---

## §2 — Linux Investigation Commands
```bash
/var/ossec/bin/wazuh-logtest                 # test each rule against sample telemetry
bash scripts/rule_test.sh samples/           # regression-test the whole set
sigma convert -t wazuh docs/detections/sigma/*.yml   # portable rule → Wazuh
jq '.rule.id' /var/ossec/logs/alerts/alerts.json | sort | uniq -c   # firing/FP check
```

---

## §3 — Real-World Threat Context & Use Cases
Building + tuning a detection set for prioritized ATT&CK techniques is the core Detection Engineer
job. The deliverable (ruleset + coverage map + Sigma) is exactly what a detection-eng interview wants
to see. Applied CySA+/SC-200/BTL1 detection objectives.

## §4 — Detection
The project *is* detection engineering: pick ≥5 techniques (e.g. T1110, T1078, T1136, T1053, T1059,
T1070, T1565), build rules/decoders/FIM/active-response, **test each** (fires on TP, quiet on benign),
**tune** (documented FP analysis), and **map** (technique→rule→tested?→tuned?). Author ≥1 as Sigma.

## §5 — Investigation & Triage
Each rule must be triage-friendly: actionable description, right level/severity, ATT&CK tag, runbook
link. Tuning uses triage feedback (Lesson 17) — the FP analysis is part of the deliverable.

## §6 — SOC Perspective
This produces the SOC's detection content — its IP + the detection engineer's portfolio. The coverage
map is what you show leadership ("we cover these techniques; here are the gaps + plan"). Builds on
Lessons 15/26.

## §7 — Incident-Response Perspective
A good detection set means incidents are caught *in Phase 2* fast (low MTTD); the active-response piece
enables fast containment (Lesson 29). The set should include the detections that would catch the
capstone's attack chain (Lesson 35).

---

## §8 — Practical Lab (the project)
Execute [`capstones/32-wazuh-detection-project.md`](../../capstones/32-wazuh-detection-project.md):
1. Pick ≥5 ATT&CK techniques across ≥2 tactics.
2. Write the detections: `local_rules.xml` (+ decoders), `fim.conf`, one active-response (lab).
3. Test each (`wazuh-logtest` + generate the benign telemetry); confirm correct level/group.
4. Tune: generate benign look-alikes, eliminate FPs, document each decision.
5. Build `docs/detections/attack-coverage.md`; author ≥1 rule as Sigma + convert.

**Lens C:** `rule_test.sh` regression-tests the set (CI for detections). **Lens D:** each rule keys
on a concrete artifact (the log/audit/FIM line) — verify the decode for each.

---

## §9 — GitHub Artifact (the 6-artifact evidence package)
1. **Script:** `scripts/rule_test.sh`. 2. **Detection/config:** `infra/wazuh/local_rules.xml` +
decoders + `fim.conf` + active-response + `docs/detections/sigma/`. 3. **Runbook:** per-rule runbooks.
4. **Playbook:** the detection-set build play. 5. **Incident report + notes:** the detection-set report
(what each catches, FP analysis). 6. **SOC ticket:** `SOC-32` → Closed. (Rubric in the plan.)

## §10 — Portfolio Artifact
- **Resume bullet:** "Engineered a tested, FP-tuned Wazuh detection set covering 5+ MITRE ATT&CK
  techniques (rules, decoders, FIM, active response) + a coverage map + a portable Sigma rule."
- **Interview talking point:** walk the coverage map + a tuning decision + the Sigma portability.
  **Serves:** Junior Detection Engineer (Stage 4) — the headline detection-eng artifact.

## §11 — Certification Crossover Notes
Applied detection/analytics across CySA+/SC-200/BTL1. Detail: `alignment/CERTIFICATION-MAPPING.md`.

## §12 — Security Notes (Lens E)
**🔴** attackers use techniques in your gaps + evade threshold-only rules. **🔵** broad, durable
(TTP-keyed), tested, tuned coverage mapped to ATT&CK — and validated against evasion (purple-team the
set).

---

## Quiz (Interview-Style, Graded)
**Q1.** How do you choose which techniques to cover first?
> **Your answer:**

**Q2.** What makes a detection "done" (the lifecycle criteria)?
> **Your answer:**

**Q3.** How do you tune a noisy rule without creating a blind spot?
> **Your answer:**

**Q4.** **Scenario:** present your coverage map to a manager — how do you explain coverage + gaps +
plan?
> **Your answer:**

**Q5.** Why author at least one rule in Sigma?
> **Your answer:**

*(Request the "Professional Answer" comparison under each before moving on.)*

---

## Reflection
*(After the project)* — What did you learn? · What confused you? · What would you do differently?

## Search Keywords For Further Understanding
- `wazuh detection set engineering` · `att&ck coverage map` · `detection tuning false positives` ·
  `sigma to wazuh` · 🔴 `coverage gap evasion` · 🔵 `tested tuned att&ck-mapped detections`

---

## Lesson Status
- [ ] Project executed (≥5 techniques, tested, tuned, coverage-mapped, ≥1 Sigma)
- [ ] 6-artifact evidence package committed (§9) · [ ] Quiz graded · [ ] Reflection + keywords

When complete, run the Update Protocol, then move to **Lesson 33 — Threat Hunting Project**.

---
*Lesson 32 written by Navi · 2026-06-20 · full-depth. Plan: `capstones/32-wazuh-detection-project.md`.*
