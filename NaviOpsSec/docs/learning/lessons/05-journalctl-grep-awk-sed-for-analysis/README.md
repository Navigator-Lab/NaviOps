# Lesson 05 — journalctl · grep · awk · sed for Analysis

**Status:** ✅ ready for self-study (full depth) · **Date written:** 2026-06-20
**Schema:** 12-section SOC (`docs/learning/CLAUDE_TEACHING_RULES.md`)
**Focus:** the text-processing toolkit that turns raw logs into answers — filtering, extracting,
counting, and building a timeline with `journalctl`, `grep`, `awk`, `sed`, `sort`, `uniq`, `cut`.
**Primary artifact:** `scripts/log_triage.sh` (v2 — grows from Lesson 01).

> **How to use this lesson:** read §1–§7, do §8 (build real one-liners + grow `log_triage.sh`),
> produce §9, answer the quiz, reflect. Then Lesson 06.

---

## §1 — Concept (Scientific Theory)

### What it is
Investigation is, mechanically, **text processing**. Logs are lines; an answer ("who hit us most",
"when did it start", "what did this user do") comes from **filtering** (grep/journalctl),
**extracting fields** (awk/cut/sed), and **summarizing** (sort/uniq -c). Master this pipeline and
you can answer almost any host question in seconds — and the SIEM query language is just this idea
with a GUI.

### Why it exists
When the SIEM is down, or the evidence is a raw file, or you need an answer *now*, the Linux text
tools are the fastest path from "200,000 log lines" to "these 3 IPs, this timeline." It's the most
transferable, interview-tested skill an analyst has.

### Three-Level Depth (Lens A)
- **Level 1 — Beginner:** `grep` finds lines with a word; `awk`/`cut` pull out a column;
  `sort | uniq -c` counts how often each thing appears. Chain them with `|`.
- **Level 2 — Analyst/SOC:** the workhorse pattern is **filter → extract → count → sort**:
  `grep PATTERN file | awk '{print $FIELD}' | sort | uniq -c | sort -rn`. That single idiom answers
  "top sources/users/URIs/errors." `journalctl` adds time/unit/priority filtering at the source.
- **Level 3 — Adversary/Kernel:** building a **timeline** means parsing timestamps and ordering
  events across multiple logs into one sequence. `awk` can compare/threshold (e.g. count attempts
  per IP and flag ≥N) — that's a *detection* expressed in Bash, the same logic a SIEM frequency
  rule implements (Lesson 19).

### Two Teaching Approaches (Lens B) — the analysis pipeline
**Approach 1 (technical):** each tool is a stream transducer; piping composes them into a query.
`grep` = row filter, `awk`/`cut` = column projection, `sort`/`uniq -c` = group-by-count, `sed` =
substitution/cleanup. Together they're a relational query over text.

**Approach 2 (analogy):** a **kitchen line** for data. `grep` picks the right ingredients off the
shelf (rows you want); `awk`/`cut` chops them to the part you need (the IP column); `sort | uniq -c`
tallies them into a recipe count; `sed` cleans up the plating. **Where it breaks down:** real logs
are messy (multi-line, varying formats) — which is why structured logging + a SIEM eventually
beats ad-hoc parsing at scale.

### Visual (ASCII) — the idiom
```
  grep "Failed password" auth.log   →  only failed-login lines
        |  awk '{print $(NF-3)}'     →  pull the source-IP column
        |  sort                      →  group identical IPs together
        |  uniq -c                   →  count each
        |  sort -rn                  →  biggest offenders first
  =>   240 10.0.0.99      18 10.0.0.50      3 10.0.0.7
```

---

## §2 — Linux Investigation Commands

```bash
# journalctl: filter at the source
journalctl -u sshd -S "2026-06-20 02:00" -U "2026-06-20 03:00"   # unit + time window
journalctl -p err -g "fail|denied" -S -1h        # priority + regex grep (-g)
journalctl -o short-iso -u nginx                  # ISO timestamps (good for timelines)

# the core idiom — top failed-login sources
grep "Failed password" /var/log/auth.log \
  | awk '{print $(NF-3)}' | sort | uniq -c | sort -rn | head

# extract + count usernames targeted
grep "Failed password" /var/log/auth.log | sed -n 's/.*for \(invalid user \)\?\([^ ]*\) from.*/\2/p' \
  | sort | uniq -c | sort -rn

# threshold in awk (a detection in one line): flag IPs with >=10 failures
grep "Failed password" /var/log/auth.log | awk '{c[$(NF-3)]++} END{for(i in c) if(c[i]>=10) print c[i], i}'

# build a quick timeline (sorted events from a window)
journalctl -S -2h -o short-iso | grep -Ei "sshd|sudo|useradd|cron" | sort
```
| Linux idiom | SIEM equivalent |
|---|---|
| `grep \| awk \| uniq -c \| sort` | a SIEM aggregation / top-N query |
| `awk` threshold | a Wazuh **frequency** rule (Lesson 19) |
| `journalctl -S/-U` | the SIEM time-range filter |

---

## §3 — Real-World Threat Context & Use Cases

- **"Who's hitting us?"** — top source IPs from auth/web logs in one pipe.
- **"When did it start/stop?"** — `journalctl` time window + ISO output → the incident window.
- **"What did this user do?"** — filter by user across auth/sudo/audit, order by time.
- **Field shifts break naïve parsing** — `awk '{print $11}'` fails when a username has spaces or
  the format varies; prefer anchored `sed`/regex or `journalctl` structured fields. (Classic
  gotcha + interview discriminator.)
- **Exam framing:** log analysis with CLI tools is core to CySA+/BTL1 and every Linux SOC screen.

---

## §4 — Detection

A detection is just the analysis idiom with a **threshold/condition** and a schedule:
- **Threshold detection** (`awk` counts ≥N) = the logic of a SIEM frequency rule — you'll port it
  to Wazuh in Lesson 19.
- **Pattern detection** (`grep -E "UNION SELECT|\.\./"`) = the logic of a Wazuh/Sigma match rule
  (Lessons 23, 27).
- Build the one-liner first, confirm it fires on the (lab) signal and is quiet on benign data,
  *then* it's ready to become a rule. That order (test in Bash → promote to rule) is the detection
  engineer's habit.

---

## §5 — Investigation & Triage

These tools *are* the investigation engine. Triage flow on the box: `grep` the alert's indicator →
`awk`/`uniq -c` to see scope (one source or many?) → `journalctl` time window to bound it → build
the timeline. The skill that wins interviews: producing the right one-liner *fast* and explaining
*why* each stage is there.

---

## §6 — SOC Perspective

Even with a SIEM, analysts drop to the CLI constantly — to validate an alert, parse an odd log the
SIEM didn't decode, or work an offline evidence file. `log_triage.sh` codifies the team's standard
first-look so every analyst runs the same query (`soc/case-management.md` consistency). Speed here
directly improves MTTR.

---

## §7 — Incident-Response Perspective

Timeline-building (IR Phase 2) is this lesson applied: parse timestamps across `auth.log`,
`audit.log`, web logs, and `journalctl` into one ordered sequence — the spine of the incident
report (`templates/incident-report.md`). Do it on a **copy** of preserved evidence, never the live
log you might alter.

---

## §8 — Practical Lab (build this yourself)

**Goal:** build the core one-liners and grow `log_triage.sh` into a real first-look tool.

### Lens C — Manual → Automated → Why
- **Manual:** type the top-sources pipe by hand against `auth.log`.
- **Automated:** fold it (and the username/timeline variants) into `scripts/log_triage.sh` so one
  command produces the whole first-look report.
- **Why:** under incident pressure, you run a trusted script, not recall flags. Production wraps
  these into scheduled detections + SOAR enrichment.

### Steps
1. Generate signal (lab): a handful of failed SSH logins to your VM (drill 1).
2. Build and run, one at a time: top source IPs, top targeted usernames, the `awk` ≥10 threshold,
   and a 2-hour `journalctl` timeline. Explain each stage out loud.
3. Add the "top failed-login sources" + "targeted usernames" blocks to `scripts/log_triage.sh`
   (v2). `bash -n` + `shellcheck` clean.
4. Run `log_triage.sh` and confirm it surfaces your lab failures.
5. Save your best 5 one-liners to `docs/playbooks/log-oneliners.md` (your personal cheat-sheet).

### Lens D — the raw artifact
```
Jun 20 02:14:07 web01 sshd[8123]: Failed password for invalid user admin from 10.0.0.99 port 51234 ssh2
#                                                              ^username        ^$(NF-3)=IP   ^port
# awk field math: NF=last field (ssh2); NF-3 = the IP. That's why '{print $(NF-3)}' extracts it.
```

---

## §9 — GitHub Artifact (the 6-artifact evidence package)

1. **Script:** `scripts/log_triage.sh` v2 (committed, `shellcheck`-clean).
2. **Detection rule/config:** `docs/playbooks/log-oneliners.md` (the tested one-liners — rule
   precursors).
3. **Runbook:** `docs/runbooks/runbook-logquery.md` — "to answer X about a log, run Y."
4. **Playbook:** the analysis-pipeline play (filter→extract→count→sort).
5. **Incident report + notes:** a short report using a one-liner to find the top attacker IP +
   build a mini-timeline.
6. **SOC ticket:** `SOC-05` (Task: "build log analysis toolkit") → Closed.

---

## §10 — Portfolio Artifact

- **Resume bullet:** "Built a Linux log-analysis toolkit (`log_triage.sh` + one-liner library)
  that extracts top attacker sources, targeted accounts, and incident timelines from raw logs."
- **Interview talking point:** write the top-failed-login one-liner from memory and explain every
  stage — the single most common Linux-SOC interview task.
- **Serves:** Security Analyst → SOC T1 (Stages 1–2). **Closes the Wave-1 foundation block.**

---

## §11 — Certification Crossover Notes

- **CySA+:** log analysis (core). **BTL1:** investigations/log analysis. **SC-200:** KQL analog
  (same filter/extract/aggregate thinking). **Security+:** monitoring (4.x). Reinforces NaviOps
  text-processing. Detail: `alignment/CERTIFICATION-MAPPING.md`.

---

## §12 — Security Notes (Lens E — Attacker & Defender)

**🔴 Attacker:** attackers generate the noise you parse (brute force, scans) and try to hide in
high-volume logs (low-and-slow) so a naïve `uniq -c` won't flag them; they may also inject
misleading entries (log injection) to confuse parsing.

**🔵 Defender:** use thresholds *and* time-windows (catch low-and-slow with longer windows),
normalize fields (don't trust positional `$11` blindly), and corroborate across log sources so a
single forged line can't mislead you. Your tested one-liner becomes the Wazuh frequency rule.

---

## Quiz (Interview-Style, Graded)

**Q1.** Write a one-liner that lists the top 5 source IPs by failed SSH login count, and explain
each stage of the pipe.
> **Your answer:**

**Q2.** Why is `awk '{print $11}'` fragile for parsing usernames out of `auth.log`, and what's a
more robust approach?
> **Your answer:**

**Q3.** How would you bound an incident to a time window using `journalctl`, and why use ISO output
for a timeline?
> **Your answer:**

**Q4.** **Scenario:** you have a 2 GB access log and need the top 10 URIs returning 500s in the last
hour. Sketch the pipeline.
> **Your answer:**

**Q5.** How does an `awk` threshold one-liner relate to a SIEM frequency rule, and why build the
one-liner first?
> **Your answer:**

*(Request the "Professional Answer" comparison under each before moving on.)*

---

## Reflection
*(After the quiz)* — What did you learn? · What confused you? · What would you do differently?

---

## Search Keywords For Further Understanding

**Core**
- `grep awk sort uniq log analysis one liner`
- `journalctl time range since until iso`
- `awk count threshold field`
- `sed extract field from log`
- `build incident timeline from logs linux`

**Tools**
- `journalctl cheat sheet`
- `bash log parsing security`

**Going further**
- `syslog log management` (L06) · `siem query` (L13) · `brute force frequency rule` (L19)

**Red / Blue (Lens E):**
- 🔴 `low and slow brute force evade threshold`, `log injection`
- 🔵 `time-window threshold detection`, `cross-source log correlation`, `robust log field parsing`

---

## Lesson Status
- [ ] §8 lab completed (one-liners built; `log_triage.sh` v2; cheat-sheet saved)
- [ ] 6-artifact evidence package committed (§9)
- [ ] Quiz answered + professional-answer comparisons (graded)
- [ ] Reflection + Search Keywords reviewed

When complete, run the Update Protocol, then move to **Lesson 06 — Syslog & Log Management**.

---

*Lesson 05 written by Navi · 2026-06-20 · full-depth. Sources to cite at study time: man7
`journalctl(1)`/`awk(1)`, GNU coreutils, CySA+ CS0-003 log-analysis objectives.*
