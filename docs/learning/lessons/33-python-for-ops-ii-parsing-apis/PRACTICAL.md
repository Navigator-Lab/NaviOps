# Lesson 33 — Pure Practical: Python for Ops II (Parsing & APIs)

> **Companion to [`README.md`](./README.md).** Pure practice: 3 scenario tasks, guided → ticket-driven
> → on-call. Do them after the README.
>
> **Lab:** `docker exec -it naviops-web bash`. **Artifacts:** grows `scripts/python/` (stdlib-only, offline).
> **Rules:** type it, test against real data, `py_compile` before you trust it, run ✅ **Verify**.

Each task: **Scenario · Objective · Given/constraints · Hints · ✅ Verify · Pitfalls · 🎯 Stretch.**

---

## Task 1 — Guided: parse logs into structured data + a report (fluency)

**Scenario.** `NAVI-331`. Turn a raw log into structured records (dicts) and emit a summary report
(counts by level, top sources) as text and JSON — a `log_report.py`.

**Objective.** A parser that reads a log, produces structured records, and prints a summary + `--json`.

**Given / constraints.** **stdlib only** (`re`, `json`, `collections`). Handle malformed lines without
crashing. Sample log provided/generated.

**Hints.**
1. `re` to capture fields; `collections.Counter` for tallies.
2. Skip/count malformed lines (don't crash); accumulate into a summary dict.
3. `json.dumps(summary, indent=2)` for the `--json` path.

✅ **Verify.**
```bash
python3 -m py_compile scripts/python/log_report.py && echo "COMPILES ✅"
python3 scripts/python/log_report.py sample.log --json | python3 -m json.tool >/dev/null && echo "VALID JSON ✅"
python3 scripts/python/log_report.py sample.log | grep -qiE 'error|count' && echo "SUMMARY ✅"
```

**Pitfalls.**
- A regex that silently matches nothing → empty report that looks fine.
- Crashing on the first malformed line instead of skipping/counting it.
- No `--json` → can't feed the next tool.

🎯 **Stretch.** Add a `--since HH:MM` filter and a per-hour breakdown.

---

## Task 2 — Ticket-driven: "the API poller is flaky/misparses" (diagnose → fix)

**Scenario.** `NAVI-332` (P2). *"The monitoring poller (`mon_check.py`) sometimes errors or reports
wrong numbers."* It hits a local HTTP endpoint (Prometheus `:9090`, or a mock) and parses JSON.

**Objective.** Make the poller correct + resilient: handle non-200s, timeouts, and missing JSON keys —
**diagnose the failure first.**

**Given / constraints.** stdlib `urllib` (no `requests`). Local endpoint only (offline). Fix the actual
fault (missing timeout, unguarded key access, no status check).

**Hints.**
1. `urllib.request` with a **timeout**; check the HTTP status before parsing.
2. Guard JSON access: `data.get(...)` / catch `json.JSONDecodeError` and `KeyError`.
3. Retry/backoff on transient failure; exit non-zero after exhausting retries.

✅ **Verify.**
```bash
python3 scripts/python/mon_check.py http://localhost:9090/api/v1/query?query=up; echo "exit=$?"
# point it at a dead port — must fail cleanly, not hang or traceback:
timeout 10 python3 scripts/python/mon_check.py http://localhost:1/nope; echo "exit=$? (non-zero, no hang)"
```

**Pitfalls.**
- No timeout → the poller hangs forever when the endpoint is down (worst case during an incident).
- Assuming HTTP 200/valid JSON → `KeyError`/`JSONDecodeError` crash.
- Reporting a wrong value silently instead of failing on a missing key.

🎯 **Stretch.** Add exponential backoff with a max-retry cap; log each attempt.

---

## Task 3 — On-call: glue tool that turns metrics/logs into an alert decision (synthesis)

**Scenario.** `NAVI-333` (P1, time-boxed). You need a single tool that pulls a metric (API) + scans a
log (parse), decides pass/warn/fail by thresholds, and emits a machine-readable verdict a pipeline can
gate on — combining L32 + this lesson.

**Objective.** A tool that fetches + parses + decides, prints a `--json` verdict, exits with a code that
maps to pass/warn/fail, and saves a report.

**Given / constraints.** stdlib only, offline (local endpoint + local log). Deterministic thresholds.
Defensive (never crash mid-incident).

**Hints.**
1. Reuse the API fetch (L33 T2) + the log parse (T1); combine into one verdict function.
2. Exit codes: `0` pass, `1` warn, `2` fail — so CI/monitors can branch.
3. Emit `{"verdict":"fail","reasons":[...]}`; save to the reports dir.

✅ **Verify.**
```bash
python3 -m py_compile scripts/python/<gluetool>.py && echo "COMPILES ✅"
python3 scripts/python/<gluetool>.py --json | python3 -m json.tool >/dev/null && echo "VALID VERDICT ✅"
python3 scripts/python/<gluetool>.py > docs/learning/reports/NAVI-333-verdict.json; echo "exit=$?"   # 0/1/2
```

**Deliverable.** `docs/learning/reports/NAVI-333-verdict.json` + a 3-line note on the thresholds chosen and why.

**Pitfalls.**
- Non-deterministic thresholds → flaky gate.
- One catch-all exit code → the pipeline can't distinguish warn from fail.
- A glue tool that crashes takes down the pipeline it was meant to protect.

🎯 **Stretch.** Wire it into the L14 CI workflow as a gate step (offline-runnable) that blocks on `fail`.

---

## Done?
- [ ] All ✅ Verify pass · [ ] resilient (timeouts, guarded parsing) · [ ] pass/warn/fail exit codes · [ ] verdict artifact saved.
- [ ] stdlib-only, offline. **Redaction:** no real endpoints/data committed. → [README Step 7](./README.md).
