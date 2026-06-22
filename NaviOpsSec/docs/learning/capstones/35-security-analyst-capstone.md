# Capstone 35 — Security Analyst Capstone (the compromised server)

**Goal:** the platform's final proof — take a **compromised Linux server** and run the whole
incident end-to-end as the defender: investigate, identify IOCs, build the timeline, contain,
recover, and produce a **technical report + executive summary + evidence package + lessons
learned**.

This brief is the project rubric. The full staged scenario (the lab, the attack chain, the
defender mission) lives in
[`../workflows/compromised-server-scenario.md`](../workflows/compromised-server-scenario.md).
Overview + grading: [`../CAPSTONE-GUIDE.md`](../CAPSTONE-GUIDE.md).

## Prerequisites
Effectively the whole platform — Modules 1–6 — plus the four projects (31–34). The Wazuh stack +
a lab victim host.

## The mission (10-item incident package)
1. Investigate the host + SIEM; reconstruct each attack stage from evidence.
2. Identify IOCs (host / network / file).
3. Build the attack timeline (UTC), mapped to ATT&CK + the kill chain.
4. Contain — *after* preserving evidence.
5. Eradicate (remove payload + all persistence; close the entry vector).
6. Recover + validate clean.
7. Technical report (`templates/incident-report.md`).
8. Executive summary (`templates/executive-summary.md`).
9. Evidence package (`templates/evidence-package.md`, sanitized + hashed).
10. Lessons learned + a **new committed detection** (`templates/lessons-learned.md`).

## Deliverables
- The full incident package (10 items above) in `docs/runbooks/capstone/` (sanitized).
- The new detection committed to `docs/detections/`.
- `SOC-35` ticket (To Do → Closed).
- `PORTFOLIO.md` — the **final portfolio summary** rolling up the whole platform.

## Rubric (capstone)
| Dimension | Pass bar |
|---|---|
| Detection | every stage detected (host evidence + SIEM alert) |
| Investigation | root cause + full timeline, no unexplained gaps |
| IOCs | host + network + file, correctly typed |
| ATT&CK | each stage mapped to a technique |
| IR lifecycle | contain→eradicate→recover, **evidence preserved before containment** |
| Reporting | technical report **and** exec summary, audience-appropriate |
| Evidence | reproducible, sanitized, hashed, chain-of-custody noted |
| Lessons learned | a concrete new detection, committed |

## Done when
The package is committed + sanitized, `SOC-35` is Closed, the capstone quiz is answered to a
professional standard, and `PORTFOLIO.md` is written. At that point you can do a SOC analyst's
core job end-to-end — and prove it with one repository.

## Resume line (the headline)
"Investigated a compromised Linux server end-to-end: detected the intrusion in a Wazuh SIEM,
reconstructed the attack timeline (MITRE ATT&CK), extracted IOCs, contained and recovered the
host, and delivered a technical report + executive summary + evidence package — `lessons/35`."
