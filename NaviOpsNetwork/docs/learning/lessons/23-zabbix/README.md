# Lesson 23 — Zabbix

**Status:** ✅ ready for self-study (full depth) · **Date written:** 2026-06-20
**Schema:** 12-section (`docs/learning/CLAUDE_TEACHING_RULES.md`)
**Focus:** agents/templates, triggers, network discovery, maps, the NOC dashboard.
**Primary artifact:** `infra/monitoring/zabbix-notes.md`.

> **How to use this lesson:** Zabbix is one of the named NOC tools in job postings (alongside
> SolarWinds/PRTG/Nagios/Grafana). Read §1–§7, stand it up in §8 and discover a host. The concepts
> transfer to all the enterprise NOC tools. Lab only.

---

## §1 — Concept (Scientific Theory)

### What it is
**Zabbix** is a mature, open-source **enterprise monitoring platform** — the kind of all-in-one
tool a real NOC sits in front of. Unlike Prometheus (a pull-based TSDB you assemble with
exporters + Grafana), Zabbix is a single integrated system with a server, a database, a web UI, an
**agent** model, **templates**, **triggers**, **network discovery**, **maps**, and built-in
alerting/escalation. It directly mirrors the workflow of SolarWinds/PRTG/Nagios, so learning it
teaches the *enterprise NOC tool* category.

### Why it exists
Prometheus+Grafana (Lesson 22) is excellent for metrics-driven, cloud-native monitoring, but many
enterprises and NOCs run an integrated platform that does host + network-device monitoring,
discovery, topology maps, and escalation out of the box, with a single pane of glass and
role-based access. Zabbix fills that "one tool, whole NOC" need.

### Core building blocks
| Concept | What it is |
|---|---|
| **Server / DB / frontend** | the engine, storage, and web UI |
| **Agent** | software on a host that reports metrics (active or passive) |
| **Agentless** | SNMP (Lesson 24), ICMP, SSH, HTTP checks for devices without an agent |
| **Item** | a single metric collected (CPU, interface in-octets, ping) |
| **Template** | a reusable bundle of items/triggers applied to many hosts |
| **Trigger** | a condition/expression that defines a problem (threshold) |
| **Action / Escalation** | what to do when a trigger fires (notify, escalate over time) |
| **Discovery** | auto-find hosts/services on the network and add them |
| **Map** | a visual topology with live status |
| **Dashboard** | the NOC screen (problems, graphs, maps) |

### Three-Level Depth (Lens A)
- **Level 1 — Beginner:** Zabbix is a monitoring program with a web page that shows all your
  devices, goes red when something breaks, and emails/pages someone — like a security
  control-room for the network.
- **Level 2 — NetOps/NOC:** you apply **templates** (don't hand-configure each host — template
  "Linux by Zabbix agent" or "Network device by SNMP"), define **triggers** (e.g. interface
  utilization > 80% for 5m), set up **actions/escalations** (notify Tier-1, escalate to Tier-2 if
  unacked in 15m — mirroring `noc/escalation-matrix.md`), use **network discovery** to onboard new
  devices automatically, and build **maps + dashboards** as the NOC view. Severity levels
  (Not classified → Information → Warning → Average → High → Disaster) map to your Sev rubric.
- **Level 3 — Wire/Kernel (Lens D):** the Zabbix agent collects metrics via OS interfaces
  (the same `/proc`/`ss`/`ip` data, Lesson 17) and active checks; agentless monitoring uses **SNMP
  GET/walk** (Lesson 24) and ICMP. Triggers are expressions evaluated against the time-series in
  the DB; escalations are stateful workflows. Architecturally it's "agent/SNMP → server → DB →
  triggers → actions → frontend."

### Two Teaching Approaches (Lens B) — templates + triggers + escalation

**Approach 1 (technical):** you attach a **template** (items + triggers) to a host or host-group;
items collect metrics on a schedule; triggers are boolean expressions over item history that
transition a host into a PROBLEM state at a severity; actions then run an **escalation schedule**
(notify, wait, escalate, repeat) until acknowledged/resolved. Discovery rules add matching hosts
automatically and apply templates.

**Approach 2 (analogy):** Zabbix is a **building security control room with guard procedures**.
- **Templates** = standard operating procedures applied to every door of a type ("all fire doors
  get a sensor + a 'door held open >30s' rule") — you don't write rules per door.
- **Triggers** = the alarm conditions ("smoke detected," "door forced").
- **Actions/escalation** = the guard playbook: alert the lobby guard; if not acknowledged in 15
  minutes, call the supervisor; if still open, call the fire department — the literal escalation
  matrix.
- **Maps** = the building floor plan on the wall with live red/green dots.
- **Where it breaks down:** a control room watches one building; Zabbix watches thousands of
  heterogeneous devices, so **templates + discovery** (scale by pattern, not per-device) are what
  make it tractable — the part the single-building analogy understates.

### Visual (ASCII) — Zabbix flow

```
   HOSTS/DEVICES            ZABBIX SERVER                   FRONTEND (NOC)
   Linux ─agent──────┐
   switch ─SNMP──────┤── items (collect) ─► DB ─► triggers ─► PROBLEM ─► dashboard/maps
   router ─ICMP──────┘                                  │
                                                    actions/escalation ─► notify → escalate → page
                                          discovery rule ─► auto-add new devices + apply templates
```

---

## §2 — Linux Networking Commands

```bash
# Stand up Zabbix (docker compose; or packages). Then the agent on a host:
systemctl status zabbix-agent2
zabbix_agent2 -p                              # test what the agent reports locally
zabbix_get -s 10.0.0.50 -k system.cpu.load    # pull an item from an agent (server side)
zabbix_get -s 10.0.0.50 -k net.if.in[eth0]    # interface inbound counter

# Agentless device monitoring uses SNMP (Lesson 24):
snmpwalk -v2c -c <COMMUNITY_STRING> 10.0.0.1 IF-MIB::ifInOctets

# Frontend: http://<server>/  → Configuration (templates/triggers/discovery), Monitoring (problems/maps/dashboards)
```

**Cisco/CCNA mapping:** Zabbix monitors Cisco gear via **SNMP** (`snmp-server community`,
`snmp-server host`) and **syslog** (Lesson 25). It's the platform that consumes the SNMP/syslog
features CCNA teaches on the device side. It's also a direct stand-in for SolarWinds/PRTG/Nagios on
a NOC résumé.

---

## §3 — Real-World Use Cases

**Production scenarios:**
1. **Single-pane NOC monitoring:** hosts (agent) + network devices (SNMP) + services (HTTP/ICMP)
   in one tool, with maps showing live topology status.
2. **Auto-onboarding:** network discovery finds new devices and applies the right template — no
   manual config per device.
3. **Built-in escalation:** actions notify Tier-1 and escalate to Tier-2/manager on a schedule —
   the `noc/escalation-matrix.md` encoded in the tool.
4. **Capacity + SLA reporting:** trend graphs + availability reports for SLOs.

**How NOC engineers use it:** this *is* the day-to-day for many NOCs — watch the problems
dashboard/map, acknowledge, run the runbook, escalate via the tool. Learning Zabbix is learning
the enterprise-NOC workflow.

**When NOT to:** for cloud-native, metrics-heavy, GitOps environments, Prometheus (Lesson 22) is
often preferred; pick the tool to the environment (many shops run both).

**Exam framing:** Network+ Network Operations lists monitoring platforms, SNMP, and discovery
generically; Zabbix is a concrete example to name in interviews.

---

## §4 — Troubleshooting Section

| Symptom | Likely cause | Diagnose | Fix |
|---|---|---|---|
| Host shows "no data" | agent down / firewall (port 10050/10051) | `zabbix_get`; `nc -vz host 10050` | start agent / allow port |
| SNMP device unreachable | wrong community/version/ACL | `snmpwalk` test (Lesson 24) | fix community/version/ACL |
| Trigger not firing | expression/threshold wrong | review trigger expression + item history | fix expression |
| Alert storm | no dependencies/escalation tuning | set trigger dependencies | dedup via dependencies |
| Discovery not adding hosts | discovery rule/checks | review discovery rule | fix rule criteria |

**Redaction check:** `<COMMUNITY_STRING>`, lab IPs in committed notes.

---

## §5 — Common Mistakes

| Mistake | Impact | Fix |
|---|---|---|
| Hand-configuring each host | unmaintainable | use templates |
| Default SNMP community (`public`) | security risk | unique community / SNMPv3 (L24) |
| No trigger dependencies | alert storms (a down router floods child alerts) | set dependencies |
| No escalation/ack workflow | missed/duplicated work | configure actions + ack |
| Monitoring without maps | no topology context | build maps |
| Exposing the frontend | attack surface | restrict + auth |

---

## §6 — NOC Perspective

> NOC Technician focus (Stage 1, `ROADMAP.md`).

Zabbix is the **enterprise-NOC tool experience** — its problems dashboard, maps, severities,
acknowledgement, and escalation actions are exactly the workflow a NOC posting describes
(SolarWinds/Remedy/ServiceNow-adjacent). Practicing it (or its concepts) means you can speak
fluently to "we use SolarWinds/PRTG" in an interview because the mental model is identical:
templates, triggers, severities, ack, escalate, map. **Trigger dependencies** are how Zabbix
solves the same dedup problem Alertmanager (Lesson 22) does.

---

## §7 — Incident-Response Perspective

- **Detect:** a trigger fires → host enters PROBLEM → appears on the dashboard/map.
- **Triage:** severity (Zabbix's 6 levels → your Sev rubric) + acknowledge (stop the MTTA clock).
- **Diagnose/Escalate:** run the runbook; if unresolved, Zabbix's escalation action auto-notifies
  Tier-2 (`noc/escalation-matrix.md`).
- **Document/Resolve:** acknowledge with notes, resolve, and the event history becomes the
  incident timeline. The NOC capstone (35) can run on Zabbix *or* the Prometheus stack.

---

## §8 — Practical Lab (build this yourself)

**Goal:** stand up Zabbix, monitor a host (agent) + a "device" (SNMP/ICMP), build a trigger +
escalation, and document `infra/monitoring/zabbix-notes.md`.

### Lens C — Manual → Automated → Why
- **Manual:** add a host, items, a trigger by hand.
- **Automated:** apply a **template** + a **discovery rule** so new hosts onboard automatically
  with their full item/trigger set.
- **Why:** at scale you monitor by *pattern* (templates) and *automation* (discovery), not
  per-device clicking — exactly how production NOCs keep thousands of devices monitored.

### Steps
1. Run Zabbix (docker compose or packages) in a lab; log into the frontend.
2. Add a Linux host with the **agent**; apply the "Linux by Zabbix agent" template; confirm items
   collect (CPU, memory, `net.if.in`).
3. Monitor a "device" via **ICMP** (and SNMP if you have a lab device/snmpd — Lesson 24).
4. Create a **trigger** (e.g. interface utilization or ping loss threshold) and an **action**
   (notify + escalate after N minutes unacked). Build a simple **map** + **dashboard**.
5. **Drill:** induce a condition (stop the agent / inject loss), watch the trigger fire, the
   dashboard go red, and the escalation run; acknowledge + resolve.
6. Write `infra/monitoring/zabbix-notes.md`: architecture, the template/trigger/escalation you
   built, severities → your Sev rubric, and screenshots (redacted).

### Lens D — agent vs SNMP collection
Note how the agent reads OS data (the same `/proc`/`ip` sources from Lesson 17) while agentless
checks use SNMP GET/walk (Lesson 24) — two collection paths, one platform.

---

## §9 — GitHub Artifact (evidence 5-tuple)

1. **Script/config:** the Zabbix compose/setup + the exported template/trigger config.
2. **Config/doc:** `infra/monitoring/zabbix-notes.md` (architecture, triggers, escalation).
3. **Drill:** a trigger fired + escalation observed.
4. **NAVI ticket:** `NAVI-23` (Change: "deploy Zabbix + host/device monitoring + escalation").
5. **Incident report:** a Zabbix-detected incident runbook (with the event timeline).

---

## §10 — Portfolio Artifact

- **Resume bullet:** "Deployed Zabbix enterprise monitoring with agent + SNMP discovery,
  templated triggers, topology maps, and tiered escalation actions mirroring a NOC escalation
  matrix."
- **Interview talking point:** Zabbix maps directly to "we use SolarWinds/PRTG/Nagios" — explain
  templates, triggers, severities, ack, and escalation as the universal NOC-tool model.
- **Serves:** NOC Technician (Stage 1) — names a concrete enterprise tool; feeds capstone 35.

---

## §11 — RHCSA Crossover Notes

Mostly **N/A for RHCSA** as a topic, but the Zabbix **agent** runs on RHEL (a systemd service —
RHCSA service-management skills apply), and it monitors the host metrics RHCSA admins care about.
Deploying it exercises package/service/firewall (firewalld port 10050/10051) RHEL skills.

---

## §12 — Security Notes (Lens E — Attacker & Defender)

> Frameworks: [MITRE ATT&CK](https://attack.mitre.org/).

**🔴 Attacker:** an exposed Zabbix frontend or default credentials is a foothold and **recon** of
the entire monitored estate (`T1590` — Zabbix literally maps your network); the Zabbix agent has
had RCE CVEs; default SNMP communities (Lesson 24) leak device data. Attackers also try to
**disable monitoring** (`T1562`).

**🔵 Defender:** restrict + authenticate the frontend (never Internet-exposed), patch the
server/agent, use **SNMPv3** (auth+priv) not v2c communities, restrict agent access (server
allowlist), and **alert if monitoring goes silent**. Verify the frontend/agent ports aren't
externally reachable (nmap, lab).

---

## Quiz (Interview-Style, Graded)

**Q1.** How does Zabbix differ from Prometheus+Grafana in architecture and use case?
> **Your answer:**

**Q2.** What is a template, and why is it essential at scale?
> **Your answer:**

**Q3.** Explain triggers and actions/escalation, and how they map to a NOC escalation matrix.
> **Your answer:**

**Q4.** **Scenario:** A core router goes down and Zabbix floods you with alerts for every device
behind it. What feature prevents this, and how?
> **Your answer:**

**Q5.** Agent vs agentless (SNMP/ICMP) monitoring — when do you use each?
> **Your answer:**

**Q6.** Name two security hardening steps for a Zabbix deployment.
> **Your answer:**

*(After you answer, request the "Professional Answer" comparison under each — graded before Lesson 24.)*

---

## Reflection
*(Fill in after the quiz)* — What did you learn? · What confused you? · What would you do differently?

---

## Search Keywords For Further Understanding

**Core**
- `zabbix architecture server agent`
- `zabbix templates triggers`
- `zabbix network discovery`
- `zabbix actions escalation`
- `zabbix maps dashboards`

**Tools**
- `zabbix docker compose setup`
- `zabbix_get test item`
- `zabbix snmp monitoring`

**Going further (future lessons)**
- `snmp monitoring` (L24) · `syslog integration` (L25) · `solarwinds prtg nagios concepts`

**Red / Blue (Lens E):**
- 🔴 `exposed zabbix frontend recon T1590`, `zabbix agent rce cve`, `disable monitoring T1562`
- 🔵 `zabbix hardening`, `snmpv3 vs v2c`, `restrict monitoring frontend`

---

## Lesson Status
- [ ] §8 lab completed (Zabbix + host/device + trigger + escalation)
- [ ] §4 drill done (trigger fired + escalation)
- [ ] Evidence committed (§9)
- [ ] Quiz answered + professional-answer comparisons (graded)
- [ ] Reflection + Search Keywords reviewed

When complete, run the Update Protocol, then move to **Lesson 24 — SNMP**.

---

*Lesson 23 written by Navi · 2026-06-20 · full-depth. Sources to cite when worked: Zabbix
documentation, CompTIA Network+ N10-009 (Network Operations), MITRE ATT&CK T1590/T1562.*
