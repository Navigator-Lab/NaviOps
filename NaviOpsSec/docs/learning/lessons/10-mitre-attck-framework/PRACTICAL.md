# Lesson 10 — Pure Practical: MITRE ATT&CK Framework

> **Companion to [`README.md`](./README.md).** Pure practice: 3 scenario tasks, guided → ticket-driven
> → on-call. **Lab:** Wazuh (maps rules to ATT&CK) + victim. **Rules:** map with evidence, run ✅
> **Verify** each task.

Each task: **Scenario · Objective · Given/constraints · Hints · ✅ Verify · Pitfalls · 🎯 Stretch.**

---

## Task 1 — Guided: map lab alerts to ATT&CK techniques (fluency)

**Scenario.** `SOC-101`. Generate activity and map each resulting alert to its ATT&CK tactic/technique —
the common SOC language.

**Objective.** ≥3 lab alerts mapped to specific technique IDs (e.g. T1110 brute force).

**Given / constraints.** Generate the activity; use Wazuh's ATT&CK mapping + your own reasoning.

**Hints.**
1. Brute-force ssh → T1110. Recon → T1046. Log clearing → T1070.
2. Wazuh often tags rules with technique IDs — verify, don't just trust.
3. Record alert → tactic → technique.

✅ **Verify.**
```bash
docker exec wazuh.manager sh -c 'grep -qiE "T1110|mitre" /var/ossec/logs/alerts/alerts.log 2>/dev/null' && echo "ATT&CK-TAGGED ALERTS ✅"
test -f docs/learning/reports/SOC-101-attack-map.md && echo "MAP ✅"
```

**Pitfalls.**
- Mapping to a tactic but not a technique (too vague).
- Trusting the tool's tag without validating the behavior.
- Forcing a mapping where none fits.

🎯 **Stretch.** Place your mapped techniques on an ATT&CK Navigator layer.

---

## Task 2 — Ticket-driven: identify the technique behind an alert (diagnose)

**Scenario.** `SOC-102` (P2). An alert fires; leadership wants the ATT&CK technique + what it implies for
next attacker steps.

**Objective.** Correct technique ID with evidence + the likely adjacent techniques (what comes next).

**Given / constraints.** Evidence-based mapping. Note the kill-chain neighbors.

**Hints.**
1. From the raw behavior → the precise technique (and sub-technique if clear).
2. Adjacent tactics: what typically follows (e.g. valid accounts → lateral movement).
3. Recommend where to look next.

✅ **Verify.**
```bash
grep -qiE 'T[0-9]{4}' docs/learning/reports/SOC-102-technique.md && echo "TECHNIQUE IDENTIFIED ✅"
```

**Deliverable.** `docs/learning/reports/SOC-102-technique.md`: behavior · technique ID · evidence · likely next techniques.

**Pitfalls.**
- Wrong technique from a superficial read.
- Not anticipating the next step (misses proactive hunting).
- Sub-technique guessed without evidence.

🎯 **Stretch.** Build a mini "if you see X, hunt for Y" playbook from the adjacency.

---

## Task 3 — On-call: reconstruct a multi-technique intrusion (synthesis)

**Scenario.** `SOC-103` (P1, time-boxed). Several alerts across the kill chain. Map them into an ATT&CK
storyline (initial access → … → impact) and report coverage gaps.

**Objective.** A technique-by-technique storyline of the intrusion + which stages you had no detection for.

**Given / constraints.** Multiple planted, related activities. Map the full chain; flag detection gaps.

**Hints.**
1. Order the techniques by tactic (the attacker's progression).
2. Which stages did you detect vs miss?
3. Recommend detections for the gaps.

✅ **Verify.**
```bash
grep -ciE 'T[0-9]{4}' docs/learning/reports/SOC-103-storyline.md   # ≥ number of stages
grep -qi 'gap' docs/learning/reports/SOC-103-storyline.md && echo "GAPS FLAGGED ✅"
```

**Deliverable.** `docs/learning/reports/SOC-103-storyline.md`: ordered techniques · evidence · detection coverage · gaps.

**Pitfalls.**
- Listing techniques out of attacker order.
- Not identifying blind spots (the actionable part).
- Over-mapping (assigning techniques without evidence).

🎯 **Stretch.** Turn gap detections into an ATT&CK Navigator "coverage" layer.

---

## Done?
- [ ] All ✅ Verify pass · [ ] techniques mapped with evidence · [ ] coverage gaps flagged.
- [ ] **Guardrails:** no real IoCs committed. → [README Reflection](./README.md).
