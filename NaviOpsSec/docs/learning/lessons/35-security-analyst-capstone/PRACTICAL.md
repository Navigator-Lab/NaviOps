# Lesson 35 — Pure Practical: Security Analyst Capstone

> **Companion to [`README.md`](./README.md).** The capstone; this adds 3 comprehensive drills that
> combine everything (Lessons 01–34): detection → hunt → full IR → report. **Lab:** full Wazuh stack +
> victim. **Rules:** you are the analyst end to end. Run ✅ **Verify** each task.

Each task: **Scenario · Objective · Given/constraints · Hints · ✅ Verify · Pitfalls · 🎯 Stretch.**

---

## Task 1 — Guided: build + prove a monitored, defended host (fluency)

**Scenario.** `SOC-351`. Deliver a defended host: monitored, detections mapped to a threat model, and
proven against test attacks.

**Objective.** Host monitored + ≥3 detections mapped to threats + all proven on test. Timed.

**Given / constraints.** Threat-model → coverage → prove. Documented.

**Hints.**
1. Threat model (L08) → detections (L15/32) → test each.
2. FIM + ingestion (L14/24).
3. Coverage matrix.

✅ **Verify.**
```bash
docker exec wazuh.manager sh -c '/var/ossec/bin/agent_control -l 2>/dev/null | grep -qi active' && echo "DEFENDED HOST ✅"
test -f docs/learning/reports/SOC-351-coverage.md && echo "COVERAGE ✅"
```

**Pitfalls.**
- Coverage not tied to threats.
- Untested detections.
- No FIM.

🎯 **Stretch.** Produce an ATT&CK coverage layer.

---

## Task 2 — Ticket-driven: full unknown-incident investigation (diagnose end to end)

**Scenario.** `SOC-352` (P1). An unknown incident (peer-planted). Take it detection/hunt → scope →
respond → report, no prior knowledge.

**Objective.** Root cause found, contained + eradicated, full IR report produced. Timed.

**Given / constraints.** Unknown incident. Complete lifecycle. Evidence throughout.

**Hints.**
1. Detect/hunt → investigate → scope → contain/eradicate/recover (L28/29).
2. Evidence + timeline live.
3. IR report: root cause, IoCs, MITRE, remediation.

✅ **Verify.**
```bash
docker exec siem-victim sh -c 'crontab -l 2>/dev/null | grep -q "<rogue>"' && echo "NOT CLEAN ❌" || echo "RESOLVED ✅"
test -f docs/learning/reports/SOC-352-ir.md && grep -qiE 'root cause|ioc' docs/learning/reports/SOC-352-ir.md && echo "IR REPORT ✅"
```

**Deliverable.** `docs/learning/reports/SOC-352-ir.md`: timeline · root cause · scope · response · IoCs · MITRE · remediation.

**Pitfalls.**
- Respond before scoping.
- No evidence trail.
- Incomplete lifecycle.

🎯 **Stretch.** Determine initial access + build a detection that would've caught it.

---

## Task 3 — On-call: capstone assessment — full portfolio artifact (synthesis)

**Scenario.** `SOC-353` (time-boxed). Produce the portfolio-grade deliverable: a complete incident case
study demonstrating detection, hunting, IR, and reporting — the artifact you'd show an employer.

**Objective.** A polished, self-contained case study (exec summary + technical + detections + lessons)
suitable for a portfolio.

**Given / constraints.** Sanitized/redacted. Publishable quality. Two audiences.

**Hints.**
1. Combine your best work: detection, hunt, IR, postmortem.
2. Exec summary + technical detail + detections + lessons learned.
3. Redact thoroughly (portfolio = public).

✅ **Verify.**
```bash
test -f docs/learning/reports/SOC-353-case-study.md && grep -qiE 'executive|detection|lessons' docs/learning/reports/SOC-353-case-study.md && echo "CASE STUDY ✅"
grep -rIqE '([0-9]{1,3}\.){3}[0-9]{1,3}' docs/learning/reports/SOC-353-case-study.md && echo "CHECK: real IP? redact" || echo "REDACTION LOOKS CLEAN ✅"
```

**Deliverable.** `docs/learning/reports/SOC-353-case-study.md`: exec summary · technical narrative · detections · IoCs · lessons.

**Pitfalls.**
- Real data in a portfolio artifact (redact!).
- Technical-only (no exec summary).
- No lessons learned (the maturity signal).

🎯 **Stretch.** Pair it with the ATT&CK coverage layer + the sanitized detection pack.

---

## Done?
- [ ] All ✅ Verify pass · [ ] defended host proven · [ ] full IR · [ ] portfolio case study (redacted).
- [ ] **Guardrails:** thorough redaction; sanitized detections; no real data. → [README Reflection](./README.md).
