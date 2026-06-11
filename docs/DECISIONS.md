# Decisions (ADR-lite)

Locked decisions + rationale. Append; don't rewrite history.

## D1 — NaviOps is a separate repo from Navi
**2026-06-10.** NaviOps is project-specific (AWS, CCNA, personal career roadmap), which
would violate Navi's own Hard Rule #1 (project-agnostic `.agent/`) if merged into the
Navi repo. NaviOps copies Navi's `.agent/` core unmodified and adds its own
`navi.project.md` + `docs/learning/`. *Rejected:* a `naviops/` subfolder inside
`Navigator-Lab/Navi`.

## D2 — Gate Rule lives in exactly one file
**2026-06-10.** `docs/learning/CLAUDE_TEACHING_RULES.md` is the single source of truth
for the Gate Rule (now 8 steps, see D4). `PROJECT_MISSION.md` links to it instead of restating it, to
avoid drift between the two (the original 001/004 prompts both contained the full rule).
*Rejected:* duplicating the Gate Rule in both files.

## D3 — `LEARNING_STATE.md` uses placeholders for all infra/AWS facts
**2026-06-10.** Since NaviOps ships to a public repo and will accumulate 30+ days of
real infrastructure work, `LEARNING_STATE.md`'s "Current Infrastructure"/"Current AWS
State" sections mandate placeholders (`<ACCOUNT_ID>`, `10.0.x.x`, `<INSTANCE_ID>`) from
day 1, backed by a Gitleaks pre-commit hook. *Rejected:* redacting retroactively before
each push (error-prone over a long-running repo).

## D4 — Gate Rule extended to 8 steps (graded quiz + Search Keywords)
**2026-06-10.** After Lesson 01, the operator asked for (a) interview-style quiz
questions with Claude's professional-answer comparison written under each learner
answer, and (b) a closing "Search Keywords For Further Understanding" section per
lesson. `CLAUDE_TEACHING_RULES.md` Step 6 now requires the comparison; a new Step 8
adds the keyword section. *Rejected:* a separate "grading" doc per lesson — keeping the
comparison inline in the lesson README keeps everything in one portfolio artifact.

## D5 — Roadmap expanded with Git/GitHub + adjacent DevOps skill areas
**2026-06-10.** WebSearch research (see Lesson 01 update) confirmed Git/GitHub,
Ansible, basic CI/CD (GitHub Actions), Terraform/IaC, and secrets management are
baseline-expected for junior Linux SysAdmin/DevOps roles in 2025-2026, not "advanced"
extras. `PROJECT_MISSION.md`'s skills table and milestones are updated to include them,
with Git/GitHub fundamentals slotted as Lesson 02 (immediately after Linux
filesystems/permissions, since version-controlling NaviOps' own scripts/docs is needed
from here on). *Rejected:* deferring Git to Month 2 — the operator is already using git
for this repo, so the gap is immediate, not theoretical.

## D6 — Primary learning OS = AlmaLinux 9 (Rocky equal) + Ubuntu LTS as required secondary
**2026-06-10.** Per the career-strategy EXP/PLAN
(`docs/reports/EXP/EXP_REPORT_2026-06-10_NaviOps-Career-Strategy.md`). WebSearch evidence:
RHEL ≈43% of the enterprise *server* segment and RHCSA is RHEL-specific (dnf, firewalld,
SELinux-enforcing, systemd), so building NaviOps on a RHEL clone makes the project double
as RHCSA prep — directly serving the Red Hat alignment goal. Ubuntu ≈60% of *cloud*
instances + Docker's default world, so it's a mandatory second VM, not optional. Rocky vs
Alma are ~interchangeable for year-one work; Alma chosen marginally (foundation governance
+ patch cadence + AMI availability), Rocky explicitly acceptable. *Rejected:* Ubuntu-only
(weak RHCSA muscle), Fedora (13-mo churn, no prod hiring), Debian-as-primary (apt/AppArmor =
wrong RHCSA muscles), OpenSUSE (low entry-hiring ROI). Satisfies the "do NOT auto-recommend
Rocky" instruction — the pick is *either* RHEL clone, proven by indistinguishable juniors' day-to-day.

## D7 — Migration strategy = Hybrid, VM-first; host OS never wiped
**2026-06-10.** The "machine has important files" constraint makes any OS-replace/dual-boot
a danger zone. Decision: keep the daily-driver OS untouched; build the lab as headless VMs
(1→3) with per-lesson snapshots, so "breaking the system" is a one-click-recoverable lesson.
Dual-boot/replace is *gated* behind a verified + restore-tested 3-2-1 backup AND a booted
recovery USB (see PLAN Phase E). *Rejected:* Option C replace (destroys files, no snapshots),
Option B dual-boot as primary (reboot friction, shared-disk risk).
**Resolved 2026-06-10:** operator confirmed the Dell E6540 (16 GB) is the **only** laptop — no
spare. So VM-first is the *only* safe path (bare-metal-on-spare option is off the table). VMs run
**headless** to fit 16 GB: 1 always-on (`vm-alma` 2 GB), 2 during networking labs, avoid 3 (use a
container or brief 3rd VM for the Month-2 Ansible target). Apply-trigger roadmap (M0–M4) added to the
PLAN so role applications start at ~Day 14, in waves, not at Day 90.

## D8 — Sequencing locks: Docker Wk3, AWS Wk5–8, K8s deferred, RHCSA ~Day 75–120
**2026-06-10.** Docker introduced Week 3 (with Podman, RHEL-native) so systemd/process/network
fundamentals land first. AWS time-boxed to Weeks 5–8 because the **2025 Free-Tier overhaul**
gives new accounts $100 credits + a Free Plan that **expires in ~6 months or when credits run
out** (verified via aws.amazon.com) — the old 12-month always-free model is gone, so the clock
must not start before the lab is ready; tear resources down nightly + set a $5 Budget alert.
Kubernetes deferred past Day 90 (mid-level multiplier, ~0 value to a first SysAdmin offer).
RHCSA sat ~Day 75–120, skills-first (the roadmap already teaches ~80% of EX200 on AlmaLinux).

## D9 — First-role target ranking = Linux Support → Junior SysAdmin → Cloud Support → Infra Ops → DevOps
**2026-06-10.** Ranked for a career-changer with a public portfolio: Linux **Support** is the
highest-probability first door (hires on troubleshooting + communication, which NaviOps' `docs/`
and runbooks evidence); Junior SysAdmin is the stated target and RHCSA-aligned; Cloud Support is
the most remote-friendly (#2 target after the Week-8 AWS labs); Infra Ops is the 6–12 mo
progression; Junior **DevOps** is the *most competitive* entry and a 6-month goal, not the first
job (data: sysadmin→DevOps is a 6–12 mo on-ramp). *Rejected:* aiming DevOps-first.

## D10 — Lesson schema extended with 4 Integration Lenses (01.md merged)
**2026-06-11.** `01.md` (operator-authored, repo root) introduced 7 new teaching rules:
Bash-first/C-aware strategy, Bash integration, C-language integration, systems-thinking
(User/SysAdmin/Kernel), double-explanation (technical + analogy), understanding
verification, and learning-depth (3 levels). Audit found 2 already covered (NaviOps
Integration = existing Top-Level Rule 2; Understanding Verification = existing Step 6
graded scenario quiz, D4) and 2 redundant with each other (Systems Thinking and
Learning Depth are the same 3-level ladder over overlapping trigger sets). The
remaining 4 are merged into `CLAUDE_TEACHING_RULES.md` as **Integration Lenses A–D**
(Three-Level Depth, Double-Explanation, Bash Automation, C/Systems Tie-In) that fire
*inside* existing Steps 1 and 4 — the Gate Rule stays at 8 steps (preserves the D4
`grep -c "^### Step"` → 8 verification). WebSearch (Bloom's Taxonomy, Feynman
technique/dual-coding, C-via-Linux-internals curricula, scenario-based assessment —
see `docs/reports/EXP/EXP_REPORT_2026-06-11_Lesson-Schema-Integration-Lenses.md`)
confirmed this design matches established instructional practice. Lessons 01 and 02
retrofitted with all 4 lenses; `01.md` removed (content fully absorbed). *Rejected:* a
second parallel "schema" document (violates D2 — single source of truth); keeping
Systems Thinking and Learning Depth as two separate rules (ambiguous which applies).
