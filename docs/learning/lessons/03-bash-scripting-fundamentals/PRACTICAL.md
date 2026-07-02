# Lesson 03 — Pure Practical: Bash Scripting Fundamentals

> **Companion to [`README.md`](./README.md).** Pure practice: 3 scenario tasks, guided → ticket-driven
> → on-call. Do them after the README.
>
> **Lab:** `docker exec -it naviops-web bash`. **Node:** `naviops-web`. **Artifact:** grows `scripts/`.
> **Rules:** type it, `bash -n` before you run, `shellcheck` if installed, run ✅ **Verify** each task.

Each task: **Scenario · Objective · Given/constraints · Hints · ✅ Verify · Pitfalls · 🎯 Stretch.**

---

## Task 1 — Guided: a safe, reusable healthcheck script (fluency)

**Scenario.** `NAVI-031`. You need a small script that checks disk, load, and a service, and prints a
clean PASS/FAIL — the seed of `scripts/healthcheck.sh`.

**Objective.** Write a script with a strict header, a `log()` helper, and 3 checks, exiting non-zero
if any fails.

**Given / constraints.** Start with `set -euo pipefail`. No hard-coded paths that only work for you.

**Hints.**
1. Header: `#!/usr/bin/env bash` + `set -euo pipefail`.
2. `log(){ printf '%s [%s] %s\n' "$(date +%FT%T)" "$1" "$2"; }`.
3. Checks: disk `df` %, load from `/proc/loadavg`, service via `systemctl is-active`. Track a `rc` and `exit "$rc"`.

✅ **Verify.**
```bash
bash -n scripts/healthcheck.sh && echo "SYNTAX ✅"
scripts/healthcheck.sh; echo "exit=$?"      # 0 when healthy, non-zero when a check fails
command -v shellcheck >/dev/null && shellcheck scripts/healthcheck.sh
```

**Pitfalls.**
- No `set -u` → typo'd variable silently expands to empty and "passes".
- Unquoted `$var` in tests → word-splitting breaks on spaces.
- `exit 0` at the end regardless of failures — the check becomes a lie.

🎯 **Stretch.** Add a `--json` flag that emits `{"check":"disk","status":"pass"}` lines so a monitor can parse it.

---

## Task 2 — Ticket-driven: "the cron script works by hand but fails scheduled" (diagnose → fix)

**Scenario.** `NAVI-032` (P3). *"My backup script runs fine when I run it, but silently does nothing
from cron."* Classic. You have the script and the crontab line.

**Objective.** Find why the environment differs under cron and fix the script to be
environment-independent. **Diagnose before editing.**

**Given / constraints.** Recreate: a script relying on a relative path / `$PATH` binary / `cd` with no
error handling. Don't "fix" it by hard-coding your home dir.

**Hints.**
1. Cron has a minimal `PATH` and no interactive profile. Capture output: append `>> /tmp/x.log 2>&1` to the cron line and read it.
2. Make it robust: absolute paths or `cd "$(dirname "$0")" || exit 1`; full binary paths or set `PATH` at top.
3. Check `$?` and quoting; test with `env -i bash script.sh` to simulate the bare environment.

✅ **Verify.**
```bash
env -i /bin/bash scripts/backup.sh && echo "RUNS IN BARE ENV ✅"   # simulates cron's environment
ls -1 <expected-output-artifact>            # the backup actually got produced
```

**Pitfalls.**
- Assuming cron sources `.bashrc`/`.profile` — it doesn't.
- Relative paths that depend on your login CWD.
- Errors swallowed because output isn't redirected anywhere.

🎯 **Stretch.** Add a lockfile (`flock`) so overlapping cron runs can't corrupt the backup.

---

## Task 3 — On-call: parse a messy log to triage an incident (synthesis)

**Scenario.** `NAVI-033` (P1, time-boxed). During an incident you must, fast, turn a raw log into
answers: top offending IPs, error rate over time, and a one-line summary — no fancy tools, just Bash.

**Objective.** Write a `scripts/alert_triage.sh` that takes a logfile and prints top-5 error sources +
total error count, exiting non-zero if errors exceed a threshold.

**Given / constraints.** Use a sample log (generate one, or `/var/log/*`). Pure Bash/coreutils
(`grep/awk/sort/uniq/cut`) — no Python for this drill.

**Hints.**
1. Errors: `grep -iE 'error|fail' | wc -l`. Top sources: `awk '{print $1}' | sort | uniq -c | sort -rn | head`.
2. Threshold gate: `if (( count > THRESH )); then exit 1; fi`.
3. Make the logfile an argument with a usage message.

✅ **Verify.**
```bash
bash -n scripts/alert_triage.sh && echo "SYNTAX ✅"
scripts/alert_triage.sh /path/to/sample.log; echo "exit=$?"   # non-zero when over threshold
test -f docs/learning/reports/NAVI-033-postmortem.md && echo "POSTMORTEM ✅"
```

**Deliverable.** `docs/learning/reports/NAVI-033-postmortem.md`: Impact · Detection · Root cause · Fix · Prevention.

**Pitfalls.**
- Parsing with a fragile `cut -c` on column positions instead of fields.
- `cat file | grep` (useless-cat) and unquoted globs.
- No usage/arg check → cryptic failure when run with no file.

🎯 **Stretch.** Add a `--since "HH:MM"` filter that only counts lines after a timestamp.

---

## Done?
- [ ] All ✅ Verify pass · [ ] `bash -n`/shellcheck clean · [ ] postmortem written.
- [ ] Scripts run in a bare environment. **Redaction:** no real IPs in sample logs. → [README Step 7](./README.md).
