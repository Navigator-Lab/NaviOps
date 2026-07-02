# Lesson 06 — Pure Practical: Syslog & Log Management

> **Companion to [`README.md`](./README.md).** Pure practice: 3 scenario tasks, guided → ticket-driven
> → on-call. **Lab:** `siem-victim` forwarding to the Wazuh manager (the central collector). **Rules:**
> evidence before verdict, run ✅ **Verify** each task.

Each task: **Scenario · Objective · Given/constraints · Hints · ✅ Verify · Pitfalls · 🎯 Stretch.**

---

## Task 1 — Guided: centralize logs to the SIEM (fluency)

**Scenario.** `SOC-061`. Get the victim's logs into the manager so detection has data — the foundation
of a SIEM.

**Objective.** Victim logs reaching the manager; a test event visible centrally.

**Given / constraints.** Wazuh agent or syslog forwarding. Confirm central receipt.

**Hints.**
1. Ensure the victim's key logs are monitored (`ossec.conf` `<localfile>` / agent enrolled).
2. Generate a test event; confirm it appears in `alerts.log` / dashboard.
3. Note facility/severity mapping.

✅ **Verify.**
```bash
docker exec siem-victim sh -c 'logger -p auth.info "SOC-061 central test"; echo sent'
docker exec wazuh.manager sh -c 'grep -qi "SOC-061 central test" /var/ossec/logs/archives/archives.* 2>/dev/null || grep -qi central /var/ossec/logs/alerts/alerts.log 2>/dev/null' && echo "CENTRALIZED ✅"
```

**Pitfalls.**
- Log not monitored → invisible to the SIEM.
- Agent disconnected.
- Assuming forwarding works without a test event.

🎯 **Stretch.** Add a second log source and confirm both land centrally.

---

## Task 2 — Ticket-driven: "a source stopped logging to the SIEM" (diagnose → fix)

**Scenario.** `SOC-062` (P2). *"We're blind on a host — no events reaching the SIEM."* Detection gap.
Find the break.

**Objective.** Restore ingestion, identifying agent-down, unmonitored path, or transport issue —
diagnose first.

**Given / constraints.** Recreate: stop the agent / unmonitor a log. Fix the specific break.

**Hints.**
1. Agent connected? `agent_control -l` on the manager.
2. Is the log monitored + being written? Transport reachable?
3. Fix and confirm a fresh event lands.

✅ **Verify.**
```bash
docker exec wazuh.manager sh -c '/var/ossec/bin/agent_control -l 2>/dev/null | grep -qi active' && echo "AGENT CONNECTED ✅"
```

**Deliverable.** `docs/learning/reports/SOC-062-ingest-gap.md`: symptom · break point · fix · verification.

**Pitfalls.**
- A silent detection gap (no data ≠ no threats).
- Unmonitored log path.
- Disk-full on the collector dropping events.

🎯 **Stretch.** Add a "no events in N minutes" heartbeat alert per critical source.

---

## Task 3 — On-call: retention/volume incident (synthesis)

**Scenario.** `SOC-063` (time-boxed). The SIEM is dropping events / storage is filling (a log flood or
retention misconfig). Stabilize ingestion without losing critical data, document.

**Objective.** Identify the flood source / retention issue, relieve it surgically, and write a note.

**Given / constraints.** Find the noisy source; don't blanket-drop critical logs.

**Hints.**
1. Which source is flooding? Volume by source.
2. Rate-limit/filter the noisy source; fix retention.
3. Confirm critical sources still ingested.

✅ **Verify.**
```bash
docker exec wazuh.manager sh -c 'du -sh /var/ossec/logs 2>/dev/null'; echo "volume checked"
test -f docs/learning/reports/SOC-063-volume.md && echo "REPORT ✅"
```

**Deliverable.** `docs/learning/reports/SOC-063-volume.md`: flood source · relief action · retention fix · prevention.

**Pitfalls.**
- Dropping all logs to save space (blinds detection).
- Not finding the flood source.
- No retention policy → recurs.

🎯 **Stretch.** Design a tiered retention (hot/warm/cold) for cost vs investigation needs.

---

## Done?
- [ ] All ✅ Verify pass · [ ] ingestion verified end to end · [ ] volume note written.
- [ ] **Guardrails:** no real hostnames/data committed. → [README Reflection](./README.md).
