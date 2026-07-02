# Lesson 04 — Pure Practical: Linux Logs & Auditing

> **Companion to [`README.md`](./README.md).** Pure practice: 3 scenario tasks, guided → ticket-driven
> → on-call. **Lab:** `docker exec -it siem-victim bash` (generate + read logs); Wazuh ingests them.
> **Rules:** evidence before verdict, run ✅ **Verify** each task.

Each task: **Scenario · Objective · Given/constraints · Hints · ✅ Verify · Pitfalls · 🎯 Stretch.**

---

## Task 1 — Guided: know your log sources + enable auditd (fluency)

**Scenario.** `SOC-041`. Map where security-relevant events live on Linux and turn on `auditd` for
syscall-level visibility.

**Objective.** Identify auth/system/audit log locations; add an audit rule and trigger it.

**Given / constraints.** Inside the victim. Use `auditctl`/`ausearch`.

**Hints.**
1. Sources: `/var/log/auth.log` (or `secure`), `journalctl`, `/var/log/audit/audit.log`.
2. Add a watch: `auditctl -w /etc/passwd -p wa -k passwd_changes`; then `touch`/edit to trigger.
3. `ausearch -k passwd_changes`.

✅ **Verify.**
```bash
docker exec siem-victim sh -c 'auditctl -w /etc/passwd -p wa -k passwd_changes 2>/dev/null; echo x >> /etc/passwd; ausearch -k passwd_changes 2>/dev/null | grep -qi passwd_changes' && echo "AUDIT RULE FIRES ✅"
```

**Pitfalls.**
- Not knowing which log holds which event (auth vs syslog vs audit).
- auditd not running → no audit.log.
- Rule key typos → can't find events.

🎯 **Stretch.** Add watches for `/etc/shadow`, sudoers, and key binaries.

---

## Task 2 — Ticket-driven: "did someone modify a sensitive file?" (diagnose → answer)

**Scenario.** `SOC-042` (P2). *"We think a config/credential file was tampered with. Who, when?"*
Answer from the audit trail.

**Objective.** Determine whether/when/by-whom a file changed, with audit evidence.

**Given / constraints.** Recreate a change to a watched file. Answer from `ausearch`, not guesswork.

**Hints.**
1. `ausearch -f /path -i` (interpret) → who (auid/uid), when, what syscall.
2. Cross-check with auth log for the session.
3. State the answer + the evidence line.

✅ **Verify.**
```bash
docker exec siem-victim sh -c 'ausearch -k passwd_changes -i 2>/dev/null | grep -qi uid' && echo "ATTRIBUTION FOUND ✅"
```

**Deliverable.** `docs/learning/reports/SOC-042-file-change.md`: file · who · when · syscall · evidence.

**Pitfalls.**
- No audit watch in place before the change → no record.
- Confusing effective uid with the login (auid) that started the session.
- Concluding without the actual audit line.

🎯 **Stretch.** Correlate the change to the SSH session that made it.

---

## Task 3 — On-call: logs were tampered with (synthesis)

**Scenario.** `SOC-043` (P1, time-boxed). You suspect an attacker cleared/edited logs to hide activity.
Detect the tampering, recover what you can, and document the anti-forensics.

**Objective.** Find evidence of log tampering (gaps, cleared files, timestamps), salvage residual
evidence, write a note.

**Given / constraints.** Simulate truncating a log / a suspicious gap. Preserve remaining evidence.

**Hints.**
1. Signs: a log that suddenly shrinks/empties, a time gap, `last`/`wtmp` inconsistencies.
2. auditd/journald may still hold what the text log lost; central logs (L06) survive local wipes.
3. Note the gap + what survived.

✅ **Verify.**
```bash
docker exec siem-victim sh -c 'journalctl --since "1 hour ago" 2>/dev/null | tail -1' >/dev/null && echo "SECONDARY SOURCE CHECKED ✅"
test -f docs/learning/reports/SOC-043-tamper.md && echo "REPORT ✅"
```

**Deliverable.** `docs/learning/reports/SOC-043-tamper.md`: tampering evidence · surviving sources · gap · recommendation (central logging).

**Pitfalls.**
- Trusting a single log the attacker could edit.
- Not checking auditd/journald/central logs for what survived.
- Missing that log-clearing is itself an IoC (MITRE T1070).

🎯 **Stretch.** Explain how forwarding to Wazuh/central log defeats local log-wiping.

---

## Done?
- [ ] All ✅ Verify pass · [ ] answered from the audit trail · [ ] tampering + surviving evidence noted.
- [ ] **Guardrails:** no real data committed. → [README Reflection](./README.md).
