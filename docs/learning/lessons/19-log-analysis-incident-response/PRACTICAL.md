# Lesson 19 — Pure Practical: Log Analysis & Incident Response

> **Companion to [`README.md`](./README.md).** Pure practice: 3 scenario tasks, guided → ticket-driven
> → on-call. Do them after the README.
>
> **Lab:** `docker exec -it naviops-web bash`. **Artifact:** `scripts/alert_triage.sh`.
> **Rules:** type it, diagnose before you fix, run ✅ **Verify** each task.

Each task: **Scenario · Objective · Given/constraints · Hints · ✅ Verify · Pitfalls · 🎯 Stretch.**

---

## Task 1 — Guided: extract signal from a raw access log (fluency)

**Scenario.** `NAVI-191`. Given a web access log, answer the standard first questions: request volume
over time, top URLs, top clients, and the error rate.

**Objective.** Produce those four numbers with coreutils, saved to a short report.

**Given / constraints.** Generate/obtain a sample log. Pure `grep/awk/sort/uniq` (no external tools).

**Hints.**
1. Top clients: `awk '{print $1}' access.log | sort | uniq -c | sort -rn | head`.
2. Error rate: `awk '$9 ~ /^5/' access.log | wc -l` vs total lines.
3. Per-hour volume: `awk -F'[:[]' '{print $2":"$3}' | uniq -c` (adjust to your format).

✅ **Verify.**
```bash
scripts/alert_triage.sh access.log | tee /tmp/triage.txt
grep -qiE 'top|error|count' /tmp/triage.txt && echo "REPORT PRODUCED ✅"
```

**Pitfalls.**
- Column positions differ by log format — parse by field/delimiter, not `cut -c`.
- Counting 4xx as outages (client errors) vs 5xx (server errors) — distinguish.
- `cat log | grep` and unquoted vars.

🎯 **Stretch.** Add a `--top N` argument and a percentage error-rate line.

---

## Task 2 — Ticket-driven: correlate logs across services to find root cause (diagnose)

**Scenario.** `NAVI-192` (P2). *"Users saw 502s at 14:05. Was it the web tier, the app, or the DB?"*
You have logs from all three with slightly different timestamp formats.

**Objective.** Build a timeline around the incident window and name the service that failed *first* —
**correlate before concluding.**

**Given / constraints.** Three sample logs. Normalize timestamps to a common window; don't guess from
one log alone.

**Hints.**
1. Slice each log to the window: `awk` / `sed` on the timestamp, or `journalctl --since --until`.
2. Order events across files by time (`sort -m` after normalizing).
3. The service whose errors *precede* the others is the likely root; downstream errors are symptoms.

✅ **Verify.**
```bash
# your merged timeline exists and shows the first failing service:
test -s /tmp/timeline.txt && head -3 /tmp/timeline.txt && echo "TIMELINE BUILT ✅"
```

**Pitfalls.**
- Concluding from the web log's 502 (symptom) instead of the DB's earlier connection error (cause).
- Mismatched timezones/formats making correlation wrong.
- Ignoring clock skew between hosts.

🎯 **Stretch.** Script the correlation: given N logs + a time window, emit a single sorted timeline.

---

## Task 3 — On-call: run a full incident from detection to postmortem (synthesis)

**Scenario.** `NAVI-193` (P1, time-boxed). You are Incident Commander. An alert fires; you must detect,
triage, mitigate, and produce a blameless postmortem — using the log skills above end to end.

**Objective.** Work the incident: confirm impact from logs, identify root cause, apply a mitigation,
verify recovery, and write a structured postmortem with a timeline.

**Given / constraints.** Combine a planted failure (from an earlier lesson's drill) + its logs. Timebox
15 min. Postmortem is blameless and has concrete action items.

**Hints.**
1. Detect/confirm: which metric/log proves user impact? Establish start time.
2. Mitigate: smallest safe action that restores service; verify with a ✅ check.
3. Postmortem: Impact · Timeline · Detection · Root cause · Resolution · Action items (with owners).

✅ **Verify.**
```bash
# service restored:
systemctl is-active <svc> 2>/dev/null || curl -sf localhost:<port> >/dev/null && echo "RECOVERED ✅"
grep -qiE 'timeline|action item' docs/learning/reports/NAVI-193-postmortem.md && echo "STRUCTURED POSTMORTEM ✅"
```

**Deliverable.** `docs/learning/reports/NAVI-193-postmortem.md`: Impact · Timeline · Detection · Root cause · Resolution · Prevention/Action items.

**Pitfalls.**
- Fixing before confirming impact/scope → you may "fix" the wrong thing.
- A postmortem that blames a person instead of the system/process.
- Action items with no owner or verification → nothing changes.

🎯 **Stretch.** Add MTTR/MTTD to the postmortem and one action item that would have shortened detection.

---

## Done?
- [ ] All ✅ Verify pass · [ ] correlated before concluding · [ ] blameless postmortem with action items.
- [ ] **Redaction:** no real IPs/users in sample logs. → [README Step 7](./README.md).
