# Lesson 14 — Pure Practical: Wazuh Deployment

> **Companion to [`README.md`](./README.md).** Pure practice: 3 scenario tasks, guided → ticket-driven
> → on-call. **Lab:** `./infra/bootstrap.sh up` (manager+indexer+dashboard) + `siem-victim` to enroll.
> See [`infra/LAB.md`](../../../../infra/LAB.md). **Rules:** type it, diagnose before you fix, run ✅.

Each task: **Scenario · Objective · Given/constraints · Hints · ✅ Verify · Pitfalls · 🎯 Stretch.**

---

## Task 1 — Guided: deploy the manager and enroll an agent (fluency)

**Scenario.** `SOC-141`. Stand up the SIEM and enroll the victim agent so events flow — the deployment core.

**Objective.** Manager/indexer/dashboard healthy; victim agent enrolled + active.

**Given / constraints.** Follow LAB.md (sysctl → pull → certs → up → enroll). Change the default password.

**Hints.**
1. `./infra/bootstrap.sh sysctl && pull && certs && up`; dashboard green in 1–2 min.
2. Enroll: install the agent on `siem-victim`, point `WAZUH_MANAGER=wazuh.manager`, start it.
3. Agent shows Active on the manager.

✅ **Verify.**
```bash
docker exec wazuh.manager sh -c '/var/ossec/bin/agent_control -l 2>/dev/null | grep -qi active' && echo "AGENT ACTIVE ✅"
curl -sk https://localhost:8443 >/dev/null && echo "DASHBOARD UP ✅"
```

**Pitfalls.**
- `vm.max_map_count` unset → indexer won't start.
- Certs step skipped → components can't talk.
- Leaving the default password.

🎯 **Stretch.** Deploy the sanitized `infra/wazuh/` detection content and reload.

---

## Task 2 — Ticket-driven: "agent shows disconnected" (diagnose → fix)

**Scenario.** `SOC-142` (P2). *"An enrolled agent went disconnected — no data from that host."* Find the break.

**Objective.** Restore the agent to Active, identifying key/registration, connectivity, or service issues —
diagnose first.

**Given / constraints.** Recreate: stop the agent / break registration. Fix the cause.

**Hints.**
1. `agent_control -l` (state); on the victim `wazuh-control status`.
2. Registration key valid? Manager reachable (1514/1515)?
3. Restart/re-register; confirm Active.

✅ **Verify.**
```bash
docker exec wazuh.manager sh -c '/var/ossec/bin/agent_control -l 2>/dev/null | grep -qi active' && echo "RECONNECTED ✅"
```

**Deliverable.** `docs/learning/reports/SOC-142-agent-down.md`: symptom · cause · fix · verification.

**Pitfalls.**
- Assuming manager-side when the agent service is down.
- Ports 1514/1515 blocked.
- Duplicate/invalid registration key.

🎯 **Stretch.** Add a "no agent keepalive" alert so disconnects page you.

---

## Task 3 — On-call: SIEM component failure (synthesis)

**Scenario.** `SOC-143` (P1, time-boxed). The indexer/dashboard is down — the SOC is blind. Restore the
stack without losing data, and document.

**Objective.** Diagnose the component failure, restore service, confirm data intact, write a note.

**Given / constraints.** Don't `down -v` (destroys data). Diagnose from logs.

**Hints.**
1. `docker compose ps` + `docker logs` for the failed component (heap? disk? cert?).
2. Fix the cause; restart just that component.
3. Confirm data volumes intact + events flowing again.

✅ **Verify.**
```bash
curl -sk https://localhost:8443 >/dev/null && echo "DASHBOARD RESTORED ✅"
test -f docs/learning/reports/SOC-143-component-down.md && echo "REPORT ✅"
```

**Deliverable.** `docs/learning/reports/SOC-143-component-down.md`: Impact · cause · fix · data-integrity check · prevention.

**Pitfalls.**
- `down -v` in a panic → data loss.
- Restarting the whole stack for one component.
- Not confirming events resumed after "fixing".

🎯 **Stretch.** Add resource limits + a health alert so the failure is caught earlier.

---

## Done?
- [ ] All ✅ Verify pass · [ ] agent Active · [ ] component restored without data loss.
- [ ] **Guardrails:** change default creds; no certs/keys committed. → [README Reflection](./README.md).
