# NaviOpsSec — Capstone Guide

The 4 projects (Lessons 31–34) and the final capstone (Lesson 35) are where the platform stops
teaching and starts *proving*. Detailed per-project plans live in
[`capstones/`](capstones/); this guide is the overview, rubric, and the rules of the road.

## The arc

| # | Project | Proves | Primary deliverable |
|---|---|---|---|
| 31 | Security Monitoring Project | you can stand up monitoring + a log pipeline and detect an event end-to-end | monitoring stack + detection report |
| 32 | Wazuh Detection Project | you can engineer a detection set (rules/decoders/FIM/active-response) for ≥5 ATT&CK techniques | Wazuh ruleset + ATT&CK coverage map |
| 33 | Threat Hunting Project | you can run a hypothesis-driven hunt and convert a finding into a detection | hunt report + new Sigma/Wazuh rule |
| 34 | SOC Operations Project | you can operate a shift: triage a queue, escalate, ticket, hand over | shift report + case tickets |
| 35 | **Security Analyst Capstone** | you can run a full incident on a **compromised Linux server** | the complete incident package |

## The capstone scenario (Lesson 35) — the compromised server

A Linux server in your lab is compromised (you stage a benign, self-owned intrusion chain — see
[`workflows/compromised-server-scenario.md`](workflows/compromised-server-scenario.md)). You play
the **defender** and must produce, sanitized and committed:

1. **Investigation** — work the host + SIEM: find the entry point, the foothold, persistence,
   and any lateral movement.
2. **IOCs** — host/network/file indicators, extracted and listed.
3. **Attack timeline** — what happened when, mapped to MITRE ATT&CK + the kill chain.
4. **Containment** — stop the attacker (isolate/block), *after* preserving evidence.
5. **Recovery** — restore service and validate clean.
6. **Technical report** — for the security team (full detail, evidence, RCA).
7. **Executive summary** — for non-technical leadership (impact, what was done, business risk).
8. **Evidence package** — the collected artifacts (logs, captures, hashes), sanitized.
9. **Lessons learned** — what detection/control would have caught it earlier; the new rule you'd
   add.

## Rubric (how the capstone is graded)

| Dimension | Pass bar |
|---|---|
| Detection | every attack stage is detected (host evidence + a SIEM alert) |
| Investigation | root cause + full timeline, no unexplained gaps |
| IOCs | host + network + file indicators, correctly typed |
| ATT&CK mapping | each stage mapped to a technique ID |
| IR lifecycle | contain → eradicate → recover, evidence preserved *before* containment |
| Reporting | technical report **and** executive summary, both clean and audience-appropriate |
| Evidence | reproducible, sanitized, chain-of-custody noted |
| Lessons learned | a concrete new detection/control, ideally committed as a rule |

## Rules of the road (non-negotiable)

- **Lab-only, self-owned, benign** (`navi.project.md` Hard Rule #2). The "attacker" is you,
  staging a benign chain on your own VMs. No real malware, no third-party targets.
- **Evidence before containment.** Preserve (copy logs off-box, capture, hash) *before* you
  block/isolate — or you destroy the very timeline you're writing.
- **Sanitize everything** before commit (redaction convention, `LEARNING_STATE.md`). A
  security capstone with a leaked real credential fails on sight.
- **Reproducible.** Someone reading your report should be able to follow the timeline and
  understand each decision.

## Definition of done

The capstone is done when the full incident package (the 9 items above) is committed, the
`SOC-35` ticket is closed, the quiz is answered to a professional standard, and
`lessons/35-security-analyst-capstone/PORTFOLIO.md` rolls up the whole platform into the final
portfolio summary. At that point you can do a SOC analyst's core job end-to-end — and prove it.
