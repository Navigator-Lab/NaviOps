# Lesson 33 — Python for Ops II: Parsing Logs/JSON, HTTP/APIs, Reports

**Gate Rule:** Concept → Real-World Use → Alternatives → Hands-On → Verification → Quiz → Reflection → Search Keywords
**Lenses:** A · B · C · E (D optional here)
**Artifacts:** `scripts/python/log_report.py`, `scripts/python/mon_check.py`
**Builds on:** Lesson 32 (CLIs/subprocess) and Lesson 19 (log analysis / incident response).

---

## Step 1 — Concept

**Plain English (Lens B):** Two things Bash does badly and Python does well: (1) reading messy text and
*aggregating* it ("how many failures, from which IPs?"), and (2) talking to services over HTTP. This lesson
turns raw logs into a triage report and turns an endpoint into an up/down check.

**Precise:** three pillars:
1. **Regex + aggregation** — `re` to extract fields, `collections.Counter` to tally them. This is where
   `grep | awk | sort | uniq -c` pipelines graduate into maintainable code.
2. **HTTP with the stdlib** — `urllib.request` (no `pip install requests` needed → runs offline in the lab)
   to probe an endpoint, capture status + latency.
3. **Structured output** — `json` so the result feeds Prometheus/Nagios/ServiceNow, not just human eyes.

**Three-level depth (Lens A) — `urllib.request.urlopen(url, timeout=5)`:**
1. *What:* fetches the URL, returns a response object with `.status`.
2. *How:* opens a TCP socket to host:port, (optionally TLS handshake), sends `GET / HTTP/1.1`, reads the
   status line + headers + body.
3. *Systems:* the `timeout` maps to a socket timeout — the same `connect()`/`recv()` sockets you met in
   Lesson 08. A monitor without a timeout is a monitor that hangs forever on a dead host.

## Step 2 — Real-World Use

- **Log triage** (`log_report.py`): the NOC/SOC "what's in this log?" pass — brute-force detection by
  counting failures per source IP, exactly what Lesson 19's `alert_triage.sh` does, but with richer grouping.
- **Synthetic monitoring** (`mon_check.py`): scheduled checks against Grafana/Prometheus/Nagios or any app
  URL — the building block of an uptime monitor and of a health endpoint in CI/CD.

## Step 3 — Alternatives

| Task | Bash | Python | Verdict |
|---|---|---|---|
| Count one pattern | `grep -c` | overkill | Bash |
| Group by IP *and* user, emit JSON | painful | `Counter` + `json` | **Python** |
| curl once | `curl` | `urllib` | either |
| Retry + parse body + timing + JSON out | fragile | clean | **Python** |
| Full monitoring | — | — | **Prometheus/Nagios** (Lesson 22/24); these scripts are the glue around them |

## Step 4 — Hands-On Task (build on the lab)

1. `./infra/bootstrap.sh monitoring` — Grafana(:3000), Prometheus(:9090), Nagios(:8081) come up.
2. Probe them:
   ```bash
   ./scripts/python/mon_check.py http://localhost:9090/-/healthy   # expect 200 UP
   ./scripts/python/mon_check.py --json http://localhost:3000
   ./scripts/python/mon_check.py http://localhost:9/   # nothing there -> DOWN (graceful, not a crash)
   ```
3. Triage a log:
   ```bash
   # generate some noise on a node, or use a real auth log:
   ./scripts/python/log_report.py /var/log/auth.log
   journalctl -u ssh --no-pager | ./scripts/python/log_report.py -
   ```
4. **Extend it:** add a `--threshold N` flag to `log_report.py` so the brute-force cutoff is configurable,
   and add one new `PATTERNS` entry (e.g. `sudo` command usage). Keep JSON output stable.

**Artifact Contract:** the two tools + your `--threshold`/new-pattern extension + a 3-line incident note
(`docs/runbooks/`) for the top offending IP `log_report.py` found.

## Step 5 — Verification

```bash
python3 -m py_compile scripts/python/log_report.py scripts/python/mon_check.py
printf 'Failed password for invalid user x from 10.0.0.9 port 1\n%.0s' {1..6} | ./scripts/python/log_report.py -
# expect: brute-force suspect 10.0.0.9 flagged, exit code 1
./scripts/python/mon_check.py --json http://localhost:9/ ; echo "exit=$?"   # DOWN, exit 1, no traceback
```

## Step 6 — Quiz (Interview-Style, Graded)

1. Why `urllib` instead of `requests` for a tool that must run on a locked-down, offline box?
2. What's the failure mode of an HTTP check with **no timeout**, and why does it matter at 3am?
3. `grep | awk | sort | uniq -c` already counts failures — when is that *better* than Python, and when worse?
4. You need the report consumed by both a human and ServiceNow. How do you serve both from one script?

## Step 7 — Reflection

- Which felt more natural for log triage — the Bash pipeline or `Counter`? When would you pick each?
- Did wiring `timeout` back to sockets (Lesson 08) change how you think about monitors?

## Lens E — Attacker & Defender

- **Attacker:** log parsers are attacked with **log injection** — forged lines / control chars to hide or
  spoof entries; giant lines to exhaust memory. `mon_check` fetching attacker-influenced URLs can be abused
  for **SSRF** (probing internal-only endpoints).
- **Defender:** read with `errors="replace"`, cap line handling, never `eval` log content; for probes,
  whitelist/validate target hosts. `log_report.py` uses `errors="replace"`; `mon_check.py` sets a UA + timeout.

## Step 8 — Search Keywords

`python re findall groups` · `collections.Counter most_common` · `urllib.request timeout status` ·
`python json.dumps indent` · `log injection prevention` · `ssrf server side request forgery` ·
`synthetic monitoring python`.

## Lesson Status
- [ ] Hands-On extension + incident note done (Step 4)
- [ ] Verification passed (Step 5)
- [ ] Quiz answered + professional comparison requested (Step 6)
- [ ] Reflection completed (Step 7)
