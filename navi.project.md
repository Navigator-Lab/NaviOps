# navi.project.md — NaviOps

> Navi loads this right after project detection as its **Project Law**. Navi's core
> (`.agent/`) stays project-agnostic; everything specific to *NaviOps* (the platform
> being built and the learning journey behind it) lives here.

## Identity
- **name**: NaviOps
- **one-liner**: AI-Assisted Infrastructure & Operations Platform, built in public on
  the Navi framework, while taking the operator from zero to Junior/Mid Linux SysAdmin.
- **stack**: Bash · Linux (systemd, journald, networking) · Docker/Compose · Terraform ·
  AWS (IAM, EC2, VPC, S3, CloudWatch). `.agent/` (Navi core, copied unmodified from
  `Navigator-Lab/Navi`).

## Commands
- **install**: _(none yet — added per lesson as tools are introduced)_
- **test**: _(none yet — add `scripts/` checks per lesson)_
- **run / dev**: open Claude Code here → `/navi <request>`
- **build**: _(n/a until first infra component)_
- **lint / typecheck**: _(none yet)_

## Layout
- **entrypoint**: `.agent/workflows/navi.md` (Navi v28 core, copied from `Navigator-Lab/Navi`)
- **pedagogy layer**: `docs/learning/` — `PROJECT_MISSION.md` (constitution),
  `CLAUDE_TEACHING_RULES.md` (the canonical 7-step Gate Rule — single source of truth),
  `LEARNING_STATE.md` (living progress tracker), `prompts/` (bootstrap prompt archive),
  `lessons/NN-topic/README.md` (one per completed lesson, Gate-Rule output)
- **memory + reports**: `docs/` (STATUS/CHANGELOG/TODO/DECISIONS/DEFERRED + `docs/reports/`)
- **platform code**: `infra/` (Terraform/Ansible/Docker Compose), `scripts/` (Bash automation)
- **config / env**: real secrets never committed — see Hard Rules below

## Hard Rules ("Schema Lock") — what Navi must never violate here
1. **Public-repo discipline (this repo ships to GitHub as a portfolio piece).** No real
   AWS account IDs, IPs, hostnames, ARNs, SSH keys, `.tfstate`, `.tfvars`, or `.env`
   values are ever committed. `LEARNING_STATE.md` and lesson write-ups use placeholders
   (`<ACCOUNT_ID>`, `10.0.x.x`, `<INSTANCE_ID>`) — see its header for the convention.
2. **Gate Rule is canonical in ONE file**: `docs/learning/CLAUDE_TEACHING_RULES.md`. Every
   lesson follows it (Concept → Real-World Use → Alternatives → Hands-On → Verification →
   Quiz → Reflection). Other docs (`PROJECT_MISSION.md`) link to it, never restate it.
3. **Every lesson improves the actual NaviOps platform** (`infra/`, `scripts/`) — no
   disconnected toy exercises (per `PROJECT_MISSION.md` Learning Philosophy).
4. **`docs/learning/LEARNING_STATE.md` is updated after every lesson/milestone** — a fresh
   session resumes teaching from it with zero re-explanation.
5. **No auto-spend / no auto-send** (P00, inherited): never run `terraform apply` against
   real AWS, push to GitHub, or incur cloud cost without the human explicitly approving
   that specific command.

## Danger Zones (confirm before touching)
- Anything that touches real AWS (creating resources, IAM changes, billing-affecting
  actions) — human-approved only, and must be redacted before any doc/screenshot is committed.
- `terraform apply` / `destroy` against real infra.
- Publishing: `git push`, creating the public GitHub repo — human-approved only.
- Editing `.agent/` (Navi core) — should stay in sync with upstream `Navigator-Lab/Navi`;
  project-specific content belongs in `docs/learning/` or this file, not `.agent/`.

## Notes
- **MENTOR (P11) teaching depth in NaviOps**: when MENTOR answers a command question, it composes
  this project's teaching schema as its §3/§8 depth — the **Gate Rule**
  (`docs/learning/CLAUDE_TEACHING_RULES.md`, Steps 1–3 / 5 / 6 / 8) + **Integration Lenses A–D**
  (Three-Level Depth, Double-Explanation, Bash automation, C/systems tie-in). So command mentoring
  matches the lesson pedagogy — and replaces reaching for an external AI chat to explain commands.
  The generic protocol stays in `.agent/`; this binding is the project-specific overlay (D1).
- A fresh session resumes from `docs/STATUS.md` (project/code state) **and**
  `docs/learning/LEARNING_STATE.md` (pedagogy/progress state) — read both first.
- Origin of this project: `docs/learning/prompts/00-bootstrap-role.md` (the original
  bootstrap prompt that defined the Gate Rule and roadmap).
