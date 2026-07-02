# Lesson 15 — Pure Practical: Wazuh Rules & Alerts

> **Companion to [`README.md`](./README.md).** Pure practice: 3 scenario tasks, guided → ticket-driven
> → on-call. **Lab:** manager `docker exec -it wazuh.manager bash`; test with `wazuh-logtest`; content in
> `infra/wazuh/local_rules.xml`. **Rules:** test every rule, run ✅ **Verify** each task.

Each task: **Scenario · Objective · Given/constraints · Hints · ✅ Verify · Pitfalls · 🎯 Stretch.**

---

## Task 1 — Guided: write a custom rule + decoder (fluency)

**Scenario.** `SOC-151`. Write a custom rule that alerts on a specific log line, validated with
`wazuh-logtest`.

**Objective.** A custom rule in `local_rules.xml` that fires on a sample line at the intended level.

**Given / constraints.** Add a decoder if needed. Validate with `wazuh-logtest` before relying on it.

**Hints.**
1. Add the rule (`<rule id="100001" level="10">` + `<match>`/`<field>`), reload.
2. `wazuh-logtest` — paste a matching line → confirm your rule id fires.
3. Confirm a non-matching line does *not* fire.

✅ **Verify.**
```bash
docker exec wazuh.manager sh -c 'echo "<your sample line>" | /var/ossec/bin/wazuh-logtest 2>/dev/null | grep -q "100001"' && echo "CUSTOM RULE FIRES ✅"
```

**Pitfalls.**
- Rule with no decoder to extract fields → never matches.
- Level too low → filtered out.
- Overly broad `<match>` → false positives.

🎯 **Stretch.** Add a frequency rule (N events in T seconds) on top of the base rule.

---

## Task 2 — Ticket-driven: "custom rule isn't firing" (diagnose → fix)

**Scenario.** `SOC-152` (P2). *"I wrote a rule but it doesn't alert on the real events."* Debug the
decoder/rule chain.

**Objective.** Make the rule fire on the real log, identifying decoder mismatch, wrong parent, or bad
regex — diagnose first.

**Given / constraints.** Recreate a subtly-broken rule. Fix via `wazuh-logtest` feedback.

**Hints.**
1. `wazuh-logtest` shows which decoder + rule matched (or none) — read it.
2. Does the field your rule references get extracted by the decoder?
3. Correct parent rule / regex / field; re-test.

✅ **Verify.**
```bash
docker exec wazuh.manager sh -c 'echo "<real line>" | /var/ossec/bin/wazuh-logtest 2>/dev/null | grep -q "<rule id>"' && echo "FIRES ON REAL LOG ✅"
```

**Deliverable.** `docs/learning/reports/SOC-152-rule-debug.md`: symptom · logtest output · fix · verification.

**Pitfalls.**
- Rule references a field the decoder never sets.
- Wrong `if_sid`/parent chain.
- Not using `wazuh-logtest` (guessing).

🎯 **Stretch.** Add a unit-test-style set of sample lines (should/shouldn't match).

---

## Task 3 — On-call: rule causing alert storm / missing a real attack (synthesis)

**Scenario.** `SOC-153` (P1, time-boxed). Either a rule is flooding or a real attack slipped past. Tune
for fidelity (catch the TP, suppress noise) and document.

**Objective.** A tuned rule set that fires on the attack and not on the benign case; documented with
test cases.

**Given / constraints.** Prove both cases with `wazuh-logtest`. Exceptions, not blanket disable.

**Hints.**
1. Identify the noisy/missing rule.
2. Add a scoped exception (benign) and/or tighten to catch the TP.
3. Prove both with `wazuh-logtest`.

✅ **Verify.**
```bash
docker exec wazuh.manager sh -c 'echo "<malicious>" | /var/ossec/bin/wazuh-logtest 2>/dev/null | grep -q "<rule>"' && \
docker exec wazuh.manager sh -c 'echo "<benign>" | /var/ossec/bin/wazuh-logtest 2>/dev/null | grep -q "<rule>" && echo NO || echo yes' | grep -q yes && echo "FIDELITY TUNED ✅"
test -f docs/learning/reports/SOC-153-fidelity.md && echo "REPORT ✅"
```

**Deliverable.** `docs/learning/reports/SOC-153-fidelity.md`: rule · TP test · FP test · tuning · result.

**Pitfalls.**
- Disabling the rule (blinds you).
- Tuning that kills the true positive.
- No documented test cases.

🎯 **Stretch.** Commit the sanitized rule + test cases to `infra/wazuh/`.

---

## Done?
- [ ] All ✅ Verify pass · [ ] rules validated with logtest · [ ] fidelity proven both ways.
- [ ] **Guardrails:** sanitized rules only; no real data. → [README Reflection](./README.md).
