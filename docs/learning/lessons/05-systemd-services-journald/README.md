# Lesson 05 — systemd, Services & journald

**Status:** ready for self-study · **Date written:** 2026-06-11
**Gate Rule:** Concept → Real-World Use → Alternatives → Hands-On → Verification → Quiz → Reflection → Search Keywords

> **How to use this lesson:** same as Lessons 03–04.

---

## Step 1 — Concept

### What it is

**systemd** is the init system (PID 1) on almost all modern Linux distributions
(RHEL/AlmaLinux, Ubuntu, Debian, Fedora). It's the first process the kernel starts at
boot and the last one to exit at shutdown — it starts, stops, supervises, and restarts
every other service. **Unit files** define how systemd manages something (a service, a
timer, a mount, etc.). **journald** is systemd's logging component — it captures
stdout/stderr and structured metadata from every service into a binary log, queried
with `journalctl`.

### Why it exists

Before systemd, services were started by sequential shell scripts in `/etc/init.d/`
— slow (sequential, not parallel), inconsistent (every script reinvented start/
stop/status logic), and had no built-in **supervision** (if a service crashed, nothing
restarted it automatically). systemd solves: parallel startup (faster boot),
declarative unit files (consistent format), automatic restart on failure, dependency
ordering, and centralized logging.

### What problem it solves

| Problem | systemd solution |
|---|---|
| "Is nginx running? Restart it if it crashed." | `systemctl status/restart nginx`, `Restart=on-failure` in the unit |
| "Make my custom script run as a background service that survives reboot" | Write a `.service` unit, `systemctl enable` |
| "Show me everything that happened with the database service in the last hour" | `journalctl -u postgresql --since '1 hour ago'` |
| "This service depends on the network being up first" | `After=network-online.target` in the unit |

### Three-Level Depth (Lens A)

- **Level 1 — Beginner:** `systemctl start/stop/restart/status <service>` controls a
  service right now. `systemctl enable/disable <service>` controls whether it starts
  **at boot** (these are independent — a service can be `enabled` but currently
  `stopped`, or `started` but not `enabled`). `journalctl -u <service>` shows that
  service's logs.
- **Level 2 — SysAdmin:** A `.service` unit file (in `/etc/systemd/system/`) has
  `[Unit]` (description, ordering — `After=`, `Requires=`), `[Service]` (`ExecStart=`
  with an **absolute path**, `Restart=on-failure`, `User=` to drop privileges), and
  `[Install]` (`WantedBy=multi-user.target` — what enables it to). After editing a
  unit file: `systemctl daemon-reload` (reread unit files) then
  `systemctl restart <service>`. Validate syntax first with
  `systemd-analyze verify <file>` — per [DevToolbox's 2026 guide](https://devtoolbox.dedyn.io/blog/systemd-complete-guide),
  this catches typos like `ExectStart` before they cause a confusing runtime failure.
  `journalctl -u <service> -f` follows logs live (like `tail -f`); `--since`/`--until`
  filter by time. **Persistent logging** (surviving reboots) requires
  `/var/log/journal/` to exist with correct permissions — by default the journal may
  be volatile (RAM-only, lost on reboot).
- **Level 3 — Systems/Kernel (Lens D):** PID 1 is special in the kernel — it's the
  only process that **can't be killed** (the kernel refuses `SIGKILL` to PID 1) and it
  **adopts orphaned processes** (Lesson 04's zombie-reaping: when a parent dies before
  its child, PID 1 becomes the new parent and calls `wait()` on it). systemd
  communicates with services via **cgroups** (control groups) — a kernel mechanism
  that groups processes for resource accounting/limiting (CPU, memory, I/O). Every
  systemd unit gets its own cgroup, which is *why* `systemctl stop` reliably kills
  **all** of a service's child processes (it sends signals to the whole cgroup), unlike
  `kill <pid>` which only signals one process.

### Analogy (Lens B)

systemd is like a **building's facilities manager**:
- **Unit files** = the maintenance schedule/contract for each system (HVAC, elevators,
  security) — what to start, in what order, what to do if it fails.
- **`Restart=on-failure`** = "if the elevator breaks down, automatically call the
  technician to restart it" — without anyone noticing or intervening.
- **`After=network-online.target`** = "don't turn on the security cameras until the
  network wiring is confirmed working."
- **journald** = the building's central security-camera recording system — every
  system's activity log goes to one place, searchable by system and time range.

This analogy holds well for service supervision but breaks down for **cgroups** — a
facilities manager doesn't have an equivalent of "every appliance in this room shares
one power circuit, so cutting the circuit cuts all of them at once" — that's the
precise mechanism, though, and it's worth knowing literally.

---

## Step 2 — Real-World Use

### How SysAdmins use systemd daily

```bash
systemctl status nginx                          # is it running? recent logs? PID?
systemctl restart nginx                         # apply a config change
journalctl -u nginx --since '1 hour ago'        # what happened recently?
journalctl -u nginx -f                          # follow live (during a deploy)
systemctl enable --now myapp.service            # enable AND start in one command
systemd-analyze verify /etc/systemd/system/myapp.service   # validate before reload
```

**Real production scenarios:**
1. **Custom app as a service** — instead of `nohup ./myapp &` (dies on logout, no
   auto-restart, no centralized logs), wrap it in a `.service` unit.
2. **Debugging a crash loop** — `systemctl status` shows "activating (auto-restart)"
   repeatedly; `journalctl -u myapp -n 50` shows the actual error from the last 50
   log lines.
3. **Boot-time troubleshooting** — `systemd-analyze blame` shows which services are
   slowing down boot; `journalctl -b` shows logs from the current boot only.

### Common mistakes

| Mistake | Impact | Fix |
|---|---|---|
| Editing a unit file but forgetting `daemon-reload` | systemd keeps using the **old** unit definition | Always `daemon-reload` after editing |
| Relative paths in `ExecStart=` | Service fails to start (no shell, no `$PATH` context) | Always absolute paths (`/usr/bin/python3 /opt/app/run.py`) |
| Running services as `root` unnecessarily | Privilege escalation risk if compromised | Set `User=`/`Group=` to a dedicated unprivileged account |
| Confusing `enable` with `start` | "I enabled it, why isn't it running NOW?" / "I started it, why didn't it survive reboot?" | `enable --now` does both |
| Not checking `journalctl` before re-running a failing command | Wastes time guessing | `journalctl -u <service> -n 50 --no-pager` first |

### When NOT to use a systemd service

- One-off scripts you run manually — a service unit adds overhead for something that
  doesn't need supervision/auto-restart.
- Tasks that should run **on a schedule, then exit** — that's a **timer unit** (or
  cron, Lesson 06), not a long-running service.

### Interview Angle

**Question:** "You deploy a config change to a service's unit file and run
`systemctl restart myapp`, but the service comes back up with the *old* behavior —
like the change was never applied. What's going on, and how do you fix it?"

A **junior** answer might re-edit the file, double-check for typos, or restart again
and hope. A **senior** answer immediately suspects a missed `systemctl daemon-reload`
— systemd caches unit file definitions in memory, so editing the file on disk doesn't
change what systemd is currently running until it's told to reread unit files. The fix
is `sudo systemctl daemon-reload && sudo systemctl restart myapp`. The senior also
validates the edited unit *before* reloading with `systemd-analyze verify`, to catch
a typo like `ExectStart` that would otherwise cause a confusing "still old behavior"
or silent failure.

---

## Step 3 — Alternatives

| Tool | Use case |
|---|---|
| **systemd** (this lesson) | Standard on RHEL/AlmaLinux/Ubuntu/Debian/Fedora — the default, expected baseline |
| **SysVinit / `/etc/init.d`** | Legacy — still found on older systems; sequential, no built-in supervision |
| **supervisord** | Application-level process supervision, common in Docker containers (lighter than systemd inside a container) |
| **Docker restart policies** (`restart: unless-stopped`) | Container-level equivalent of `Restart=on-failure` (Lesson 12) |
| **systemd timers vs cron** | Timers integrate with journald logging and can depend on other units; cron is simpler and more universally known — Lesson 06 covers both |

**For NaviOps:** systemd is correct and unavoidable on AlmaLinux/Ubuntu. Inside Docker
containers (Lesson 11–12), supervisord or simple entrypoint scripts are more common —
systemd-in-a-container is generally discouraged.

---

## Step 4 — Hands-On Task (build this yourself)

> ▶ **Do this on the lab**: start the environment first — `./infra/bootstrap.sh up` (once: `pull`), then
> `docker exec -it naviops-web bash`. **Node:** naviops-web. **Artifact:** systemctl/journalctl here; build `scripts/service_check.sh`.
> Reference solution (after you try): `docs/learning/reference-solutions/` (gitignored answer key).

**Goal:** Wrap one of your `/scripts` (e.g., `user_audit.sh` from Lesson 03/04) as a
systemd **service** that you can start/check/inspect via `systemctl`/`journalctl` —
and write `scripts/service_check.sh`, a health-check script that reports on a list of
services.

### Lens C — Manual → Automated → Why

**Manual** (running the script ad-hoc): `./scripts/user_audit.sh`, output goes to
your terminal and a `/tmp` log file — lost when the terminal closes, not centrally
logged.

**Automated** — create `/etc/systemd/system/naviops-audit.service`:

```ini
[Unit]
Description=NaviOps user/permission audit
After=network.target

[Service]
Type=oneshot
ExecStart=/home/sys-ctl/NaviOps/scripts/user_audit.sh
User=sys-ctl

[Install]
WantedBy=multi-user.target
```

`Type=oneshot` = runs once and exits (not a long-running daemon) — appropriate for an
audit script. Then:

```bash
sudo systemd-analyze verify /etc/systemd/system/naviops-audit.service
sudo systemctl daemon-reload
sudo systemctl start naviops-audit.service
sudo systemctl status naviops-audit.service
journalctl -u naviops-audit.service
```

**Why this matters:** now the audit's output is in `journalctl` — centrally logged,
timestamped, queryable by time range — instead of scattered `/tmp` files. This is the
foundation for Lesson 06 (turning this into a scheduled timer) and Lesson 18
(CloudWatch — the cloud equivalent of "centralize logs").

### Optional: failure drill

When you're ready for a timed challenge, try [`troubleshooting-drills.md` §5 (Failed systemd service)](../../troubleshooting-drills.md#5-failed-systemd-service) in your sandbox VM.

### What to build, step by step

1. Write the unit file above (adjust paths/user to match your system), validate with
   `systemd-analyze verify`.
2. `daemon-reload`, `start`, `status`, then `journalctl -u naviops-audit.service` —
   confirm your script's `log()` output (Lesson 03) appears in the journal.
3. Write `scripts/service_check.sh` — a script that takes a list of service names and
   reports `systemctl is-active <name>` for each (this is Lens C applied again: you're
   automating "check if these N services are up" into one command).
4. **Do not** `enable` the audit service unless you actually want it persisted — for
   learning, `start` (without `enable`) is enough; clean up with
   `sudo systemctl disable --now naviops-audit.service` if you enabled it.
5. Commit the unit file (e.g., under `infra/systemd/naviops-audit.service` — keep
   real paths/usernames generic per the redaction convention) and
   `scripts/service_check.sh` on `lesson/05-systemd-services-journald`.

---

## Step 5 — Verification

```bash
# Unit file syntax
sudo systemd-analyze verify /etc/systemd/system/naviops-audit.service

# Confirm it ran and logged
sudo systemctl start naviops-audit.service
journalctl -u naviops-audit.service --no-pager | tail -20

# Confirm enable/start are independent
systemctl is-enabled naviops-audit.service   # likely "static" or "disabled" if not enabled
systemctl is-active naviops-audit.service    # "inactive" after a oneshot completes — expected

# service_check.sh
./scripts/service_check.sh sshd cron   # (or relevant services on your system)
```

### Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| `Failed to start ...: Unit not found` | Typo in unit filename, or didn't `daemon-reload` | Check filename matches exactly; `daemon-reload` |
| Service starts then immediately exits with error | `ExecStart` path wrong, or script needs args/env it doesn't get under systemd | `journalctl -u <unit> -n 50` for the actual error; test the exact `ExecStart` command manually |
| `journalctl` shows nothing for the unit | Persistent journal not configured (logs lost on reboot only — current-boot logs should still show) | `journalctl -u <unit> -b` (current boot); for persistence, `mkdir -p /var/log/journal` |
| `Permission denied` running script under systemd | `User=` in unit doesn't have execute permission on the script | `chmod +x` the script; check ownership |

### Redaction check ✅

Use generic paths (`/home/<user>/NaviOps/...` → keep your actual local username if this
stays local-only, but if committing the unit file to the public repo, use a placeholder
username or `%h`/`$HOME`-relative conventions where possible).

---

## Step 6 — Quiz (Interview-Style, Graded)

**Q1.** What's the difference between `systemctl enable` and `systemctl start`? Give
a scenario where you'd want one without the other.

> **Your answer:** `enable` makes a service start automatically at boot by creating a symlink under the target directory (e.g. `WantedBy=multi-user.target`). `start` starts the service right now in the current session only. They are independent: a service can be enabled (survives reboot) but currently stopped, or started (running now) but not enabled (won't survive reboot). Example of one without the other: during a rolling deployment test I want to `start` a new version of a service to smoke-test it in the current session, but I don't `enable` it yet — if it breaks, rebooting restores the previous state. Conversely, I might `enable` a monitoring agent on a box I'm about to hand off but not `start` it yet because I want it to begin on next boot, after final config is in place. `enable --now` does both atomically.

**Q2.** **Scenario:** You edited `/etc/systemd/system/myapp.service` to fix a typo in
`ExecStart`, then ran `systemctl restart myapp` — but it's still failing the same way.
What step did you forget, and why does it matter?

> **Your answer:** I forgot `systemctl daemon-reload`. systemd caches all unit file definitions in memory at startup and after each reload. Editing the file on disk does not update the in-memory definition — systemd is still using the stale, cached version with the original typo. `daemon-reload` tells PID 1 to re-read all unit files from disk; only then does `restart` pick up the change. The correct sequence is: edit → `systemd-analyze verify <file>` (catch typos before they cause silent failures) → `daemon-reload` → `restart`.

**Q3.** Where do you look first when a systemd service fails to start, and what
specific command(s) would you run?

> **Your answer:** First stop: `systemctl status <unit>` — it shows the active state, recent journal tail, PID, and exit code inline. If I need more log lines: `journalctl -u <unit> -n 50 --no-pager` (last 50 lines without a pager). For a crash loop: `journalctl -u <unit> -b` (current boot only). The exit code in the status output tells me if it's a permission issue, a missing binary, a bad config, or a scripting error. I run the exact `ExecStart` command manually as the specified `User=` to reproduce the failure outside systemd.

**Q4.** Explain `Type=oneshot` vs the default service type. When is `oneshot`
appropriate?

> **Your answer:** The default type is `Type=simple` — systemd considers the service started as soon as `ExecStart` is launched (the process is the main process; it's expected to run continuously). `Type=oneshot` is for tasks that run, do their work, and exit — systemd waits for the process to exit before considering the unit active/done. After it exits, the unit status shows `inactive (dead)` — which is expected, not an error. `RemainAfterExit=yes` can keep it in `active` state after exit if you want `systemctl status` to show green. Appropriate for: one-shot audit scripts (like `naviops-audit.service`), initialization tasks (seed a DB schema once), or any job-style workload that isn't a long-running daemon.

**Q5.** Why does `systemctl stop myapp` reliably terminate all of `myapp`'s child
processes, when `kill <main-pid>` might not? (Hint: cgroups.)

> **Your answer:** systemd assigns every service unit its own **cgroup** (control group) — a kernel mechanism that groups all processes belonging to that unit together. When `systemctl stop` is issued, systemd sends the stop signal (typically `SIGTERM`, then `SIGKILL` after `TimeoutStopSec`) to the **entire cgroup**, not just the main PID. Every child process, grandchild, or background worker the service spawned — regardless of whether they re-parented — lives in the same cgroup and is terminated atomically. `kill <main-pid>` only signals that one process; any workers that forked and continued running in the background are missed, causing resource leaks or zombie listeners.

**Q6.** How would you view only the logs for `nginx` from the last 30 minutes, and
follow new entries live afterward?

> **Your answer:**
> ```bash
> journalctl -u nginx --since '30 minutes ago' -f
> ```
> `--since '30 minutes ago'` filters to only log entries in that window. `-f` follows new entries as they arrive (like `tail -f`). Combined, it shows the last 30 minutes of nginx logs and then tails live. To also add a priority filter (errors only): `journalctl -u nginx --since '30 minutes ago' -p err -f`.

---

## Step 7 — Reflection

- **What I learned:** systemd's model — unit files as declarative service contracts, the daemon-reload requirement (because systemd caches in memory), and the cgroup-based stop mechanism — is clean and consistent once the mental model clicks. The separation of `enable` (boot persistence) from `start` (now) was the most practically useful distinction.
- **What confused me initially:** `Type=oneshot` showing `inactive (dead)` after success looked like a failure at first. Knowing that `inactive` is correct for oneshot (it ran and exited cleanly) required re-reading the status semantics.
- **What I'd do differently:** Run `systemd-analyze verify` before `daemon-reload` on every future unit edit — catching typos like `ExectStart` before applying them saves the confusion of "why is my change not working?" when the real issue is a silently-ignored malformed key.

---

## Lens E — Attacker & Defender (Red / Blue)

> Red/Blue framing (Gate Rule **Lens E**, D14). Build *both* mindsets: know how the
> tools in this lesson are abused, and how a defender detects and stops them.
> Frameworks: [GTFOBins](https://gtfobins.github.io/) · [MITRE ATT&CK](https://attack.mitre.org/) · [LOLBAS](https://lolbas-project.github.io/).

**🔴 Attacker (how it's abused — Step 2):** systemd units & timers are a clean persistence mechanism (drop a malicious `.service`/`.timer`, `enable` it). Attackers also tamper with or clear journald to cover tracks. ATT&CK **T1543.002** (Systemd Service), **T1070** (Indicator Removal), **T1562.001** (Disable/Modify Tools).

**🔵 Defender (detect & harden — Step 5):** Review enabled units & timers (`systemctl list-unit-files --state=enabled`, `list-timers`), **forward logs to a remote/immutable store** so local wipes don't hide activity, and alert on journal gaps or `systemctl` changes to critical units.

## Step 8 — Search Keywords For Further Understanding

**Core**
- `systemd unit file sections explained ExecStart`
- `systemctl enable vs start difference`
- `journalctl filter by time service`
- `systemd-analyze verify unit file`

**Tools**
- `systemd timers vs cron`
- `cgroups explained linux`
- `systemd restart policies on-failure`

**Going further (future lessons)**
- `systemd persistent journal var log journal`
- `docker restart policy vs systemd`
- `ansible systemd module manage services`

---

**Red / Blue (Lens E — study attacker & defender in parallel):**
- 🔴 **Red (attacker):** `malicious systemd service persistence`, `MITRE ATT&CK T1543.002 systemd`, `systemd timer backdoor`, `clear journald logs anti-forensics`
- 🔵 **Blue (defender):** `audit enabled systemd units`, `remote syslog log forwarding`, `detect log tampering journald`, `systemctl change monitoring`

## Lesson Status

- [x] Hands-on task completed (Step 4)
- [x] Verification passed (Step 5)
- [x] Quiz answered + professional-answer comparisons requested (Step 6)
- [x] Reflection completed (Step 7)
- [x] Search Keywords reviewed (Step 8)

✅ **Lesson 05 complete — 2026-07-01.** Moving to **Lesson 06 — Cron, Scheduled
Tasks & Log Rotation**.

---

*Lesson 05 written by Navi v28 · 2026-06-11 · WebSearch sources:
[DevToolbox systemd guide 2026](https://devtoolbox.dedyn.io/blog/systemd-complete-guide),
[Better Stack journalctl guide](https://betterstack.com/community/guides/logging/how-to-control-journald-with-journalctl/),
[DigitalOcean journalctl tutorial](https://www.digitalocean.com/community/tutorials/how-to-use-journalctl-to-view-and-manipulate-systemd-logs)*
