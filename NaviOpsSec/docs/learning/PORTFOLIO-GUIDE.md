# NaviOpsSec — Portfolio Guide

How to turn the lesson artifacts into a portfolio that gets a Blue-Team analyst hired. The
governing rule (all three platforms): **claim = committed evidence.** If it's on your
resume/LinkedIn, it must point to a real, sanitized artifact in this repo.

## What a SOC hiring manager actually wants to see

Not "I studied security." They want proof you can **work an alert end-to-end**:
detect → triage → investigate → contain → report. The 6-artifact package every lesson produces
*is* that proof. Curate it; don't dump it.

## The portfolio stack (best → supporting)

1. **Incident reports** (`docs/runbooks/`) — the headline artifacts. A clean report with a
   timeline, IOCs, RCA, containment, and recovery is the single strongest signal. Lead with the
   **capstone** (Lesson 35, compromised server) and 2–3 detection investigations (brute force,
   suspicious process, web attack).
2. **Detection content** (`docs/detections/`, `infra/wazuh/`) — your Wazuh rules + Sigma rules +
   an ATT&CK coverage map. Shows detection-engineering ability.
3. **Investigation scripts** (`scripts/`) — `shellcheck`-clean Bash that automates triage
   (`failed_logins.sh`, `proc_investigate.sh`, `ioc_sweep.sh`, …). Shows you automate the
   repetitive parts.
4. **Playbooks & runbooks** (`docs/playbooks/`, `docs/runbooks/`) — shows you think in
   repeatable process, not heroics.
5. **The build log itself** — the commit history + `LEARNING_STATE.md` shows consistent,
   self-driven growth.

## Repo presentation

- **Pin the repo** and make the README lead with the capstone incident report + a screenshot of
  a Wazuh dashboard/alert (sanitized).
- **One folder, one story.** Each lesson folder's `README.md` is a self-contained case: concept
  → detection → investigation → report. A reviewer can open any one and "get it" in 60 seconds.
- **Sanitize ruthlessly** (see the redaction convention in `LEARNING_STATE.md`). A leaked real
  IP/hostname/cred is an instant credibility (and sometimes legal) problem in a *security*
  portfolio — reviewers will notice, and it's the fastest way to fail the screen.

## Turning an artifact into a resume bullet (the formula)

> **[Action verb] + [what you built/did] + [tool] + [outcome/ATT&CK], proven in `<repo path>`.**

- "Detected and triaged SSH brute-force attacks with a custom Wazuh rule + Bash detector
  (`brute_force_detect.sh`), mapped to MITRE ATT&CK T1110 — `lessons/19`."
- "Investigated a compromised Linux server end-to-end: built the attack timeline, extracted
  IOCs, contained the host, and wrote the technical report + executive summary — `lessons/35`."
- "Engineered a Sigma → Wazuh detection set covering 5 ATT&CK techniques with documented
  coverage and FP-tuning — `lessons/32`."

## Milestone roll-ups

At each Wave (`JOB_MILESTONES.md`), write `lessons/<milestone>/PORTFOLIO.md`: 3–5 resume bullets,
3 interview talking points, and a one-paragraph portfolio summary linking the evidence. That file
is what you copy onto the resume/LinkedIn — never write a claim that doesn't trace to an artifact.
