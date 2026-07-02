# Lesson 23 — Pure Practical: Zabbix

> **Companion to [`README.md`](./README.md).** Pure practice: 3 scenario tasks, guided → ticket-driven
> → on-call. **Lab:** run Zabbix via a throwaway compose (`zabbix-server` + `zabbix-web` + a DB) or
> practice the concepts against the existing monitoring stack. **Rules:** type it, diagnose before you
> fix, run ✅ **Verify** each task.

Each task: **Scenario · Objective · Given/constraints · Hints · ✅ Verify · Pitfalls · 🎯 Stretch.**

---

## Task 1 — Guided: monitor a host with an item + trigger (fluency)

**Scenario.** `NOC-231`. Add a host, an item (a metric), and a trigger (the condition that alerts) —
Zabbix's core model.

**Objective.** A monitored host with a live item and a trigger that changes state on breach.

**Given / constraints.** Zabbix agent on a lab host or an agentless check. Trigger has a threshold.

**Hints.**
1. Add host → attach a template or a single item (e.g. ICMP ping / CPU).
2. Trigger expression on the item (e.g. `last() = 0` for down).
3. Drive the condition; watch the trigger fire.

✅ **Verify.**
```bash
# agent reachable / item collecting (adapt to your deployment):
curl -s "http://localhost:8080" >/dev/null 2>&1 && echo "ZABBIX WEB UP ✅"
echo "confirm item has recent data + trigger state in the UI"
```

**Pitfalls.**
- Item key typo → "not supported" (no data).
- Trigger expression referencing the wrong item.
- Agent firewall blocking 10050.

🎯 **Stretch.** Use a template to apply many items/triggers to a host at once.

---

## Task 2 — Ticket-driven: "host shows unreachable / no data" (diagnose → fix)

**Scenario.** `NOC-232` (P2). *"A monitored host went grey / no data."* Zabbix can't collect. Find the
break.

**Objective.** Restore data collection, identifying agent down, port blocked, or wrong key — diagnose
first.

**Given / constraints.** Recreate: stop the agent / block 10050 / bad item key. Fix the cause.

**Hints.**
1. `zabbix_get -s <host> -k agent.ping` from the server (agent reachable?).
2. Port 10050 open? Agent running? Key supported?
3. Fix and confirm data resumes.

✅ **Verify.**
```bash
echo "zabbix_get -s <host> -k agent.ping   # expect 1"
echo "confirm host green + fresh data in UI"
```

**Pitfalls.**
- Assuming server-side when the agent/port is the issue.
- "Unsupported item" ignored (bad key).
- 10050 firewalled.

🎯 **Stretch.** Compare passive vs active agent checks and when each fails differently.

---

## Task 3 — On-call: alert flood + escalation (synthesis)

**Scenario.** `NOC-233` (P1, time-boxed). A dependency fails and dependent triggers flood. Use
dependencies/escalations to cut noise and route the real one, then document.

**Objective.** Configure trigger dependencies so downstream triggers suppress under the root, verify,
write a note.

**Given / constraints.** Use Zabbix trigger dependencies + escalation. Suppress, don't delete.

**Hints.**
1. Set the downstream triggers to *depend on* the root trigger (they won't fire if the root is active).
2. Escalation: notify tiers over time.
3. Confirm only the root pages.

✅ **Verify.**
```bash
echo "confirm dependent triggers suppressed while root active (UI)"
test -f docs/learning/reports/NOC-233-zabbix-flood.md && echo "REPORT ✅"
```

**Deliverable.** `docs/learning/reports/NOC-233-zabbix-flood.md`: root trigger · dependencies added · escalation · result.

**Pitfalls.**
- No trigger dependencies → every downstream fires.
- Over-notifying (escalation too aggressive).
- Disabling triggers instead of using dependencies.

🎯 **Stretch.** Add maintenance windows so planned work doesn't page.

---

## Done?
- [ ] All ✅ Verify pass · [ ] dependencies configured · [ ] flood note written.
- [ ] **Guardrails:** lab only; change default creds. → [README Reflection](./README.md).
