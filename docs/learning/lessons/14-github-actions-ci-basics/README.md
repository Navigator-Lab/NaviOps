# Lesson 14 — GitHub Actions CI Basics

**Status:** ready for self-study · **Date written:** 2026-06-11
**Gate Rule:** Concept → Real-World Use → Alternatives → Hands-On → Verification → Quiz → Reflection → Search Keywords

> **How to use this lesson:** same as Lessons 03–13. This lesson connects
> directly to Lesson 02's Git/GitHub fundamentals — CI runs on every push/PR.

---

## Step 1 — Concept

### What it is

**GitHub Actions** is GitHub's built-in CI/CD (Continuous Integration /
Continuous Deployment) platform. You define **workflows** as YAML files in
`.github/workflows/` that automatically run on events (push, pull request,
schedule) — e.g., "every time someone opens a PR, run the linter and tests."

### Why it exists

Without CI, "did my change break anything?" is answered by a human manually
running tests/lints **if they remember to**. CI runs automatically, on every
change, the same way every time — catching mistakes before they merge. This is
the automated counterpart to everything you've manually verified in Lessons
03-13 (`bash -n`, `ansible-lint`, `docker build`, etc.) — CI runs those checks
for you, on every PR, without relying on memory or discipline.

### What problem it solves

| Problem | GitHub Actions solution |
|---|---|
| "Did this PR break the `hardening_audit.sh` script?" | A workflow runs `bash -n` / shellcheck on every PR |
| "Someone pushed a Dockerfile that doesn't build" | A workflow runs `docker build` on every push |
| "We keep forgetting to run `ansible-lint` before merging" | CI runs it automatically and blocks the merge if it fails |
| "Deploy to production only after tests pass and someone approves" | Environments with protection rules + `needs:` job dependencies |

### Three-Level Depth (Lens A)

- **Level 1 — Beginner:** A workflow is a YAML file in `.github/workflows/`
  (e.g., `ci.yml`). It has `on:` (what triggers it — `push`, `pull_request`,
  `schedule`), and `jobs:` (what to run). Each job has `runs-on:` (which OS —
  `ubuntu-latest`) and `steps:` — each step is either `run:` (a shell command)
  or `uses:` (a reusable "action," like `actions/checkout@v4` to clone your
  repo).
- **Level 2 — SysAdmin:** Per [techoral's CI/CD guide](https://techoral.com/automation/github-actions-complete-guide.html)
  and [GitHub's secure-use reference](https://docs.github.com/en/actions/reference/security/secure-use):
  jobs within a workflow run **in parallel by default**; use `needs:` to make
  one job wait for another (e.g., `deploy` needs `test` to pass first).
  **Secrets** (`${{ secrets.MY_SECRET }}`) are encrypted at rest, only decrypted
  for authorized workflows, and **automatically masked** in logs — never echo a
  secret directly (masking can be bypassed by transformations like base64).
  **Caching** (`actions/cache` or built-in caching in `actions/setup-node` etc.)
  is the highest-impact speed optimization — an uncached dependency install can
  take 60-120s, cached often 5-15s. **Pin action versions** — use a specific
  tag/SHA (`actions/checkout@v4`, or better, a commit SHA) rather than `@main`,
  to avoid a third-party action changing unexpectedly (a supply-chain risk).
  **Set explicit `permissions:`** on every workflow (least privilege — most
  workflows need only `contents: read`).
- **Level 3 — Systems/Kernel (Lens D):** A GitHub-hosted **runner** is literally
  a fresh VM (or container) provisioned per job — your `steps:` execute as
  shell commands inside that ephemeral VM, which is destroyed after the job
  completes. This is why workflows need `actions/checkout` (the repo isn't
  there by default — fresh VM) and why state doesn't persist between separate
  job runs unless explicitly cached/uploaded as an **artifact**. Conceptually,
  this is the same "ephemeral, reproducible environment" idea as a Docker
  container (Lesson 11) — in fact, many runners *are* containers, and your
  workflow can also explicitly run steps inside a Docker container
  (`container: image: ...`).

### Analogy (Lens B)

- **CI workflow** = a quality-control checkpoint on a factory assembly line:
  every item (commit/PR) automatically passes through the same inspection
  stations (lint, build, test) before being allowed onto the next stage
  (merge/deploy) — no item skips inspection because an inspector forgot.
- **Runner** = a brand-new, identical workstation handed to each inspector for
  each item, then thrown away after — guarantees no leftover material from the
  previous item contaminates this inspection (ephemeral, reproducible).
- **`needs:`** = "station B can't start inspecting until station A signs off" —
  an explicit dependency, vs. the default of all stations running in parallel
  on independent items.
- **Secrets masking** = the inspector is handed a sealed envelope (the secret)
  they can use to unlock a specific tool, but anything they read aloud from
  inside that envelope gets bleeped out of the recording (logs) automatically.

The factory analogy holds well structurally but breaks down for **caching** —
a factory inspection station doesn't have a direct equivalent of "remember the
exact state of your toolbox from last time so you don't have to re-sharpen
every tool" persisting *across* otherwise-identical-but-separate workstations.

---

## Step 2 — Real-World Use

### How SysAdmins/developers use this daily

```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [main]
  pull_request:

permissions:
  contents: read

jobs:
  lint-and-validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Shellcheck all scripts
        run: |
          sudo apt-get install -y shellcheck
          shellcheck scripts/*.sh

      - name: Validate Dockerfile builds
        run: docker build -t naviops-audit:ci .

      - name: Lint Ansible playbooks
        run: |
          pip install ansible-lint
          ansible-lint playbooks/*.yml
```

**Real production scenarios:**
1. **Every PR runs lint + build + test** — catches `bash -n` failures, broken
   Dockerfiles, `ansible-lint` violations before a human reviews the PR.
2. **Scheduled jobs** — `on: schedule: cron: '0 6 * * *'` runs a daily check
   (e.g., dependency vulnerability scan) — same cron syntax from Lesson 06.
3. **Multi-stage pipelines** — `build` → `test` → `deploy-staging` →
   (manual approval) → `deploy-production`, using `needs:` and GitHub
   Environments with protection rules.

### Common mistakes

| Mistake | Impact | Fix |
|---|---|---|
| Using `@main`/`@latest` for third-party actions | A supply-chain attack or breaking change in the action affects your CI without warning | Pin to a specific version tag or commit SHA |
| No `permissions:` block | Workflow gets default (sometimes broad) permissions | Explicitly set `permissions: contents: read` (add more only as needed) |
| Echoing secrets for "debugging" | Even masked, transformed secrets (base64, substring) can leak | Never print secrets; use `::add-mask::` if you must derive a new sensitive value |
| Not caching dependencies | Every CI run reinstalls everything — slow, wastes runner minutes | `actions/cache` or built-in caching in `setup-*` actions |
| One massive job instead of parallel jobs | Slow feedback — a lint failure waits behind a long build | Split into parallel jobs (`lint`, `build`, `test`) |

### When NOT to over-engineer CI

- A learning/personal repo doesn't need a 12-stage pipeline — start with one
  workflow that lints/validates your scripts and Dockerfiles (Step 4), and add
  stages as the project grows.

---

## Step 3 — Alternatives

| Tool | Use case |
|---|---|
| **GitHub Actions** (this lesson) | Tightly integrated with GitHub repos/PRs — the most common choice for GitHub-hosted projects, and what most job postings expect |
| **GitLab CI** | Equivalent for GitLab-hosted repos — very similar YAML concepts |
| **Jenkins** | Self-hosted, older, highly configurable — still common in enterprises with on-prem infrastructure |
| **CircleCI / Travis CI** | Other hosted CI platforms — less common now relative to GitHub Actions |

**For NaviOps:** GitHub Actions is the natural choice (repo is already on
GitHub, Lesson 02) and directly demonstrable to employers via a public repo's
"Actions" tab and green checkmarks on PRs.

---

## Step 4 — Hands-On Task (build this yourself)

**Goal:** Write `.github/workflows/ci.yml` that validates the artifacts you've
built across Lessons 03-13: shell scripts, Dockerfile, Ansible playbook.

### Lens C — Manual → Automated → Why

**Manual:** before each commit, you remember to run `bash -n scripts/*.sh`,
`docker build .`, `ansible-lint playbooks/*.yml` yourself.

**Automated (`.github/workflows/ci.yml`):**
```yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:

permissions:
  contents: read

jobs:
  validate-scripts:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Syntax-check all scripts
        run: |
          for f in scripts/*.sh; do
            echo "Checking $f"
            bash -n "$f"
          done
      - name: Run ShellCheck
        uses: ludeeus/action-shellcheck@master
        with:
          scandir: './scripts'

  validate-docker:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Build image
        run: docker build -t naviops-audit:ci .

  validate-ansible:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.12'
      - name: Install ansible-lint
        run: pip install ansible-lint
      - name: Lint playbooks
        run: ansible-lint playbooks/*.yml
```

**Why this matters:** every push/PR now automatically re-runs the
**Verification (Step 5)** sections of Lessons 03, 11, and 13 — turning your
manual "did I check this?" habit into an enforced, visible (green checkmark)
guarantee.

### What to build, step by step

1. Create `.github/workflows/ci.yml` per the structure above (adjust to which
   scripts/Dockerfile/playbooks actually exist in your repo at this point —
   it's fine if some jobs are simpler/missing if you haven't built that
   artifact yet).
2. Pin the third-party action (`ludeeus/action-shellcheck`) to a specific
   version tag, not `@master`, per the security best practice.
3. Push to a branch, open a PR — watch the "Checks" section on the PR run your
   workflow.
4. Intentionally introduce a syntax error in one script, push, confirm CI
   **fails** and shows you why.
5. Fix it, push again, confirm CI passes (green checkmark).
6. Commit on `lesson/14-github-actions-ci-basics`.

---

## Step 5 — Verification

```bash
# Locally simulate what CI will do, before pushing
for f in scripts/*.sh; do bash -n "$f"; done
docker build -t naviops-audit:ci .
ansible-lint playbooks/*.yml

# Then push and check the Actions tab on GitHub / the PR's Checks tab
```

### Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| Workflow doesn't trigger at all | File not in `.github/workflows/`, or YAML syntax error | Check exact path; validate YAML (`yamllint` or GitHub's own UI will show parse errors) |
| `actions/checkout` step needed but missing | Without it, the runner has no copy of your repo | Always include `- uses: actions/checkout@v4` as the first step |
| Job passes locally but fails in CI | Different OS/tool versions on the runner vs. your machine | Pin tool versions explicitly (`actions/setup-python@v5` with `python-version:`) |
| Secret not available in workflow | Secret not added in repo Settings → Secrets, or wrong scope (org vs repo vs environment) | Add the secret in the correct scope; reference as `${{ secrets.NAME }}` |
| CI takes a long time on every run | No caching | Add `actions/cache` for dependency directories |

### Redaction check ✅

CI workflow YAML is committed publicly — never hardcode real
hostnames/IPs/credentials in workflow files; use `secrets.*` for anything
sensitive.

---

## Step 6 — Quiz (Interview-Style, Graded)

**Q1.** What's the difference between a **workflow**, a **job**, and a **step**
in GitHub Actions? How do jobs run relative to each other by default, and how
do you change that?

> **Your answer:**

**Q2.** **Scenario:** Your CI workflow uses `uses: some-org/some-action@main`.
A teammate asks you to change this before merging. Why, and what should you
change it to?

> **Your answer:**

**Q3.** Why are GitHub-hosted runners described as "ephemeral," and what two
practical consequences does this have for how you write workflow steps? (Tie
back to Lesson 11's container ephemerality.)

> **Your answer:**

**Q4.** How does GitHub Actions handle secrets — what happens if a workflow
step accidentally `echo`s a secret value?

> **Your answer:**

**Q5.** You have three jobs: `lint`, `build`, `deploy`. `deploy` should only run
after both `lint` and `build` succeed. How do you express this in YAML?

> **Your answer:**

**Q6.** Why would you add a CI workflow to a personal learning repo, even though
no one else reviews your PRs? What does it demonstrate to a potential employer
looking at your GitHub profile?

> **Your answer:**

---

## Step 7 — Reflection

*(Fill in after the quiz)*

- What did you learn?
- What confused you?
- What would you do differently?

---

## Step 8 — Search Keywords For Further Understanding

**Core**
- `github actions workflow job step explained`
- `github actions secrets best practices`
- `github actions caching dependencies`
- `pin github actions to commit sha security`

**Tools**
- `shellcheck github action`
- `ansible-lint ci pipeline`
- `github actions matrix builds`

**Going further (future lessons)**
- `github actions deploy to aws`
- `github actions terraform plan apply`
- `github environments protection rules approval`

---

## Lesson Status

- [ ] Hands-on task completed (Step 4)
- [ ] Verification passed (Step 5)
- [ ] Quiz answered + professional-answer comparisons requested (Step 6)
- [ ] Reflection completed (Step 7)
- [ ] Search Keywords reviewed (Step 8)

When complete, run the Update Protocol, then move to **Lesson 15 — AWS
Fundamentals (Account & IAM)**.

---

*Lesson 14 written by Navi v28 · 2026-06-11 · WebSearch sources:
[techoral GitHub Actions Complete Guide 2026](https://techoral.com/automation/github-actions-complete-guide.html),
[GitHub Actions Secure Use Reference](https://docs.github.com/en/actions/reference/security/secure-use),
[GitHub Actions 2026 Security Roadmap](https://github.blog/news-insights/product-news/whats-coming-to-our-github-actions-2026-security-roadmap/),
[awesome-copilot GitHub Actions CI/CD Best Practices](https://github.com/github/awesome-copilot/blob/main/instructions/github-actions-ci-cd-best-practices.instructions.md)*
