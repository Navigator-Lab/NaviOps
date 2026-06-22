# Lesson 14 — Wazuh Deployment

**Status:** ✅ ready for self-study (full depth) · **Date written:** 2026-06-20
**Schema:** 12-section SOC (`docs/learning/CLAUDE_TEACHING_RULES.md`)
**Focus:** stand up Wazuh — manager + indexer + dashboard + **agents** — enroll a host, collect its
logs, and see your first real alerts. Wazuh as a first-class citizen.
**Primary artifact:** `infra/wazuh/ossec.conf` (sanitized agent/manager config) + `infra/wazuh/README.md`.

> **Danger zone (`navi.project.md`):** lab-only, self-owned VMs. Never commit real agent keys,
> cluster keys, IPs, or hostnames. Read §1–§7, do §8 (deploy + enroll + first alert), produce §9,
> quiz, reflect. Then Lesson 15.

---

## §1 — Concept (Scientific Theory)

### What it is
**Wazuh** is an open-source security platform (SIEM + XDR). Components:
- **Wazuh manager** — receives agent data, runs decoders/rules, generates alerts, drives FIM +
  active response.
- **Wazuh indexer** (OpenSearch) — stores + indexes alerts/events for search.
- **Wazuh dashboard** — the web UI (search, dashboards, rule/agent management).
- **Wazuh agent** — installed on each monitored host; collects logs, file-integrity data, inventory,
  and runs active-response scripts; ships to the manager (encrypted, port 1514).

### Why it exists
It's the practical, free, lab-runnable SIEM — the spec's required first-class tool. Deploying it
yourself teaches the *whole* pipeline (Lesson 13) hands-on: you see collection (agent),
normalization (decoders), correlation (rules), and alerting (dashboard) as real moving parts you
configured.

### Three-Level Depth (Lens A)
- **Level 1 — Beginner:** install a "manager" (the brain + screen) and put "agents" on the machines
  you want to watch; the agents send their logs to the manager, which shows you alerts.
- **Level 2 — Analyst/SOC:** you deploy the single-node stack, **enroll** agents (key exchange), tell
  agents which logs to collect (`ossec.conf` `<localfile>`), and verify alerts flow to
  `alerts.json` + the dashboard. Agent **health** (connected/disconnected) is a monitored signal.
- **Level 3 — Adversary/Kernel:** the agent reads logs + FIM + inventory and forwards over an
  encrypted channel (1514/UDP-TCP) using a per-agent key; the manager decodes + evaluates rules and
  writes alerts. An agent going **disconnected** (and not in maintenance) is itself a detection
  (T1562 — the attacker killed the agent).

### Two Teaching Approaches (Lens B) — agent/manager model
**Approach 1 (technical):** a hub-and-spoke telemetry system — lightweight agents (collectors +
response actuators) report to a central manager (decoder/rule engine + alert store), decoupling
collection from analysis and enabling fleet-wide detection + response.

**Approach 2 (analogy):** **security guards (agents) reporting to a control room (manager).** Each
guard watches their building (host), radios anything noteworthy to the control room, and can act on
orders (active response). The control room correlates all reports and sounds alarms. **Where it
breaks down:** if a guard's radio is cut (agent disconnected), the control room must *notice the
silence* — which is exactly the disconnected-agent detection.

### Visual (ASCII) — single-node lab
```
   host01 [agent] ─┐
   host02 [agent] ─┼─1514(enc)─► [ Wazuh MANAGER ]──► decoders/rules ──► alerts.json
   web01  [agent] ─┘                    │                                    │
                                        ▼                                    ▼
                                   [ INDEXER (OpenSearch) ] ◄──── [ DASHBOARD (web UI) ]
```

---

## §2 — Linux Investigation Commands

```bash
# manager side
systemctl status wazuh-manager wazuh-indexer wazuh-dashboard
/var/ossec/bin/wazuh-control status         # component status
/var/ossec/bin/manage_agents                # add/list agents, extract keys (lab)
tail -f /var/ossec/logs/alerts/alerts.json  # live alerts (the proof it works)
tail -f /var/ossec/logs/ossec.log           # manager health/errors
# agent side
systemctl status wazuh-agent
grep -E "Connected|server" /var/ossec/logs/ossec.log   # is the agent talking to the manager?
/var/ossec/bin/agent-auth -m <MANAGER_IP>   # enroll (lab)
```
| Task | Wazuh artifact |
|---|---|
| enroll agent | `manage_agents` / `agent-auth` (key exchange) |
| choose logs to collect | `ossec.conf` `<localfile>` blocks |
| verify alerts | `alerts.json` + dashboard |
| agent health | `ossec.log` "Connected", dashboard agent status |

---

## §3 — Real-World Threat Context & Use Cases

- **Endpoint visibility:** agents give per-host log + FIM + inventory coverage — the foundation for
  every detection in Lessons 18–24.
- **Fleet detection:** one manager correlates across all agents → lateral-movement + multi-host
  scoping (Lesson 35).
- **Active response:** agents can auto-act (block IP, kill process) — powerful + dangerous (Lesson
  29; lab-only).
- **Exam framing:** SIEM/agent architecture + deployment concepts on CySA+/SC-200/BTL1 (Wazuh as
  the hands-on instance).

---

## §4 — Detection

- **Out of the box,** Wazuh ships thousands of rules — you'll get real alerts (SSH failures, sudo,
  package changes) the moment an agent reports. That's your detection baseline.
- **Collection is the prerequisite detection decision:** if `ossec.conf` doesn't collect
  `auth.log`, no auth detection fires. Choosing `<localfile>` sources *is* deciding what you can
  detect.
- **Agent-disconnected rule:** Wazuh alerts when an agent stops reporting — a high-value, built-in
  tamper detection.

---

## §5 — Investigation & Triage

Once deployed, the dashboard is your triage surface (alert → fields → pivot/search). Verify each
new agent actually produces alerts (generate a failed login, confirm it appears) — an enrolled-but-
silent agent is a blind spot. Cross-check with the box (Linux-first) when an alert's parsing looks
off.

---

## §6 — SOC Perspective

This lesson stands up the SOC's actual tooling — from here on, "the SIEM" is real. Agent inventory
+ health become a dashboard; onboarding a new asset = deploy + enroll + verify alerts. Maps to the
Security-Monitoring project (Lesson 31), which formalizes the deployment + baseline.

---

## §7 — Incident-Response Perspective

Wazuh is your IR platform: agents preserve + ship evidence off-box in real time (Lesson 06 made
concrete), the manager correlates across the estate for scoping, and active response enables fast
containment (Lesson 29). A disconnected agent during an incident is itself a finding.

---

## §8 — Practical Lab (build this yourself)

**Goal:** stand up single-node Wazuh, enroll one agent, and see your first real alert.

### Lens C — Manual → Automated → Why
- **Manual:** you tailed `auth.log` on one host (Lesson 05).
- **Automated:** the agent ships that log continuously to a manager that *alerts* automatically —
  the SIEM pipeline, running.
- **Why:** this is the leap from "I can investigate one box" to "the system watches all boxes for
  me." Production uses multi-node clusters + automated agent deployment.

### Steps
1. Deploy single-node Wazuh on a lab VM (manager + indexer + dashboard — the official quickstart).
   Confirm `wazuh-control status` all green.
2. Install + enroll an agent on a second lab host (the target). Confirm `ossec.log` shows
   "Connected to manager."
3. Ensure the agent collects `auth.log` (check `ossec.conf` `<localfile>`); save a sanitized copy to
   `infra/wazuh/ossec.conf`.
4. **First alert:** generate a few failed SSH logins on the agent host (drill 1). Watch them appear
   in `alerts.json` + the dashboard. You just ran the whole pipeline.
5. Verify the **agent-disconnected** alert: stop the agent briefly, confirm the manager alerts,
   restart it.

### Lens D — the raw artifact
```
# alerts.json (post-pipeline) — your failed login, normalized + ruled:
{"rule":{"level":5,"description":"sshd: authentication failed","id":"5710",
 "groups":["authentication_failed"]},"data":{"srcip":"10.0.0.99","srcuser":"admin"},
 "agent":{"name":"web01"},"timestamp":"2026-06-20T02:14:07Z"}
```

---

## §9 — GitHub Artifact (the 6-artifact evidence package)

1. **Script:** `scripts/wazuh_health.sh` — check manager/agent status + recent alert flow.
2. **Detection rule/config:** `infra/wazuh/ossec.conf` (sanitized) + `infra/wazuh/README.md`.
3. **Runbook:** `docs/runbooks/runbook-agent-onboarding.md` — deploy + enroll + verify an agent.
4. **Playbook:** the deploy/verify play (incl. agent-disconnected check).
5. **Incident report + notes:** the first-alert proof (generated failed login → alert in dashboard)
   + agent-disconnected test + notes.
6. **SOC ticket:** `SOC-14` (Task: "deploy Wazuh + enroll agent + first alert") → Closed.

---

## §10 — Portfolio Artifact

- **Resume bullet:** "Deployed a Wazuh SIEM/XDR (manager + indexer + dashboard), enrolled agents,
  and validated the end-to-end detection pipeline with live alerts and agent-health monitoring."
- **Interview talking point:** describe the agent/manager architecture + enrollment + how you'd
  verify an agent is actually producing alerts (not just connected).
- **Serves:** SOC T1 (Stage 2). The platform's hands-on SIEM milestone.

---

## §11 — Certification Crossover Notes

- **CySA+:** SIEM tooling. **SC-200:** Sentinel/Defender deployment (analog). **BTL1:** SIEM
  hands-on (Wazuh-style). **Security+:** monitoring tooling (4.x). Detail:
  `alignment/CERTIFICATION-MAPPING.md`.

---

## §12 — Security Notes (Lens E — Attacker & Defender)

**🔴 Attacker:** kill/uninstall the agent (T1562.001), block its egress to the manager, or compromise
the manager itself. They want the control room blind.

**🔵 Defender:** alert on **agent-disconnected**, protect/segment the manager, restrict who can
manage rules/agents, and verify agents are *producing alerts* not just "connected." Secure the SIEM
like the crown jewel it is — it's the thing watching everything else.

---

## Quiz (Interview-Style, Graded)

**Q1.** Name the four Wazuh components and what each does.
> **Your answer:**

**Q2.** What happens during agent enrollment, and over what channel does an agent report?
> **Your answer:**

**Q3.** Why does the choice of `<localfile>` sources in `ossec.conf` determine what you can detect?
> **Your answer:**

**Q4.** **Scenario:** an agent shows "connected" but you're getting no alerts from its host. How do
you debug it?
> **Your answer:**

**Q5.** Why is an agent-disconnected alert a security detection, not just an ops nuisance?
> **Your answer:**

*(Request the "Professional Answer" comparison under each before moving on.)*

---

## Reflection
*(After the quiz)* — What did you learn? · What confused you? · What would you do differently?

---

## Search Keywords For Further Understanding

**Core**
- `wazuh single node deployment quickstart`
- `wazuh agent enrollment manage_agents`
- `wazuh ossec.conf localfile log collection`
- `wazuh alerts.json dashboard`
- `wazuh agent disconnected alert`

**Tools**
- `wazuh-control status`
- `wazuh indexer opensearch`

**Going further**
- `wazuh rules alerts` (L15) · `file integrity monitoring` (L24) · `active response` (L29) · `security monitoring project` (L31)

**Red / Blue (Lens E):**
- 🔴 `disable wazuh agent T1562.001`, `block agent egress`, `compromise siem`
- 🔵 `agent disconnected detection`, `harden wazuh manager`, `verify agent producing alerts`

---

## Lesson Status
- [ ] §8 lab completed (Wazuh deployed; agent enrolled; first alert seen; disconnect tested)
- [ ] 6-artifact evidence package committed (§9)
- [ ] Quiz answered + professional-answer comparisons (graded)
- [ ] Reflection + Search Keywords reviewed

When complete, run the Update Protocol, then move to **Lesson 15 — Wazuh Rules & Alerts**.

---

*Lesson 14 written by Navi · 2026-06-20 · full-depth. Sources to cite at study time: Wazuh
documentation (installation/agents), Wazuh ruleset docs.*
