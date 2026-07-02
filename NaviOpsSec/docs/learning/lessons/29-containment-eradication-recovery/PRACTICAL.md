# Lesson 29 — Pure Practical: Containment, Eradication & Recovery

> **Companion to [`README.md`](./README.md).** Pure practice: 3 scenario tasks, guided → ticket-driven
> → on-call. **Lab:** `siem-victim` + Wazuh. **Rules:** preserve evidence, act deliberately, run ✅
> **Verify** each task.

Each task: **Scenario · Objective · Given/constraints · Hints · ✅ Verify · Pitfalls · 🎯 Stretch.**

---

## Task 1 — Guided: contain without destroying evidence (fluency)

**Scenario.** `SOC-291`. A host is compromised. Practice *containment* that stops the bleeding while
preserving forensic evidence.

**Objective.** Contain the threat (isolate/disable) with evidence captured first.

**Given / constraints.** Plant a compromise. Capture volatile state before containing.

**Hints.**
1. Capture first: `ps`, `ss`, network, memory-ish artifacts → `/tmp/ir/`.
2. Contain: isolate network / disable the account / kill C2 — not wipe.
3. Confirm the active threat is stopped.

✅ **Verify.**
```bash
docker exec siem-victim sh -c 'ls /tmp/ir/ 2>/dev/null | grep -q . && echo EVIDENCE' | grep -q EVIDENCE && echo "EVIDENCE CAPTURED ✅"
```

**Pitfalls.**
- Wiping/rebooting → destroys volatile evidence.
- Containing so aggressively you lose the ability to scope.
- No evidence captured before action.

🎯 **Stretch.** Practice network isolation that keeps the host up for forensics.

---

## Task 2 — Ticket-driven: eradicate the threat completely (diagnose → fix)

**Scenario.** `SOC-292` (P2). Post-containment: remove all attacker footholds. Miss one and they're back.

**Objective.** Enumerate + remove every persistence mechanism, verified clean.

**Given / constraints.** Plant multiple footholds (cron + service + key). Find them all.

**Hints.**
1. Hunt persistence: cron, systemd units/timers, authorized_keys, startup, rogue accounts.
2. Remove each; re-scan.
3. Verify none remain.

✅ **Verify.**
```bash
docker exec siem-victim sh -c 'crontab -l 2>/dev/null | grep -q "<rogue>" || systemctl list-unit-files 2>/dev/null | grep -q "<rogue>"' && echo "STILL PRESENT ❌" || echo "ERADICATED ✅"
```

**Deliverable.** `docs/learning/reports/SOC-292-eradication.md`: footholds found · removed · verification.

**Pitfalls.**
- Removing one foothold, missing others (attacker returns).
- Not re-scanning after removal.
- Eradicating before scoping (miss related hosts).

🎯 **Stretch.** Add detections for each persistence type so re-establishment alerts.

---

## Task 3 — On-call: full contain→eradicate→recover cycle (synthesis)

**Scenario.** `SOC-293` (P1, time-boxed). Run the complete IR lifecycle: contain, eradicate, recover to
known-good, verify, and document — with a decision on rebuild vs clean.

**Objective.** Threat contained + eradicated + service recovered + verified; documented with the
rebuild/clean rationale.

**Given / constraints.** Plant a full compromise. Recovery must be verified clean before "done".

**Hints.**
1. Contain (evidence first) → eradicate all footholds → recover (restore/rebuild).
2. Rebuild-from-known-good is safer than cleaning if depth is uncertain.
3. Verify clean; monitor for recurrence.

✅ **Verify.**
```bash
docker exec siem-victim sh -c 'crontab -l 2>/dev/null | grep -q "<rogue>"' && echo "NOT CLEAN ❌" || echo "RECOVERED CLEAN ✅"
test -f docs/learning/reports/SOC-293-lifecycle.md && echo "REPORT ✅"
```

**Deliverable.** `docs/learning/reports/SOC-293-lifecycle.md`: contain · eradicate · recover · rebuild-vs-clean rationale · verification.

**Pitfalls.**
- Declaring recovery before verifying clean.
- Cleaning when a rebuild was warranted.
- No post-recovery monitoring.

🎯 **Stretch.** Define the criteria for "rebuild vs clean" as a reusable decision guide.

---

## Done?
- [ ] All ✅ Verify pass · [ ] evidence before containment · [ ] all footholds eradicated · [ ] recovery verified clean.
- [ ] **Guardrails:** fake compromise only; no real data. → [README Reflection](./README.md).
