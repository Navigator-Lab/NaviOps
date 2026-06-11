# Lesson 06 — Cron, Scheduled Tasks & Log Rotation

**Status:** ready for self-study · **Date written:** 2026-06-11
**Gate Rule:** Concept → Real-World Use → Alternatives → Hands-On → Verification → Quiz → Reflection → Search Keywords

> **How to use this lesson:** same as Lessons 03–05.

---

## Step 1 — Concept

### What it is

**Cron** is a time-based job scheduler — a daemon (`crond`) that wakes up every
minute, checks a table of scheduled commands (**crontabs**), and runs any that are
due. **systemd timers** are the modern equivalent, integrated with the unit/journal
system from Lesson 05. **logrotate** is a utility that prevents log files from growing
forever — it rotates (renames/compresses/deletes) logs on a schedule or size
threshold.

### Why it exists

Some tasks must run **unattended, repeatedly, on a schedule** — backups at 3am,
certificate renewal checks daily, log cleanup weekly. Without a scheduler, these
either don't happen (someone has to remember) or require a process to stay running
forever just to wait (wasteful). Without log rotation, a busy service's log file grows
until it fills the disk — a real, common cause of production outages ("disk full,
nothing can write, service crashes").

### What problem it solves

| Problem | Solution |
|---|---|
| "Run the backup script every night at 2am" | Crontab entry: `0 2 * * * /scripts/backup.sh` |
| "Check disk space every 5 minutes and alert if >90%" | Cron or systemd timer + `service_check.sh` |
| "`/var/log/myapp.log` is 40GB and growing" | logrotate config: rotate daily, keep 7, compress |
| "I need to know exactly when a scheduled job ran and what it printed" | systemd timer + `journalctl -u myjob.service` |

### Three-Level Depth (Lens A)

- **Level 1 — Beginner:** `crontab -e` opens your personal crontab. Each line:
  `minute hour day-of-month month day-of-week command`. `*` = "every". Example:
  `0 2 * * * /scripts/backup.sh` = run at 02:00 every day.
- **Level 2 — SysAdmin:** Per [Binadit's 2026 cron guide](https://binadit.com/tutorials/configure-linux-cron-jobs-and-system-task-scheduling-with-best-practices)
  and [crongen's cron-vs-timers comparison](https://www.crongen.com/blog/cron-vs-systemd-timers-2026):
  cron is simplest for predictable, single-host jobs and is universally portable.
  **systemd timers** add: automatic logging to journald (every run's stdout/stderr +
  exit code, queryable with `journalctl -u myjob.service`), `Persistent=true` (catch
  up on a missed run if the machine was off), resource limits
  (`CPUQuota=`, `MemoryLimit=` in the paired `.service`), and dependency ordering
  (`After=`). System-wide cron jobs (not per-user) live in `/etc/cron.d/` or
  `/etc/crontab` and **must specify the user** as an extra field:
  `0 2 * * * root /scripts/backup.sh`. **logrotate** configs live in
  `/etc/logrotate.d/<name>`, run daily via cron or a systemd timer
  (`/etc/cron.daily/logrotate` traditionally).
- **Level 3 — Systems/Kernel (Lens D):** `crond` itself is just another process that
  wakes up (via a `sleep`+poll loop or timer) once a minute, reads crontab files,
  computes which entries are due (string-matching the 5 time fields against the
  current time), and `fork()`+`exec()`s each due command — the exact mechanism from
  Lesson 03's Level 3. logrotate's "rotation" is implemented with `rename()` syscalls
  (e.g., `app.log` → `app.log.1`) plus, for the active log, a signal (often `SIGHUP`,
  Lesson 04) sent to the writing process so it **reopens** its log file — without this,
  the process keeps writing to the renamed (now-unlinked-from-the-active-name) file's
  inode, and `app.log` stays empty while disk space isn't actually freed (the inode
  persists until the writing process closes its file descriptor).

### Analogy (Lens B)

- **Cron** = a wall calendar with recurring reminders ("every day at 2am: take out
  the trash"). Simple, reliable, but the calendar doesn't keep a record of *whether
  you actually did it* or *what happened*.
- **systemd timers** = the same calendar, but each reminder is linked to a logbook
  entry — after each task, you write down what time it ran, what you did, and whether
  it succeeded — automatically.
- **logrotate** = a filing cabinet policy: "when this folder's papers exceed a size
  (or every Monday), seal the current folder, label it with last week's date, start a
  fresh folder, and shred folders older than 7 weeks."

The "reopen the log file" mechanism (Level 3) doesn't have a clean analogy — it's the
one place where understanding the actual file-descriptor/inode mechanism matters more
than the metaphor.

---

## Step 2 — Real-World Use

### How SysAdmins use this daily

```bash
crontab -l                       # view your crontab
crontab -e                       # edit it
sudo cat /etc/crontab            # system-wide jobs (note the extra "user" field)
ls /etc/cron.d/ /etc/cron.daily/ # distro-managed scheduled tasks
cat /etc/logrotate.d/nginx       # how nginx's logs are rotated
logrotate -d /etc/logrotate.conf # dry-run (debug mode), shows what WOULD happen
```

**Real production scenarios:**
1. **Nightly backups** — `0 2 * * * /scripts/backup.sh >> /var/log/backup.log 2>&1`
2. **Certificate renewal checks** — Let's Encrypt's `certbot renew` is typically a
   twice-daily cron/timer job.
3. **Health-check polling** — every 5 minutes, run `service_check.sh` (Lesson 05) and
   alert on failure.
4. **Log cleanup** — without logrotate, a verbose app can fill `/var/log` and crash
   every service that needs to write logs (real outage pattern).

### Common mistakes

| Mistake | Impact | Fix |
|---|---|---|
| Relative paths / assuming `$PATH` in cron | Cron runs with a **minimal environment** — `python3: command not found` even though it works in your shell | Use absolute paths (`/usr/bin/python3`), or set `PATH=` at the top of the crontab |
| No output redirection | Cron emails output to the user's local mailbox (often unread) — errors go unnoticed | `>> /var/log/myjob.log 2>&1` |
| Forgetting the **user field** in `/etc/crontab`/`/etc/cron.d/` | "Job doesn't run" — syntax error (this field doesn't exist in personal `crontab -e`) | `0 2 * * * root /scripts/backup.sh` |
| Non-idempotent jobs (Lesson 03 Q3) on a schedule | A missed/duplicate run causes drift or duplicate side effects | Design jobs to be safe to re-run |
| logrotate without `copytruncate` or signal/postrotate, for apps that hold the file open | App keeps writing to the renamed (now-invisible) file — disk usage doesn't actually drop | Use `postrotate`/`sharedscripts` to signal the app to reopen its log, or `copytruncate` |

### When NOT to use cron

- Sub-minute scheduling (cron's resolution is 1 minute) — use a long-running daemon
  with an internal sleep loop, or systemd timers with `OnUnitActiveSec=`.
- Tasks with complex dependencies on other jobs — that's a workflow orchestrator
  (beyond this lesson's scope) or systemd unit dependencies.

---

## Step 3 — Alternatives

| Tool | Use case |
|---|---|
| **cron** (this lesson) | Simple, universal, portable across every Linux distro |
| **systemd timers** | Better logging (journald), resource limits, `Persistent=` catch-up — increasingly preferred on systemd systems |
| **`at`** | One-time future execution (`at 2am tomorrow`), not recurring |
| **Ansible `cron` module** | Manage crontabs declaratively across many hosts (Lesson 13) |
| **Cloud-native: AWS EventBridge Scheduler** | Cloud equivalent for triggering Lambda/scripts on AWS infrastructure (Lesson 15+) |

**For NaviOps:** start with cron (simplest, you already know the syntax broadly);
convert your most important jobs to systemd timers once Lesson 05's concepts are
solid — the journald integration is a real operational upgrade.

---

## Step 4 — Hands-On Task (build this yourself)

**Goal:** Schedule `scripts/user_audit.sh` (or `service_check.sh`) to run
automatically, **and** write `scripts/backup.sh` — a script that backs up NaviOps'
`docs/` directory locally, with logrotate managing its logs.

### Lens C — Manual → Automated → Why

**Manual:** you remember to run `./scripts/user_audit.sh` periodically and check the
output yourself.

**Automated — Option A (cron):**
```cron
# crontab -e
0 6 * * * /home/sys-ctl/NaviOps/scripts/user_audit.sh >> /home/sys-ctl/NaviOps/logs/audit.log 2>&1
```

**Automated — Option B (systemd timer, pairs with Lesson 05's `.service`):**
```ini
# /etc/systemd/system/naviops-audit.timer
[Unit]
Description=Run NaviOps audit daily

[Timer]
OnCalendar=daily
Persistent=true

[Install]
WantedBy=timers.target
```
```bash
sudo systemctl enable --now naviops-audit.timer
systemctl list-timers | grep naviops
journalctl -u naviops-audit.service   # every run's output, automatically
```

**Why this matters:** Option B gives you, for free, exactly what
[dasroot.net's 2026 comparison](https://dasroot.net/posts/2026/03/cron-jobs-systemd-timers-scheduling-tasks/)
calls out — every run logged with timestamps, exit codes, and full output, queryable
without any extra logging code in your script.

### `scripts/backup.sh` spec (build this yourself)

Write it yourself using the Lesson 03 header + `log()` pattern. What it must do:

- **Header:** `#!/usr/bin/env bash` + `set -euo pipefail` + `IFS=$'\n\t'`.
- **Variables:** `BACKUP_SRC` (what to back up), `BACKUP_DEST` (where archives go), a
  `TIMESTAMP` from `date +%Y%m%d_%H%M%S`, and an `ARCHIVE` path built from them.
- **Create:** `mkdir -p` the destination, then `tar -czf` the source into `ARCHIVE`
  (use `-C` so the archive stores relative paths, not absolute ones).
- **Verify:** confirm the archive isn't corrupt by listing it — `tar -tzf "$ARCHIVE" > /dev/null`.
- **Report:** echo the archive path and its size (`du -h ... | cut -f1`).
- **Retention:** keep only the N most recent archives — sort by time (`ls -1t`), skip
  the first N (`tail -n +N+1`), and `xargs -r rm --` the rest. Think about why `-r`
  matters when there's nothing to delete.

The verify-then-retain ordering is the interesting design decision (don't prune old
backups until the new one is proven good) — make sure your version gets that right.

### `/etc/logrotate.d/naviops` (for `logs/audit.log` if using Option A)

```
/home/sys-ctl/NaviOps/logs/*.log {
    daily
    rotate 7
    compress
    missingok
    notifempty
}
```

### What to build, step by step

1. Choose Option A or B (try both if you have time — they teach different things).
2. Write `scripts/backup.sh` per the structure above; test it manually first.
3. Schedule it (cron entry or systemd timer + service, `Type=oneshot`).
4. Write the logrotate config for `logs/*.log`.
5. Test logrotate with `logrotate -d` (dry-run, per [the bugzilla discussion](https://bugzilla.redhat.com/show_bug.cgi?id=1655153)
   on logrotate/cron/systemd integration) before relying on the schedule.
6. Commit `scripts/backup.sh` and the logrotate/cron/timer config (in `infra/`) on
   `lesson/06-cron-scheduling-logrotate`.

---

## Step 5 — Verification

```bash
# Cron syntax check (doesn't execute, just validates by listing)
crontab -l

# Manually trigger the backup and confirm output
./scripts/backup.sh
ls -lh ~/backups/

# Test retention logic: create 9 dummy archives, run again, confirm only 7 remain
for i in $(seq 1 9); do touch -d "$i days ago" ~/backups/naviops-docs_test$i.tar.gz; done
./scripts/backup.sh
ls ~/backups/ | wc -l   # should be <= 8 (7 + the new real one)

# logrotate dry run
logrotate -d /etc/logrotate.d/naviops

# systemd timer (if Option B)
systemctl list-timers --all | grep naviops
journalctl -u naviops-audit.service --no-pager | tail
```

### Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| Cron job doesn't run, but works when you run it manually | `$PATH`/environment differences | Use absolute paths everywhere; add `PATH=` line at top of crontab if needed |
| No output anywhere from a cron job | Output not redirected | Add `>> logfile 2>&1` |
| Backup archive is 0 bytes / `tar -tzf` fails | Source path wrong, or `tar` ran before files were ready | Check `$BACKUP_SRC`, run manually with `set -x` |
| logrotate doesn't shrink disk usage despite "rotating" | App still has old log file open (Level 3) | Add `postrotate`/`sharedscripts` to signal the app, or use `copytruncate` |
| systemd timer never fires | Timer not `enable`d, or `OnCalendar=` syntax wrong | `systemctl list-timers`; `systemd-analyze calendar "daily"` to test syntax |

### Redaction check ✅

Backup archive paths/usernames should be placeholders if shown in committed docs;
don't commit actual `.tar.gz` archives to git.

---

## Step 6 — Quiz (Interview-Style, Graded)

**Q1.** Write a crontab line that runs `/scripts/cleanup.sh` every Sunday at 3:30 AM.
Explain each of the 5 fields.

> **Your answer:**

**Q2.** A cron job works when you run it manually but fails silently when run by
cron. What are the two most likely causes, and how do you debug it?

> **Your answer:**

**Q3.** What's the difference between a personal crontab (`crontab -e`) and an entry
in `/etc/cron.d/`? What extra field does the latter require, and why?

> **Your answer:**

**Q4.** **Scenario:** `/var/log/app.log` is 50GB. You add a logrotate config and run
`logrotate -f`, but `df -h` still shows the disk full 10 minutes later. What's likely
happening, and how do you fix it?

> **Your answer:**

**Q5.** Compare cron and systemd timers for a job that backs up a database nightly.
Which would you choose, and what's the concrete operational benefit of your choice?

> **Your answer:**

**Q6.** Why is **idempotency** especially important for scheduled jobs (tie back to
Lesson 03 Q3)? Give an example specific to `backup.sh`'s retention logic.

> **Your answer:**

---

## Step 7 — Reflection

*(Fill in after the quiz)*

- What did you learn?
- What confused you?
- What would you do differently?

---

## Step 8 — Search Keywords For Further Understanding

**Core**
- `crontab syntax fields explained`
- `cron environment variables PATH issues`
- `logrotate postrotate copytruncate explained`
- `systemd timer OnCalendar syntax examples`

**Tools**
- `systemd-analyze calendar test schedule`
- `logrotate dry run debug mode`
- `at command one time job linux`

**Going further (future lessons)**
- `ansible cron module idempotent scheduling`
- `aws eventbridge scheduler vs cron`
- `3-2-1 backup strategy linux`

---

## Lesson Status

- [ ] Hands-on task completed (Step 4)
- [ ] Verification passed (Step 5)
- [ ] Quiz answered + professional-answer comparisons requested (Step 6)
- [ ] Reflection completed (Step 7)
- [ ] Search Keywords reviewed (Step 8)

When complete, run the Update Protocol, then move to **Lesson 07 — SSH, Package
Management & Storage**.

---

*Lesson 06 written by Navi v28 · 2026-06-11 · WebSearch sources:
[crongen cron vs systemd timers 2026](https://www.crongen.com/blog/cron-vs-systemd-timers-2026),
[Binadit cron jobs guide](https://binadit.com/tutorials/configure-linux-cron-jobs-and-system-task-scheduling-with-best-practices),
[dasroot.net scheduling 2026](https://dasroot.net/posts/2026/03/cron-jobs-systemd-timers-scheduling-tasks/),
[ModernTechOps logrotate+cron](https://moderntechops.com/automate-daily-log-rotation-with-logrotate-cron/)*
