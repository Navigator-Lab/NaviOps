# NaviOps

**An AI-Assisted Infrastructure & Operations Platform — built in public, lesson by
lesson, on top of [Navi](https://github.com/Navigator-Lab/Navi).**

NaviOps is two things at once:
1. A real (small but growing) ops platform: health checks, log analysis, monitoring,
   runbooks, and eventually AWS infrastructure-as-code.
2. The build log of someone going from "comfortable in a terminal" to **Junior Linux
   SysAdmin** (and beyond) — entirely through building #1.

Every change in this repo is the output of an AI-tutored lesson, gated by quizzes and
reflection. Nothing here is a toy exercise disconnected from the platform.

## Start here

- **[docs/learning/PROJECT_MISSION.md](docs/learning/PROJECT_MISSION.md)** — the
  project's "constitution": mission, learning philosophy, skills roadmap, definitions
  of done.
- **[docs/learning/CLAUDE_TEACHING_RULES.md](docs/learning/CLAUDE_TEACHING_RULES.md)** —
  the "Gate Rule" every lesson follows (Concept → Real-World Use → Alternatives →
  Hands-On → Verification → Quiz → Reflection).
- **[docs/learning/LEARNING_STATE.md](docs/learning/LEARNING_STATE.md)** — live
  progress tracker (skills, infra state, next lesson).
- **[docs/learning/lessons/](docs/learning/lessons/)** — one folder per completed
  lesson, each a self-contained write-up.
- **[docs/STATUS.md](docs/STATUS.md)** — current project/code state.

## How this repo is organized

```
NaviOps/
├── .agent/              # Navi v28 framework core (router + protocols), unmodified
├── docs/
│   ├── STATUS.md / TODO.md / CHANGELOG.md / DECISIONS.md / DEFERRED.md
│   ├── learning/         # the pedagogy layer (mission, rules, progress, lessons)
│   └── reports/          # EXP/PLAN/etc. reports
├── infra/                # Terraform / Docker Compose / Ansible (grows over time)
└── scripts/              # Bash automation (grows over time)
```

## Running this with Claude Code

Open this folder in Claude Code and run:
```
/navi <plain-language request>
```
`/navi` reads `navi.project.md` (this project's rules) and `docs/learning/` (the
pedagogy layer) and routes the request accordingly — e.g. "next lesson", "review this
script", "explain how systemd works".

## A note on what's NOT in this repo

This is a **public learning repo**. Real AWS account IDs, IPs, hostnames, credentials,
`.tfstate`, and `.tfvars` are never committed — see `.gitignore` and `.gitleaks.toml`.
`docs/learning/LEARNING_STATE.md` documents the redaction convention used throughout.

## License

MIT — see [LICENSE](LICENSE).
