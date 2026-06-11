# NaviOps — Project Mission

This is the **constitution** for NaviOps. A future Claude session that reads ONLY this
file should understand the entire mission. For the lesson mechanics (the "Gate Rule"),
see `docs/learning/CLAUDE_TEACHING_RULES.md` — it is the single source of truth and is
not restated here.

> Origin: generated from the bootstrap prompts in `docs/learning/prompts/00-bootstrap-role.md`.

## Mission

Build **NaviOps** — an AI-Assisted Infrastructure & Operations Platform — in public, on
top of the [Navi](https://github.com/Navigator-Lab/Navi) framework, while the operator
(the human in this project) learns Linux/DevOps/Cloud/Networking/Security by *building
it*, not by taking courses.

## End Goal

A portfolio-quality, public, MIT-licensed repo that demonstrates:
- Linux Administration · Bash Scripting · Networking (CCNA-level) · Docker · AWS ·
  Monitoring · Logging · Security Analysis · Incident Response · Documentation ·
  Infrastructure Automation · Operations Engineering
- A working platform capable of: monitoring Linux servers, performing health checks,
  managing backups, auditing users, analyzing logs, generating operational reports,
  running infrastructure checks, documenting operational decisions, and acting as an
  operations assistant for infrastructure teams.

## Career Goal

- **Phase 1 (≈30 days):** Junior Linux SysAdmin — confident with Linux fundamentals,
  Bash automation, basic networking, and able to discuss/troubleshoot at an interview
  standard.
- **Phase 2 (ongoing):** Strong Junior / Early Mid-Level Infrastructure Engineer —
  Docker in production, AWS operations, observability, incident response.

## Why NaviOps Exists

Two goals reinforce each other:
1. **Learning** — the fastest way to learn infrastructure operations is to operate real
   infrastructure, with a mentor that gates progression on demonstrated understanding.
2. **Evolving Navi** — Navi started as a software-engineering intent router. NaviOps is
   the proving ground for extending the same router/protocol approach to **systems and
   operations** work (monitoring, audits, runbooks, incident response).

## Relationship Between Navi And NaviOps

- **Navi** (`Navigator-Lab/Navi`) is the project-agnostic **framework**: the `.agent/`
  router, protocols (P00–P14), and the `docs/` memory system. It stays generic — no
  AWS/CCNA/personal content lives there (Navi's own Hard Rule #1).
- **NaviOps** (this repo) is a **project built using Navi**: it copies Navi's `.agent/`
  core unmodified, adds a NaviOps-specific `navi.project.md`, and adds the
  `docs/learning/` pedagogy layer on top. See `docs/DECISIONS.md` D1.
- Improvements to the *router/protocols* discovered while building NaviOps should be
  upstreamed to `Navigator-Lab/Navi` as generic changes — not hardcoded here.

## Learning Philosophy

- No courses, no theory-first learning.
- Learn by building — every lesson must directly improve NaviOps (`infra/`, `scripts/`,
  or its docs). No disconnected toy exercises.
- Production-oriented: real commands, real configs, real (eventually AWS) infrastructure
  — always behind the public-repo redaction discipline (`navi.project.md` Hard Rule #1).
- Progression is **gated**: see `CLAUDE_TEACHING_RULES.md`. The learner must demonstrate
  understanding (quiz + reflection) before the next lesson begins.

## Gate Rule

See `docs/learning/CLAUDE_TEACHING_RULES.md` — every lesson, command, script, or
technology follows its 8 steps (Concept → Real-World Use → Alternatives → Hands-On Task
→ Verification → Quiz [graded with professional-answer comparisons] → Reflection →
Search Keywords For Further Understanding).

## Technical Skills To Master

| Area | Topics |
|---|---|
| Linux Administration | Filesystems, permissions, users/groups, processes, services, systemd, journald, cron, SSH, package management, storage, backups |
| Git & GitHub | Core git (init/clone/add/commit/branch/merge/rebase/log/diff), remote workflows (push/pull/fetch/upstream/forks), GitHub collaboration (PRs, code review, issues, branch protection, commit conventions, tags/releases), GitHub Actions/CI basics, version-controlling scripts/configs/IaC as the audit trail (GitOps fundamentals) |
| Bash | Variables, functions, loops, conditions, logging, error handling, automation, CLI tools |
| Networking (CCNA-level) | OSI model, TCP/IP, subnetting, DNS, DHCP, NAT, routing, switching, VLANs, VPNs, firewalls, load balancing — always tied back to Linux administration |
| Security | Linux hardening, SSH security, user auditing, log analysis, threat detection, security monitoring, least privilege, secrets management, incident response |
| Docker | Containers, images, networks, volumes, Compose, production deployment, basic orchestration concepts |
| Configuration Management | Ansible basics (inventories, playbooks, roles) for repeatable Linux config — pairs with Git for GitOps-style change review |
| CI/CD & IaC | GitHub Actions pipelines (lint/test/deploy), Terraform fundamentals (plan/apply, state) — introduced once Git/Docker/AWS basics are in place |
| AWS | IAM, EC2, VPC, security groups, EBS, S3, CloudWatch, backups, monitoring — only what NaviOps needs |
| Observability | Logs, metrics, monitoring, alerting, root cause analysis |
| Documentation | Architecture notes, runbooks, operational docs, incident docs — using Navi's `docs/` standards |
| Systems Programming (C) & Linux Internals | Not a standalone track — woven into Linux/networking/security lessons whenever the topic touches OS internals (processes, memory, file descriptors, signals, sockets, threads, syscalls, daemons). Small, focused C examples illustrate the kernel-level mechanism behind the sysadmin command (Lens D, `CLAUDE_TEACHING_RULES.md`) |

> **2026-06-11 update (D10):** `01.md`'s Bash-first/C-aware, systems-thinking,
> double-explanation, and learning-depth rules were merged into
> `CLAUDE_TEACHING_RULES.md` as four **Integration Lenses** (A–D) applied within the
> existing 8-step Gate Rule. C programming is taught *through* Linux internals (Lens
> D), never as an isolated track — confirmed via WebSearch against established
> systems-programming curricula (Harvard DCE, CU Boulder, man7.org/Kerrisk).

> **2026-06-10 update (D5):** Git/GitHub, Ansible, GitHub Actions/CI, and Terraform/IaC
> were added after WebSearch research confirmed these are baseline 2025-2026 junior
> SysAdmin/DevOps expectations, not "advanced" extras. Git/GitHub is sequenced as
> Lesson 02 — every lesson from here on should also produce a real commit to this repo,
> turning version control into a running habit rather than a one-off topic.

If a missing but important skill is identified mid-project, it gets added to this table
and the roadmap (`LEARNING_STATE.md`) without waiting for permission — and the rationale
is logged in `docs/DECISIONS.md`.

## Portfolio Objectives

Every completed milestone produces (per `CLAUDE_TEACHING_RULES.md` Rule 9):
1. A **Portfolio Summary** (`docs/learning/lessons/<milestone>/PORTFOLIO.md`)
2. **Resume Bullet Points**
3. **Interview Talking Points**

— each framed for Linux SysAdmin, Cloud Support, DevOps, and Infrastructure roles.

## Interview Objectives

By the end of Phase 1, the operator should be able to:
- Explain and troubleshoot Linux fundamentals confidently from memory (no notes).
- Walk an interviewer through NaviOps' architecture and the *why* behind each decision
  (`docs/DECISIONS.md`).
- Demonstrate at least one real incident-response or troubleshooting scenario from the
  lesson log (`docs/learning/lessons/`).

## Rules For Future Claude Sessions

1. Read `docs/STATUS.md` AND `docs/learning/LEARNING_STATE.md` first — resume with zero
   re-explanation.
2. Follow `CLAUDE_TEACHING_RULES.md` for every lesson — no exceptions, no skipped steps.
3. Honor `navi.project.md` Hard Rules, especially public-repo redaction discipline.
4. Use Navi's `/navi` router and the standard `docs/` memory protocol
   (`docs/README.md`) for anything that isn't a lesson (e.g. "fix this script",
   "review this Terraform file") — those are normal EXP/PLAN/REVIEW/DEBUG requests.
5. After every lesson/milestone, run the `CLAUDE_TEACHING_RULES.md` Update Protocol.

## Definition Of Done — Junior Linux SysAdmin

- [ ] Can administer users/groups/permissions, manage services with systemd, and read
      logs via journald without assistance.
- [ ] Can use Git confidently (branch, commit, merge/rebase, resolve conflicts) and
      run a GitHub PR-based workflow (open PR, review, merge, branch protection).
- [ ] Can write a Bash script with argument handling, error handling, and logging.
- [ ] Can explain OSI/TCP-IP basics, subnetting, and configure a basic firewall (e.g.
      `ufw`/`iptables`/security groups).
- [ ] Can run a containerized service with Docker Compose and troubleshoot it.
- [ ] Has completed ≥1 incident-response style exercise with a written runbook.
- [ ] NaviOps repo has ≥1 working "platform" component (e.g. a health-check script that
      produces a real report) plus its lesson write-up.

## Definition Of Done — Mid-Level Linux SysAdmin

- [ ] Operates a small multi-service Docker Compose stack with monitoring/alerting.
- [ ] Has provisioned and torn down real AWS infrastructure via Terraform (with state
      and secrets handled per the public-repo redaction rules).
- [ ] Can perform log analysis across multiple services to root-cause an incident and
      document it.
- [ ] NaviOps can run automated health checks, produce operational reports, and
      document at least one real incident end-to-end.
- [ ] Portfolio includes ≥3 milestone write-ups with resume bullets + interview talking
      points.

## Monthly Milestones

- **Month 1 (Days 1–30):** Linux fundamentals + Git/GitHub fundamentals + Bash
  automation + basic networking + Docker basics → Junior Linux SysAdmin DoD. NaviOps
  gains: health-check scripts, log analysis tooling, first runbooks — all version
  controlled with proper branch/PR hygiene from Lesson 02 onward.
- **Month 2+:** Ansible + GitHub Actions CI basics + AWS (IAM/EC2/VPC/S3/CloudWatch) +
  Terraform + multi-service Docker Compose + observability/alerting → progress toward
  Mid-Level DoD. NaviOps gains: `infra/` (Ansible + Terraform), CI pipelines, monitoring
  stack, incident-response runbooks.

(Milestones are refined in `docs/learning/LEARNING_STATE.md` as the project progresses —
this section states the *shape*, not a fixed locked schedule.)

## Success Criteria

By the end of this journey, the operator should be able to:
- Pass Junior Linux SysAdmin interviews.
- Discuss Linux confidently and troubleshoot servers independently.
- Write Bash automation scripts.
- Deploy Dockerized services.
- Operate AWS infrastructure.
- Analyze logs and incidents.
- Understand CCNA-level networking concepts.
- Point to NaviOps — a real, public, MIT-licensed open-source project — as proof of
  practical experience.
