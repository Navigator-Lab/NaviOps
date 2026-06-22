# Lesson 31 — Security Monitoring Project

**Status:** ✅ ready for self-study (full depth) · **Date written:** 2026-06-20
**Schema:** 12-section SOC (`docs/learning/CLAUDE_TEACHING_RULES.md`) · **Type:** Project
**Focus:** stand up a monitoring + log pipeline + baseline dashboard and detect a simulated event
**end-to-end**. **Full plan:** [`capstones/31-security-monitoring-project.md`](../../capstones/31-security-monitoring-project.md).

> **How to use this project:** this README is the schema wrapper; the build brief + rubric live in
> the capstone plan. Read §1–§7, execute §8 (the project), produce §9, quiz, reflect. Then Lesson 32.

---

## §1 — Concept (Scientific Theory)
A **security monitoring capability** is the assembled pipeline of Lessons 04–16: log collection
(agents/rsyslog) → SIEM (Wazuh) → normalization → rules/alerts → dashboards. This project proves you
can *build and operate* it, not just describe it — and demonstrate one event flowing end-to-end (log →
decoder → rule → alert → triage). It's the integration of the whole "see it" half of the platform.

**Lens A:** *Beginner* — set up the system that watches the logs and shows alerts. *Analyst* —
deploy the pipeline, baseline normal, build a dashboard, prove a detection fires end-to-end.
*Adversary/Kernel* — the project's value is the **baseline** (you can't spot abnormal without
documented normal) + verified end-to-end flow (every pipeline stage actually works, no silent gap).

**Lens B (the capability):** *technical* — an integrated collection→SIEM→alert→dashboard system with a
documented normal baseline. *Analogy* — installing the **building's whole security system** (cameras,
sensors, control room, monitors) and doing a walk-through test that one tripped sensor lights up the
right monitor. *Breaks down:* a real SOC also continuously tunes + expands — the project is the
foundation, not the finish.

```
 [agents/rsyslog] → [Wazuh manager: normalize+rule] → [alerts] → [dashboard]   + documented BASELINE
       └────────────── prove ONE event flows the whole way → triage ──────────────┘
```

---

## §2 — Linux Investigation Commands
```bash
/var/ossec/bin/wazuh-control status ; systemctl status wazuh-manager     # pipeline up?
tail -f /var/ossec/logs/alerts/alerts.json                                # alerts flowing?
bash scripts/wazuh_health.sh                                              # agents + flow health
jq '.rule.level' /var/ossec/logs/alerts/alerts.json | sort | uniq -c     # baseline alert profile
```

---

## §3 — Real-World Threat Context & Use Cases
This is the "stand up monitoring for a new environment" task a SecOps engineer does. It produces the
platform every later detection + investigation runs on, and the dashboard leadership/SOC watch.
Exam-wise it integrates SIEM/monitoring objectives (CySA+/SC-200/BTL1) applied, not recited.

## §4 — Detection
End-to-end: pick one event (failed login), show log → decoder → rule → alert → dashboard → triage.
The **baseline** is itself a detection enabler (deviation = signal). Pipeline-health monitoring (agents
reporting, events/sec) is a meta-detection (Lesson 06/13).

## §5 — Investigation & Triage
The dashboard becomes the triage surface; the baseline tells you what "normal" looks like so anomalies
are visible. Verify each source actually produces alerts (no silent/blind source).

## §6 — SOC Perspective
This *builds* the SOC's primary tool + situational-awareness dashboard. It formalizes Lesson 14's
deployment into an operated, baselined capability. Maps to the whole `soc/` module set.

## §7 — Incident-Response Perspective
The monitoring capability is IR's detection + evidence backbone (off-box logs, correlation, search).
Without it, IR is blind. This project is the "Preparation" phase of IR (Lesson 28) made real.

---

## §8 — Practical Lab (the project)
Execute [`capstones/31-security-monitoring-project.md`](../../capstones/31-security-monitoring-project.md):
1. **Pipeline:** logs from ≥1 host reach Wazuh (verify ingestion).
2. **Baseline:** document a normal day (logs/alerts with no attack).
3. **Dashboard:** build + export (sanitized) a SOC overview (`docs/dashboards/soc-overview.md`).
4. **End-to-end:** generate one event, trace it log→decoder→rule→alert→triage.
5. **Document:** monitoring runbook + a short detection report.

**Lens C:** automate health-checking the pipeline (`wazuh_health.sh`) — production monitors its own
monitoring. **Lens D:** confirm the baseline is data, not vibes (the actual normal alert/event rates).

---

## §9 — GitHub Artifact (the 6-artifact evidence package)
1. **Script:** `scripts/wazuh_health.sh`. 2. **Detection/config:** `docs/dashboards/soc-overview.md`
+ pipeline config (sanitized). 3. **Runbook:** monitoring-setup runbook. 4. **Playbook:** the
end-to-end-verification play. 5. **Incident report + notes:** the end-to-end detection report.
6. **SOC ticket:** `SOC-31` → Closed. (Rubric in the capstone plan.)

## §10 — Portfolio Artifact
- **Resume bullet:** "Stood up a security-monitoring pipeline (Wazuh + agents), baselined normal
  activity, built a SOC dashboard, and demonstrated end-to-end detection of a simulated event."
- **Interview talking point:** how you verify a pipeline actually works end-to-end (no silent gaps) +
  why a baseline matters. **Serves:** SecOps Engineer (Stage 5).

## §11 — Certification Crossover Notes
Applied SIEM/monitoring across CySA+/SC-200/BTL1. Detail: `alignment/CERTIFICATION-MAPPING.md`.

## §12 — Security Notes (Lens E)
**🔴** attackers exploit blind sources + un-baselined environments (nothing to compare to). **🔵**
broad source coverage + documented baseline + pipeline-health monitoring remove the blind spots; the
monitoring system is itself a hardened asset.

---

## Quiz (Interview-Style, Graded)
**Q1.** What are the stages of a monitoring pipeline, and how do you prove one works end-to-end?
> **Your answer:**

**Q2.** Why is a documented baseline essential to detection?
> **Your answer:**

**Q3.** What does a useful SOC overview dashboard show at a glance?
> **Your answer:**

**Q4.** **Scenario:** you deployed monitoring but a key host's events never appear. How do you debug
the pipeline?
> **Your answer:**

**Q5.** Why monitor the monitoring system's own health?
> **Your answer:**

*(Request the "Professional Answer" comparison under each before moving on.)*

---

## Reflection
*(After the project)* — What did you learn? · What confused you? · What would you do differently?

## Search Keywords For Further Understanding
- `wazuh deployment baseline dashboard` · `siem pipeline end to end test` · `security monitoring
  architecture` · `soc dashboard design` · 🔴 `blind log source` · 🔵 `pipeline health monitoring baseline`

---

## Lesson Status
- [ ] Project executed (pipeline + baseline + dashboard + end-to-end detection)
- [ ] 6-artifact evidence package committed (§9) · [ ] Quiz graded · [ ] Reflection + keywords

When complete, run the Update Protocol, then move to **Lesson 32 — Wazuh Detection Project**.

---
*Lesson 31 written by Navi · 2026-06-20 · full-depth. Plan: `capstones/31-security-monitoring-project.md`.*
