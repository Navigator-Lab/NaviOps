# Project 32 — Wazuh Detection Project

**Goal:** prove you can do **detection engineering** — build a tested, tuned detection set in
Wazuh (custom rules + decoders + FIM + active response) covering **≥5 MITRE ATT&CK techniques**,
with documented coverage and false-positive tuning.

## Prerequisites
Lessons 14–16 (Wazuh), 18–24 (the detections), 26–27 (detection engineering + Sigma).

## Build steps
1. **Pick ≥5 techniques** spanning tactics — e.g. T1110 (brute force), T1078 (valid accounts),
   T1136 (account creation), T1053 (cron persistence), T1059 (execution), T1070 (log tampering),
   T1565 (FIM/data manipulation).
2. **Write the detections:** custom `local_rules.xml` (+ decoders where needed), a `syscheck`/FIM
   config for critical files, and one **active-response** action (lab-only, e.g. firewall-drop on
   brute force).
3. **Test each** with `wazuh-logtest` and by generating the (benign, lab) telemetry — confirm the
   alert fires at the right level/group.
4. **Tune:** generate benign look-alike activity (legit sudo, your own vuln scan, a backup) and
   tune out the false positives. Document each tuning decision.
5. **Map coverage:** build an ATT&CK coverage map (technique → rule ID → tested? → FP-tuned?).
6. **Author at least one as Sigma** and convert it (portability, Lesson 27).

## Deliverables
- `infra/wazuh/local_rules.xml` + decoders + `fim.conf` + active-response config (sanitized).
- `docs/detections/attack-coverage.md` (the coverage map).
- `docs/detections/sigma/` (≥1 Sigma rule + the converted Wazuh rule).
- A short "detection set" report: what each rule catches, expected FPs, how tuned.
- `SOC-32` ticket.

## Rubric
| Dimension | Pass bar |
|---|---|
| Coverage | ≥5 techniques, ≥2 tactics |
| Tested | each rule fires on real (lab) telemetry via `wazuh-logtest` |
| Tuned | each rule has a documented FP analysis |
| Portable | ≥1 rule authored in Sigma + converted |
| Mapped | a coverage map ties rules → ATT&CK |

## Resume line
"Engineered a tested, FP-tuned Wazuh detection set covering 5+ MITRE ATT&CK techniques (rules,
decoders, FIM, active response) with a documented coverage map and a portable Sigma rule —
`lessons/32`."
