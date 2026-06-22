# NaviOpsSec — Certification Mapping

How the 35 lessons map to the four certifications this platform tracks. Certs are **mapped, not
the goal** (`PROJECT_MISSION.md`): the lessons teach the *job*, and the mapping shows the exam
coverage you pick up for free. Use this to decide which cert to sit and when.

> **Targets:** CompTIA **Security+** (SY0-701) · CompTIA **CySA+** (CS0-003) · Microsoft
> **SC-200** (Security Operations Analyst) · **Blue Team Level 1 (BTL1)**. SC-200 is mapped
> conceptually (Wazuh stands in for Microsoft Sentinel; the analyst workflow transfers).

## Lesson → cert coverage matrix

| # | Lesson | Security+ | CySA+ | SC-200 | BTL1 |
|---|---|---|---|---|---|
| 01 | Security Fundamentals | ✅ 1.x General concepts | ✅ Security ops | — | ✅ SOC intro |
| 02 | CIA · Risk · Threat · Vuln | ✅ 1.x, 5.x Risk | ✅ Risk | — | ✅ Fundamentals |
| 03 | SOC Fundamentals | ✅ 4.x Ops | ✅ Security ops | ✅ Manage a SOC | ✅ SOC |
| 04 | Linux Logs & Auditing | ✅ 4.x Logging | ✅ Logging/analysis | ✅ Data sources | ✅ SIEM/logs |
| 05 | journalctl/grep/awk/sed | — (job skill) | ✅ Log analysis | ✅ KQL analog | ✅ Investigations |
| 06 | Syslog & Log Management | ✅ 4.x | ✅ Log mgmt | ✅ Connectors | ✅ SIEM |
| 07 | Network Security Fundamentals | ✅ 3.x, 4.x | ✅ Network analysis | ✅ Network signals | ✅ Network forensics |
| 08 | Threat Modeling Basics | ✅ 2.x, 5.x | ✅ Threat mgmt | — | ✅ |
| 09 | Threat Intelligence | ✅ 2.x Threat intel | ✅ Threat intel | ✅ Threat intel | ✅ Threat intel |
| 10 | MITRE ATT&CK | ✅ 2.x | ✅ ATT&CK | ✅ ATT&CK | ✅ ATT&CK |
| 11 | Cyber Kill Chain | ✅ 2.x | ✅ Attack frameworks | ✅ | ✅ |
| 12 | Indicators of Compromise | ✅ 2.x IOCs | ✅ IOA/IOC | ✅ Indicators | ✅ IOCs |
| 13 | SIEM Fundamentals | ✅ 4.x | ✅ SIEM | ✅ Sentinel core | ✅ SIEM |
| 14 | Wazuh Deployment | — | ✅ Tooling | ✅ (Sentinel analog) | ✅ SIEM hands-on |
| 15 | Wazuh Rules & Alerts | — | ✅ Detection | ✅ Analytics rules | ✅ Detections |
| 16 | Log-Analysis Workflows | ✅ 4.x | ✅ Analysis | ✅ Hunting/KQL | ✅ Investigations |
| 17 | Alert Triage | ✅ 4.x IR | ✅ Triage | ✅ Incident triage | ✅ Triage |
| 18 | Failed SSH Login Detection | ✅ 4.x | ✅ Detection | ✅ | ✅ |
| 19 | Brute Force Detection | ✅ 2.x attacks | ✅ Detection | ✅ | ✅ |
| 20 | Port Scan Detection | ✅ 2.x recon | ✅ Network detection | ✅ | ✅ |
| 21 | Suspicious Process Investigation | ✅ 4.x | ✅ Host analysis | ✅ Endpoint | ✅ Host forensics |
| 22 | User Account Investigation | ✅ 4.x IAM | ✅ Identity analysis | ✅ Identity (Entra analog) | ✅ |
| 23 | Web Attack Analysis | ✅ 2.x app attacks | ✅ Web/app analysis | ✅ | ✅ |
| 24 | File Integrity Monitoring | ✅ 4.x | ✅ FIM | ✅ | ✅ |
| 25 | Threat Hunting | — | ✅ Threat hunting | ✅ Hunting | ✅ Threat hunting |
| 26 | Detection Engineering | — | ✅ Detection | ✅ Analytics | ✅ Detections |
| 27 | Sigma Rules | — | ✅ Detection content | ✅ (rule logic) | ✅ Sigma |
| 28 | Incident Response Fundamentals | ✅ 4.x IR | ✅ IR process | ✅ Incident mgmt | ✅ IR |
| 29 | Containment/Eradication/Recovery | ✅ 4.x | ✅ IR phases | ✅ Respond | ✅ IR |
| 30 | Report Writing | ✅ 5.x governance | ✅ Reporting/comms | ✅ | ✅ Reporting |
| 31–34 | Projects | (applied) | ✅ (applied) | ✅ (applied) | ✅ (applied) |
| 35 | Capstone | (applied) | ✅ (applied) | ✅ (applied) | ✅ (applied) |

## Recommended sit order

1. **Security+ (SY0-701)** — after Module 1–3 (Lessons 01–12). Broad baseline; most-requested
   HR filter for analyst roles.
2. **BTL1** — after Modules 4–6 (Lessons 13–30). It's the most hands-on Blue-Team cert and lines
   up almost 1:1 with this platform's labs (SIEM, IR, investigations, malware/log analysis).
3. **CySA+ (CS0-003)** — after the projects (31–34). Analyst-focused; the detection/IR/reporting
   work maps directly.
4. **SC-200** — optional, if targeting a Microsoft-stack SOC; do the Azure/Sentinel hands-on
   separately (the Wazuh workflow transfers conceptually). Mapped, not built here (`DEFERRED.md`).

## How to claim a cert objective as "covered"

A lesson covers a cert objective only when its **6-artifact evidence package** exists (the rule
across this platform: *claim = committed evidence*). Tick the objective in your own copy when the
artifact is committed — not when you've merely read the lesson.
