# Lesson 24 — Pure Practical: File Integrity Monitoring (FIM)

> **Companion to [`README.md`](./README.md).** Pure practice: 3 scenario tasks, guided → ticket-driven
> → on-call. **Lab:** Wazuh FIM (syscheck) watching `siem-victim`; config in `infra/wazuh/fim.conf`.
> **Rules:** evidence before verdict, run ✅ **Verify** each task.

Each task: **Scenario · Objective · Given/constraints · Hints · ✅ Verify · Pitfalls · 🎯 Stretch.**

---

## Task 1 — Guided: monitor a critical path with FIM (fluency)

**Scenario.** `SOC-241`. Configure FIM on a sensitive directory and trigger a change alert.

**Objective.** FIM watching a path; a file change produces an alert with who/what.

**Given / constraints.** Add the path to syscheck; change a file; confirm the alert.

**Hints.**
1. Add the directory to `<syscheck>` (report_changes, realtime); restart the agent.
2. Modify a watched file; wait for the FIM alert.
3. Confirm added/modified/deleted + hash.

✅ **Verify.**
```bash
docker exec siem-victim sh -c 'echo change >> /etc/hosts'   # a watched file (adjust)
docker exec wazuh.manager sh -c 'grep -qiE "syscheck|integrity|55[0-9]" /var/ossec/logs/alerts/alerts.log' && echo "FIM ALERT ✅"
```

**Pitfalls.**
- Watching too much → noise (build config binaries change constantly).
- Not realtime → delayed detection.
- No baseline → first scan floods.

🎯 **Stretch.** Enable `report_changes` to see the actual diff of what changed.

---

## Task 2 — Ticket-driven: "FIM alert — authorized change or tampering?" (diagnose → verdict)

**Scenario.** `SOC-242` (P2). A FIM alert fired on a system file. Decide: legit patch/admin vs malicious
tampering.

**Objective.** A verdict backed by who changed it, when, and whether it maps to a change window.

**Given / constraints.** Corroborate with auditd/auth. Evidence-based.

**Hints.**
1. FIM says *what* changed; auditd/auth says *who/when*.
2. Maps to a maintenance window / package update? Or off-hours + odd user?
3. Verdict + action.

✅ **Verify.**
```bash
grep -qiE 'authorized|tamper|verdict' docs/learning/reports/SOC-242-verdict.md && echo "VERDICT ✅"
```

**Deliverable.** `docs/learning/reports/SOC-242-verdict.md`: file · change · who/when · authorized? · verdict.

**Pitfalls.**
- FIM alone can't attribute — pair it with auditd.
- Assuming all changes are attacks (patches change files).
- Missing off-hours/odd-user signals.

🎯 **Stretch.** Whitelist package-management changes to cut FIM noise.

---

## Task 3 — On-call: attacker modified system binaries (synthesis)

**Scenario.** `SOC-243` (P1, time-boxed). FIM flags changes to system binaries/config — possible
rootkit/backdoor. Scope the tampering, preserve evidence, and write an IR note.

**Objective.** Scope all tampered files, capture hashes/evidence, and document with remediation.

**Given / constraints.** Simulate changes to several files. Preserve; don't overwrite before capture.

**Hints.**
1. Enumerate all FIM changes in the window; hash the affected files.
2. Compare to known-good (package DB / baseline).
3. IR note: scope, IoCs, remediation (restore from trusted source), MITRE T1565/T1554.

✅ **Verify.**
```bash
test -f docs/learning/reports/SOC-243-tamper.md && grep -qiE 'hash|scope|remediat' docs/learning/reports/SOC-243-tamper.md && echo "IR NOTE ✅"
```

**Deliverable.** `docs/learning/reports/SOC-243-tamper.md`: tampered files · hashes · scope · remediation · MITRE.

**Pitfalls.**
- Restoring before capturing evidence.
- Assuming one file (attackers change several).
- No known-good comparison.

🎯 **Stretch.** Verify integrity against the package manager's expected hashes.

---

## Done?
- [ ] All ✅ Verify pass · [ ] FIM paired with attribution · [ ] tampering scoped + evidence preserved.
- [ ] **Guardrails:** lab only; no real data. → [README Reflection](./README.md).
