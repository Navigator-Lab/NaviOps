# Lesson 28 — Pure Practical: SIEM / SOC Alert Triage

> **Companion to [`README.md`](./README.md).** Pure practice: 3 scenario tasks, guided → ticket-driven
> → on-call. Do them after the README.
>
> **Lab:** Wazuh/ELK from L23, or log rules on `naviops-web`. **Artifact:** `scripts/alert_triage.sh`.
> **Rules:** type it, evidence before verdict, run ✅ **Verify** each task.

Each task: **Scenario · Objective · Given/constraints · Hints · ✅ Verify · Pitfalls · 🎯 Stretch.**

---

## Task 1 — Guided: triage a queue of alerts by priority (fluency)

**Scenario.** `NAVI-281`. A SOC shift starts with a backlog of alerts of mixed severity. Triage them
into a priority order with a documented rationale (the daily analyst job).

**Objective.** Classify each alert (severity × asset criticality × confidence), order the queue, and
record why — top items first.

**Given / constraints.** A sample alert set (JSON/CSV). Consistent scoring; highest business risk first.

**Hints.**
1. Score = severity × asset value × fidelity (true-positive likelihood).
2. `scripts/alert_triage.sh` can sort/summarize the queue; enrich with asset context.
3. Document the ordering rationale — an analyst must justify prioritization.

✅ **Verify.**
```bash
scripts/alert_triage.sh alerts.json | head    # sorted, highest-risk first
grep -qi 'rationale\|priority' /tmp/triage.md && echo "RATIONALE RECORDED ✅"
```

**Pitfalls.**
- Sorting by raw severity only, ignoring asset criticality (a "medium" on a crown-jewel beats a "high" on a test box).
- No documented rationale → inconsistent triage across analysts.
- Ignoring alert fidelity (known-noisy rules).

🎯 **Stretch.** Add a de-duplication/grouping step so 50 alerts from one event become one case.

---

## Task 2 — Ticket-driven: TP vs FP investigation (diagnose → verdict)

**Scenario.** `NAVI-282` (P2). A single alert lands ("suspicious PowerShell/curl to a rare domain").
Decide true-positive vs false-positive with evidence, and act accordingly.

**Objective.** Reach a defensible TP/FP verdict by gathering context (who/what/when/where), and either
escalate (TP) or tune the rule (FP) — **evidence before verdict.**

**Given / constraints.** A planted event + surrounding logs. No verdict without corroborating evidence
from ≥2 sources.

**Hints.**
1. Pivot: user, host, process tree, network destination, timing — correlate across log sources.
2. Benign explanation? (a known admin task / change ticket). Malicious indicators? (rare domain, off-hours, unusual parent process).
3. FP → tune the rule (exception, not disable). TP → escalate with the evidence package.

✅ **Verify.**
```bash
grep -qiE 'true positive|false positive' /tmp/verdict.md && echo "VERDICT ✅"
grep -ci 'evidence' /tmp/verdict.md        # ≥2 corroborating items
```

**Pitfalls.**
- Verdict on a hunch without corroboration.
- Disabling a noisy rule wholesale (FP) instead of a targeted exception → blinds you.
- Escalating every alert (analyst fatigue) or none (missed breach).

🎯 **Stretch.** Write the FP tuning as a rule exception and prove the benign case no longer alerts while the malicious one still does.

---

## Task 3 — On-call: multi-stage attack — build the kill chain (synthesis)

**Scenario.** `NAVI-283` (P1, time-boxed). Several alerts across hosts look related. Reconstruct the
attack chain (initial access → execution → persistence → exfil), scope impact, respond, and report.

**Objective.** Correlate the alerts into a single incident timeline mapped to MITRE ATT&CK, contain,
and write an IR report with IoCs and affected assets.

**Given / constraints.** Multiple planted, related events. Timebox 20 min. Contain without destroying
evidence; map each stage to a technique.

**Hints.**
1. Group by entity (host/user) and time; build one timeline across sources.
2. Map each step to a MITRE tactic/technique; identify the entry point.
3. Contain the active stage (isolate host/disable account), collect IoCs, list affected assets.

✅ **Verify.**
```bash
grep -ciE 'T[0-9]{4}' docs/learning/reports/NAVI-283-ir-report.md    # ≥ number of stages mapped
grep -qi 'kill chain\|timeline' docs/learning/reports/NAVI-283-ir-report.md && echo "CHAIN BUILT ✅"
```

**Deliverable.** `docs/learning/reports/NAVI-283-ir-report.md`: timeline · MITRE mapping · entry point · affected assets · IoCs · containment · recommendations.

**Pitfalls.**
- Treating related alerts as separate incidents → miss the campaign.
- Containing loudly and tipping off the attacker before scoping.
- No IoCs/detections produced → the same actor returns undetected.

🎯 **Stretch.** Turn each unmapped step into a new detection rule; verify with `wazuh-logtest`.

---

## Done?
- [ ] All ✅ Verify pass · [ ] verdicts backed by ≥2 evidence sources · [ ] kill chain + MITRE mapped · [ ] IR report written.
- [ ] **Redaction:** fake IoCs/domains only. → [README Step 7](./README.md).
