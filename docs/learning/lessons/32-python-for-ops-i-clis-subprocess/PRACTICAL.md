# Lesson 32 — Pure Practical: Python for Ops I (CLIs & subprocess)

> **Companion to [`README.md`](./README.md).** Pure practice: 3 scenario tasks, guided → ticket-driven
> → on-call. Do them after the README.
>
> **Lab:** `docker exec -it naviops-web bash`. **Artifacts:** grows `scripts/python/` (stdlib-only, offline).
> **Rules:** type it, run with real inputs, `python3 -m py_compile` before you trust it, run ✅ **Verify**.

Each task: **Scenario · Objective · Given/constraints · Hints · ✅ Verify · Pitfalls · 🎯 Stretch.**

---

## Task 1 — Guided: a proper CLI wrapping a system command (fluency)

**Scenario.** `NAVI-321`. Rewrite a Bash healthcheck as a Python CLI (`svc_ctl.py`) with `argparse`,
proper exit codes, and safe `subprocess` calls — the seed of a real ops tool.

**Objective.** A CLI with subcommands/flags that shells out safely, returns correct exit codes, and has
a `--help`.

**Given / constraints.** **stdlib only** (no pip). `subprocess.run` with a list (never `shell=True` on
user input). Non-zero exit on failure.

**Hints.**
1. `argparse` with subcommands (`status`, `check`); `--json` flag.
2. `subprocess.run([...], capture_output=True, text=True, check=False)`; inspect `.returncode`.
3. `sys.exit(code)` to propagate failure to callers/CI.

✅ **Verify.**
```bash
python3 -m py_compile scripts/python/svc_ctl.py && echo "COMPILES ✅"
python3 scripts/python/svc_ctl.py --help >/dev/null && echo "CLI OK ✅"
python3 scripts/python/svc_ctl.py status; echo "exit=$?"   # non-zero when a check fails
```

**Pitfalls.**
- `shell=True` with interpolated input → command injection.
- Ignoring `returncode` → failures look like successes.
- `print`ing errors to stdout instead of stderr; wrong exit codes break CI.

🎯 **Stretch.** Add `--timeout` to `subprocess.run` and handle `TimeoutExpired` gracefully.

---

## Task 2 — Ticket-driven: "the script crashes on some inputs" (diagnose → fix)

**Scenario.** `NAVI-322` (P2). *"The ops script throws a traceback on certain hosts/inputs and exits
dirty."* Make it robust — **diagnose the traceback first.**

**Objective.** Reproduce the crash, fix the root cause (unhandled exception, missing file, bad parse),
and make failures return clean errors + correct exit codes.

**Given / constraints.** Recreate a crash (e.g. parsing a command whose output format varies, or a
missing binary). Fix with proper exception handling, not a bare `except: pass`.

**Hints.**
1. Read the traceback — the last line is the exception type + the line that raised it.
2. Handle the *specific* exception (`FileNotFoundError`, `subprocess.CalledProcessError`), log context, exit non-zero.
3. Reproduce with the exact failing input; add a regression check.

✅ **Verify.**
```bash
python3 scripts/python/<tool>.py <the-failing-input>; echo "exit=$?"   # clean error, non-zero, no traceback
python3 scripts/python/<tool>.py <good-input>; echo "exit=$?"          # still 0 on happy path
```

**Pitfalls.**
- `except Exception: pass` → hides the bug and returns success.
- Catching too broadly and masking the real cause.
- Assuming a command's output format is stable across systems.

🎯 **Stretch.** Add a `unittest` (stdlib) that asserts the tool exits non-zero on the bad input.

---

## Task 3 — On-call: build a triage tool under pressure (synthesis)

**Scenario.** `NAVI-323` (P1, time-boxed). During an incident you need a tool *now* that gathers system
state (top processes, disk, failed services, recent errors) into one report — faster than typing five
commands each time.

**Objective.** A `scripts/python/sysinfo.py` that collects the key signals via `subprocess`/stdlib,
prints a readable + `--json` report, and exits non-zero if any signal is red.

**Given / constraints.** stdlib only, offline. Must run fast and never crash mid-incident (defensive).
Save a report artifact.

**Hints.**
1. Collect: disk (`shutil.disk_usage`), load (`os.getloadavg`), failed units (`systemctl --failed`), recent errors (`journalctl -p err --since`).
2. Structure results in a dict → human print + `json.dumps`.
3. Set exit code from a red-flag check so a monitor/CI can consume it.

✅ **Verify.**
```bash
python3 -m py_compile scripts/python/sysinfo.py && echo "COMPILES ✅"
python3 scripts/python/sysinfo.py --json | python3 -m json.tool >/dev/null && echo "VALID JSON ✅"
python3 scripts/python/sysinfo.py > docs/learning/reports/NAVI-323-sysinfo.txt; echo "exit=$?"
```

**Deliverable.** `docs/learning/reports/NAVI-323-sysinfo.txt` (the captured report) + a 3-line note on what it flagged.

**Pitfalls.**
- A tool that itself crashes during the incident (defensive coding matters most here).
- Blocking forever on a hung `subprocess` (use `timeout`).
- Human-only output with no `--json` → can't be automated later.

🎯 **Stretch.** Have it compare against a saved baseline and highlight only *changed* signals.

---

## Done?
- [ ] All ✅ Verify pass · [ ] no `shell=True` on input · [ ] correct exit codes · [ ] report artifact saved.
- [ ] stdlib-only, offline. **Redaction:** no real hostnames in reports. → [README Step 7](./README.md).
