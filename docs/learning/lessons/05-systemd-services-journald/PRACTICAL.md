# Lesson 05 — Pure Practical: systemd, Services & journald

> **Companion to [`README.md`](./README.md).** The README teaches the concepts and builds *one*
> artifact. This file is **pure practice**: 3 real-world, scenario-driven tasks that take you from
> procedural fluency → diagnostic judgement → on-call pressure. Do them *after* the README.
>
> **Lab:** `./infra/bootstrap.sh up` (once: `pull`), then `docker exec -it naviops-web bash`.
> **Node:** `naviops-web`  ·  **You'll touch:** `systemctl`, `journalctl`, `scripts/service_check.sh`.
> **Rules of engagement:** type the commands (don't paste blindly), diagnose *before* you fix, and
> run the ✅ **Verify** check after each task. Reference answers live in the gitignored
> `docs/learning/reference-solutions/` — only after you've tried.

---

## How to use this file

Each task follows the same shape (validated against RHCSA performance-based design + Google SRE
incident drills — see README Step 8):

- **Scenario** — the on-the-job situation (role + ticket).
- **Objective** — one measurable outcome.
- **Given / constraints** — starting state and what's off-limits.
- **Hints** — checkpoints, *not* a copy-paste script.
- ✅ **Verify** — a runnable self-check; its output is your grader.
- **Pitfalls** — the wrong turns people actually take.
- 🎯 **Stretch** — optional harder variant.

Difficulty climbs: **Task 1 guided → Task 2 ticket-driven → Task 3 on-call.**

---

## Task 1 — Guided: turn a script into a supervised service (fluency)

**Scenario.** `NAVI-051`. Your team wants the `user_audit.sh` script (Lesson 03/04) to run as a
managed unit so its output lands in the journal instead of scattered `/tmp` files.

**Objective.** Create a `oneshot` systemd unit that runs the script, start it, and confirm its
output is queryable via `journalctl` — the unit reports `SUCCESS` / `exited`.

**Given / constraints.**
- Work inside `naviops-web`. The script exists under `/home/.../scripts/` (adjust the path).
- **Do not** `enable` the unit (we don't want it persisted for a drill) — `start` only.

**Hints.**
1. Unit lives at `/etc/systemd/system/naviops-audit.service`. `Type=oneshot`, set `ExecStart` and `User`.
2. `systemd-analyze verify <unit>` *before* loading — catch typos early.
3. `daemon-reload` → `start` → `status`. Then query: `journalctl -u naviops-audit.service`.

✅ **Verify.**
```bash
systemctl show naviops-audit.service -p Type,Result,ExecMainStatus
#   Type=oneshot  Result=success  ExecMainStatus=0   ← all three must match
journalctl -u naviops-audit.service --no-pager | grep -qi audit && echo "LOGGED ✅"
```

**Pitfalls.**
- Forgetting `daemon-reload` after editing → systemd runs the *old* unit.
- Relative `ExecStart` path → `status` shows `203/EXEC` (file not found). Always absolute.
- Expecting a `oneshot` to stay `active (running)` — correct end-state is `inactive (dead)` with `Result=success`.

🎯 **Stretch.** Add `StandardOutput=journal` explicitly and a `SyslogIdentifier=naviops-audit`, then
prove it: `journalctl SYSLOG_IDENTIFIER=naviops-audit`.

---

## Task 2 — Ticket-driven: a service that won't start (diagnose → fix)

**Scenario.** `NAVI-052` (P2). A teammate committed a unit for a small health API. It fails on boot
and the app is down. You get: *"naviops-api won't start, no idea why — fix it."* No further detail.

**Objective.** Get `naviops-api.service` to `active (running)` **by diagnosing first** — identify the
root cause from logs before changing anything.

**Given / constraints.** Create this deliberately-broken unit, then fix it *without* rewriting it
from scratch (find the specific fault):
```ini
[Unit]
Description=NaviOps health API
After=network.target

[Service]
ExecStart=/usr/bin/pyton3 -m http.server 8085
Restart=on-failure

[Install]
WantedBy=multi-user.target
```
- You may not disable `Restart=` to "make the error stop" — fix the actual cause.

**Hints.**
1. `systemctl status naviops-api` then `journalctl -xeu naviops-api` — read the *actual* error string.
2. What does `ExecMainStatus`/`code=exited` tell you? What binary is it trying to run?
3. After the fix: `daemon-reload` before `restart` (you edited the unit).

✅ **Verify.**
```bash
systemctl is-active naviops-api            # → active
curl -sf localhost:8085 >/dev/null && echo "SERVING ✅"
systemctl show naviops-api -p NRestarts    # NRestarts should stop climbing once fixed
```

**Pitfalls.**
- "Fixing" by masking the symptom (`Restart=no`) — the app still doesn't serve.
- Editing the file but forgetting `daemon-reload` → the typo persists and you chase a ghost.
- Reading only `status` (truncated) instead of `journalctl -xeu` (full trace with the real cause).

🎯 **Stretch.** Make it resilient: add `Restart=on-failure`, `RestartSec=2`, and a `StartLimitBurst`
so a genuinely crashing binary doesn't restart-loop forever. Prove the limit trips with a bad `ExecStart`.

---

## Task 3 — On-call: cascading failure, write the postmortem (synthesis + pressure)

**Scenario.** `NAVI-053` (P1, time-boxed 15 min). 02:00. Alert: *"naviops-web disk filling, API
flapping."* You suspect a service is log-spamming the journal and a dependent unit keeps restarting.
You are Incident Commander for this drill.

**Objective.** Within the time box: (a) find which unit is generating the most journal volume,
(b) stop the bleed, (c) confirm the dependent service is stable, (d) write a 5-line incident summary.

**Given / constraints.**
- Simulate the noise: a unit that runs `while true; do echo flooding; done` (or `yes`) piped to the
  journal. Create it, start it, watch the journal grow.
- **Constraint:** you may **not** delete `/var/log` or wipe the whole journal blindly — you must
  target the offending unit and use journald's own retention controls.

**Hints.**
1. Who's noisy? `journalctl --disk-usage`, then per-unit: `journalctl -u <unit> --since "5 min ago" | wc -l`.
2. Stop the bleed: `systemctl stop <noisy-unit>`. Reclaim space *surgically*: `journalctl --vacuum-time=10min` or `--vacuum-size=50M`.
3. Prevent recurrence: cap it in `/etc/systemd/journald.conf` (`SystemMaxUse=`) → `systemctl restart systemd-journald`.
4. Confirm the dependent unit recovered (`systemctl is-active`, `NRestarts` steady).

✅ **Verify.**
```bash
systemctl is-active <noisy-unit>           # → inactive/failed (stopped)
journalctl --disk-usage                    # smaller than the peak you recorded
# Deliverable exists:
test -f docs/learning/reports/NAVI-053-postmortem.md && echo "POSTMORTEM WRITTEN ✅"
```

**Deliverable — incident summary (5 lines).** Save to `docs/learning/reports/NAVI-053-postmortem.md`:
*Impact* · *Detection* · *Root cause* · *Fix* · *Prevention*. (Mirrors Google SRE postmortem structure.)

**Pitfalls.**
- Panicking and `rm -rf /var/log/journal` — loses forensic evidence and may not be reclaimed until restart.
- Vacuuming space but not stopping the source → journal refills in minutes.
- Fixing the noise but never confirming the *dependent* service actually recovered.

🎯 **Stretch.** Turn the whole drill into `scripts/service_check.sh` v2: it takes a list of units and
reports `is-active` + `NRestarts` + per-unit journal volume, exiting non-zero if any unit is failed or
restart-looping — so next time the monitor catches it before the disk does.

---

## Done?

- [ ] All three ✅ Verify blocks pass.
- [ ] You diagnosed Task 2 *before* editing (read the journal first).
- [ ] `NAVI-053-postmortem.md` written.
- [ ] `scripts/service_check.sh` committed on `lesson/05-systemd-services-journald`.

**Redaction check:** no real hostnames/IPs/usernames in committed units — use generic paths and the
`<PLACEHOLDER>` convention. When all three pass, you own systemd for real-world ops. →
[`README.md` Step 7 (Reflection)](./README.md).
