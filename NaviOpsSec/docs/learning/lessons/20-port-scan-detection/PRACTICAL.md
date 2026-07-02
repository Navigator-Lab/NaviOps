# Lesson 20 — Pure Practical: Port Scan Detection

> **Companion to [`README.md`](./README.md).** Pure practice: 3 scenario tasks, guided → ticket-driven
> → on-call. **Lab:** scan `siem-victim` from another host → detect via logs/firewall. **Rules:** test
> the detection, run ✅ **Verify** each task.

Each task: **Scenario · Objective · Given/constraints · Hints · ✅ Verify · Pitfalls · 🎯 Stretch.**

---

## Task 1 — Guided: detect a port scan (fluency)

**Scenario.** `SOC-201`. Run a scan against the victim and detect the signature (many ports, one source,
short time).

**Objective.** A scan generated + detected (firewall log / Wazuh rule).

**Given / constraints.** `nmap` from a peer/host at the victim. Confirm detection.

**Hints.**
1. `nmap -Pn -p1-1000 <victim>`; ensure connection attempts are logged.
2. Signature: many dst ports from one src in a short window.
3. Confirm the alert/log.

✅ **Verify.**
```bash
docker exec wazuh.manager sh -c 'grep -qiE "scan|portscan|multiple connection" /var/ossec/logs/alerts/alerts.log 2>/dev/null' && echo "SCAN DETECTED ✅" || echo "add a scan-detection rule/log source"
```

**Pitfalls.**
- No connection logging → nothing to detect.
- Single-port connect isn't a scan (need the fan-out).
- SYN scan may not complete handshakes (log accordingly).

🎯 **Stretch.** Compare SYN vs connect vs UDP scan footprints.

---

## Task 2 — Ticket-driven: "scan alert — recon or noise?" (diagnose → verdict)

**Scenario.** `SOC-202` (P2). A scan alert fired. Determine scope (what was probed) and intent
(targeted recon vs internet background noise).

**Objective.** Characterize the scan (source, ports, breadth) and a verdict on intent.

**Given / constraints.** Evidence-based. Recon often precedes an attack — weigh that.

**Hints.**
1. Source, port range, which services probed, timing.
2. Targeted (your specific services) vs broad internet noise.
3. Verdict + whether to escalate/monitor the source.

✅ **Verify.**
```bash
grep -qiE 'recon|noise|verdict' docs/learning/reports/SOC-202-verdict.md && echo "VERDICT ✅"
```

**Deliverable.** `docs/learning/reports/SOC-202-verdict.md`: source · ports · breadth · intent verdict · action.

**Pitfalls.**
- Dismissing all scans as noise (recon precedes attacks).
- Not noting which services were probed (the intent clue).
- No follow-up watch on the source.

🎯 **Stretch.** Watch whether the scan source returns for exploitation (escalation trigger).

---

## Task 3 — On-call: scan → exploitation attempt (synthesis)

**Scenario.** `SOC-203` (P1, time-boxed). A scan is followed by connection attempts to the discovered
service — recon turning into attack. Detect the progression, contain, document.

**Objective.** Link scan → follow-up, contain the source, and write an IR note mapping the kill-chain
progression.

**Given / constraints.** Scan then target an open port. Correlate the two; contain by rule.

**Hints.**
1. Correlate: same source scanning then connecting to a found port.
2. Contain (block source); capture IoCs.
3. Map recon → exploitation; recommend detection linking the two.

✅ **Verify.**
```bash
test -f docs/learning/reports/SOC-203-recon-to-attack.md && grep -qiE 'ioc|containment' docs/learning/reports/SOC-203-recon-to-attack.md && echo "IR NOTE ✅"
```

**Deliverable.** `docs/learning/reports/SOC-203-recon-to-attack.md`: scan · follow-up · correlation · containment · IoCs · MITRE T1046.

**Pitfalls.**
- Treating the scan and the follow-up as unrelated.
- Containing after the exploitation instead of at recon.
- No correlation detection proposed.

🎯 **Stretch.** Write a rule that escalates when a scanner later connects to an open port.

---

## Done?
- [ ] All ✅ Verify pass · [ ] scan detected · [ ] recon→attack correlated + contained.
- [ ] **Guardrails:** lab only; fake sources. → [README Reflection](./README.md).
