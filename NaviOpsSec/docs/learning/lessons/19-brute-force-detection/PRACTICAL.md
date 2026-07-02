# Lesson 19 — Pure Practical: Brute-Force Detection

> **Companion to [`README.md`](./README.md).** Pure practice: 3 scenario tasks, guided → ticket-driven
> → on-call. **Lab:** brute the victim (port 2222) → Wazuh frequency rule. **Rules:** test the rule,
> run ✅ **Verify** each task.

Each task: **Scenario · Objective · Given/constraints · Hints · ✅ Verify · Pitfalls · 🎯 Stretch.**

---

## Task 1 — Guided: trigger the brute-force (frequency) rule (fluency)

**Scenario.** `SOC-191`. Generate enough failures fast enough to trip the *frequency* rule (not just a
single-failure rule) — the essence of brute-force detection.

**Objective.** The brute-force composite alert fires (N failures in T seconds).

**Given / constraints.** Generate a burst; confirm the frequency rule (e.g. 5712) fires above the base.

**Hints.**
1. `for i in $(seq 12); do sshpass -p wrong ssh -o StrictHostKeyChecking=no root@localhost -p 2222 true; done`.
2. The composite/frequency rule fires only after the threshold.
3. Confirm the higher-level alert.

✅ **Verify.**
```bash
docker exec wazuh.manager sh -c 'grep -qiE "5712|multiple auth|brute" /var/ossec/logs/alerts/alerts.log' && echo "BRUTE-FORCE RULE ✅"
```

**Pitfalls.**
- Too few/slow attempts → threshold not met.
- Confusing the single-failure rule with the frequency rule.
- Wrong timeframe.

🎯 **Stretch.** Tune the threshold and observe how it changes sensitivity vs noise.

---

## Task 2 — Ticket-driven: "brute-force alert — real or scanner noise?" (diagnose)

**Scenario.** `SOC-192` (P2). A brute-force alert fired. Determine attacker intent + whether it
succeeded.

**Objective.** Characterize the attack (source, target accounts, success?) and give a verdict.

**Given / constraints.** Corroborate. Check for a success amid the failures.

**Hints.**
1. Source(s), targeted usernames, rate.
2. Any accepted login after the failures?
3. Verdict + recommended action.

✅ **Verify.**
```bash
grep -qiE 'succeeded|no success|verdict' docs/learning/reports/SOC-192-verdict.md && echo "VERDICT ✅"
```

**Deliverable.** `docs/learning/reports/SOC-192-verdict.md`: source · targets · success? · verdict · action.

**Pitfalls.**
- Missing a successful login in the noise.
- Verdict without checking targeted accounts.
- No action.

🎯 **Stretch.** Distinguish spray (many users, few tries) vs brute (one user, many tries).

---

## Task 3 — On-call: distributed brute-force / password spray (synthesis)

**Scenario.** `SOC-193` (P1, time-boxed). Attempts come from many sources (distributed) or across many
accounts (spray) — harder to catch by per-source thresholds. Detect, contain, document.

**Objective.** Detect the distributed pattern, contain appropriately, and write an IR note with a
detection improvement.

**Given / constraints.** Generate from varied sources/accounts. Per-source thresholds may miss it.

**Hints.**
1. Aggregate by *target account* and by *time*, not just per source IP.
2. Contain (account lockout / MFA / block source ranges).
3. Note why per-source detection missed it → detection improvement.

✅ **Verify.**
```bash
test -f docs/learning/reports/SOC-193-distributed.md && grep -qiE 'spray|distributed|detection' docs/learning/reports/SOC-193-distributed.md && echo "IR NOTE ✅"
```

**Deliverable.** `docs/learning/reports/SOC-193-distributed.md`: pattern · why missed · containment · new detection · MITRE T1110.

**Pitfalls.**
- Per-source thresholds blind to distributed attacks.
- Blocking one IP while others continue.
- No detection improvement.

🎯 **Stretch.** Write a rule that aggregates failures by account across sources.

---

## Done?
- [ ] All ✅ Verify pass · [ ] frequency rule fired · [ ] distributed pattern detected + new detection.
- [ ] **Guardrails:** fake sources only. → [README Reflection](./README.md).
