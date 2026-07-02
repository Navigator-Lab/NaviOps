# Lesson 21 — Pure Practical: Suspicious Process Investigation

> **Companion to [`README.md`](./README.md).** Pure practice: 3 scenario tasks, guided → ticket-driven
> → on-call. **Lab:** `docker exec -it siem-victim bash` + Wazuh. **Rules:** evidence before verdict,
> preserve evidence, run ✅ **Verify** each task.

Each task: **Scenario · Objective · Given/constraints · Hints · ✅ Verify · Pitfalls · 🎯 Stretch.**

---

## Task 1 — Guided: profile a running process (fluency)

**Scenario.** `SOC-211`. Fully characterize a process: parent, binary path, user, network, open files —
the process-investigation toolkit.

**Objective.** A complete profile of one process (spawn a benign test one).

**Given / constraints.** Inside the victim. Read-only investigation.

**Hints.**
1. `ps -ef --forest` (parent/child), `ls -l /proc/<pid>/exe` (real binary), `/proc/<pid>/cwd`.
2. Network: `ss -tp | grep <pid>`. Open files: `ls -l /proc/<pid>/fd`.
3. Record the full profile.

✅ **Verify.**
```bash
docker exec siem-victim sh -c 'p=$(pgrep -n bash); ls -l /proc/$p/exe 2>/dev/null && ps -o ppid= -p $p' | grep -q . && echo "PROFILE ✅"
```

**Pitfalls.**
- Trusting the process *name* (spoofable) over `/proc/<pid>/exe`.
- Ignoring the parent (how it was spawned).
- Missing network/open-files context.

🎯 **Stretch.** Reconstruct the full process tree back to its origin.

---

## Task 2 — Ticket-driven: "is this process malicious?" (diagnose → verdict)

**Scenario.** `SOC-212` (P2). An odd process appears (unusual name/path/parent). Decide malicious vs
benign — with evidence.

**Objective.** A TP/FP verdict backed by path, parent, hash, and network behavior.

**Given / constraints.** Plant a suspicious process (e.g. a script in /tmp with a network connection).
Preserve it; investigate.

**Hints.**
1. Path in /tmp or masquerading name? Odd parent (e.g. spawned by a web server)?
2. Hash the binary; check network (`ss -tp`).
3. Verdict + evidence.

✅ **Verify.**
```bash
grep -qiE 'malicious|benign|verdict' docs/learning/reports/SOC-212-verdict.md && echo "VERDICT ✅"
```

**Deliverable.** `docs/learning/reports/SOC-212-verdict.md`: process · path/parent/hash/network · verdict · evidence.

**Pitfalls.**
- Killing it before capturing evidence (hash, args, connections).
- Verdict on name alone.
- Missing the suspicious parent.

🎯 **Stretch.** Map the behavior to an ATT&CK technique.

---

## Task 3 — On-call: active malicious process — contain + scope (synthesis)

**Scenario.** `SOC-213` (P1, time-boxed). A confirmed-malicious process is running (beaconing /
persistence). Preserve evidence, contain, scope persistence, and write an IR note.

**Objective.** Evidence captured, process contained, persistence found + removed, IR note written.

**Given / constraints.** Plant process + a persistence artifact (cron/service). Capture *before* killing.

**Hints.**
1. Capture: `ps`, args, `/proc/<pid>/exe` hash, `ss -tp`, open files → to `/tmp/ir/`.
2. Contain: kill the process; then hunt persistence (cron, systemd, authorized_keys).
3. Scope + IR note with IoCs + MITRE.

✅ **Verify.**
```bash
docker exec siem-victim sh -c 'crontab -l 2>/dev/null | grep -q "<rogue>" && echo PERSIST || echo clean'
test -f docs/learning/reports/SOC-213-malproc.md && echo "IR NOTE ✅"
```

**Deliverable.** `docs/learning/reports/SOC-213-malproc.md`: evidence · containment · persistence found/removed · IoCs · MITRE.

**Pitfalls.**
- Killing first, losing volatile evidence.
- Removing the process but leaving persistence (it returns).
- No scope (assuming a single artifact).

🎯 **Stretch.** Write a detection for the persistence mechanism so it auto-alerts.

---

## Done?
- [ ] All ✅ Verify pass · [ ] evidence before kill · [ ] persistence scoped + removed.
- [ ] **Guardrails:** fake malware only; no real samples committed. → [README Reflection](./README.md).
