# Lesson 14 — Pure Practical: GitHub Actions CI Basics

> **Companion to [`README.md`](./README.md).** Pure practice: 3 scenario tasks, guided → ticket-driven
> → on-call. Do them after the README.
>
> **Lab:** author workflows locally; test **offline** with [`act`](https://github.com/nektos/act) or by
> running the same commands the job runs — no need to push to run the drill. **Rules:** type it,
> diagnose before you fix, run ✅ **Verify** each task. No secrets committed.

Each task: **Scenario · Objective · Given/constraints · Hints · ✅ Verify · Pitfalls · 🎯 Stretch.**

---

## Task 1 — Guided: a CI pipeline that lints and tests the repo's scripts (fluency)

**Scenario.** `NAVI-141`. Every push should lint the Bash scripts (`shellcheck`) and syntax-check them
so broken scripts never merge.

**Objective.** A `.github/workflows/ci.yml` that runs `shellcheck` + `bash -n` on `scripts/`, verified
locally.

**Given / constraints.** Pin action versions (`actions/checkout@v4`, not `@main`). Job must fail on a
lint error.

**Hints.**
1. `on: [push, pull_request]`, one job, `runs-on: ubuntu-latest`.
2. Steps: checkout → install shellcheck → run it over `scripts/*.sh`.
3. Test locally: run the *exact* commands the job runs, or `act -j <job>` if installed.

✅ **Verify.**
```bash
# simulate the job's core step locally:
find scripts -name '*.sh' -exec bash -n {} \; && echo "SYNTAX ✅"
command -v shellcheck && shellcheck scripts/*.sh && echo "LINT ✅"
command -v act && act -n   # dry-run the workflow graph
```

**Pitfalls.**
- `@main`/`@master` action refs → non-reproducible, supply-chain risk. Pin a version/SHA.
- A step that fails but the job stays green (missing non-zero propagation).
- Assuming it works without running the steps locally first.

🎯 **Stretch.** Add a matrix (`bash` + `dash`) or cache to speed repeat runs.

---

## Task 2 — Ticket-driven: "the pipeline is red and blocking the PR" (diagnose → fix)

**Scenario.** `NAVI-142` (P2). *"CI fails on every PR, log is a wall of red, nobody can merge."* Read
the failure, find the real cause, fix it — **diagnose before editing the YAML randomly.**

**Objective.** Get the job green having identified whether it's a YAML syntax error, a missing
tool/step, a wrong path, or a genuine lint failure in the code.

**Given / constraints.** Recreate a broken workflow (bad indentation, missing `run:`, or a step that
references a nonexistent path). Fix the specific fault.

**Hints.**
1. YAML valid? `yamllint .github/workflows/ci.yml` or `python -c 'import yaml,sys;yaml.safe_load(open(sys.argv[1]))' ci.yml`.
2. Reproduce a step locally (copy its `run:` block into a shell). Real code failure vs pipeline failure?
3. `act` reproduces the run offline without pushing.

✅ **Verify.**
```bash
python3 -c 'import yaml;yaml.safe_load(open(".github/workflows/ci.yml"))' && echo "YAML VALID ✅"
# the step that was failing now passes locally:
bash -n scripts/*.sh && echo "STEP PASSES ✅"
```

**Pitfalls.**
- Tabs in YAML (must be spaces) → parse error that looks like a logic bug.
- "Fixing" red CI by deleting the failing step → you removed the safety net.
- Editing and pushing repeatedly to debug ("commit-driven debugging") instead of reproducing locally.

🎯 **Stretch.** Add `concurrency` to cancel superseded runs and stop wasting minutes on stale commits.

---

## Task 3 — On-call: a secret leaked / a workflow has too much privilege (synthesis)

**Scenario.** `NAVI-143` (P1, time-boxed). Review finds a workflow echoes a secret to logs and runs
with broad write permissions. Contain the exposure and harden the pipeline; document.

**Objective.** Remove the leak path, scope `permissions:` to least privilege, and confirm secrets are
masked — write an incident note (and note the secret must be rotated).

**Given / constraints.** Recreate a workflow with `permissions: write-all` and a step that prints a
`${{ secrets.X }}`. Never commit a real secret; rotation is the real remediation for any true leak.

**Hints.**
1. Set top-level `permissions: contents: read` (add only what specific jobs need).
2. Remove the `echo ${{ secrets.X }}`; GitHub masks known secrets, but printing derived values leaks them — never print secrets.
3. Pin third-party actions to a full commit SHA (supply-chain).

✅ **Verify.**
```bash
grep -q 'write-all' .github/workflows/*.yml && echo "STILL OVER-PRIVILEGED ❌" || echo "SCOPED ✅"
grep -rE 'echo .*secrets\.' .github/workflows/ && echo "SECRET PRINTED ❌" || echo "NO SECRET ECHO ✅"
test -f docs/learning/reports/NAVI-143-postmortem.md && echo "POSTMORTEM ✅"
```

**Deliverable.** `docs/learning/reports/NAVI-143-postmortem.md`: Impact · Detection · Root cause · Fix · Prevention (+ "rotate the secret").

**Pitfalls.**
- Assuming masking = safe; a transformed/base64'd secret bypasses masking.
- `write-all` "to make it work" — huge blast radius if the token leaks.
- Fixing the workflow but forgetting the leaked secret is already compromised → rotate it.

🎯 **Stretch.** Add a secret-scanning step (e.g. `gitleaks`) to the pipeline so future leaks fail CI.

---

## Done?
- [ ] All ✅ Verify pass · [ ] reproduced locally (not commit-debugging) · [ ] least-privilege perms · [ ] postmortem written.
- [ ] Actions pinned; no secret printed/committed. → [README Step 7](./README.md).
