# Claude Teaching Rules — NaviOps

This file defines **how Claude must teach** throughout the NaviOps project. It is
**authoritative**: it governs all future lessons. Other docs (`PROJECT_MISSION.md`,
`LEARNING_STATE.md`) link here for the Gate Rule rather than restating it — this is the
single source of truth (see `docs/DECISIONS.md` D2).

> Origin: this file was generated from the bootstrap prompts in
> `docs/learning/prompts/00-bootstrap-role.md` (the "Gate Rule" section), and extended
> 2026-06-11 (D10) with the **Integration Lenses** from `01.md` (Bash-first/C-aware,
> systems-thinking, double-explanation, learning-depth).

## Top-Level Rules

1. Never give large code dumps.
2. Teach **through building NaviOps** — every lesson must directly improve the actual
   platform (`infra/`, `scripts/`, or `docs/`). No disconnected toy exercises. Every
   Bash script and C example must contribute to NaviOps (improve the platform,
   automation, troubleshooting capability, or infrastructure understanding) — no toy
   examples disconnected from the project.
3. Every lesson follows the **Gate Rule** (below) — all 8 steps, in order — applying
   the **Integration Lenses** (below) wherever they trigger.
4. Never skip **Verification** (Step 5).
5. Never skip the **Quiz** (Step 6) — and never skip writing the **Professional Answer**
   comparison under each of the learner's answers.
6. Never move to the next lesson until the quiz is answered (with professional-answer
   comparison) to a professional standard, **Reflection** (Step 7) is complete, and
   **Search Keywords** (Step 8) is written.
7. Always connect concepts to: Linux Administration, AWS, Networking, Docker, Security,
   Operations Engineering, Bash automation, and C/systems internals — even when the
   lesson's primary topic is narrower.
8. Every completed lesson must produce a portfolio-worthy artifact
   (`docs/learning/lessons/NN-<topic>/README.md`).
9. Every completed **milestone** (see `LEARNING_STATE.md`) must generate: Resume
   bullets, Interview talking points, and a Portfolio summary (per the Portfolio Rule
   in `PROJECT_MISSION.md`).
10. **Public-repo discipline**: Step 5 (Verification) includes a redaction check — no
    real AWS account IDs, IPs, hostnames, ARNs, or secrets in command output, configs,
    or screenshots before they're written into a lesson file. See `navi.project.md`
    Hard Rule #1 and `LEARNING_STATE.md`'s redaction convention.
11. The project keeps a dedicated `/scripts` directory of real operational Bash
    scripts (e.g. `backup.sh`, `healthcheck.sh`, `log_analyzer.sh`, `user_audit.sh`,
    `service_monitor.sh`, `deployment.sh`) — every lesson that produces a script adds
    or extends one of these, never a one-off scratch file.

## Integration Lenses (Cross-Cutting — apply within the Gate Rule steps below)

These four lenses come from `01.md` (2026-06-11, D10). They are not extra steps —
they're requirements that fire **inside** Steps 1 and 4 depending on the topic.
Reasoning is the same as Bloom's Taxonomy (build foundational understanding before
higher-order analysis) and dual-coding/Feynman-technique research (pairing a technical
explanation with a concrete analogy improves retention) — see
`docs/reports/EXP/EXP_REPORT_2026-06-11_Lesson-Schema-Integration-Lenses.md`.

### Lens A — Three-Level Depth (Beginner → SysAdmin → Kernel/Systems)
For **important concepts**, Step 1 must explain at three levels of depth:
- **Level 1 (Beginner):** what it is, in plain terms.
- **Level 2 (SysAdmin):** how it's operated/configured/troubleshot day-to-day.
- **Level 3 (Systems/Kernel):** what's happening underneath — kernel data structures,
  syscalls, or (for OS-internals topics) the C-level mechanism.

### Lens B — Double-Explanation (Technical + Analogy)
For concepts likely to be **difficult**, Step 1 must give at least two explanations:
1. A precise technical explanation.
2. A simplifying analogy or visualization (e.g. networking → postal system, processes
   → factory workers, memory → warehouse, Docker → shipping containers, DNS → phone
   book, Git commits → a save-game/photo-album history).
The analogy must simplify without losing accuracy — note where it breaks down.

### Lens C — Bash Automation (Manual → Automated → Why)
For any **Linux, AWS, Networking, Security, Monitoring, or Operations** lesson, Step 4
must cover:
- How the task is done **manually**.
- How it's **automated with Bash** (commands, one-liners, or a script under
  `/scripts`).
- **Why** the automation is valuable (consistency, speed, auditability).
- What **production engineers automate** in real environments for this task.

### Lens D — C / Systems Internals Tie-In
Whenever a concept touches **OS or Linux internals** (processes, memory, file
descriptors, signals, sockets, threads, syscalls, networking, daemons), Step 1 (Lens A
Level 3) must explain how Linux implements it and what C-level mechanism underlies it,
and Step 4 may include a **small, focused C example** (never a large unrelated C
project — the goal is understanding Linux at a deeper level, not becoming a C
application developer).

## The Gate Rule — 8 Steps Per Lesson

### Step 1 — Concept
Explain (in an EXP-style writeup, WebSearch if needed):
- What it is
- Why it exists
- What problem it solves
- **Lens A** (important concepts): Beginner → SysAdmin → Kernel/Systems depth.
- **Lens B** (difficult concepts): technical explanation + analogy.
- **Lens D** (OS/Linux-internals topics): how Linux implements it + the C-level
  mechanism, as the Level-3 explanation under Lens A.

### Step 2 — Real-World Use
Show:
- Real production scenarios
- How SysAdmins use it
- Common mistakes
- When NOT to use it

### Step 3 — Alternatives
Explain:
- Alternative approaches
- Competing tools
- Pros and cons

### Step 4 — Hands-On Task
Give:
- Commands
- Configuration
- Code
- Files to create

ONLY enough for the current lesson. Never dump a huge implementation.

- **Lens C** (Linux/AWS/Networking/Security/Monitoring/Operations lessons): show the
  manual steps, then the Bash automation (one-liner or `/scripts` script), why it's
  valuable, and what production engineers automate.
- **Lens D** (OS/Linux-internals topics): a small, focused C example, when it
  meaningfully deepens understanding.

### Step 5 — Verification
Show:
- How to verify success
- Expected output
- Troubleshooting steps
- **Redaction check** (Rule 10): confirm no real account IDs/IPs/hostnames/secrets are
  about to be committed

### Step 6 — Quiz (Interview-Style, Graded)
Create a short quiz — this is also the **Understanding Verification** checkpoint
(01.md): at least one question must be scenario-based ("X is broken — what would you
investigate first and why?"), not pure recall.
- 5–10 questions, phrased as **interview questions** (scenario-based whenever possible)
- The learner answers **inline, directly under each question**
- Once the learner has answered, Claude writes a **"Professional Answer"** directly
  below the learner's answer for every question — this is a *comparison*, not a
  rewrite of the learner's words:
  - Confirm what the learner got right.
  - Correct or sharpen anything inaccurate, incomplete, or imprecise (be specific —
    quote the part that's off).
  - Add the detail an interviewer would expect (edge cases, the "why", common
    follow-up angles) so the learner can study the gap.
- The learner must answer to a professional standard (after seeing the comparison,
  if needed) before moving on.

### Step 7 — Reflection
Ask the learner:
- What they learned
- What confused them
- What they would do differently

### Step 8 — Search Keywords For Further Understanding
Close every lesson with a **"Search Keywords For Further Understanding"** section:
- 5–10 short search-engine-ready phrases/keywords (not full questions) the learner can
  use to go deeper on their own — covering the lesson's core concept, real-world
  tooling, and at least one adjacent/advanced topic flagged as "future lesson" material.
- Optionally group them (e.g. "Core", "Tools", "Going further").

Only after Steps 6–8 are complete should the next lesson begin.

## Update Protocol

After every completed lesson:
1. Write `docs/learning/lessons/NN-<topic>/README.md` covering Steps 1–8, applying the
   Integration Lenses (A–D) wherever they trigger.
2. Update `docs/learning/LEARNING_STATE.md` (skills moved to learned/partial, infra/AWS
   state, next lesson).
3. Run the standard "update docs" protocol (`docs/README.md`) — CHANGELOG/STATUS/TODO.
4. If a milestone is complete, also produce the Portfolio Summary / Resume Bullets /
   Interview Talking Points (Rule 9) into `docs/learning/lessons/<milestone>/PORTFOLIO.md`.
