# Lesson 18 — Pure Practical: Failed SSH Login Detection

> **Companion to [`README.md`](./README.md).** Pure practice: 3 scenario tasks, guided → ticket-driven
> → on-call. **Lab:** brute the victim's sshd (port 2222) → Wazuh detects. **Rules:** test the rule,
> run ✅ **Verify** each task.

Each task: **Scenario · Objective · Given/constraints · Hints · ✅ Verify · Pitfalls · 🎯 Stretch.**

---

## Task 1 — Guided: detect failed SSH logins (fluency)

**Scenario.** `SOC-181`. Generate failed SSH logins and confirm Wazuh's authentication-failure rule fires.

**Objective.** Failed-login alerts present with source + count.

**Given / constraints.** Generate failures against port 2222; confirm the alert.

**Hints.**
1. `for i in $(seq 5); do sshpass -p wrong ssh -o StrictHostKeyChecking=no root@localhost -p 2222 true; done`.
2. Wazuh rule 5710/5712 (auth failure). Confirm in `alerts.log`/dashboard.
3. Note source IP + count.

✅ **Verify.**
```bash
docker exec wazuh.manager sh -c 'grep -qiE "authentication fail|5710|5712" /var/ossec/logs/alerts/alerts.log' && echo "FAILED-LOGIN DETECTED ✅"
```

**Pitfalls.**
- Watching the wrong log path.
- One failure ≠ meaningful (need volume for brute-force).
- Not recording the source IP (the IoC).

🎯 **Stretch.** Distinguish a single fat-finger from a pattern.

---

## Task 2 — Ticket-driven: triage a failed-login alert (diagnose → verdict)

**Scenario.** `SOC-182` (P2). A failed-login alert fires. Decide: user typo vs attack — with evidence.

**Objective.** TP/FP verdict backed by frequency, source, and timing.

**Given / constraints.** Corroborate before deciding.

**Hints.**
1. How many failures, from where, over what window? Followed by a success?
2. One-off from a known host = likely benign; many from a rare source = attack.
3. Verdict + evidence.

✅ **Verify.**
```bash
grep -qiE 'true positive|false positive' docs/learning/reports/SOC-182-verdict.md && echo "VERDICT ✅"
```

**Deliverable.** `docs/learning/reports/SOC-182-verdict.md`: alert · frequency/source/timing · verdict · action.

**Pitfalls.**
- Verdict on count alone (context matters).
- Missing a failure→success (successful breach!).
- No action.

🎯 **Stretch.** Check whether any failure was followed by a success from the same source (compromise).

---

## Task 3 — On-call: credential attack in progress (synthesis)

**Scenario.** `SOC-183` (P1, time-boxed). Sustained failed logins + a possible success. Contain the
source, determine if any account was compromised, and write an IR note.

**Objective.** Contain the attacker, confirm/deny compromise, and document with IoCs.

**Given / constraints.** Generate a burst (+ optionally a success). Contain by rule; preserve evidence.

**Hints.**
1. Confirm the attack scope (sources, targeted accounts).
2. Any success? Treat that account as compromised (disable, force reset).
3. Contain the source; IoCs; document.

✅ **Verify.**
```bash
docker exec wazuh.manager sh -c 'grep -qiE "authentication success|accepted" /var/ossec/logs/alerts/alerts.log 2>/dev/null' ; echo "checked for success-after-failures"
test -f docs/learning/reports/SOC-183-cred-attack.md && echo "IR NOTE ✅"
```

**Deliverable.** `docs/learning/reports/SOC-183-cred-attack.md`: scope · compromise verdict · containment · IoCs · MITRE T1110.

**Pitfalls.**
- Blocking the source but ignoring a compromised account.
- No IoCs.
- Not mapping to T1110 (brute force).

🎯 **Stretch.** Add fail2ban-style active response (auto-block) and prove it.

---

## Done?
- [ ] All ✅ Verify pass · [ ] checked failure→success · [ ] IR note with IoCs + T1110.
- [ ] **Guardrails:** fake sources only; no real IPs. → [README Reflection](./README.md).
