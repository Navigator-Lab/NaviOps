# NaviOps — Full Curriculum Map

This is the **lesson-by-lesson roadmap** for the 90-day plan locked in
`docs/DECISIONS.md` (D6–D9) and `PROJECT_MISSION.md`. It expands the "Technical
Skills To Master" table into a concrete, sequenced lesson list. Each lesson is written
on-demand, full quality (8-step Gate Rule + Lenses A–D + WebSearch + graded quiz) per
`CLAUDE_TEACHING_RULES.md` — this file is the **map**, not the content.

For the career-side view (which lessons unlock which job applications), see
`JOB_MILESTONES.md`. For day-to-day state, see `LEARNING_STATE.md`.

> Numbering is sequential and may shift by ±1–2 lessons as topics are split/merged —
> `LEARNING_STATE.md`'s "Next Lesson" field is always the source of truth for what's
> actually next.

---

## Month 1 (Days 1–30) — Linux + Git + Bash + Networking + Docker → Junior SysAdmin DoD

| # | Lesson | Core Skills | NaviOps Artifact | Status |
|---|---|---|---|---|
| 01 | Linux Filesystems & Permissions | rwx/octal, chmod/chown/chgrp, setuid, ACLs, inode/st_mode | `docs/learning/lessons/01-.../README.md` | ✅ done |
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

**Month 1 milestone:** Junior Linux SysAdmin DoD (`PROJECT_MISSION.md`) + first
Portfolio Summary / Resume v1 / Interview talking points → unlocks **M2** in
`JOB_MILESTONES.md`.

---

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

**Month 2 milestone:** progress toward Mid-Level SysAdmin DoD; first AWS
provision+teardown cycle (≤ $5 spend, $100 free-tier credit clock per
`naviops-strategy` memory) → unlocks **M3**.

---

## Month 3 (Days 61–90) — Integration + Security + RHCSA → Infra/DevOps-ready

| # | Lesson | Core Skills | NaviOps Artifact | Status |
|---|---|---|---|---|
| 21 | Advanced Networking — VLANs, VPNs, Load Balancing | VLAN tagging, site-to-site/remote VPN basics, ALB/NLB concepts | `docs/networking/advanced-notes.md` | planned |
| 22 | Observability Stack | Prometheus/Grafana or CloudWatch dashboards, alert thresholds, SLOs | `docker/monitoring-stack/` | planned |
| 23 | Security Monitoring & Threat Detection | log-based threat detection, fail2ban tuning, CIS benchmarks intro | `scripts/threat_scan.sh` | planned |
| 24 | Multi-Service Docker Compose + Monitoring | full stack: app + db + reverse proxy + monitoring, troubleshooting | `docker-compose.yml` v2 | planned |
| 25 | Terraform + AWS Infra Project | multi-resource stack (VPC+EC2+SG+S3), remote state, teardown discipline | `infra/terraform/` v2 | planned |
| 26 | Capstone Incident-Response Project | end-to-end: break something on purpose, detect, diagnose, fix, document | `docs/runbooks/incident-002.md` + `PORTFOLIO.md` | planned |
| 27 | RHCSA Exam Prep & Review | spaced review across Lessons 01–26, RHCSA objective checklist | `docs/learning/RHCSA-CHECKLIST.md` | planned |

**Month 3 milestone:** Mid-Level SysAdmin DoD + RHCSA exam (sat ~Day 75–120,
skills-first per `naviops-strategy`) → unlocks **M4**.

---

## Cross-Cutting (woven into lessons above, not standalone)

- **C / Linux Internals (Lens D):** small focused C examples inside Lessons 03–05, 08–10
  (processes, signals, sockets, file descriptors) — never a standalone "C track".
- **Documentation:** every lesson produces a portfolio-worthy README; runbooks
  (Lessons 19, 26) follow Navi's `docs/` standards.
- **Git hygiene:** every lesson from 02 onward is its own branch + PR (GitHub Flow,
  Lesson 02).

## Update Protocol

When a lesson's number/scope changes (split, merged, reordered), update this table
**and** `LEARNING_STATE.md`'s "Next Lesson" field in the same commit — they must never
disagree about what's next.
