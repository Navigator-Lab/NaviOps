# Lesson 08 — Pure Practical: Threat Modeling Basics

> **Companion to [`README.md`](./README.md).** Pure practice: 3 scenario tasks, guided → ticket-driven
> → on-call. **Lab:** model the NaviOpsSec lab itself (Wazuh + victim) as your system. **Rules:**
> produce real artifacts, run ✅ **Verify** each task.

Each task: **Scenario · Objective · Given/constraints · Hints · ✅ Verify · Pitfalls · 🎯 Stretch.**

---

## Task 1 — Guided: STRIDE the lab (fluency)

**Scenario.** `SOC-081`. Threat-model the lab: draw the data flow, then enumerate threats with STRIDE.

**Objective.** A DFD (trust boundaries) + a STRIDE threat list per component.

**Given / constraints.** Cover the victim, agent, manager, dashboard. STRIDE each flow.

**Hints.**
1. DFD: victim → agent → manager → dashboard → analyst; mark trust boundaries.
2. STRIDE each element (Spoofing/Tampering/Repudiation/Info-disclosure/DoS/Elevation).
3. Note the highest-risk threats.

✅ **Verify.**
```bash
test -f docs/learning/reports/SOC-081-threat-model.md && grep -qiE 'spoof|tamper|denial' docs/learning/reports/SOC-081-threat-model.md && echo "STRIDE MODEL ✅"
```

**Pitfalls.**
- No trust boundaries (the whole point of the DFD).
- Listing threats without ranking.
- Skipping components (the agent/transport is a real target).

🎯 **Stretch.** Add a mitigation per top threat and map to a detection.

---

## Task 2 — Ticket-driven: model a proposed change (diagnose → assess)

**Scenario.** `SOC-082` (P3). *"We want to expose the dashboard to the internet — safe?"* Threat-model
the change before it ships.

**Objective.** Enumerate the new threats the change introduces + required controls, with a go/no-go.

**Given / constraints.** Focus on the delta the change introduces. Evidence-based recommendation.

**Hints.**
1. What new attack surface/trust boundary does the change create?
2. STRIDE the new exposure; list required controls (auth, TLS, WAF, IP allowlist).
3. Go/no-go with conditions.

✅ **Verify.**
```bash
grep -qiE 'control|go/no-go|recommend' docs/learning/reports/SOC-082-change-model.md && echo "ASSESSMENT ✅"
```

**Deliverable.** `docs/learning/reports/SOC-082-change-model.md`: change · new threats · required controls · recommendation.

**Pitfalls.**
- Modeling the whole system instead of the change delta.
- No concrete controls tied to threats.
- Approving without conditions.

🎯 **Stretch.** Add abuse cases (how an attacker would use the new surface).

---

## Task 3 — On-call: prioritize the model into a detection backlog (synthesis)

**Scenario.** `SOC-083` (time-boxed). Turn the threat model into action: rank threats and map the top
ones to detections you can build in this lab.

**Objective.** A ranked threat→detection backlog (which Wazuh rule/log would catch each top threat).

**Given / constraints.** Map to feasible lab detections. Rank by risk.

**Hints.**
1. Rank threats by likelihood × impact.
2. For each top threat, name the log source + detection that would catch it.
3. Sequence the backlog.

✅ **Verify.**
```bash
test -f docs/learning/reports/SOC-083-detection-backlog.md && grep -qi 'detection' docs/learning/reports/SOC-083-detection-backlog.md && echo "BACKLOG ✅"
```

**Deliverable.** `docs/learning/reports/SOC-083-detection-backlog.md`: threat · risk · log source · detection · priority.

**Pitfalls.**
- A model that never turns into detections (shelfware).
- Threats with no feasible detection noted as such.
- No prioritization.

🎯 **Stretch.** Build one of the top detections now (feeds L15/L26).

---

## Done?
- [ ] All ✅ Verify pass · [ ] DFD with trust boundaries · [ ] threats mapped to detections.
- [ ] **Guardrails:** no real infra details committed. → [README Reflection](./README.md).
