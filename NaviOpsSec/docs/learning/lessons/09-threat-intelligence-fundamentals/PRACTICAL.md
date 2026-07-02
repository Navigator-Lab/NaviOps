# Lesson 09 — Pure Practical: Threat Intelligence Fundamentals

> **Companion to [`README.md`](./README.md).** Pure practice: 3 scenario tasks, guided → ticket-driven
> → on-call. **Lab:** Wazuh + victim; enrich lab alerts with (offline/sanitized) intel. **Rules:**
> evidence before verdict, run ✅ **Verify** each task.

Each task: **Scenario · Objective · Given/constraints · Hints · ✅ Verify · Pitfalls · 🎯 Stretch.**

---

## Task 1 — Guided: enrich an indicator (fluency)

**Scenario.** `SOC-091`. Take an IoC from a lab alert and enrich it with context (type, confidence,
TLP) — the analyst-to-intel workflow.

**Objective.** A structured enrichment record for one indicator.

**Given / constraints.** Use a lab-generated IoC (e.g. the brute-force source). Offline/sanitized only.

**Hints.**
1. Classify the IoC (IP/hash/domain), note where seen, first/last seen.
2. Assign confidence + TLP handling.
3. Record structured (STIX-like fields, even in markdown).

✅ **Verify.**
```bash
test -f docs/learning/reports/SOC-091-enrichment.md && grep -qiE 'confidence|tlp|indicator' docs/learning/reports/SOC-091-enrichment.md && echo "ENRICHED ✅"
```

**Pitfalls.**
- IoC with no context (useless).
- No confidence/TLP → mishandling.
- Treating a single IP as high-fidelity without corroboration.

🎯 **Stretch.** Map the IoC to a likely tactic (feeds L10 MITRE).

---

## Task 2 — Ticket-driven: is this indicator actionable? (diagnose → decide)

**Scenario.** `SOC-092` (P2). *"Intel feed flagged an indicator seen in our logs — act or ignore?"*
Decide with context.

**Objective.** A defensible act/ignore decision on the indicator, with confidence + rationale.

**Given / constraints.** Weigh source reliability + relevance. Avoid acting on low-fidelity noise.

**Hints.**
1. Source reliability + indicator confidence + relevance to your assets.
2. Corroborate in your own logs (did it actually interact?).
3. Decide + document; if act, what action.

✅ **Verify.**
```bash
grep -qiE 'act|ignore|confidence' docs/learning/reports/SOC-092-actionable.md && echo "DECISION ✅"
```

**Deliverable.** `docs/learning/reports/SOC-092-actionable.md`: indicator · source reliability · local corroboration · decision.

**Pitfalls.**
- Blocking on every feed indicator (noise, false positives).
- Ignoring without checking local relevance.
- No source-reliability weighting.

🎯 **Stretch.** Propose an automated enrichment step in the SIEM pipeline.

---

## Task 3 — On-call: intel-driven hunt (synthesis)

**Scenario.** `SOC-093` (P1, time-boxed). New intel describes a TTP. Hunt your lab logs for it, confirm
presence/absence with evidence, and report.

**Objective.** Translate the TTP into log queries, hunt, and produce a findings report.

**Given / constraints.** Plant (or not) the TTP. Evidence-based presence/absence.

**Hints.**
1. Turn the TTP into concrete log signatures/queries.
2. Hunt across sources; record hits with evidence.
3. Report presence/absence + recommended detection.

✅ **Verify.**
```bash
test -f docs/learning/reports/SOC-093-intel-hunt.md && grep -qiE 'found|not found|hunt' docs/learning/reports/SOC-093-intel-hunt.md && echo "HUNT REPORT ✅"
```

**Deliverable.** `docs/learning/reports/SOC-093-intel-hunt.md`: TTP · queries · findings (evidence) · new detection.

**Pitfalls.**
- Hunting without translating the TTP into concrete queries.
- "Not found" without showing what you searched.
- No detection produced from the hunt.

🎯 **Stretch.** Convert the hunt query into a persistent Wazuh/Sigma rule (feeds L27).

---

## Done?
- [ ] All ✅ Verify pass · [ ] indicators enriched with confidence/TLP · [ ] intel-hunt reported.
- [ ] **Guardrails:** sanitized/offline IoCs only; TLP respected. → [README Reflection](./README.md).
