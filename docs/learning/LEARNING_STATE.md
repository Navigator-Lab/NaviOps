# NaviOps — Learning State

This file is the **living pedagogy tracker**. Updated after every lesson and milestone
(see Update Protocol at the bottom). A future Claude session reads this **and**
`docs/STATUS.md` to resume teaching with zero re-explanation.

> ⚠️ **Redaction convention (mandatory — `navi.project.md` Hard Rule #1):**
> This file (and every lesson under `docs/learning/lessons/`) is part of a **public**
> repo. The "Current Infrastructure" and "Current AWS State" sections below — and any
> command output / screenshots referenced from lessons — MUST use placeholders only:
> - AWS Account ID → `<ACCOUNT_ID>`
> - Real public/private IPs → `10.0.x.x` / `203.0.113.x` (TEST-NET-3, RFC 5737) or `<IP>`
> - Hostnames/domains → `<HOSTNAME>` / `example.internal`
> - ARNs, instance IDs, key pair names → `<INSTANCE_ID>`, `<ARN>`, `<KEY_NAME>`
> - Never paste real `~/.aws/credentials`, `.pem` keys, `.tfstate`/`.tfvars` content.
> Real values may exist *locally* (gitignored) but never in this file or any committed doc.

## Current Goal
Phase 1: Junior Linux SysAdmin in ~30 days (see `PROJECT_MISSION.md` Career Goal),
building NaviOps as the vehicle.

## Current Phase
**Day 0 — Bootstrap.** Repo scaffolded (`.agent/`, `docs/`, pedagogy stack, gitignore,
Gitleaks). No lessons completed yet.

## Skills Already Learned
_(none yet)_

## Skills Partially Learned
_(none yet)_

## Skills Not Started
- Linux: filesystems, permissions, users/groups, processes, systemd, journald, cron, SSH, package management, storage, backups
- Bash: variables, functions, loops, conditions, logging, error handling, automation
- Networking: OSI/TCP-IP, subnetting, DNS, DHCP, NAT, routing, switching, VLANs, VPNs, firewalls, load balancing
- Security: hardening, SSH security, user auditing, log analysis, threat detection, incident response
- Docker: containers, images, networks, volumes, Compose, production deployment
- AWS: IAM, EC2, VPC, security groups, EBS, S3, CloudWatch, backups, monitoring
- Observability: logs, metrics, monitoring, alerting, RCA

## Current Infrastructure
_(none provisioned yet — placeholders only once it exists, e.g.)_
- Dev box: `<not yet created>`

## Current AWS State
_(no AWS account work started — placeholders only once it exists, e.g.)_
- Account: `<ACCOUNT_ID>` (not yet in use)
- IAM: `<not yet configured>`
- VPC/EC2/S3/CloudWatch: `<none>`

## Current Networking Knowledge
_(not started)_

## Current Bash Knowledge
_(not started)_

## Current Security Knowledge
_(not started)_

## Current Docker Knowledge
_(not started)_

## Completed Projects
_(none yet)_

## Active Tasks
- Choose and start Lesson 01 (Linux filesystems & permissions — recommended Day 1 per
  `PROJECT_MISSION.md`).

## Blockers
_(none)_

## Interview Readiness
Not yet assessed — baseline to be set after Lesson 01.

## Portfolio Readiness
Not yet started — first artifact expected after Lesson 01.

## Next Lesson
**Lesson 01 — Linux Filesystems & Permissions** (proposed). Run through the full Gate
Rule in `CLAUDE_TEACHING_RULES.md`; output to
`docs/learning/lessons/01-linux-filesystems-permissions/README.md`.

## Recommended Next Actions
1. Confirm Lesson 01 topic with the operator (or accept the proposed default above).
2. Run Lesson 01 through all 7 Gate Rule steps.
3. Update this file (Update Protocol below) and `docs/STATUS.md`.

---

## Update Protocol (Claude must execute after every completed lesson/milestone)

1. **Skills**: move completed-lesson topics from "Not Started" → "Partially Learned" →
   "Already Learned" as evidence accumulates (quiz passed + hands-on task done).
2. **Current Infrastructure / AWS State / Networking / Bash / Security / Docker
   Knowledge**: append a dated bullet summarizing what changed — using the redaction
   convention above for any infra/AWS facts.
3. **Completed Projects**: add the new lesson's artifact (link to
   `docs/learning/lessons/NN-<topic>/README.md`).
4. **Active Tasks / Blockers**: refresh.
5. **Interview Readiness / Portfolio Readiness**: update qualitatively (e.g. "can now
   explain X confidently"); on a milestone, link the new `PORTFOLIO.md`.
6. **Next Lesson / Recommended Next Actions**: set based on `PROJECT_MISSION.md`
   roadmap and what the operator found confusing in the Reflection step.
7. Run the standard "update docs" protocol (`docs/README.md`) for STATUS/CHANGELOG/TODO.
