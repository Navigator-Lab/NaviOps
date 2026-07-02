# Lesson 27 — Pure Practical: Sigma Rules Fundamentals

> **Companion to [`README.md`](./README.md).** Pure practice: 3 scenario tasks, guided → ticket-driven
> → on-call. **Lab:** author Sigma YAML; convert with `sigma`/`sigmac` (or by hand) to a Wazuh rule and
> test with `wazuh-logtest`. **Rules:** test every rule, run ✅ **Verify** each task.

Each task: **Scenario · Objective · Given/constraints · Hints · ✅ Verify · Pitfalls · 🎯 Stretch.**

---

## Task 1 — Guided: write a portable Sigma rule (fluency)

**Scenario.** `SOC-271`. Write a detection once in Sigma (vendor-neutral) so it can target any SIEM.

**Objective.** A valid Sigma YAML for a detection (e.g. failed logins) with logsource + detection +
condition.

**Given / constraints.** Valid Sigma structure. Map fields to the log you have.

**Hints.**
1. `title`, `logsource`, `detection` (selection + condition), `level`.
2. Keep field names to the log's real fields.
3. Validate the YAML.

✅ **Verify.**
```bash
python3 -c 'import yaml,sys; yaml.safe_load(open("rules/soc-271.yml"))' && echo "VALID SIGMA YAML ✅"
```

**Pitfalls.**
- Invalid YAML (indentation).
- Fields that don't exist in the target log.
- No `condition` (the logic).

🎯 **Stretch.** Add a `falsepositives` + `tags` (ATT&CK) section.

---

## Task 2 — Ticket-driven: convert + deploy a Sigma rule (diagnose → fix)

**Scenario.** `SOC-272` (P2). A Sigma rule needs to run in Wazuh but the conversion/mapping is off — it
doesn't fire. Fix the mapping.

**Objective.** The converted rule fires on the target log, identifying the field/format mismatch —
diagnose first.

**Given / constraints.** Convert to a Wazuh rule; test with `wazuh-logtest`. Fix field mapping.

**Hints.**
1. Convert (sigmac/pySigma or hand-translate to `<rule>`).
2. `wazuh-logtest` — does the field the rule checks get decoded?
3. Fix the mapping; re-test.

✅ **Verify.**
```bash
docker exec wazuh.manager sh -c 'echo "<sample>" | /var/ossec/bin/wazuh-logtest 2>/dev/null | grep -q "Rule id"' && echo "CONVERTED RULE FIRES ✅"
```

**Deliverable.** `docs/learning/reports/SOC-272-sigma-convert.md`: Sigma · conversion · mapping fix · test.

**Pitfalls.**
- Field names differ between Sigma abstraction and the real decoded field.
- Conversion done but never tested.
- Losing the condition logic in translation.

🎯 **Stretch.** Round-trip: keep the Sigma as source-of-truth, regenerate the Wazuh rule.

---

## Task 3 — On-call: a Sigma detection pack from threat intel (synthesis)

**Scenario.** `SOC-273` (time-boxed). Intel describes several TTPs. Author a portable Sigma pack, convert
+ test in the lab, and document coverage.

**Objective.** ≥3 valid Sigma rules mapped to ATT&CK, converted + tested; coverage note.

**Given / constraints.** Valid Sigma + tested conversions. Map to techniques.

**Hints.**
1. One rule per TTP; valid YAML; ATT&CK tags.
2. Convert + `wazuh-logtest` each.
3. Coverage note.

✅ **Verify.**
```bash
for f in rules/soc-273-*.yml; do python3 -c "import yaml;yaml.safe_load(open('$f'))" || echo "BAD $f"; done; echo "yaml checked"
test -f docs/learning/reports/SOC-273-sigma-pack.md && echo "PACK ✅"
```

**Deliverable.** `docs/learning/reports/SOC-273-sigma-pack.md`: TTP · Sigma rule · ATT&CK · test result.

**Pitfalls.**
- Rules that validate but never tested against real logs.
- No ATT&CK mapping.
- Untranslatable abstractions left unnoted.

🎯 **Stretch.** Publish the sanitized Sigma pack to the repo for portability.

---

## Done?
- [ ] All ✅ Verify pass · [ ] valid Sigma · [ ] conversions tested · [ ] pack mapped to ATT&CK.
- [ ] **Guardrails:** sanitized rules; no real data. → [README Reflection](./README.md).
