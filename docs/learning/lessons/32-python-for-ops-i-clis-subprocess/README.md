# Lesson 32 — Python for Ops I: CLIs, argparse, subprocess

**Gate Rule:** Concept → Real-World Use → Alternatives → Hands-On → Verification → Quiz → Reflection → Search Keywords
**Lenses:** A (three-level depth) · B (double-explanation) · C (automation) · D (C/internals) · E (attacker/defender)
**Artifacts:** `scripts/python/sysinfo.py`, `scripts/python/svc_ctl.py`
**Why this lesson exists:** the 2026 job market wants Bash **and** Python. Bash is the daily driver;
Python is what you reach for the moment a script needs real logic, structured data, or error handling.
(EXP 2026-07-01 §4 — Python was the one missing language in the curriculum.)

---

## Step 1 — Concept

**Plain English (Lens B):** Bash is glue for running commands; Python is a real programming language for
when the glue gets complicated. A Python "ops tool" is just a script that (1) takes arguments, (2) does
something to the system, (3) prints a result, and (4) returns an exit code so other tools can react.

**Precise:** A well-formed Python CLI has four parts:
1. **argument parsing** — `argparse` turns `--json --disk-warn 70` into typed values, with a free `--help`.
2. **doing the work** — pure functions that read `/proc`, call other programs, or hit an API.
3. **output** — human-readable *or* machine-readable (JSON) behind a `--json` flag.
4. **exit code** — `sys.exit(0)` healthy, non-zero on problems (cron/monitoring depend on this).

**Three-level depth (Lens A) — `subprocess.run(["systemctl","is-active","ssh"])`:**
1. *What:* runs `systemctl is-active ssh` and captures its output.
2. *How:* Python `fork()`s, the child `execve()`s `systemctl`, stdout/stderr are wired to pipes, the parent
   `wait()`s and collects the return code.
3. *Kernel (Lens D):* this is the exact `fork`/`exec`/`wait` syscall dance you saw in C in Lesson 04 —
   `subprocess` is a friendly wrapper over the same primitives. **Passing a list (not a string) means no
   shell is involved → no shell-injection surface.** That's a security property, not a style choice.

## Step 2 — Real-World Use

- **On the job:** health snapshots, service restarts, provisioning glue, "run this on 50 boxes" wrappers,
  API calls to monitoring/cloud. Job posts list Python as *the* most common sysadmin technical skill.
- **Why not just Bash?** The moment you need a dictionary, JSON, retries, or "parse this and decide," Bash
  becomes fragile. Python stays readable.

## Step 3 — Alternatives (and when to pick each)

| Need | Reach for | Why |
|---|---|---|
| One-liner over files/pipes | **Bash** | shortest path; native to the shell |
| Logic, data structures, JSON, APIs | **Python** | real types, error handling, libraries |
| Config-manage many hosts declaratively | **Ansible** (Lesson 13) | idempotent, inventory-driven |
| Static, compiled, low-level | **C** (Lens D) | when you need the syscall itself, not a wrapper |

Rule of thumb: **> ~30 lines of Bash, or any JSON/HTTP → switch to Python.**

## Step 4 — Hands-On Task (build on the lab)

1. Bring the lab up: `./infra/bootstrap.sh up`, then `docker exec -it naviops-web bash`.
2. Copy the two tools in (or `git pull` the repo inside the node) and run:
   ```bash
   python3 sysinfo.py            # health snapshot
   python3 sysinfo.py --json     # same data, machine-readable
   python3 svc_ctl.py status ssh cron
   python3 svc_ctl.py restart ssh   # stop ssh first to see the restart path
   ```
3. **Extend it (the real learning):** add a `--swap-warn` check to `sysinfo.py` reading `SwapTotal`/`SwapFree`
   from `/proc/meminfo`. Keep the JSON shape consistent.

**Artifact Contract:** the two `scripts/python/*.py` tools + your `--swap-warn` extension.

## Step 5 — Verification

```bash
python3 -m py_compile scripts/python/sysinfo.py scripts/python/svc_ctl.py   # no output = clean
./scripts/python/sysinfo.py --json | python3 -m json.tool                   # valid JSON pretty-prints
echo "exit code: $?"                                                        # 0 healthy / 1 warnings
```
Expected: compiles clean, JSON parses, exit code reflects health.

## Step 6 — Quiz (Interview-Style, Graded)

1. Why pass a **list** to `subprocess.run` instead of a string with `shell=True`?
2. What does a non-zero exit code let a *cron job* or *monitoring system* do that printing "ERROR" doesn't?
3. Your script must run on a box with no internet and no pip. Which libraries are safe to use?
4. When would you rewrite a 200-line Bash script in Python — and when would you leave it in Bash?

*(Answer from memory, then ask for the professional-answer comparison before Lesson 33.)*

## Step 7 — Reflection

- Where did Bash's lack of real data structures bite you before?
- Did the `fork`/`exec`/`wait` link back to Lesson 04 make `subprocess` feel less magic?

## Lens E — Attacker & Defender

- **Attacker:** `shell=True` with any user-influenced input = command injection (`; rm -rf /`). String
  concatenation into shell commands is the classic Python-ops vulnerability.
- **Defender:** always pass argument **lists**; validate/whitelist inputs; never interpolate untrusted data
  into a shell. `sysinfo.py`/`svc_ctl.py` use lists and `shell=False` on purpose.

## Step 8 — Search Keywords

`python argparse subcommands` · `subprocess run capture_output check` · `shell=True injection` ·
`python /proc/meminfo parse` · `os.getloadavg cpu_count` · `python cli exit codes sys.exit` ·
`why python over bash sysadmin`.

## Lesson Status
- [ ] Hands-On extension done (Step 4)
- [ ] Verification passed (Step 5)
- [ ] Quiz answered + professional comparison requested (Step 6)
- [ ] Reflection completed (Step 7)
