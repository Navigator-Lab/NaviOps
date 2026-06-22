# Documentation Playbook — NaviOpsEnterprise

The operating manual for documentation across the platform — the **force multiplier** that makes support
scale (Lesson 28). Pair with the [Help Desk](HELPDESK-PLAYBOOK.md) and [IT Support](IT-SUPPORT-PLAYBOOK.md)
playbooks, and the templates in `docs/templates/`.

## The prime directives
1. **Capture knowledge as you solve** (KCS) — not "later" (later never comes).
2. **Match the artifact to the audience** — runbook (tech), troubleshooting guide (tech), KB (end user).
3. **Write so the next person needs zero help from you** — that's the only real quality test.
4. **Own it and review it** — every artifact has an owner + a last-reviewed date, or it rots.
5. **A wrong/stale article is worse than none** — retire it.

## Artifact → audience → where it lives
| Artifact | Audience | Purpose | Folder |
|---|---|---|---|
| Runbook | technician | repeatable "when X, do Y" (ordered, verifiable, rollback) | `docs/runbooks/` |
| Troubleshooting guide | technician | the diagnostic spine (Symptoms→…→Post-incident docs) | `docs/troubleshooting/` |
| KB article | end user / T1 | plain-language self-service how-to (deflect tickets) | `docs/kb/` |
| Ticket note | next tech | the per-incident record (public/internal split) | `docs/tickets/` |
| Incident report / RCA | the org | what happened + prevent recurrence | template + capstones |

## The KCS loop (keep the KB alive)
```
   solve a ticket ─▶ CAPTURE/UPDATE a KB article ─▶ users SELF-SERVE (deflect) ─▶ fewer tickets
        ▲                                                                              │
        └───────────────── REVIEW (owner + cadence) ── RETIRE stale ◀── usage data ───┘
```

## The KB quality checklist (an article isn't "done" until all YES)
- [ ] Title is the **user's goal** ("How to connect to the VPN"), not a system name
- [ ] **Audience** stated (end user vs tech) → language matches
- [ ] **"Before you start"** lists prerequisites
- [ ] Steps are **numbered, exact**, and say what **success** looks like
- [ ] **"Still not working?"** → self-checks + how to contact the desk (what info to give)
- [ ] **Owner + last-reviewed** date present
- [ ] **No sensitive/internal data** in a user-facing article (data classification, L29)
- [ ] A **non-expert could follow it with zero help** ← the real test

## Lifecycle (owner + review + retire)
- Every artifact gets an **owner** and a **review cadence** (e.g. quarterly).
- On review: **keep / update / merge / retire**. Retire actively-wrong content immediately.
- Consolidate duplicates to a **single source of truth**.

## Metrics that prove it's working
Deflection rate · article usage · "did this help?" feedback · FCR uplift · reduced "tribal knowledge"
(bus-factor). Use them to **prune and promote** (Lesson 16 continual improvement).

## Public-repo discipline
All examples are sanitized placeholders (`corp.example`, RFC 1918, asset tags) — `navi.project.md` HR#1.
Keep secrets, internal IPs/architecture, and sensitive procedures out of user-facing articles.
