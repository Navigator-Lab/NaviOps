# Deferred

Postponed items — with *why* + *when to revisit*. Not forgotten, just not now.

## Public GitHub repo creation
- **What:** Create `Navigator-Lab/NaviOps` on GitHub and push.
- **Why deferred:** No-auto-send (P00) — repo creation/push is human-approved. Also want
  at least Lesson 01 done so the first push isn't an empty scaffold.
- **Revisit:** After Lesson 01 (Gate Rule end-to-end) is complete and verified clean
  by the Gitleaks pre-commit hook.

## TruffleHog full-history scans
- **What:** Periodic `trufflehog` scan of full git history (deeper than Gitleaks pre-commit).
- **Why deferred:** No history to scan yet (1 commit, no infra/AWS content).
- **Revisit:** Before the first push to GitHub, and periodically thereafter.
