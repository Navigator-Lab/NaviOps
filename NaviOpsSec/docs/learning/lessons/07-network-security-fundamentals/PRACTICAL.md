# Lesson 07 — Pure Practical: Network Security Fundamentals

> **Companion to [`README.md`](./README.md).** Pure practice: 3 scenario tasks, guided → ticket-driven
> → on-call. **Lab:** `siem-victim` (netshoot-style tooling / `ss`, `tcpdump`) + Wazuh detection.
> **Rules:** evidence before verdict, run ✅ **Verify** each task.

Each task: **Scenario · Objective · Given/constraints · Hints · ✅ Verify · Pitfalls · 🎯 Stretch.**

---

## Task 1 — Guided: map the host's network exposure (fluency)

**Scenario.** `SOC-071`. Enumerate what the victim exposes on the network and what it's talking to — the
network view of attack surface.

**Objective.** A list of listening services (and their exposure) + current connections.

**Given / constraints.** `ss -tulpn`, `ss -tp`. Distinguish local vs world-facing.

**Hints.**
1. `ss -tulpn` — listeners + pids; note `0.0.0.0` vs `127.0.0.1`.
2. `ss -tp` — active connections (to where?).
3. Flag anything unexpected.

✅ **Verify.**
```bash
docker exec siem-victim ss -tulpn | grep -q . && echo "EXPOSURE MAPPED ✅"
test -f docs/learning/reports/SOC-071-net-exposure.md && echo "REPORT ✅"
```

**Pitfalls.**
- Ignoring the bind address (local vs exposed).
- No process attribution (`-p`).
- Missing outbound connections (beaconing hides there).

🎯 **Stretch.** Baseline "normal" connections so future anomalies stand out.

---

## Task 2 — Ticket-driven: suspicious outbound connection (diagnose → verdict)

**Scenario.** `SOC-072` (P2). *"The host is talking to an unfamiliar address."* Determine if it's benign
or C2 beaconing — evidence-based.

**Objective.** Characterize the connection (process, destination, pattern) and reach a verdict.

**Given / constraints.** Simulate a periodic outbound connection. Corroborate before deciding.

**Hints.**
1. `ss -tp` → which process owns it? Destination reputation/context?
2. Beaconing = regular interval to a rare destination (`tcpdump` timing).
3. Verdict + evidence.

✅ **Verify.**
```bash
docker exec siem-victim ss -tp 2>/dev/null | head; echo "connections reviewed"
grep -qiE 'benign|malicious|beacon' docs/learning/reports/SOC-072-outbound.md && echo "VERDICT ✅"
```

**Deliverable.** `docs/learning/reports/SOC-072-outbound.md`: connection · owning process · pattern · verdict · evidence.

**Pitfalls.**
- Verdict without identifying the process.
- Missing the periodicity that signals beaconing.
- Blocking before capturing evidence.

🎯 **Stretch.** Write a Wazuh rule idea to flag regular outbound to rare destinations.

---

## Task 3 — On-call: detect + respond to a network attack (synthesis)

**Scenario.** `SOC-073` (P1, time-boxed). A scan/exploit attempt hits the victim. Detect via logs +
network evidence, contain the source, and write an IR note with IoCs.

**Objective.** Confirm the attack, contain the source, capture IoCs, and document.

**Given / constraints.** Simulate a scan against the victim. Preserve evidence; contain by rule.

**Hints.**
1. Detect: Wazuh alert + `tcpdump`/`ss` evidence.
2. Contain: firewall-block the source (scoped); log it.
3. IoCs: source IP/MAC, ports, timing.

✅ **Verify.**
```bash
docker exec wazuh.manager sh -c 'grep -qiE "scan|multiple" /var/ossec/logs/alerts/alerts.log 2>/dev/null' && echo "DETECTED ✅"
test -f docs/learning/reports/SOC-073-net-attack.md && echo "IR NOTE ✅"
```

**Deliverable.** `docs/learning/reports/SOC-073-net-attack.md`: detection · IoCs · containment · prevention.

**Pitfalls.**
- Containing before capturing evidence.
- Blocking too broadly (collateral).
- No detection rule follow-up.

🎯 **Stretch.** Add a detection rule so this pattern auto-alerts (feeds L20 port-scan detection).

---

## Done?
- [ ] All ✅ Verify pass · [ ] process-attributed connections · [ ] IR note with IoCs.
- [ ] **Guardrails:** fake IoCs; no real IPs committed. → [README Reflection](./README.md).
