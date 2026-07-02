# Lesson 13 — Pure Practical: Ansible Fundamentals

> **Companion to [`README.md`](./README.md).** Pure practice: 3 scenario tasks, guided → ticket-driven
> → on-call. Do them after the README.
>
> **Lab:** control from the host; targets `naviops-web` (.10) & `naviops-db` (.11) over SSH (L07 keys).
> Needs `ansible` installed (`pipx install ansible` or distro pkg). **Rules:** type it, diagnose before
> you fix, run ✅ **Verify** each task.

Each task: **Scenario · Objective · Given/constraints · Hints · ✅ Verify · Pitfalls · 🎯 Stretch.**

---

## Task 1 — Guided: an idempotent playbook against the two lab nodes (fluency)

**Scenario.** `NAVI-131`. Configure both lab nodes the same way — a package, a config file, and a
service — with a playbook you can run repeatedly and get "changed" only when something actually differs.

**Objective.** An inventory + playbook that converges both nodes; a second run reports `changed=0`
(true idempotence).

**Given / constraints.** Use modules (`package`, `copy`/`template`, `service`), not `command`/`shell`
where a module exists. No hard-coded secrets.

**Hints.**
1. `inventory.ini` with `[web]`/`[db]` and `ansible_host` = the lab IPs.
2. Playbook tasks use proper modules; `handlers` for "restart on change".
3. `ansible-playbook -i inventory.ini site.yml` twice — compare the play recap.

✅ **Verify.**
```bash
ansible-playbook -i inventory.ini site.yml | tee /tmp/run1.txt
ansible-playbook -i inventory.ini site.yml | grep -E 'changed=0.*failed=0' && echo "IDEMPOTENT ✅"
ansible all -i inventory.ini -m ping        # both nodes reachable
```

**Pitfalls.**
- `command`/`shell` for everything → never idempotent (always "changed").
- No `changed_when`/`creates` on a raw command → false "changed" every run.
- Editing files on the host with `copy` but no handler to restart the service.

🎯 **Stretch.** Run with `--check --diff` and show it predicts changes without applying them (dry run).

---

## Task 2 — Ticket-driven: "the playbook fails on one host only" (diagnose → fix)

**Scenario.** `NAVI-132` (P2). *"`site.yml` works on web but fails on db with an unreachable / module
error."* Find why one host differs and fix it — **diagnose first.**

**Objective.** Get the play green on both hosts, having identified whether it's connectivity, privilege
(`become`), a missing dependency, or a host-specific variable.

**Given / constraints.** Recreate: db missing the SSH key, or a task needing `become: true`, or a
distro difference. Fix the root cause, not by removing the failing task.

**Hints.**
1. Verbose: `ansible-playbook ... -l db -vvv` — read the actual failure.
2. Connectivity vs privilege: `ansible db -i inventory.ini -m ping` then `-b -m command -a 'id'`.
3. Host-specific fix via `host_vars`/`group_vars`, not by editing the task.

✅ **Verify.**
```bash
ansible-playbook -i inventory.ini site.yml -l db | grep -E 'failed=0' && echo "DB FIXED ✅"
ansible-playbook -i inventory.ini site.yml | grep -E 'unreachable=0.*failed=0' && echo "ALL GREEN ✅"
```

**Pitfalls.**
- Deleting/`ignore_errors`-ing the failing task instead of fixing it → silent drift.
- Missing `become: true` for a privileged task → permission denied.
- Assuming all hosts are identical (package name/path differs across distros).

🎯 **Stretch.** Add `ansible-lint` to catch anti-patterns and fix its top findings.

---

## Task 3 — On-call: emergency config rollout + safe rollback (synthesis)

**Scenario.** `NAVI-133` (P1, time-boxed). A config must be pushed to all nodes now (e.g. block a bad
setting), but if it breaks the service you must roll back fast across the fleet.

**Objective.** Push the change with a `--check` dry run first, apply, verify the service, and have a
tested rollback play — document it.

**Given / constraints.** Use `serial` (rolling) so you don't break every node at once. Keep a backup of
the file the play replaces.

**Hints.**
1. Dry run: `ansible-playbook rollout.yml --check --diff`.
2. Rolling apply: `serial: 1` + a post-task health check; `any_errors_fatal` to stop the rollout on first failure.
3. Rollback play restores the backed-up config and restarts the service.

✅ **Verify.**
```bash
ansible-playbook rollout.yml --check --diff | grep -q changed && echo "DRY RUN OK ✅"
ansible all -i inventory.ini -b -m command -a 'systemctl is-active <svc>' | grep -c active
test -f docs/learning/reports/NAVI-133-postmortem.md && echo "POSTMORTEM ✅"
```

**Deliverable.** `docs/learning/reports/NAVI-133-postmortem.md`: Impact · Detection · Root cause · Fix · Prevention.

**Pitfalls.**
- No `serial` → a bad change hits 100% of the fleet simultaneously.
- No `backup: yes` on the file module → nothing to roll back to.
- Skipping `--check` on a fleet-wide change.

🎯 **Stretch.** Gate the rollout behind a health-check task that fails the play (and halts `serial`) if the service doesn't come back.

---

## Done?
- [ ] All ✅ Verify pass · [ ] idempotent (changed=0 on rerun) · [ ] rollback tested · [ ] postmortem written.
- [ ] Modules over shell; secrets in vault/`.env`. **Redaction:** lab IPs only. → [README Step 7](./README.md).
