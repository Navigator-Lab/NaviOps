# Lesson 23 — Pure Practical: Security Monitoring & Threat Detection (Wazuh)

> **Companion to [`README.md`](./README.md).** Pure practice: 3 scenario tasks, guided → ticket-driven
> → on-call. Do them after the README.
>
> **Lab:** a Wazuh manager + agent (compose) or the concepts against `auditd`/`journald` on
> `naviops-web`. **Artifact:** `scripts/threat_scan.sh`. **Rules:** type it, diagnose before you fix,
> run ✅ **Verify** each task.

Each task: **Scenario · Objective · Given/constraints · Hints · ✅ Verify · Pitfalls · 🎯 Stretch.**

---

## Task 1 — Guided: detect a brute-force with a rule (fluency)

**Scenario.** `NAVI-231`. Configure detection so repeated failed SSH logins raise an alert — the most
common real-world detection.

**Objective.** Generate failed logins, have Wazuh (or a log rule) flag the brute-force pattern above a
threshold.

**Given / constraints.** Simulate failed logins (`ssh baduser@localhost` a few times). Rule has a
frequency + timeframe (not one failure = alert).

**Hints.**
1. Failed logins land in the auth log / `journalctl -u ssh`. Wazuh has built-in rules (5710/5712…).
2. Generate several failures within the window; watch the manager alerts (`/var/ossec/logs/alerts/`).
3. If not using Wazuh: write a log rule that counts failures per IP over N minutes.

✅ **Verify.**
```bash
# Wazuh:
grep -q '5712\|brute force\|multiple authentication failures' /var/ossec/logs/alerts/alerts.log && echo "DETECTED ✅"
# or log-rule fallback:
scripts/threat_scan.sh /var/log/auth.log; echo "exit=$?"   # non-zero when brute-force pattern found
```

**Pitfalls.**
- One failure = alert → alert fatigue. Use frequency/timeframe.
- Watching the wrong log (distro path differences).
- No IP grouping → can't tell one attacker from scattered typos.

🎯 **Stretch.** Add an active-response that temporarily firewall-blocks the offending IP; verify + auto-unblock.

---

## Task 2 — Ticket-driven: "the rule isn't firing on a real attack" (diagnose → fix)

**Scenario.** `NAVI-232` (P2). *"We were probed but Wazuh stayed quiet."* Find why the detection missed
it — **diagnose the pipeline.**

**Objective.** Get the rule to fire on the attack pattern, fixing the real gap (log not ingested,
decoder mismatch, rule level too high/threshold wrong, or agent disconnected).

**Given / constraints.** Recreate a gap: agent not sending, wrong log path monitored, or a threshold
that never trips. Fix the specific link.

**Hints.**
1. Is the log ingested? Check the agent is connected + the log is in `ossec.conf` `<localfile>`.
2. Does the decoder parse it? `/var/ossec/bin/wazuh-logtest` — paste a sample line, see rule/decoder match.
3. Threshold/level: is the rule level filtered out by your alerting threshold?

✅ **Verify.**
```bash
echo '<sample attack log line>' | /var/ossec/bin/wazuh-logtest | grep -q 'Rule id' && echo "RULE MATCHES ✅"
grep -q '<expected rule id>' /var/ossec/logs/alerts/alerts.log && echo "FIRES ✅"
```

**Pitfalls.**
- Agent disconnected → nothing to detect on (check `agent_control -l`).
- Log path not monitored → invisible to Wazuh.
- Custom log with no decoder → rule never matches; write/adjust the decoder.

🎯 **Stretch.** Write a custom rule + decoder for one of *your* NaviOps scripts' log format and prove it matches with `wazuh-logtest`.

---

## Task 3 — On-call: investigate a real alert to verdict + response (synthesis)

**Scenario.** `NAVI-233` (P1, time-boxed). A high-severity alert fires (e.g. possible privilege
escalation). Triage true-positive vs false-positive, scope it, respond, and write an incident note.

**Objective.** From the alert, gather context (who/what/when), decide TP/FP with evidence, contain if
real, and document with IoCs and MITRE mapping.

**Given / constraints.** Plant an event (rogue sudo / new SUID from L10). Preserve evidence; contain by
disabling, not wiping. Timebox 15 min.

**Hints.**
1. Pivot from the alert to the raw events (same host/time): correlate Wazuh alert → auth/audit logs.
2. TP/FP: does the activity have a legitimate explanation (change ticket)? Evidence over assumption.
3. Respond: disable the account/rule, capture IoCs, map to a MITRE ATT&CK technique.

✅ **Verify.**
```bash
grep -qi 'true positive\|false positive' docs/learning/reports/NAVI-233-postmortem.md && echo "VERDICT RECORDED ✅"
grep -qi 'T[0-9]\{4\}\|MITRE' docs/learning/reports/NAVI-233-postmortem.md && echo "MITRE MAPPED ✅"
```

**Deliverable.** `docs/learning/reports/NAVI-233-postmortem.md`: Impact · Detection · Evidence · TP/FP verdict · Response · IoCs · MITRE technique.

**Pitfalls.**
- Declaring TP/FP without evidence.
- Destroying logs/host state before scoping (loses the story).
- Closing the alert without an IoC/detection improvement so it recurs.

🎯 **Stretch.** Turn the investigation into a new detection rule so this specific pattern auto-alerts next time.

---

## Done?
- [ ] All ✅ Verify pass · [ ] verdict backed by evidence · [ ] IoCs + MITRE recorded · [ ] postmortem written.
- [ ] **Redaction:** fake IoCs/IPs only. → [README Step 7](./README.md).
