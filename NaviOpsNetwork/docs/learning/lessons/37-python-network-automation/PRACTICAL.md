# Lesson 37 — Pure Practical: Python Network Automation

> **Companion to [`README.md`](./README.md).** Pure practice: 3 scenario tasks, guided → ticket-driven
> → on-call. **Lab:** run Python from a host/control node against `clab-r1/r2` (SSH/`vtysh`) and hosts.
> Prefer stdlib; `netmiko`/`napalm` optional. **Rules:** type it, `py_compile` before you trust it, run ✅.

Each task: **Scenario · Objective · Given/constraints · Hints · ✅ Verify · Pitfalls · 🎯 Stretch.**

---

## Task 1 — Guided: script a multi-device health check (fluency)

**Scenario.** `NOC-371`. Replace manual per-device checks with a script that polls all devices and
reports up/down + a key metric.

**Objective.** A script that iterates devices, runs a check (ping/SSH command), and prints a clean
report with a non-zero exit on any failure.

**Given / constraints.** stdlib (`subprocess`/`socket`) or netmiko. Correct exit codes.

**Hints.**
1. A device list; loop; `subprocess.run(["ping","-c1",ip])` or an SSH `show` command.
2. Structure results; print human + `--json`.
3. `sys.exit(1)` if any device is down.

✅ **Verify.**
```bash
python3 -m py_compile net_healthcheck.py && echo "COMPILES ✅"
python3 net_healthcheck.py; echo "exit=$?"   # non-zero if any device down
```

**Pitfalls.**
- `shell=True` with interpolated device data (injection).
- No timeout → hangs on a dead device.
- Always exit 0 → CI can't catch failures.

🎯 **Stretch.** Add concurrency (threads) to poll many devices fast.

---

## Task 2 — Ticket-driven: "the automation misconfigured a device" (diagnose → fix)

**Scenario.** `NOC-372` (P2). A config-push script produced wrong/partial config on a device. Find the
bug and make the script safe (idempotent, validated) — diagnose first.

**Objective.** Fix the script so pushes are validated + idempotent; re-run is a no-op when compliant.

**Given / constraints.** Recreate a script that pushes without checking. Add validation + dry-run.

**Hints.**
1. Read the traceback / diff intended vs actual device config.
2. Add a dry-run (show diff) and a post-push verify (read back).
3. Idempotence: only change when non-compliant.

✅ **Verify.**
```bash
python3 net_push.py --check && echo "DRY RUN OK ✅"
python3 net_push.py && python3 net_push.py --check | grep -qi 'no change' && echo "IDEMPOTENT ✅"
```

**Pitfalls.**
- Push without read-back verify (blind).
- Not idempotent → drift/churn.
- No dry-run before touching devices.

🎯 **Stretch.** Add a rollback (save pre-change config, restore on verify-fail).

---

## Task 3 — On-call: bulk change with safety rails (synthesis)

**Scenario.** `NOC-373` (P1, time-boxed). A change must hit many devices now, but a bad push could take
down the fleet. Build the script with staged rollout + auto-rollback and document.

**Objective.** A safe bulk-change tool: dry-run, staged (N at a time), health-gate, rollback on failure —
plus a note.

**Given / constraints.** Simulate against the lab devices. Stage + gate + rollback.

**Hints.**
1. Dry-run all; apply in batches; after each batch run the health check; stop on failure.
2. Rollback the failed batch from saved config.
3. Log each device's result.

✅ **Verify.**
```bash
python3 -m py_compile net_bulk_change.py && echo "COMPILES ✅"
python3 net_bulk_change.py --dry-run && echo "DRY RUN ✅"
test -f docs/learning/reports/NOC-373-bulk-change.md && echo "REPORT ✅"
```

**Deliverable.** `docs/learning/reports/NOC-373-bulk-change.md`: staging plan · health gate · rollback · results.

**Pitfalls.**
- All-at-once push (fleet-wide blast radius).
- No health gate between batches.
- No rollback path.

🎯 **Stretch.** Emit a machine-readable run report (JSON) for audit.

---

## Done?
- [ ] All ✅ Verify pass · [ ] idempotent + validated · [ ] staged rollout with rollback.
- [ ] **Guardrails:** lab only; no real device creds committed. → [README Reflection](./README.md).
