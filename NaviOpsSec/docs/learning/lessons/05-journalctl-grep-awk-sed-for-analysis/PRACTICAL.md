# Lesson 05 — Pure Practical: journalctl, grep, awk, sed for Analysis

> **Companion to [`README.md`](./README.md).** Pure practice: 3 scenario tasks, guided → ticket-driven
> → on-call. **Lab:** `docker exec -it siem-victim bash`. **Rules:** analyze before you conclude, run ✅
> **Verify** each task.

Each task: **Scenario · Objective · Given/constraints · Hints · ✅ Verify · Pitfalls · 🎯 Stretch.**

---

## Task 1 — Guided: slice logs by time, unit, and pattern (fluency)

**Scenario.** `SOC-051`. Master fast log triage: filter by time window, service, and pattern — the
analyst's core reflex.

**Objective.** Extract auth failures in a time window and tally them by source with one pipeline.

**Given / constraints.** Generate failures first; use `journalctl` + `grep/awk/sort/uniq`.

**Hints.**
1. Generate: brute-force the victim ssh (see L03). 
2. `journalctl -u ssh --since "10 min ago" | grep -i fail`.
3. Top sources: `... | awk '{print $NF}' | sort | uniq -c | sort -rn`.

✅ **Verify.**
```bash
docker exec siem-victim sh -c 'journalctl --since "1 hour ago" 2>/dev/null | grep -ic fail || grep -ic fail /var/log/auth.log' | grep -qE '[0-9]' && echo "FAILURES COUNTED ✅"
```

**Pitfalls.**
- Parsing by fixed columns instead of fields/regex (formats vary).
- No time bound → too much data.
- Case-sensitive grep missing `Failed`/`failed`.

🎯 **Stretch.** One pipeline: top 5 offending IPs with counts, sorted.

---

## Task 2 — Ticket-driven: extract the signal from a noisy log (diagnose)

**Scenario.** `SOC-052` (P2). *"Somewhere in this log is the attacker's activity — find it."* Filter
noise, isolate the suspicious pattern.

**Objective.** Isolate the malicious lines and summarize them (who/what/when) from a noisy log.

**Given / constraints.** A mixed log. Use progressive filtering (grep → awk → sort).

**Hints.**
1. Start broad (`grep -iE 'fail|error|denied'`), then narrow to the suspicious source/pattern.
2. `awk` to pull the fields that matter; `sort|uniq -c` to find volume.
3. `sed` to reformat for the report.

✅ **Verify.**
```bash
test -f docs/learning/reports/SOC-052-extract.md && echo "EXTRACT ✅"
```

**Deliverable.** `docs/learning/reports/SOC-052-extract.md`: filter pipeline · isolated activity · summary.

**Pitfalls.**
- Over-filtering (grep away the evidence).
- Regex that matches nothing (silent empty).
- Not recording the pipeline used (irreproducible).

🎯 **Stretch.** Turn the pipeline into a reusable `triage.sh`.

---

## Task 3 — On-call: build an incident timeline from raw logs (synthesis)

**Scenario.** `SOC-053` (P1, time-boxed). Multiple log sources, one incident. Merge them into a single
time-ordered timeline and identify the first malicious event.

**Objective.** A merged, normalized timeline naming the initial event; written up.

**Given / constraints.** Normalize timestamps across sources. Root = earliest malicious action.

**Hints.**
1. Extract + normalize timestamps from each source; `sort -m`.
2. Distinguish the first *cause* from downstream effects.
3. Write the timeline + the initial-access event.

✅ **Verify.**
```bash
test -s /tmp/timeline.txt && test -f docs/learning/reports/SOC-053-timeline.md && echo "TIMELINE ✅"
```

**Deliverable.** `docs/learning/reports/SOC-053-timeline.md`: merged timeline · first event · analysis.

**Pitfalls.**
- Timezone/format mismatches corrupting order.
- Calling a downstream effect the root.
- No reproducible extraction steps.

🎯 **Stretch.** Feed the normalized events into Wazuh for correlation.

---

## Done?
- [ ] All ✅ Verify pass · [ ] pipelines recorded · [ ] timeline names the first event.
- [ ] **Guardrails:** no real IPs/data committed. → [README Reflection](./README.md).
