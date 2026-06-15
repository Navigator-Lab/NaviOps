# NaviOps — Roadmap (Lessons + Career Stages)

This is the **one place** that answers "what do I build, in what order, and which job does
each lesson serve." It merges the former `CURRICULUM.md` (numeric lesson map) and
`CAREER_STAGES.md` (career-stage view) into a single document (D15, 2026-06-15).

> **Three docs, three jobs (don't confuse them):**
> - **this file (`ROADMAP.md`)** — *what to build* (numeric order) + *which role it serves* (stages).
> - **`JOB_MILESTONES.md`** — *when to apply*, for what roles, with what keywords (the live job-hunt driver).
> - **`LEARNING_STATE.md`** — *where you are now* (what's done, what's next — the live progress tracker).
>
> The teaching *method* (8-step Gate Rule + Lenses A–E) lives in `CLAUDE_TEACHING_RULES.md`;
> the *why* lives in `PROJECT_MISSION.md`. Each lesson is written on-demand, full quality
> (Gate Rule + Lenses A–E + WebSearch + graded quiz) — this file is the **map**, not the content.

> Numbering is sequential and may shift by ±1–2 as topics split/merge —
> `LEARNING_STATE.md`'s "Next Lesson" field is always the source of truth for what's next.

---

# Part A — Numeric Lesson Map (build order)

## Month 1 (Days 1–30) — Linux + Git + Bash + Networking + Docker → Junior SysAdmin DoD

| # | Lesson | Core Skills | NaviOps Artifact | Status |
|---|---|---|---|---|
| 01 | Linux Filesystems & Permissions | rwx/octal, chmod/chown/chgrp, setuid, ACLs, inode/st_mode | `lessons/01-.../README.md` | ✅ done |
| 02 | Git & GitHub Fundamentals | add/commit/branch/merge, PRs, GitOps, SSH auth | `scripts/git-health-check.sh` | ✅ done |
| 03 | Bash Scripting Fundamentals | variables, functions, loops, conditions, args, error handling, logging | `scripts/user_audit.sh` or `scripts/healthcheck.sh` | ▶ next |
| 04 | Linux Users, Groups & Process Management | useradd/usermod/groups, ps/top/htop, signals, kill, nice/renice | `scripts/process_monitor.sh` | planned |
| 05 | systemd, Services & journald | unit files, systemctl, enable/disable, journalctl filtering | `scripts/service_check.sh` | planned |
| 06 | Cron, Scheduled Tasks & Log Rotation | crontab, at, logrotate, systemd timers | `scripts/backup.sh` (cron-driven) | planned |
| 07 | SSH, Package Management & Storage | ssh-keygen/agent/config, apt/dnf, disks/partitions/LVM, mounts, fstab | `scripts/disk_report.sh` | planned |
| 08 | Networking I — OSI/TCP-IP & Subnetting | OSI 7 layers, IPv4 addressing, CIDR/subnetting math, ip/ss/netstat | `docs/networking/subnet-cheatsheet.md` | planned |
| 09 | Networking II — DNS, DHCP, NAT, Routing, Firewalls | dig/nslookup, DHCP lease cycle, NAT types, routing tables, ufw/iptables | `scripts/firewall_audit.sh` | planned |
| 10 | Linux Hardening & Security Basics | SSH hardening, fail2ban, user auditing, least privilege, sudoers | `scripts/security_audit.sh` | planned |
| 11 | Docker Fundamentals | images, containers, Dockerfile, volumes, networks, registries | `docker/` first Dockerfile | planned |
| 12 | Docker Compose & Multi-Container Apps | compose.yml, service dependencies, healthchecks, troubleshooting | `docker-compose.yml` for NaviOps tooling | planned |

**Month 1 milestone:** Junior Linux SysAdmin DoD (`PROJECT_MISSION.md`) + first Portfolio
Summary / Resume v1 / Interview talking points → unlocks **M2** in `JOB_MILESTONES.md`.

## Month 2 (Days 31–60) — Automation + AWS + Observability → Cloud Support / SysAdmin

| # | Lesson | Core Skills | NaviOps Artifact | Status |
|---|---|---|---|---|
| 13 | Ansible Fundamentals | inventories, ad-hoc commands, playbooks, roles, idempotency | `infra/ansible/` first playbook | planned |
| 14 | GitHub Actions CI Basics | workflow YAML, lint/test/deploy jobs, secrets, branch-protected merges | `.github/workflows/ci.yml` | planned |
| 15 | AWS Fundamentals — Account & IAM | account setup, IAM users/roles/policies, MFA, least privilege, billing alarms | `docs/aws/iam-notes.md` (redacted) | planned |
| 16 | AWS EC2 & VPC Basics | EC2 launch/connect, VPC/subnets/route tables, security groups, key pairs | `infra/terraform/` (or console notes) | planned |
| 17 | AWS S3, EBS & Backups | S3 buckets/policies, EBS volumes/snapshots, backup strategy (3-2-1) | `scripts/aws_backup_check.sh` | planned |
| 18 | AWS CloudWatch & Monitoring/Alerting | metrics, alarms, log groups, SNS notifications, dashboards | `docs/aws/cloudwatch-dashboard.md` | planned |
| 19 | Log Analysis & Incident Response Runbook #1 | journald/CloudWatch log correlation, RCA method, runbook format | `docs/runbooks/incident-001.md` | planned |
| 20 | Terraform Fundamentals | providers, resources, state, plan/apply/destroy, variables | `infra/terraform/main.tf` | planned |

**Month 2 milestone:** progress toward Mid-Level SysAdmin DoD; first AWS provision+teardown
cycle (≤ $5 spend, $100 free-tier credit clock per `naviops-strategy`) → unlocks **M3**.

## Month 3 (Days 61–90) — Integration + Security + RHCSA → Infra/DevOps-ready

| # | Lesson | Core Skills | NaviOps Artifact | Status |
|---|---|---|---|---|
| 21 | Advanced Networking — VLANs, VPNs, Load Balancing | VLAN tagging, site-to-site/remote VPN basics, ALB/NLB concepts | `docs/networking/advanced-notes.md` | planned |
| 22 | Observability Stack | Prometheus/Grafana or CloudWatch dashboards, alert thresholds, SLOs | `docker/monitoring-stack/` | planned |
| 23 | Security Monitoring & Threat Detection | log-based threat detection, fail2ban tuning, CIS benchmarks intro, Wazuh SIEM | `scripts/threat_scan.sh` | planned |
| 24 | Multi-Service Docker Compose + Monitoring | full stack: app + db + reverse proxy + monitoring, troubleshooting | `docker-compose.yml` v2 | planned |
| 25 | Terraform + AWS Infra Project | multi-resource stack (VPC+EC2+SG+S3), remote state, teardown discipline | `infra/terraform/` v2 | planned |
| 26 | Capstone Incident-Response Project | end-to-end: break something on purpose, detect, diagnose, fix, document | `docs/runbooks/incident-002.md` + `PORTFOLIO.md` | planned |
| 27 | RHCSA Exam Prep & Review | spaced review across Lessons 01–26, RHCSA objective checklist | `docs/learning/RHCSA-CHECKLIST.md` | planned |
| 28 | SIEM Operations & SOC Alert Triage | alert triage, true/false positive, severity rubric, MITRE ATT&CK, brute-force/scan detection | `scripts/alert_triage.sh` + `docs/runbooks/soc-triage-runbook.md` | planned |

**Month 3 milestone:** Mid-Level SysAdmin DoD + RHCSA exam (sat ~Day 75–120, skills-first
per `naviops-strategy`) → unlocks **M4**. **Lesson 28** is the Security-Analyst stage
detection capstone (see Part B, Stage 5).

## Cross-Cutting (woven into lessons above, not standalone)

- **Attacker/Defender — Lens E (D14):** every lesson teaches both the attacker abuse
  (GTFOBins/MITRE ATT&CK) and the defender detection/hardening, scaled by lesson. This is
  the running thread that builds the Security-Analyst (Stage 5) mindset from Lesson 01.
- **C / Linux Internals (Lens D):** small focused C examples inside Lessons 03–05, 08–10.
- **Documentation:** every lesson produces a portfolio-worthy README; runbooks (19, 26).
- **Git hygiene:** every lesson from 02 onward is its own branch + PR (GitHub Flow).

---

# Part B — Career Stages (NOC-First View)

Groups the lessons above into the job progression the operator is targeting — **NOC first,
then Linux SysAdmin, then Security Analyst** — without renumbering. Answers "which lessons
get me hired for *this* role."

### Honest framing: is NOC really "easiest first"? (WebSearch 2026)

Mostly yes, with one correction. **NOC Technician is an accessible entry tier**, but it is
**not strictly easier than Help Desk** — Help Desk has the lowest barrier; NOC expects a
**Network+/CCNA-level baseline**, monitoring dashboards (SolarWinds, Nagios, Zabbix, PRTG),
ticketing (ServiceNow/Remedy), 24/7 shift work, and **structured escalation**. The upside:
**NOC → SysAdmin → SOC is a real, recognized bridge**, and blended **"NOSC"** roles are now
posted — so a NOC start that deliberately builds Linux + security depth is a strong on-ramp
to both SysAdmin and Security Analyst. *(Sources in
`docs/reports/EXP/EXP_REPORT_2026-06-15_read.md-Audit-NOC-First-Attacker-Defender.md`.)*

### Stage 1 — NOC Technician  *(primary near-term target)*
**Lessons:** 01, 03, 04, 05, 08, 09, 18, 19 — plus NOC scope notes in 08/09/18/19 (monitoring
tooling, ticketing, escalation matrix, shift handover).
- **Objectives:** read dashboards (normal vs abnormal); Tier-1 network/Linux troubleshooting;
  open/route tickets; follow an escalation matrix; document incidents and hand over cleanly.
- **Hiring relevance:** monitoring tools, TCP/IP, ticketing, escalation, 24/7, documentation.
  **Cert:** CompTIA **Network+** (highest leverage), CCNA a plus. → `JOB_MILESTONES.md` **M1 (Wave 1)**.

### Stage 2 — Linux Support Technician
**Lessons:** Stage 1 + 02 (Git), 06 (cron/logrotate), 07 (SSH/packages/storage), 10 (hardening).
- **Objectives:** confident Linux CLI troubleshooting, user/permission/service fixes, package
  & storage issues, basic hardening, version-controlled changes.
- **Cert:** Linux+/LPIC-1 (in progress is fine). Highest-probability first door (D9).

### Stage 3 — Junior Linux SysAdmin
**Lessons:** 01–12 complete (Junior SysAdmin DoD), incl. 11–12 (Docker/Compose). → **M2 (Wave 2)**.
- **Objectives:** administer users/services/storage/networking independently; Bash automation
  with error handling; run a containerized service; ≥1 incident-response write-up.
- **Cert:** **RHCSA** (skills-first, sat ~Day 75–120 per D8).

### Stage 4 — Linux SysAdmin (Cloud-Capable)
**Lessons:** 13, 14, 15–18, 20, 21, 22, 25. → **M3 (Wave 3)** — Cloud Support / SysAdmin / SRE-junior.
- **Objectives:** IaC provision/teardown, cloud monitoring/alerting, config management.
- **Cert:** **AWS Cloud Practitioner** (highest leverage for the cloud wave).

### Stage 5 — Security Analyst (SOC)  *(the security-track destination)*
**Lessons:** 10 (hardening), 19 (log analysis & IR — failed-SSH/brute-force/scan detection),
23 (Wazuh SIEM, threat detection, FIM), **28 (SIEM ops & SOC alert triage)**, 26 (capstone IR)
— **plus every lesson's Lens E** (the attacker/defender thread woven through 01–27).
- **Objectives:** operate a SIEM, **triage alerts** (true/false positive, severity,
  escalate/close), tune false positives, map activity to **MITRE ATT&CK**, run the IR
  lifecycle (detect → contain → eradicate → recover → report).
- **Hiring relevance:** SIEM (Wazuh/Splunk/ELK), log analysis, ATT&CK, alert triage, false
  positives. **Cert:** CompTIA **Security+** (the standard SOC Tier-1 entry cert).
- **Why the Lens E thread matters:** by Stage 5 you've already seen, in every lesson, *how
  each command is attacked and detected* — so SOC triage is recognition, not new theory.

### Stage 6 — DevOps / Infrastructure Engineer  *(6-month goal, not first job — D9)*
**Lessons:** 13, 14, 20, 24, 25, 27 — the full IaC + CI/CD + orchestration + observability stack.
→ **M4 (Wave 4)**. NaviOps itself becomes the portfolio pitch.

### Stage ↔ Application-wave map

| Stage | Lessons | Wave (`JOB_MILESTONES.md`) | Headline cert |
|---|---|---|---|
| 1 — NOC Technician | 01,03,04,05,08,09,18,19 (+NOC notes) | M1 (Wave 1, ~Day 14) | Network+ |
| 2 — Linux Support | + 02,06,07,10 | M1 (Wave 1) | Linux+/LPIC-1 |
| 3 — Jr Linux SysAdmin | 01–12 | M2 (Wave 2, ~Day 30) | RHCSA (in progress) |
| 4 — Linux SysAdmin / Cloud | 13–18,20–22,25 | M3 (Wave 3, ~Day 60) | AWS Cloud Practitioner |
| 5 — Security Analyst (SOC) | 10,19,23,28,26 + Lens E thread | M3→M4 | Security+ |
| 6 — DevOps / Infra | 13,14,20,24,25,27 | M4 (Wave 4, ~Day 90+) | RHCSA + AWS |

> Stages are **cumulative and overlapping**, not exclusive — apply for NOC (Stage 1) while
> finishing Stage 3 lessons (the "apply in waves, widen the net" strategy, D6–D9).

---

## Update Protocol

When a lesson's number/scope changes (split, merged, reordered) **or** a stage's membership
changes, update this file **and** `LEARNING_STATE.md`'s "Next Lesson" field **and**
`JOB_MILESTONES.md`'s wave skills in the same commit — these views must never disagree about
what's next or which lesson serves which role.
