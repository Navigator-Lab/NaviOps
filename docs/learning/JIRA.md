# JIRA — NaviOps Ticketing & Change-Management Layer

> **Purpose.** Convert NaviOps work into the three things NOC/Linux-support postings ask for —
> **ticketing experience, change management, documentation** (~60% of NOC JDs name Jira/ServiceNow).
> The board is the *operations record*; the git repo is its *evidence*. This file is the bridge.
>
> Design rationale: `docs/reports/EXP/EXP_REPORT_2026-06-16_Resume-Portfolio-Jira-Integration.md` (Part 4).

## 0. Principles (don't break these)
1. **Mirror real work — never invent tickets.** Every ticket maps to an actual lesson artifact,
   drill, or bug. No fictional incidents.
2. **Claim = committed evidence.** Only put a skill on the resume/portfolio once a ticket is *Done*
   and linked to a real commit. (Same rule that governs the AWS wording.)
3. **Public-repo discipline (Hard Rule 1).** The Jira board stays private/personal. This repo may
   reference it generically ("tracked via Jira Service Management"); never commit Jira-internal IDs,
   real hostnames, IPs, account IDs, or anything that leaks infra detail.
4. **No auto-send (P00).** The board is operated by hand; nothing here automates Jira.

## 1. Product
- **Use: Jira Service Management (JSM) — Free tier.** Native issue types are **Incident · Change ·
  Service Request · Problem** = literal NOC/ITIL vocabulary. That vocabulary is the differentiator.
- **Fallback:** Jira Software Free (simple Kanban) if JSM feels heavy — but then say "task board,"
  not "ITSM/ITIL" (weaker claim).
- Project key: **`NAVI`** · Project name: **NaviOps**.

## 2. Issue-type scheme (map to work that already exists)
| Issue type | Use for | NaviOps source |
|---|---|---|
| **Incident** | something broke / a troubleshooting drill | the 7 RHCSA drills (SSH lockout, broken fstab, failed systemd, broken sudo, full disk, SELinux, firewall); real bugs like the `scripts/user_audit.sh` unquoted-`$dir` defect |
| **Change** | a planned infra change | Configure SSH key auth (L07) · Add firewalld rules (L09) · Deploy Docker container (L11) · Harden sshd (L10) |
| **Service Request / Task** | routine build / ops | Create user-audit script (L04) · Write `healthcheck.sh` (L03) · Set up AlmaLinux VM |
| **Problem** | recurring root cause behind ≥2 incidents | e.g. "unquoted variables across scripts" → links its blast-audit siblings |

## 3. The discipline (this *is* the NOC skill)
Every ticket runs **To Do → In Progress → Done** with these fields filled:
- **Description** — symptom (Incident) or goal (Change/Task).
- **Steps taken** — what you actually ran.
- **Resolution + Verification** — the fix and the proof it worked (command output / check).
- **Linked commit** — the git commit that closed it (`Navigator-Lab/NaviOps@<sha>`).

That round-trip — opened → worked → documented → verified → linked — *is* change management +
ticketing + documentation in one artifact. **One ticket per lesson hands-on artifact**, keyed `NAVI-NN`.

## 4. Lesson → Ticket → Commit map (living)
Backfill done lessons first so the board has history on day one. Update after every lesson.

| Ticket | Type | Title | Lesson | Status | Commit |
|---|---|---|---|---|---|
| NAVI-1 | Change | Configure repo + Git/GitHub workflow | L02 | Done | _link_ |
| NAVI-2 | Task | Filesystem permissions hands-on | L01 | Done | _link_ |
| NAVI-3 | Task | Write `healthcheck.sh` (Bash fundamentals) | L03 | To Do | — |
| NAVI-4 | Incident | Fix unquoted `$dir` in `user_audit.sh` | (bug) | To Do | — |
| NAVI-5 | Task | Create user-audit script | L04 | To Do | — |
| NAVI-6 | Change | systemd service + journald | L05 | To Do | — |
| NAVI-7 | Change | Configure SSH key auth + hardening | L07/L10 | To Do | — |
| NAVI-8 | Change | firewalld rules (Networking II) | L09 | To Do | — |
| NAVI-9 | Change | Deploy Docker container | L11 | To Do | — |
| NAVI-10 | Incident | Drill: SSH lockout recovery | drills | To Do | — |
| NAVI-11 | Incident | Drill: broken fstab | drills | To Do | — |
| NAVI-12 | Incident | Drill: failed systemd unit | drills | To Do | — |
> Extend with the remaining drills (broken sudo, full disk, SELinux, firewall) and lessons 06, 08,
> 12–28 as you reach them.

## 5. When to put it on the resume / portfolio
Once ≥1 full ticket round-trip exists (opened → Done → linked commit):
- **Resume Tools line:** add `Jira Service Management (Incident / Change / Service Request)`.
- **Portfolio:** a one-line callout — "operational work tracked as ITSM tickets (incident / change /
  service request) in Jira Service Management."
- **Never** claim "Jira administrator" or years of Jira experience — claim the demonstrated workflow.

## 6. Adjacent rule — AWS wording (same evidence gate)
- ❌ Never "AWS Engineer" / "Cloud Architect" / "AWS infrastructure experience."
- ✅ Allowed **only after** Lessons 15–18 produce real, redacted artifacts (you actually create
  EC2/IAM/S3 and commit redacted proof): "Hands-on AWS Fundamentals (IAM, EC2, S3)."
- Until then AWS stays **curriculum-only** wording.

## 7. Getting started — first 30 minutes
1. **Create the account.** Go to `atlassian.com/software/jira/service-management` → *Get it free*.
   Sign up with `mahmoud.mansour.ops@gmail.com`. Free tier = up to 3 agents, plenty for solo use.
2. **Create the project.** *Projects → Create project →* template **IT Service Management**.
   Name **NaviOps**, key **NAVI**. This gives you the Incident / Change / Service Request / Problem
   issue types out of the box.
3. **Open the board.** Use the **Queues** (ITSM) or a simple **Board** view. Columns = To Do →
   In Progress → Done.
4. **Backfill what's already done** (gives the board instant history):
   - `NAVI-1` *Change* — "Configure repo + Git/GitHub workflow" (L02) → status **Done**.
   - `NAVI-2` *Task* — "Filesystem permissions hands-on" (L01) → **Done**.
   For each: paste a 2-line Resolution and the closing commit URL into the ticket. Done.
5. **Open your next real ticket as you work** (don't pre-create 28):
   - About to write `healthcheck.sh`? Open `NAVI-3` *Task* **before** you start → move to
     *In Progress* → write the script → fill Resolution + Verification → paste the commit URL →
     **Done**. That single round-trip is the demonstrable skill.
6. **Per-ticket fields to always fill** (this is the muscle memory recruiters mean by "Jira"):
   Description (symptom/goal) · Steps taken · Resolution + Verification · Linked commit.
7. **Keep §4 in sync.** After each ticket closes, add/refresh its row in the map above and commit
   this file. The repo is the public evidence; the board is the private demonstration.

**Weekly rhythm:** one drill logged as an *Incident* + one lesson artifact logged as a *Change/Task*.
In ~4 weeks you have a board with closed incidents, changes, and service requests — enough to honestly
say "tracked operational work via Jira Service Management (incident / change / service-request
workflows)" on the resume (step §5 of this doc).

---
*Created 2026-06-16 · Navi v28 · pairs with JOB_MILESTONES.md (the live job-search driver).*
