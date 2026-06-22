---
description: The Karpathy lens — minimum, well-reasoned code; state assumptions; understanding over output. Project-agnostic quality gate used by REVIEW (P04+P07) and referenced by P00 Axioms 6–7.
---

# The Karpathy Lens

A short, project-agnostic discipline for agentic engineering. Run it before finishing any BUILD/REVIEW.
Grounded in Andrej Karpathy's public guidance (Software 3.0 / Agentic Engineering, Sequoia AI Ascent 2026):
*agents execute, the human validates; you can outsource your thinking, but not your understanding.*

## The 7 checks

1. **State assumptions first.** Write them down before code. If an assumption is load-bearing and unverified, verify it or flag it — don't bury it.
2. **Simplest thing that works.** The best solution is the smallest one that fully solves the stated problem. No speculative abstraction for a future that may not come.
3. **Delete > add.** Removing code/branches/flags is usually higher-value than adding. Ask "what can go?" before "what can I add?".
4. **Surgical edits.** Touch only what the task needs. A 3-line fix should not become a 300-line refactor unless the refactor *is* the task.
5. **Name the trade-off.** When two routes are plausible, present both with their costs and let the human choose (P00 Axiom 6). Never silently pick and hide it.
6. **Understanding over output.** Don't ship code you can't explain. If you can't say *why* it works and *when* it breaks, you're not done.
7. **Validate, don't rubber-stamp.** Run the real check (build/test/observe), not a plausible-looking summary. Cite the evidence.

## How to apply
- **REVIEW intent** loads this with P04 + P07: score the diff against the 7 checks; flag speculative complexity and unexplained code.
- **BUILD intent** ends with a one-line self-check against checks 2–7 before declaring done.
- **PLAN intent**: each step should pass check 4 (atomic/surgical) and check 5 (rollback named).

## Anti-patterns this catches
Over-engineering · premature abstraction · big-bang rewrites of working code · confident edits with hidden assumptions · "looks done" without running it · adding a flag instead of deleting a branch.

> Dynamic to any project: no stack, framework, or file path is hardcoded here — it's a thinking discipline, not a checklist of commands.
