# Lesson 02 — Pure Practical: Git & GitHub Fundamentals

> **Companion to [`README.md`](./README.md).** Pure practice: 3 scenario tasks, guided → ticket-driven
> → on-call. Do them after the README.
>
> **Lab:** local repo — work in a throwaway clone under `/tmp` so you can't hurt real history:
> `git clone <this-repo> /tmp/git-drill && cd /tmp/git-drill`. **Rules:** type it, diagnose before you
> fix, run ✅ **Verify** after each task.

Each task: **Scenario · Objective · Given/constraints · Hints · ✅ Verify · Pitfalls · 🎯 Stretch.**

---

## Task 1 — Guided: feature-branch workflow, clean history (fluency)

**Scenario.** `NAVI-021`. You're adding `scripts/hello_ops.sh` on a feature branch and opening it for
review the way a team expects — no commits straight to `main`.

**Objective.** Create a branch, make 2 small commits with good messages, and produce a clean
`git log --oneline` that reviewers can read.

**Given / constraints.** Never commit on `main`. Conventional-style messages (`feat:`, `fix:`).

**Hints.**
1. `git switch -c lesson/02-drill`.
2. Two commits: add the file, then make it executable — separate logical changes.
3. `git log --oneline -5` should read as a story.

✅ **Verify.**
```bash
git branch --show-current          # lesson/02-drill   (NOT main)
git log --oneline main..HEAD       # exactly your commits, readable messages
```

**Pitfalls.**
- One giant commit mixing unrelated changes — un-reviewable.
- Vague messages ("update", "fix stuff").
- Committing on `main` then trying to move it after.

🎯 **Stretch.** Squash the two into one with `git rebase -i main`, keep the best message, confirm history.

---

## Task 2 — Ticket-driven: "I committed a secret / to the wrong branch" (diagnose → fix)

**Scenario.** `NAVI-022` (P2). *"I accidentally committed `secrets.env` (and it's the wrong branch
too). Not pushed yet. Undo it without losing my other work."*

**Objective.** Remove the file from the commit + history-so-far, keep the real changes, and move them
to a proper branch — **before** any push. Diagnose what's staged/committed first.

**Given / constraints.** Recreate: commit a fake `secrets.env` plus a legit change on `main`. Do **not**
`push`. Fix locally.

**Hints.**
1. `git log --stat -1` and `git status` — see exactly what landed.
2. Move work off main: `git switch -c lesson/02-fix` (commits come with the branch pointer).
3. Un-commit the secret: `git rm --cached secrets.env`, add to `.gitignore`, `git commit --amend` (still unpushed → safe).

✅ **Verify.**
```bash
git ls-files | grep -q secrets.env && echo "STILL TRACKED ❌" || echo "SECRET REMOVED ✅"
grep -q secrets.env .gitignore && echo "IGNORED ✅"
git branch --show-current          # the fix branch, not main
```

**Pitfalls.**
- Assuming `rm secrets.env` untracks it — it doesn't; you need `git rm --cached`.
- Force-pushing a rewritten shared branch (here it's unpushed, so amend is fine — know the difference).
- If it *had* been pushed: the secret is compromised — rotate it, don't just rewrite history.

🎯 **Stretch.** Add a `.git/hooks/pre-commit` (or the repo's) that blocks committing any `*.env`/`*.pem`.
Prove it rejects a staged secret.

---

## Task 3 — On-call: a bad commit is on main, prod is broken (synthesis)

**Scenario.** `NAVI-023` (P1, time-boxed). A merged commit broke the deploy. You must identify the
culprit and safely reverse it on a shared branch without rewriting public history.

**Objective.** Find the offending commit, `revert` it (not reset), and document why.

**Given / constraints.** Simulate several commits where one introduces a syntax error in a script.
History is "shared" → **no `reset --hard`/force-push**; use `revert`.

**Hints.**
1. `git log --oneline` to see candidates; `git bisect` if you have a test to run (`git bisect start / bad / good`).
2. `git revert <sha>` creates a new commit undoing it — safe on shared branches.
3. Confirm the tree is healthy again (script parses / test passes).

✅ **Verify.**
```bash
bash -n scripts/<the-broken-script>.sh && echo "SYNTAX OK ✅"
git log --oneline -1 | grep -qi revert && echo "REVERTED (not reset) ✅"
test -f docs/learning/reports/NAVI-023-postmortem.md && echo "POSTMORTEM ✅"
```

**Deliverable.** `docs/learning/reports/NAVI-023-postmortem.md`: Impact · Detection · Root cause · Fix · Prevention.

**Pitfalls.**
- `reset --hard` on a pushed branch → rewrites shared history, breaks everyone's clone.
- Reverting the merge commit vs the file commit — know which you have (`revert -m 1` for merges).
- Fixing forward with a new edit but never recording *why* it broke.

🎯 **Stretch.** Use `git bisect run bash -c 'bash -n scripts/x.sh'` to auto-find the first bad commit.

---

## Done?
- [ ] All ✅ Verify pass · [ ] no force-push on shared history · [ ] postmortem written.
- [ ] No secret ever pushed. **Redaction:** fake secrets only. → [README Step 7](./README.md).
