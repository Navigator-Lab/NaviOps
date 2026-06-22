# GitHub Portfolio Strategy — NaviOpsNetwork

How this repo converts into **GitHub / LinkedIn / Resume / interview** evidence. The principle
(carried from NaviOps): **claim = committed evidence** — nothing goes on the resume that isn't
backed by a real artifact here.

## The repo as a portfolio piece

A hiring manager skimming this repo should, in 60 seconds, see:
1. **README** — Linux-first networking + NOC focus, 36-lesson curriculum, what it prepares for.
2. **ROADMAP** — a coherent, sequenced plan tied to real jobs.
3. **lessons/** — written lessons that are clearly *operational* (troubleshooting, NOC,
   incident response), not exam dumps.
4. **scripts/ + infra/ + docs/runbooks/** — real, runnable evidence.
5. **Commit history** — steady, self-paced, honest (matches the operator's stated dates).

## Artifact types (what each lesson contributes)

| Artifact | Where | Portfolio value |
|---|---|---|
| **Runbooks** | `docs/runbooks/` | shows you can document an incident end-to-end (symptom→RCA→fix→verify) — the #1 NOC skill |
| **Incident reports** | `docs/runbooks/` | proof of IR lifecycle; interview demo material |
| **Troubleshooting guides** | `troubleshooting-drills.md`, lesson §4 | shows structured, bottom-up method |
| **Architecture diagrams** | `docs/diagrams/` (ASCII + diagram-as-code) | network design literacy |
| **Monitoring dashboards** | `docs/dashboards/`, `infra/monitoring/` | observability skill, the NOC "read the dashboard" competency |
| **Bash scripts** | `scripts/` | automation skill (every script `shellcheck`-clean, with usage + error handling) |
| **Automation utilities** | `scripts/` | net_diag, dns_check, latency_monitor, port_scan_detect, snmp_poll, capture_triage |
| **Cheatsheets** | `docs/networking/` | quick-reference, also doubles as study material |

## Per-channel framing

### GitHub
- Pin: NaviOpsNetwork (this repo) + NaviOps (sibling).
- README badges/sections: curriculum table, "taught Linux-first", capstones.
- Each capstone (34/35/36) gets its own clearly-linked folder — these are the centerpieces.

### LinkedIn
- Headline keywords: NOC · Network Operations · Linux Networking · TCP/IP · Monitoring · Incident Response.
- Featured: link the repo + 1–2 capstone runbooks.
- Posts: "Built a DNS-outage NOC drill — here's the RCA" (per milestone) draws engagement and
  doubles as spaced repetition.

### Resume
- One project block: **NaviOpsNetwork — Linux-first Network Operations Lab (public, MIT)**.
- 3–4 bullets, tailored per wave (`JOB_MILESTONES.md` keyword blocks).
- Skills section mirrors the §2 command toolkit (only tools with committed evidence).

### Interviews
- Walk the architecture + the *why* (`docs/DECISIONS.md`).
- Demo a real scenario from `docs/runbooks/` (e.g. "VLAN misconfig — here's how I localized it").
- Use the alignment matrices to answer "have you covered X?" with "yes — Lesson NN, here's the artifact."

## Milestone deliverables (per `CLAUDE_TEACHING_RULES.md`)

At each milestone, produce `lessons/<milestone>/PORTFOLIO.md` with:
1. **Portfolio Summary** — what was built, the skills demonstrated.
2. **Resume Bullets** — 3–4, quantified where possible, keyword-tuned.
3. **Interview Talking Points** — the architecture story + 1 demo scenario + 1 "what I'd do
   differently" (shows reflection/seniority).

## Authenticity guardrails
- AI disclosure stays in the README (write-ups are AI-assisted; artifacts + quiz answers are
  the operator's).
- Redaction discipline (`LEARNING_STATE.md`) on every commit — a leaked real IP/capture is
  both a security issue and a credibility hit.
- Commit cadence reflects real pace — no bulk back-dated dumps.
