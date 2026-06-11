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
**Day 1 — Lesson 01 complete.** Repo scaffolded (`.agent/`, `docs/`, pedagogy stack,
gitignore, Gitleaks). Lesson 01 (Linux filesystems & permissions) done end-to-end
(Gate Rule Steps 1-8). Roadmap expanded with Git/GitHub + adjacent DevOps skill areas
(D5) — Lesson 02 is Git & GitHub Fundamentals.

## Skills Already Learned
- Linux filesystems & permissions: rwx/octal notation, owner/group/other, `chmod`/
  `chown`/`chgrp`, setuid (`passwd` example), SSH key permission requirements (`600`),
  ACLs as the alternative for non-owner fine-grained access. (Lesson 01,
  `docs/learning/lessons/01-linux-filesystems-permissions/README.md`)

## Skills Partially Learned
- Directory `r` vs `x` distinction (listing vs traversal/access) — answer in Lesson 01
  quiz Q7 was directionally right but missed the precise split; flagged for spaced
  review.
- Recursive permission fixes (`chown -R`/`chmod -R` pitfalls, setgid for shared dirs,
  when ACLs beat blanket `775`) — Lesson 01 quiz Q4 needs reinforcement.
- `chown` vs `chgrp` root requirements — Q5 needs reinforcement (chgrp doesn't always
  need root; chown does).

## Skills Not Started
- Linux: users/groups, processes, systemd, journald, cron, SSH, package management, storage, backups
- Git & GitHub: core git, branching/merging/rebasing, remote workflows, PR/code review, branch protection, GitHub Actions/CI basics, GitOps fundamentals
- Bash: variables, functions, loops, conditions, logging, error handling, automation
- Networking: OSI/TCP-IP, subnetting, DNS, DHCP, NAT, routing, switching, VLANs, VPNs, firewalls, load balancing
- Security: hardening, SSH security, user auditing, log analysis, threat detection, secrets management, incident response
- Docker: containers, images, networks, volumes, Compose, production deployment, basic orchestration
- Configuration Management: Ansible (inventories, playbooks, roles)
- CI/CD & IaC: GitHub Actions pipelines, Terraform fundamentals
- AWS: IAM, EC2, VPC, security groups, EBS, S3, CloudWatch, backups, monitoring
- Observability: logs, metrics, monitoring, alerting, RCA
- C / Linux Internals (Lens D, woven into Linux/networking/security lessons):
  processes, memory, file descriptors, signals, sockets, threads, syscalls, daemons

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

## Current C / Linux Internals Knowledge
_(not started — Lens D introduced 2026-06-11 (D10); first concrete tie-in was Lesson
01's `stat()`/`chmod()`/`open()` syscalls and `struct stat st_mode`)_

## Completed Projects
- **Lesson 01 — Linux Filesystems & Permissions**
  (`docs/learning/lessons/01-linux-filesystems-permissions/README.md`) — full Gate Rule
  (Steps 1-8), graded quiz with professional-answer comparisons, search keywords.

## Active Tasks
- Start Lesson 02 (Git & GitHub Fundamentals — see Next Lesson below).
- Spaced-review the 3 partially-learned items from Lesson 01 (directory r/x split,
  recursive chmod/setgid/ACL fix, chown/chgrp root requirements) during Lesson 02's
  reflection.

## Blockers
_(none)_

## Interview Readiness
Baseline set after Lesson 01: can explain rwx/octal, ownership commands, setuid, ACLs
at an interview standard for 5/8 areas; 3/8 need another pass (see Skills Partially
Learned).

## Portfolio Readiness
First artifact complete: Lesson 01 README is portfolio-worthy (Concept → Hands-On →
Verification → Graded Quiz → Reflection → Search Keywords).

## Next Lesson
**Lesson 02 — Git & GitHub Fundamentals.** Added 2026-06-10 (D5) after WebSearch
research showed Git/GitHub is a baseline junior SysAdmin/DevOps expectation, and the
operator is already using git for this repo. Cover: core git commands (init/clone/
add/commit/branch/log/diff), branching & merging, remote workflows (push/pull/fetch),
and GitHub collaboration (PRs, code review, issues, branch protection). Run through
the full 8-step Gate Rule; output to
`docs/learning/lessons/02-git-github-fundamentals/README.md`. The hands-on task should
use this NaviOps repo itself (e.g. create a branch, make a small doc change, open a PR)
— first real "build NaviOps via Git" rep.

## Recommended Next Actions
1. Start Lesson 02 (Git & GitHub Fundamentals) per the above.
2. During Lesson 02's reflection, spot-check the 3 partially-learned Lesson 01 items.
3. Update this file (Update Protocol below) and `docs/STATUS.md` after Lesson 02.

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
