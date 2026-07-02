# Lesson 22 — Pure Practical: User Account Investigation

> **Companion to [`README.md`](./README.md).** Pure practice: 3 scenario tasks, guided → ticket-driven
> → on-call. **Lab:** `docker exec -it siem-victim bash` + Wazuh. **Rules:** evidence before verdict,
> preserve evidence, run ✅ **Verify** each task.

Each task: **Scenario · Objective · Given/constraints · Hints · ✅ Verify · Pitfalls · 🎯 Stretch.**

---

## Task 1 — Guided: audit accounts + privileges (fluency)

**Scenario.** `SOC-221`. Enumerate who can log in, who can escalate, and who's UID 0 — the account
attack surface.

**Objective.** A report of login-capable users, sudo/wheel members, UID-0 accounts, and last logins.

**Given / constraints.** Read-only. Flag anything unexpected.

**Hints.**
1. UID 0: `awk -F: '$3==0' /etc/passwd`. Shells: `getent passwd | grep -v nologin`.
2. Privilege: `getent group sudo wheel`. Logins: `last`, `lastlog`.
3. Flag anomalies.

✅ **Verify.**
```bash
docker exec siem-victim sh -c 'awk -F: "\$3==0{print \$1}" /etc/passwd | grep -q root' && echo "ACCOUNT AUDIT ✅"
test -f docs/learning/reports/SOC-221-account-audit.md && echo "REPORT ✅"
```

**Pitfalls.**
- Assuming only root is UID 0 (a backdoor can share it).
- Ignoring dormant accounts with shells.
- No baseline to compare against.

🎯 **Stretch.** Diff against a committed baseline to catch new privileged accounts.

---

## Task 2 — Ticket-driven: "unexpected account / privilege change" (diagnose → verdict)

**Scenario.** `SOC-222` (P2). *"An account appeared / gained sudo — legit or backdoor?"* Investigate.

**Objective.** Determine who created/changed it and whether it's authorized — with audit evidence.

**Given / constraints.** Recreate: add a user / grant sudo. Answer from logs (auditd/auth), not guess.

**Hints.**
1. When created? `useradd` in auth log / `ausearch`. By whom?
2. Authorized (change ticket) or not?
3. Verdict + action (disable if rogue).

✅ **Verify.**
```bash
grep -qiE 'authorized|backdoor|verdict' docs/learning/reports/SOC-222-verdict.md && echo "VERDICT ✅"
```

**Deliverable.** `docs/learning/reports/SOC-222-verdict.md`: account · creation evidence · authorized? · verdict · action.

**Pitfalls.**
- Deleting the account before forensics.
- Verdict without the creation evidence.
- Missing the privilege grant (focusing only on creation).

🎯 **Stretch.** Correlate the account creation to the session/process that did it.

---

## Task 3 — On-call: compromised account response (synthesis)

**Scenario.** `SOC-223` (P1, time-boxed). An account is confirmed compromised. Contain it, scope what it
touched, and write an IR note.

**Objective.** Contain the account, scope its activity (logins, commands, files, persistence), document.

**Given / constraints.** Simulate compromise (logins + a persistence artifact). Preserve evidence.

**Hints.**
1. Contain: lock the account, kill its sessions, remove its keys.
2. Scope: `last`, command history, files owned/modified, cron, authorized_keys.
3. IR note + IoCs + MITRE (T1078 valid accounts).

✅ **Verify.**
```bash
docker exec siem-victim sh -c 'passwd -S <user> 2>/dev/null | grep -qi "L" && echo LOCKED || echo check'
test -f docs/learning/reports/SOC-223-compromised-acct.md && echo "IR NOTE ✅"
```

**Deliverable.** `docs/learning/reports/SOC-223-compromised-acct.md`: containment · scope · persistence · IoCs · MITRE T1078.

**Pitfalls.**
- Locking the account but leaving its SSH keys/persistence.
- Not scoping what it did (assume minimal).
- No evidence preserved.

🎯 **Stretch.** Determine initial access (how the account was compromised).

---

## Done?
- [ ] All ✅ Verify pass · [ ] answered from audit trail · [ ] contained + scoped + persistence removed.
- [ ] **Guardrails:** fake accounts only; no real data. → [README Reflection](./README.md).
