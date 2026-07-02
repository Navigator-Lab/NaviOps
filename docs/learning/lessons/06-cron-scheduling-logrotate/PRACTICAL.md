# Lesson 06 — Pure Practical: Cron, Scheduling & logrotate

> **Companion to [`README.md`](./README.md).** Pure practice: 3 scenario tasks, guided → ticket-driven
> → on-call. Do them after the README.
>
> **Lab:** `docker exec -it naviops-web bash`. **Node:** `naviops-web`.
> **Rules:** type it, diagnose before you fix, run ✅ **Verify** each task.

Each task: **Scenario · Objective · Given/constraints · Hints · ✅ Verify · Pitfalls · 🎯 Stretch.**

---

## Task 1 — Guided: schedule the healthcheck two ways (fluency)

**Scenario.** `NAVI-061`. Run `scripts/healthcheck.sh` every 10 minutes and keep its output. Do it
first with **cron**, then as a **systemd timer** (the modern equivalent) so you know both.

**Objective.** A working cron entry *and* a working `.timer`/`.service` pair, both logging output.

**Given / constraints.** Log to a rotate-friendly path. Don't schedule anything that spams.

**Hints.**
1. Cron: `crontab -e` → `*/10 * * * * /path/healthcheck.sh >> /var/log/naviops/health.log 2>&1`.
2. Timer: `naviops-health.service` (`Type=oneshot`) + `naviops-health.timer` (`OnCalendar=*:0/10`), then `systemctl enable --now naviops-health.timer`.
3. Compare: `systemctl list-timers` vs `crontab -l`.

✅ **Verify.**
```bash
crontab -l | grep -q healthcheck && echo "CRON SET ✅"
systemctl list-timers --all | grep -q naviops-health && echo "TIMER SET ✅"
sleep 1; tail -n1 /var/log/naviops/health.log
```

**Pitfalls.**
- `*/10` in the wrong column (that's minutes — good; don't put it in hours).
- No output redirect → cron mails root and you never see it.
- Running both cron *and* timer for the same job (double runs) once you've compared them — disable one.

🎯 **Stretch.** Add `Persistent=true` to the timer so a missed run (host asleep) fires on next boot; contrast with cron's behavior.

---

## Task 2 — Ticket-driven: "logs never rotate, disk keeps filling" (diagnose → fix)

**Scenario.** `NAVI-062` (P2). *"`/var/log/naviops/app.log` is 2 GB and growing; there's a logrotate
config but it does nothing."* Find why rotation isn't happening and fix it.

**Objective.** Get logrotate to actually rotate + compress the log, verified with a forced dry-run.
**Diagnose before editing.**

**Given / constraints.** Recreate a broken `/etc/logrotate.d/naviops` (e.g. wrong path, missing
`copytruncate` for an app that holds the file open, or bad permissions). Fix the real fault.

**Hints.**
1. Dry-run to see the plan/errors: `logrotate -d /etc/logrotate.d/naviops`.
2. Force once: `logrotate -f /etc/logrotate.d/naviops`. Does a `.1`/`.gz` appear?
3. App holds the log open? Use `copytruncate` (or signal the app to reopen). Check file ownership vs the `su` directive.

✅ **Verify.**
```bash
logrotate -d /etc/logrotate.d/naviops 2>&1 | grep -qi error && echo "STILL BROKEN ❌" || echo "CONFIG OK ✅"
logrotate -f /etc/logrotate.d/naviops && ls /var/log/naviops/ | grep -qE '\.1(\.gz)?$' && echo "ROTATED ✅"
```

**Pitfalls.**
- Path/glob in the config doesn't match the real file → logrotate silently skips it.
- Missing `copytruncate` for a daemon that keeps the fd open → it keeps writing the old inode; rotation "works" but disk still fills.
- Wrong permissions/`su` → "error: skipping, parent directory has insecure permissions".

🎯 **Stretch.** Add `maxsize 100M` so it also rotates on size (not just daily), and `delaycompress` to keep the last file readable.

---

## Task 3 — On-call: a runaway cron job is hammering the box (synthesis)

**Scenario.** `NAVI-063` (P1, time-boxed). Overlapping cron runs of a slow job are piling up and load
is climbing. Stop the pile-up, prevent overlap, and document.

**Objective.** Identify the offending cron job, kill the backlog safely, add an overlap guard
(`flock`), and confirm only one instance can run.

**Given / constraints.** Simulate a slow job scheduled every minute with no lock. Don't blanket-kill
unrelated processes.

**Hints.**
1. Find them: `pgrep -af <jobname>`; see the schedule in `crontab -l` / `/etc/cron.d`.
2. Serialize: wrap in `flock -n /run/lock/job.lock <cmd>` so a second start exits immediately.
3. Kill the backlog gracefully (`pkill -f`, TERM first), then confirm one-at-a-time.

✅ **Verify.**
```bash
pgrep -cf <jobname>        # ≤ 1 after the guard
flock -n /run/lock/job.lock true && echo "LOCK FREE" || echo "LOCK HELD (expected while running)"
test -f docs/learning/reports/NAVI-063-postmortem.md && echo "POSTMORTEM ✅"
```

**Deliverable.** `docs/learning/reports/NAVI-063-postmortem.md`: Impact · Detection · Root cause · Fix · Prevention.

**Pitfalls.**
- Killing the current run but leaving the schedule → it stampedes again next minute.
- `flock` without `-n` in a fast schedule → locks queue up instead of skipping.
- Assuming cron ran "once" — check for multiple crontabs (`/etc/cron.d`, per-user, `/etc/crontab`).

🎯 **Stretch.** Convert the job to a systemd timer with `OnCalendar` + the unit's built-in "won't start if already running" behavior — no external lock needed.

---

## Done?
- [ ] All ✅ Verify pass · [ ] rotation forced-tested · [ ] postmortem written.
- [ ] No double-scheduling left. **Redaction:** generic paths. → [README Step 7](./README.md).
