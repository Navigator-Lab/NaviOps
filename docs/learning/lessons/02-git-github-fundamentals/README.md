# Lesson 02 — Git & GitHub Fundamentals

**Status:** in progress · **Date started:** 2026-06-10
**Gate Rule:** Concept → Real-World Use → Alternatives → Hands-On → Verification → Quiz → Reflection → Search Keywords
(see `docs/learning/CLAUDE_TEACHING_RULES.md`)

---

## Step 1 — Concept

### What it is

**Git** is a **distributed version control system (DVCS)** created by Linus Torvalds in
2005. It tracks changes to files over time, allowing you to snapshot your work, revert
mistakes, and collaborate safely with others.

**GitHub** is a **cloud hosting platform for Git repositories** — it adds a web UI, pull
requests, issues, branch protection rules, and CI/CD hooks on top of plain Git.

The mental model:

```
Your files  →  Git (local tracker)  →  GitHub (remote backup + collaboration)
              (commits, branches)       (PRs, reviews, CI/CD triggers)
```

The core data structure is the **commit graph** — a chain of snapshots, each pointing
to its parent:

```
A ← B ← C ← D   (main branch)
              ↑
              └─ E ← F   (feature branch, forked at D)
```

Every commit records: *what changed*, *who changed it*, *when*, and *why* (the message).

### Why it exists

Before version control, teams emailed zip files or overwrote each other's work. Even
solo, "save a copy before editing" doesn't scale. Git solves:

- **History** — every change is permanent and inspectable (`git log`, `git diff`).
- **Parallelism** — multiple people (or feature branches) work simultaneously without
  blocking each other.
- **Safety** — you can always roll back to any previous commit.
- **Auditability** — who changed what and why is recorded forever.

### What problem it solves

In a SysAdmin/DevOps context specifically:

| Problem | Git solution |
|---|---|
| "Who changed the Nginx config and broke prod?" | `git log` + `git blame` |
| "Roll back the Ansible playbook to last week's version" | `git revert` / `git checkout` |
| "Test a risky change without breaking the live config" | Feature branch |
| "Two engineers updating the same Terraform file" | Branching + merge/PR workflow |
| "Prove to auditors that no one touched the firewall rules" | Immutable commit history |

### Three-Level Depth (Lens A)

- **Level 1 — Beginner:** `git add` stages changes, `git commit` snapshots them,
  `git log` shows history, `git branch`/`git checkout` switch lines of work.
- **Level 2 — SysAdmin:** branching strategy (GitHub Flow), PRs/code review, branch
  protection, resolving merge conflicts, `git bisect`/`git log -S` for incident
  root-cause, GitOps (merging to `main` triggers infra apply).
- **Level 3 — Systems (Lens D):** Git is a **content-addressable filesystem**. Every
  blob, tree, and commit is stored under `.git/objects/<sha1[0:2]>/<sha1[2:]>`, named
  by the **SHA-1 hash of its own (zlib-compressed) content**. A commit object is just a
  pointer (hash) to a tree (snapshot of the directory) plus a pointer to its parent
  commit(s) — that's why the "commit graph" diagram in Step 1 is literally a graph of
  hash pointers, not a special data structure. `git cat-file -p HEAD` and
  `git cat-file -p HEAD^{tree}` show this directly. Git itself is written in C; the
  object format and hashing are why `git` operations are fast even on huge histories
  (content is deduplicated by hash — identical file content across commits is stored
  once).

### Analogy (Lens B)

Git is like a **video game's save-file system** crossed with a **photo album**:
- Each **commit** is a save point — a complete snapshot you can always load again,
  with a note (commit message) describing what happened since the last save.
- A **branch** is a separate save slot forked from a save point — you can play out a
  risky experiment in slot B without overwriting slot A (`main`).
- **Merging** is combining progress from two save slots back into one.
- A **Pull Request** is asking a teammate to review your save-file diff *before* it
  becomes the new "official" save that everyone builds on.

This analogy holds for the everyday workflow, but it breaks down for **merge
conflicts** — two save files don't "conflict," but two sets of *line-by-line text
changes to the same file* can, and resolving that requires understanding the diff, not
just picking one save over the other.

---

## Step 2 — Real-World Use

### How SysAdmins use Git daily (2025 baseline)

**Infrastructure-as-Code (IaC) repos** — Terraform, Ansible, Kubernetes manifests all
live in Git. A SysAdmin's day looks like:

```
1. git pull origin main          # get latest
2. git checkout -b fix/nginx-ssl # create an isolated branch
3. (edit config files)
4. git add .
5. git commit -m "fix: renew wildcard cert path for nginx"
6. git push origin fix/nginx-ssl
7. Open PR on GitHub → team reviews → CI runs → merge
```

**Common real-world scenarios:**

1. **Hotfix under pressure** — prod is down. Branch from `main`, fix, PR, merge in 10
   minutes. The audit trail proves exactly what changed.
2. **Onboarding a new teammate** — `git clone <repo>` and they have the entire history
   of every config decision ever made.
3. **GitOps** — the Git repo *is* the source of truth for infrastructure state. Merging
   to `main` automatically triggers Terraform/Ansible/ArgoCD to apply the change to
   prod. Increasingly the standard in 2025–2026.
4. **Secrets audit** — `git log --all -S "password"` scans history for accidental
   credential commits (then you rotate immediately and purge with `git filter-branch`).

### Common mistakes

| Mistake | Impact | Fix |
|---|---|---|
| Committing secrets (API keys, `.pem` files) | Full rotation required; history is permanent | `.gitignore` + pre-commit hooks (Gitleaks — already in this repo) |
| Working directly on `main` | Impossible to review before it's live | Branch protection rules |
| Giant "mega-commits" | Impossible to pinpoint what broke | Small, atomic commits |
| Vague messages (`"fix stuff"`) | Useless history for debugging | Conventional Commits format |
| Not pulling before branching | Merge conflicts later | Always `git pull origin main` first |

### When NOT to use Git (or what not to put in Git)

- Binary blobs (large compiled artifacts, video files) — use Git LFS or S3 instead.
- Generated files (`.tfstate`, `node_modules/`, compiled binaries) — `.gitignore` them.
- Real secrets — `.env`, `.pem` keys, `.tfvars` with real values — never, ever commit.
- Frequently-changing database dumps — not meant for Git; use dedicated backup tools.

---

## Step 3 — Alternatives

### Alternative VCS tools

| Tool | Model | Best for | Why Git won |
|---|---|---|---|
| **SVN (Subversion)** | Centralized | Legacy enterprise, binary-heavy repos | Git is faster, works offline, cheaper to branch |
| **Mercurial (Hg)** | Distributed | Similar to Git; cleaner CLI some say | GitHub network effect killed it for most teams |
| **Perforce (Helix Core)** | Centralized hybrid | Game dev (huge binary assets), enterprise | Still used in gaming/AAA; overkill for SysAdmin |
| **Fossil** | Distributed + wiki + bug tracker built-in | Embedded/solo projects | No ecosystem |

**Verdict for a SysAdmin/DevOps engineer in 2025:** Git + GitHub is the unambiguous
standard. Perforce knowledge is a niche bonus for game-studio work. SVN still appears
in older enterprises but is being replaced.

### Alternative Git hosting platforms

| Platform | Key differentiator |
|---|---|
| **GitHub** | Largest ecosystem, Actions CI/CD, GitHub Copilot |
| **GitLab** | Self-hostable, built-in CI/CD pipelines, DevSecOps features |
| **Bitbucket** | Atlassian ecosystem (Jira/Confluence integration) |
| **Gitea** | Lightweight self-hosted, minimal resources |
| **AWS CodeCommit** | IAM-native, no egress to third-party SaaS |

**For this repo:** GitHub is correct — it's the portfolio platform and has the widest
recruiter/employer visibility.

### Branching strategy alternatives

| Strategy | How it works | Best for |
|---|---|---|
| **GitHub Flow** | `main` + short-lived feature branches + PRs | Web apps, continuous deployment (us) |
| **Trunk-Based Development** | Everyone commits to `main` daily; feature flags for incomplete work | Large teams, high velocity CI/CD |
| **GitFlow** | `main` + `develop` + `feature/` + `release/` + `hotfix/` | Versioned software with scheduled releases |

**For NaviOps:** GitHub Flow — it's the simplest, teaches the PR habit, and is what
most employers expect juniors to know.

---

## Step 4 — Hands-On Task

**Goal:** Run the complete professional Git workflow on the NaviOps repo itself —
create a branch, make a real doc change, commit it with a proper message, and prepare
it for a push to GitHub (the push is the human-approved step, not auto-run).

**Lens C (Bash automation) note:** steps 4b/4f below (`git status`, `git log`,
`git branch -a`, `git remote -v`) are exactly the manual checks a SysAdmin runs before
touching a repo. `scripts/git-health-check.sh` (built in 4d) automates that check into
one command — what a production engineer would wire into a pre-deploy CI step or a
periodic repo-health report, instead of remembering to run 4 commands by hand every
time.

### 4a — Configure your identity (one-time)

```bash
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
git config --global init.defaultBranch main

# Verify
git config --global --list
```

### 4b — Inspect the repo's current state

```bash
# From inside /home/sys-ctl/NaviOps/
git status           # what's changed vs last commit?
git log --oneline -5 # last 5 commits in compact format
git branch -a        # all branches (local + remote)
```

Expected output of `git log --oneline`:

```
a1b2c3d (HEAD -> main) Initial NaviOps scaffold with Navi v28 core
```

### 4c — Create a feature branch

Always branch from an up-to-date `main`:

```bash
git checkout main
git pull origin main 2>/dev/null || echo "(no remote yet — that's fine)"
git checkout -b lesson/02-git-github-fundamentals
```

What happened:
- `git checkout -b <name>` creates a new branch AND switches to it in one command.
- The branch is a lightweight pointer to the current commit — no files are copied.
- Naming convention: `lesson/`, `fix/`, `feat/`, `chore/` prefixes describe the type.

### 4d — Make a real platform improvement

Add a script that reports the repo's Git health — a genuine NaviOps `scripts/` artifact:

```bash
cat > /home/sys-ctl/NaviOps/scripts/git-health-check.sh << 'EOF'
#!/usr/bin/env bash
# git-health-check.sh — NaviOps Lesson 02
# Reports basic Git repo health: branch, last commit, uncommitted changes, remotes.
set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || {
  echo "ERROR: not inside a git repository" >&2; exit 1
}

echo "=== Git Health Check: $REPO_ROOT ==="
echo ""
echo "Branch:      $(git rev-parse --abbrev-ref HEAD)"
echo "Last commit: $(git log -1 --format='%h %s (%ar)' 2>/dev/null || echo 'no commits yet')"
echo "Status:"
git status --short || true
echo ""
echo "Remotes:"
git remote -v 2>/dev/null || echo "  (none configured)"
echo ""
echo "Stash count: $(git stash list 2>/dev/null | wc -l)"
echo "Unpushed commits vs origin/main:"
git log origin/main..HEAD --oneline 2>/dev/null || echo "  (no remote to compare)"
EOF

chmod +x /home/sys-ctl/NaviOps/scripts/git-health-check.sh
```

### 4e — Stage and commit

```bash
cd /home/sys-ctl/NaviOps

# Stage specific files (precise > shotgun)
git add scripts/git-health-check.sh
git add docs/learning/lessons/02-git-github-fundamentals/README.md

# Inspect what's staged before committing
git diff --staged

# Commit with a Conventional Commits message
git commit -m "feat(lesson-02): add git-health-check script and Git fundamentals lesson"
```

**Conventional Commits format:** `<type>(<scope>): <what>` where type is one of:
- `feat` — new feature or capability
- `fix` — bug fix
- `chore` — maintenance (no production code change)
- `docs` — documentation only
- `refactor` — restructuring without behavior change

### 4f — Inspect what you built

```bash
git log --oneline -3
git show HEAD --stat        # what files changed in the last commit?
git diff main..HEAD         # what's different between this branch and main?
```

### 4g — Ready-to-push (human-approved command)

The following command pushes your branch to GitHub. **Do NOT run this yet** — GitHub
remote setup (creating the repo at `Navigator-Lab/NaviOps`) is a separate step. This
is the command you'll run when ready:

```bash
# Human-approved — run when GitHub remote is configured
git remote add origin git@github.com:Navigator-Lab/NaviOps.git
git push -u origin lesson/02-git-github-fundamentals
```

The `-u` flag sets the upstream so future `git push` (no args) knows where to send.

---

## Step 5 — Verification

### Expected state after Step 4

Run the health check script:

```bash
bash /home/sys-ctl/NaviOps/scripts/git-health-check.sh
```

Expected output (approximate):

```
=== Git Health Check: /home/sys-ctl/NaviOps ===

Branch:      lesson/02-git-github-fundamentals
Last commit: <hash> feat(lesson-02): add git-health-check script and Git fundamentals lesson (just now)
Status:
(empty — clean working tree)

Remotes:
  (none configured)

Stash count: 0
Unpushed commits vs origin/main:
  (no remote to compare)
```

### Spot-check commands

```bash
# Confirm you're on the feature branch, not main
git branch

# Confirm the commit exists
git log --oneline -3

# Confirm the script is executable
ls -la scripts/git-health-check.sh
# Expected: -rwxr-xr-x

# Confirm no secrets staged (Gitleaks pre-commit hook covers this,
# but manual check: look at git diff --staged output above)
```

### Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| `git: 'pull' has no remote` | No GitHub remote configured yet | Expected — skip pull for now |
| `Permission denied (publickey)` on push | SSH key not on GitHub | Add `~/.ssh/id_ed25519.pub` to GitHub → Settings → SSH Keys |
| `! [rejected] main -> main (non-fast-forward)` | Remote has commits your local doesn't | `git pull --rebase origin main` then push |
| Committed a secret by accident | **Critical** | Rotate the secret immediately. Then `git reset HEAD~1`, `.gitignore` the file, recommit. If already pushed, use `git filter-branch` or `git-filter-repo`. |

### Redaction check ✅

Before committing: this lesson and the `git-health-check.sh` script contain no real
account IDs, IPs, hostnames, ARNs, or credentials — the script only reads local Git
metadata. Safe to commit.

---

## Step 6 — Quiz (Interview-Style)

> **Instructions:** Answer each question directly under it (edit this file). Once you've
> answered all questions, I'll write the Professional Answer comparison below each.

**Q1.** What is the difference between `git add` and `git commit`? Why does Git have
this two-step process instead of saving directly?

> **Your answer:**
> *(write here)*

---

**Q2.** A teammate tells you: "I always push directly to `main` — it's faster." What
are the risks, and how would you explain branch-based workflow to them?

> **Your answer:**
> *(write here)*

---

**Q3.** You're debugging a prod incident. The Nginx config broke sometime in the last
3 days. What Git commands would you use to find which commit introduced the breakage?

> **Your answer:**
> *(write here)*

---

**Q4.** What does `git pull` actually do under the hood? Is it always safe to run?

> **Your answer:**
> *(write here)*

---

**Q5.** Explain what a merge conflict is, when it happens, and how you resolve one.

> **Your answer:**
> *(write here)*

---

**Q6.** Your `.gitignore` file says `*.log`. You already committed `app.log` before
adding the rule. Will `.gitignore` now hide `app.log` from Git? Why or why not?

> **Your answer:**
> *(write here)*

---

**Q7.** What is a Pull Request (PR)? How does it differ from `git merge` run locally?

> **Your answer:**
> *(write here)*

---

**Q8.** A colleague accidentally committed an AWS secret key and pushed it to GitHub.
What are the steps, in order, to handle this?

> **Your answer:**
> *(write here)*

---

## Step 7 — Reflection

*(Filled in after quiz is complete and professional answers are written)*

- What did you learn?
- What confused you?
- What would you do differently?

---

## Step 8 — Search Keywords For Further Understanding

*(Written after Reflection)*

---

*Lesson 02 written by Navi v28 · 2026-06-10 · WebSearch sources: medium.com DevOps Git workflow, gitkraken.com branching strategies*
