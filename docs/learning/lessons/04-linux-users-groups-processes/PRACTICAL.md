# Lesson 04 — Pure Practical: Users, Groups & Processes

> **Companion to [`README.md`](./README.md).** Pure practice: 3 scenario tasks, guided → ticket-driven
> → on-call. Do them after the README.
>
> **Lab:** `docker exec -it naviops-web bash`. **Node:** `naviops-web`. **Artifacts:** `scripts/user_audit.sh`, `scripts/process_monitor.sh`.
> **Rules:** type it, diagnose before you fix, run ✅ **Verify** each task.

Each task: **Scenario · Objective · Given/constraints · Hints · ✅ Verify · Pitfalls · 🎯 Stretch.**

---

## Task 1 — Guided: onboard a service account with least privilege (fluency)

**Scenario.** `NAVI-041`. A new app needs a dedicated system user that can't log in interactively and
owns only its own working dir.

**Objective.** Create a no-login system user + group, own `/opt/naviapp`, and confirm it can't `ssh`/`su -`.

**Given / constraints.** No password login, no shell. Least privilege only.

**Hints.**
1. `useradd -r -s /usr/sbin/nologin -d /opt/naviapp -m naviapp`.
2. `chown -R naviapp:naviapp /opt/naviapp`.
3. Confirm shell: `getent passwd naviapp` ends in `nologin`.

✅ **Verify.**
```bash
getent passwd naviapp | grep -q nologin && echo "NO SHELL ✅"
sudo -u naviapp -s 2>&1 | grep -qi 'not allowed\|nologin' && echo "LOGIN BLOCKED ✅"
stat -c '%U' /opt/naviapp        # naviapp
```

**Pitfalls.**
- Giving a service account `/bin/bash` and a password — needless attack surface.
- Forgetting `-r` (system UID range) — clutters the human-UID space.
- Owning files as root when the service runs as the user → permission errors at runtime.

🎯 **Stretch.** Restrict it further with a `sudoers` drop-in allowing only one specific command (NOPASSWD), and prove `sudo -u naviapp` can run that and nothing else.

---

## Task 2 — Ticket-driven: "a process is pegging the CPU" (diagnose → fix)

**Scenario.** `NAVI-042` (P2). Alert: *"naviops-web load average climbing, users report slowness."*
Something is eating CPU; find it and stop it safely.

**Objective.** Identify the top CPU process, its owner and parent, and terminate it **gracefully**
(then forcibly only if needed) — after confirming it's safe to kill.

**Given / constraints.** Simulate: `yes > /dev/null &` (or a busy loop). Don't `kill -9` first — try
`TERM`, escalate to `KILL` only if it ignores.

**Hints.**
1. `top`/`ps -eo pid,ppid,user,%cpu,cmd --sort=-%cpu | head`.
2. Understand it: who owns it, what's its parent (`ppid`)? Is it a symptom of something else?
3. `kill <pid>` (SIGTERM) → recheck → `kill -9 <pid>` only if it won't die.

✅ **Verify.**
```bash
ps -eo %cpu,cmd --sort=-%cpu | head -3     # the hog is gone; load settling
uptime                                      # 1-min load trending down
```

**Pitfalls.**
- `kill -9` reflexively → no clean shutdown, possible corruption; and you may kill the wrong pid.
- Killing a *child* while a supervisor respawns it — trace the `ppid` first.
- Confusing high load (I/O wait) with high CPU — check `top`'s `wa`.

🎯 **Stretch.** Extend `scripts/process_monitor.sh` to alert (exit non-zero) when any process exceeds
an `%CPU`/RSS threshold for N samples — the seed of a real monitor.

---

## Task 3 — On-call: audit "who has access to what" after a scare (synthesis)

**Scenario.** `NAVI-043` (P1, time-boxed). Security asks, mid-incident: *"which accounts can get root,
which have shells, and are any unexpected?"* You must answer fast and leave an artifact.

**Objective.** Produce a `scripts/user_audit.sh` report: login-capable users, `sudo`/`wheel` members,
UID-0 accounts, and empty-password accounts — flagging anything unexpected.

**Given / constraints.** Read-only investigation (don't delete accounts during an incident). Output a
saved report.

**Hints.**
1. UID 0: `awk -F: '$3==0' /etc/passwd` (should be only `root`). Shells: `getent passwd | grep -v nologin`.
2. Privilege: `getent group sudo wheel`. Empty passwords: `awk -F: '($2==""){print $1}' /etc/shadow` (sudo).
3. Write findings to a file; exit non-zero if a red flag (extra UID-0 / empty password) is found.

✅ **Verify.**
```bash
scripts/user_audit.sh > /tmp/audit.txt; echo "exit=$?"    # non-zero if a red flag found
grep -c . /tmp/audit.txt                                   # report has content
test -f docs/learning/reports/NAVI-043-postmortem.md && echo "POSTMORTEM ✅"
```

**Deliverable.** `docs/learning/reports/NAVI-043-postmortem.md`: Impact · Detection · Root cause · Fix · Prevention.

**Pitfalls.**
- Reading `/etc/shadow` without sudo → silent empty result, false "all clear".
- Assuming only `root` has UID 0 — a backdoor account can share it; always check.
- Deleting a suspicious account before forensics captures it.

🎯 **Stretch.** Diff today's audit against a committed baseline so *changes* in privileged access page you.

---

## Done?
- [ ] All ✅ Verify pass · [ ] graceful kill before force · [ ] postmortem written.
- [ ] Least privilege everywhere. **Redaction:** no real usernames committed. → [README Step 7](./README.md).
