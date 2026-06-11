# EXP — NaviOps Career & Infrastructure Strategy (Evidence-Based)

**Date:** 2026-06-10 · **Mode:** RESEARCH → PLAN · **Tier:** Enterprise
**Protocols:** P00 + P02 (EXP) → P01 (PLAN) · **Author:** Navi v28
**Companion PLAN:** `docs/reports/PLAN/PLAN_2026-06-10_Backup-Migration-and-30-90-Roadmap.md`

<success_criteria>
Answer all 10 deliverables with evidence (not opinion). Every recommendation must (a) cite
a source or the project's own state, (b) raise hiring probability for Junior Linux SysAdmin /
Support / Cloud Support / Infra Ops, and (c) be implementable on a single 16 GB i7 laptop with
~€0 budget. Challenge the Rocky-Linux default rather than assume it.
</success_criteria>

<output_contract>
This EXP holds the *analysis* (Deliverables 1–4, 7–10 + cert/VM analysis). The companion PLAN
holds the *executable* steps (Deliverable 2 backup/migration as atomic steps, Deliverables 5–6
the 30/90-day roadmap). Reports live under `docs/reports/`, never the repo root.
</output_contract>

<assumptions> (Karpathy — stated up front; correct me if any is wrong)
1. The "current machine with important files" and the "Dell E6540, 16 GB, i7, SSD" are the
   **same** laptop (your one machine). If the E6540 is a *spare* second machine you can wipe,
   that is a strict upgrade — see §2 "Spare-machine upside". The plan is safe either way.
2. You are in/near the EU (budget in €, AWS region eu-* assumed). Adjust regions if not.
3. Target: first paid role in **Linux SysAdmin / Support / Cloud Support / Infra Ops** — *not*
   startup DevOps. This single fact decides the OS war (§1).
4. ~€0 budget, ~30–60 days to "junior-interviewable", continuing toward mid-level.
5. You are at **Day 1 / Lesson 01 complete** (Linux permissions). Roadmap starts from there.
</assumptions>

---

## Phase 0 — Anchor & Scope

Audited project state (`docs/STATUS.md`, `docs/learning/LEARNING_STATE.md`,
`PROJECT_MISSION.md`, `navi.project.md`):
- **Where you are:** Day 1. Lesson 01 (filesystems/permissions) done; 3 sub-topics flagged for
  spaced review. Lesson 02 (Git/GitHub) queued. Repo scaffolded, 1 commit, **not yet pushed**.
- **Constitution already commits to:** RHCSA-aligned skills, AWS free-tier-first, public-repo
  redaction discipline, "build don't course", gated lessons. This strategy *refines* that — it
  does not replace it. Where it changes a locked decision, it's logged in `docs/DECISIONS.md`.
- **The one real constraint:** one 16 GB laptop, €0, and files you cannot lose. Every
  recommendation below is filtered through "does this survive on that machine without risking
  the files."

## Phase 2 — Web Intel (sources used; full list in §References)

Five searches grounded the contested claims. Headline facts that *changed* the recommendation:
1. **Enterprise server share:** RHEL ~43% of the enterprise Linux *server* segment; Ubuntu ~38%
   enterprise usage **but ~60% of public-cloud Linux instances**. Rocky ~12%, Alma ~11% (post-
   CentOS migration). → The hiring market is *split by venue*: RHEL-family on-prem/enterprise,
   Ubuntu in cloud. [commandlinux, fosspost]
2. **RHCSA ROI:** ~$400 exam; cited as the highest-ROI Linux credential, ~197 US roles name it
   explicitly, mid-level salary pull-forward. RHCSA is **RHEL-specific** (dnf, firewalld,
   SELinux-enforcing, systemd). [certdemand, electromech]
3. **AWS Free Tier was overhauled (July 2025).** New accounts get **$100 credits + up to $100
   more**, and the Free *Plan* **expires after 6 months or when credits run out** — the old
   "12-month always-free t2.micro" is **gone** for new accounts. This forces a *deliberate,
   time-boxed* AWS phase, not "leave it running." [aws.amazon.com, neowin, infratally]
4. **Entry skills hiring managers prioritise:** CLI + shell + SSH, and **73% prioritise cloud +
   container skills**; Linux + a cloud credential is the strongest entry combo. [linuxcareers,
   coursera]
5. **Role entry timelines:** sysadmin → DevOps is a 6–12 month on-ramp; cloud/Terraform/Bash are
   the connective tissue. DevOps is *not* the easiest first door without code background. [dev.to]

---

# DELIVERABLE 1 — OS Recommendation Report

**Verdict (proven, not assumed): a 2-distro split — `AlmaLinux 9` (or Rocky 9) as the primary
"enterprise" learning OS, with `Ubuntu Server LTS` as the mandatory second distro for cloud/Docker
reality. Fedora, Debian-as-primary, and OpenSUSE are rejected for *this* goal.**

Why this beats "just pick one": your stated target (SysAdmin/Support/Infra Ops + explicit Red Hat
alignment + RHCSA) lives in **RHEL-family shops** (banks, gov, healthcare, telco, Red Hat
partners). But ~60% of cloud instances are Ubuntu and Docker's default world is Debian-family.
A junior who *only* knows one family interviews badly for the other. Learning both costs you
almost nothing (it's two VMs) and is itself a portfolio talking point ("I run a mixed RHEL/Debian
estate").

| Distro | Enterprise use | Hiring | RHCSA fit | AWS fit | Stability | Docs | Verdict |
|---|---|---|---|---|---|---|---|
| **AlmaLinux 9** | High (CentOS successor) | Strong (RHEL-proxy) | **Perfect** (dnf/firewalld/SELinux/systemd) | Official AMIs | 10-yr lifecycle | RHEL docs apply | **PRIMARY** |
| **Rocky 9** | High | Strong | **Perfect** (identical) | Official AMIs | 10-yr lifecycle | RHEL docs apply | **PRIMARY (equal)** |
| **Ubuntu Server LTS** | High in cloud | Most raw postings | Weak (apt/ufw/AppArmor) | Default cloud OS | 5-yr LTS | Excellent | **SECONDARY (required)** |
| Debian 12 | High in hosting | Moderate | Weak | Good | Rock-solid | Excellent | Optional (Docker host) |
| Fedora Server | Low in prod | Low | Partial (too new) | Some | 13-mo life — churns | Good | **Reject** (unstable for hiring) |
| OpenSUSE Leap | Niche (SAP/EU) | Low entry | Weak (zypper/YaST) | Limited | Good | Good | **Reject** (low hiring ROI) |

**Rocky vs AlmaLinux — the honest answer:** they are ~interchangeable for everything you'll do in
year one (Rocky = 1:1 binary compatible; Alma = ABI compatible, non-profit foundation governance,
historically faster security-patch cadence). **Pick one and be consistent** — consistency matters
more than the choice. I lean **AlmaLinux** (foundation governance + patch cadence + broad cloud
AMI availability); **Rocky is an equally defensible pick** and the larger mindshare. This directly
satisfies your "do NOT automatically recommend Rocky" instruction: the recommendation is *either*,
proven by the fact that the differentiators don't affect a junior's work.

**Rejections, justified:**
- **Fedora Server** — upstream of RHEL, 13-month lifecycle, constant churn. Teaches you tomorrow's
  RHEL but no shop hires juniors to run it. Reject as primary; fine as a curiosity later.
- **Debian as primary** — superb and huge in hosting/cloud, but `apt`/`ufw`/AppArmor train the
  *wrong muscles* for RHCSA. Keep it as the thing your Docker host happens to run.
- **OpenSUSE Leap** — excellent engineering (zypper, YaST, SUSE), but SUSE entry roles are rare
  outside SAP/Europe-enterprise. Low hiring probability for a first job. Reject.

**Risks & mitigations:** (a) RHEL-family `dnf` repos for some third-party tools lag Ubuntu →
mitigated by EPEL + you *want* that friction (it's real sysadmin work). (b) Tutorials online skew
Ubuntu → translating `apt`→`dnf`/`ufw`→`firewalld` is itself a learning rep, not a cost.

---

# DELIVERABLE 2 — Backup & Migration Plan (analysis; steps are in the PLAN)

**The migration question is answered by the file-safety requirement: you do NOT migrate.** The
correct strategy is **Option E — Hybrid, VM-first**, which never touches your files. Full reasoning
in §"VM Strategy" below; the *atomic* backup/verify/rollback steps live in the companion PLAN.

### File Safety Audit (what to back up vs leave vs export)
| Class | Examples | Action |
|---|---|---|
| **Irreplaceable** | personal docs, photos, projects, `~/.ssh`, password vault, code not on GitHub | **BACK UP (must)** — twice (3-2-1) |
| **Exportable config** | browser bookmarks/profiles, dotfiles, app settings, `~/.gnupg` | **EXPORT** to the backup set |
| **Reproducible** | OS, installed packages, caches, `/usr`, downloaded ISOs | **LEAVE** (re-installable) — just record a package list |
| **Secrets** | `~/.aws/credentials`, `.pem` keys, tokens | Back up **encrypted**, never into the public repo (Hard Rule #1) |

### Backup Strategy — 3-2-1 (the only rule that matters)
**3** copies, on **2** different media, with **1** off-site/cloud:
- **Copy 1 (local, primary):** external USB drive or second internal partition — full `rsync` of
  `/home` + an explicit "irreplaceable" set.
- **Copy 2 (different medium):** a second external drive **or** a cloud sync of just the
  irreplaceable set (encrypted).
- **Copy 3 (off-site):** cloud (Backblaze/rclone to any provider, or even a private GitHub repo
  for *code only*, or Proton/Google Drive for encrypted archives).
- Because the recommended path is **VM-first (no OS wipe)**, this backup is *insurance*, not a
  migration dependency — which is exactly why it's safe to start the lab immediately after it.

### Verification Strategy (never trust an unverified backup)
A backup you haven't restored from is a *hope*, not a backup. Verify with checksums + a real
restore test of a sample. (Exact commands — `sha256sum` manifests, `rsync --checksum` dry-run,
restore-one-file test — are atomic steps in the PLAN.)

### Rollback Plan (if anything ever fails)
Because the primary path never wipes the host, "rollback" is trivial: **delete the VM, restore
from snapshot, or re-clone.** The host is untouched. The only place you *could* lose data is if you
later choose dual-boot/replace — and the PLAN gates those behind a **verified, restore-tested**
backup *plus* a bootable recovery USB. Exact recovery runbook is in the PLAN.

---

# DELIVERABLE 3 — Home Lab Architecture (Dell E6540, 16 GB, i7, SSD)

**Design: a virtualised mixed-distro estate on the one laptop. Host OS stays as-is; the lab is VMs.**

```
  Host laptop (your daily OS — UNTOUCHED, files safe)
   └── Hypervisor:  KVM/virt-manager (if host is Linux)  |  VirtualBox (if Win/Mac)
        ├── vm-alma   (AlmaLinux 9, headless, 2 GB)   ← PRIMARY: RHCSA muscle, NaviOps "server"
        ├── vm-ubuntu (Ubuntu 24.04 LTS, headless, 2 GB) ← cloud/Docker reality, apt world
        └── vm-mgmt   (Alma or Ubuntu, 1.5 GB)        ← Ansible control node + monitoring (later)
   Total VM RAM ≈ 5.5 GB of 16 GB → comfortable; host keeps ~10 GB.
```

**Answers to the four design questions:**
- **How many VMs?** Start with **1** (`vm-alma`) for Lessons 02–08. Add **`vm-ubuntu`** when you
  start networking/SSH-between-hosts (Lesson ~09) so you have a 2-host network to practise on. Add
  **`vm-mgmt`** only when Ansible arrives (Month 2). Never run more than ~3 at once on 16 GB —
  keep them **headless (CLI only)** to stay light. This 2–3 host topology is also the exact shape
  of the RHCSA lab and of a real "control node + targets" Ansible setup → free portfolio realism.
- **Docker immediately?** **No — sequence it ~Week 3.** Docker before you're fluent in
  systemd/processes/networking hides the very fundamentals you're being hired for. Introduce it
  *inside `vm-alma`* (so you also meet `podman`, the RHEL-native, daemonless, rootless engine —
  an RHCSA-aligned bonus over Docker).
- **Kubernetes — delay?** **Yes, hard-delay past Day 90.** K8s is a mid/senior multiplier and a
  time sink that adds ~zero to a *first* SysAdmin/Support offer. A single-node `k3s` *taste* is a
  fine Month-3+ stretch goal, not a Phase-1 item.
- **AWS — now or later?** **Later, and time-boxed (~Week 5–8).** The Free Tier overhaul means the
  clock starts the moment you create the account: **$100 credits, ~6-month window.** Do *not* burn
  it on Day 1 fumbling. Build local Linux/Docker fluency first, *then* open AWS and spend the
  window on focused, billed-aware labs (IAM→EC2→VPC→S3→CloudWatch), tearing everything down nightly.

**Spare-machine upside (if the E6540 is a *second* machine you can wipe):** then *also* install
**AlmaLinux bare-metal** on it and treat it as the "production" NaviOps server, using VMs on your
daily laptop as the dev/test estate. Bare-metal gives you real disk/LVM/partitioning, boot, and
firmware reps that VMs fake. This is a strict upgrade — but only if those files are elsewhere.

---

# DELIVERABLE 4 — NaviOps Technical Architecture

NaviOps stays true to its constitution (an AI-assisted *operations* platform you build to learn).
The architecture below is the **technical skeleton each lesson fills in** — so every lesson ships a
real component, never a toy:

```
NaviOps/
  scripts/        Bash automation — the platform's "hands"
    healthcheck.sh        (Wk1)  disk/mem/cpu/service/login report → writes docs/reports/
    user-audit.sh         (Wk2)  who has sudo, stale accounts, bad SSH perms, password age
    log-triage.sh         (Wk3)  journald/auth.log scan → top errors, failed logins, anomalies
    backup.sh             (Wk3)  rsync + checksum + retention — dogfoods your own 3-2-1 rule
  infra/
    compose/              (Wk3+) Docker/Podman Compose: a monitored sample service stack
    ansible/              (Mo2)  inventory + playbooks: harden + configure vm-alma & vm-ubuntu
    terraform/            (Mo2)  AWS: IAM/VPC/EC2/S3/CloudWatch — plan/apply, state gitignored
  .github/workflows/      (Mo2)  CI: shellcheck + ansible-lint + terraform validate on every PR
  docs/                   living memory + lessons + runbooks (already scaffolded)
```

**Design principles (each maps to a hiring signal):**
- **Bash-first, then declarative.** Hand-rolled scripts teach the OS; Ansible/Terraform later teach
  *idempotence & IaC* — and the contrast ("I replaced my `setup.sh` with an Ansible role because…")
  is a senior-sounding interview story.
- **Everything is version-controlled from Lesson 02.** Each lesson = a branch + PR (mirrors a real
  GitOps change-review workflow; satisfies the "Git every lesson" rule already in PROJECT_MISSION).
- **The platform monitors the lab it runs on.** `healthcheck.sh` runs on `vm-alma`, reports get
  committed (redacted) → you literally operate infrastructure, which is the whole pitch.
- **SELinux/firewalld stay enforcing.** Don't `setenforce 0`. Hitting and *solving* SELinux denials
  is RHCSA gold and the #1 thing Ubuntu-only juniors can't do.

---

# DELIVERABLE 7 — Skills Gap Analysis

Your listed skills (Linux, Bash, Networking, Docker, AWS, Monitoring, Logging, Security) are a
**strong core but incomplete** for 2026 hiring. The constitution already added Git, Ansible, CI,
Terraform (D5) — good. Remaining gaps, with the *why* and where they slot:

| Skill | Have it? | Why it's required (2026) | Slots into |
|---|---|---|---|
| **Git/GitHub** | ✅ added (D5) | Baseline; 73% of managers want cloud/container/VCS fluency | Lesson 02 (next) |
| **SELinux** | ⚠️ implied | The RHCSA differentiator; Ubuntu-juniors can't do it | Wk2–3 on vm-alma |
| **firewalld** | ⚠️ implied | RHEL firewall; pairs with SELinux | Wk2–3 |
| **systemd (units/timers)** | ❌ gap | Replace cron with timers; write a unit for your script | Wk2 |
| **Podman** | ❌ gap | RHEL-native containers (rootless/daemonless); RHCSA-adjacent | Wk3 alongside Docker |
| **Ansible** | ✅ added (D5) | Config mgmt is now a *junior* expectation | Month 2 |
| **Terraform/IaC** | ✅ added (D5) | Cloud provisioning standard | Month 2 |
| **CI/CD (GH Actions)** | ✅ added (D5) | Even sysadmins lint/test infra in CI now | Month 2 |
| **Incident Response** | ❌ gap | "Walk me through an outage" is *the* interview question | Wk4 + Month 2 (runbook) |
| **Backup/Restore ops** | ⚠️ partial | You're literally living it — formalise it as `backup.sh` | Wk3 |
| **Monitoring/alerting** | ❌ gap | Prometheus/Grafana or even CloudWatch alarms | Month 2 |
| **Networking hands-on** | ⚠️ theory | Don't stop at OSI theory — `ss`, `tcpdump`, `nmcli`, routing between VMs | Wk... |
| **Ticketing / soft skills** | ❌ gap | Support roles hire on *communication*; your `docs/` write-ups prove it | continuous |

**The single biggest gap is Incident Response storytelling.** Juniors get hired on "tell me about a
time something broke and what you did." NaviOps must manufacture ≥2 real incidents (break a service,
fill a disk, lock yourself out via SELinux) and document the fix as a runbook. That's the plan's
Week-4 capstone.

---

# DELIVERABLE 8 — Hiring Market Analysis (role ranking)

Ranked for *your* profile (career-changer, building a public portfolio, EU-ish, remote-wanting):

| Rank | Role | Hiring prob. | Remote | Competition | Salary (entry) | Fit for you |
|---|---|---|---|---|---|---|
| **1** | **Linux Support Engineer** | **Highest** | High | Medium | Solid | **Best first door** — hires on troubleshooting + communication, which your `docs/`/runbooks prove. Tolerant of no-degree/career-change. |
| **2** | **Junior Linux SysAdmin** | High | Medium | Medium | Solid (~$42–62/hr US data) | Your stated target; NaviOps is purpose-built for it. RHCSA-aligned. |
| **3** | **Cloud Support Engineer** | High | **Highest** | Medium-High | Good | Most remote-friendly; needs the AWS phase done. Great #2 target once Week-8 AWS labs ship. |
| **4** | **Infra Operations Engineer** | Medium | Medium | Medium | Good | Natural 6–12 mo progression from #1/#2. |
| **5** | **Junior DevOps** | Lower (as *first* job) | High | **Highest** | Highest | Most competitive entry; the data says sysadmin→DevOps is a 6–12 mo on-ramp. **Aim here second**, not first. |

**Strategy: target #1/#2 to *land*, position toward #3 for *remote*, grow into #4/#5.** Apply to
Support and SysAdmin roles the moment Week-4 capstone ships; treat DevOps as the 6-month goal, not
the entry point. Sources: ziprecruiter/dice/glassdoor entry-Linux data, dev.to DevOps on-ramp. [see refs]

---

# DELIVERABLE 9 — Interview Readiness Plan

You become interviewable when you can do three things *from memory, no notes*:
1. **Whiteboard NaviOps' architecture and the *why*** behind each choice (this EXP + `DECISIONS.md`
   is your script). "Why AlmaLinux not Ubuntu?" → you have the §1 answer cold.
2. **Tell 2–3 incident stories** in STAR form (Situation-Task-Action-Result) from your real lesson
   log — the disk-fill, the SELinux lockout, the broken service you fixed.
3. **Live-troubleshoot** common scenarios out loud: "service won't start" (`systemctl status` →
   `journalctl -xeu` → config → SELinux → port), "disk full" (`df`/`du`/`lsof +L1`), "can't SSH"
   (perms `600`, `sshd` config, firewall, key).

**Readiness gates (tie to the roadmap):** after Week 4 you can do #1 and #2 for Linux fundamentals;
after Month 2 you add cloud/Docker/IaC stories. Each lesson's existing **Quiz + Reflection** steps
*are* mock-interview reps — lean into answering them aloud. Build a one-page `INTERVIEW.md` of your
top 20 Q&A as you go (added to the plan).

---

# DELIVERABLE 10 — Portfolio Strategy

Your portfolio is **NaviOps itself**, made legible to a hiring manager who spends 30 seconds:
1. **README that sells in 30 seconds** — what NaviOps is, a screenshot of a `healthcheck.sh`
   report, the skills matrix, "built in public over N days." (Refresh it at each milestone.)
2. **Green commit history** — a commit/PR per lesson proves consistency and Git fluency (the D5
   rule already enforces this). **Push to GitHub after Lesson 02** so this becomes visible.
3. **Per-milestone `PORTFOLIO.md`** (already in your Gate Rule): resume bullets + interview talking
   points, framed for SysAdmin/Support/Cloud/DevOps.
4. **Runbooks as proof of operations thinking** — the incident write-ups are the rarest, most
   convincing junior artifact. Most juniors have tutorials; you'll have *operations docs*.
5. **A pinned, MIT-licensed public repo** is your "experience" line when you have no job experience.

**Resume bullet pattern (evidence-backed):** *"Built NaviOps, a public Linux operations platform:
authored Bash health-check/audit tooling, hardened RHEL-family + Ubuntu hosts (SELinux, firewalld,
SSH), provisioned AWS via Terraform, and documented incident-response runbooks — all version-
controlled with PR review and CI."* Every clause is a thing you'll have actually done by Day 90.

---

# CERTIFICATION STRATEGY (skills → portfolio → certs)

**Default holds: build skills, build portfolio, *then* certify.** Ranked by ROI for your goal:

| Cert | ROI | When | Master first |
|---|---|---|---|
| **RHCSA (EX200)** | **Highest** | **~Day 75–120**, after Month-2 skills land | systemd, dnf, SELinux, firewalld, LVM/storage, users, SSH, networking — *all of which the roadmap already teaches you on AlmaLinux*. You'll be ~80% ready "for free." |
| AWS Cloud Practitioner | Medium-high (cheap, ~$100, fast) | Optional, ~Week 8 after AWS labs | IAM/EC2/VPC/S3/CloudWatch basics — also taught by the roadmap |
| CompTIA Linux+ / LPIC-1 | Medium | Only if a target listing demands it | Overlaps RHCSA but distro-neutral; lower ceiling. Skip if RHCSA-bound. |
| RHCE / CKA / Terraform Assoc. | Defer | Month 4+ | Ansible automation / K8s / IaC — mid-level multipliers |

**Why this order:** RHCSA is performance-based (you fix a live broken system), so the *skills are
the prep*. Building NaviOps on AlmaLinux **is** RHCSA study. Sitting it ~Day 90 converts work you'd
do anyway into a credential — that's the highest ROI move available. Don't pay for it on Day 1.

---

## Scorecard

| Dimension | Call | Confidence |
|---|---|---|
| Primary OS | AlmaLinux 9 (Rocky equal) + Ubuntu LTS secondary | High |
| Migration | None — Hybrid VM-first, host untouched | High |
| Lab | 1→3 headless VMs on the laptop; bare-metal if E6540 is spare | High |
| Docker | Week ~3, with Podman | High |
| Kubernetes | Defer past Day 90 | High |
| AWS | Week ~5–8, time-boxed (6-mo Free Plan clock) | High |
| First role target | Linux Support → Junior SysAdmin | Medium-High |
| Top cert | RHCSA ~Day 90, skills-first | High |
| Biggest gap | Incident-response storytelling + SELinux | High |

## Backlog → see companion PLAN
- Backup → Verify → (optional second VM) → Lesson 02 push → Week-by-week roadmap → AWS time-box →
  RHCSA sit. All sequenced as atomic, rollback-bearing steps in:
  `docs/reports/PLAN/PLAN_2026-06-10_Backup-Migration-and-30-90-Roadmap.md`.

## References
- Distro/enterprise share: https://commandlinux.com/statistics/most-popular-linux-distributions-market-share/ · https://commandlinux.com/statistics/centos-alternatives-adoption-almalinux-rocky-linux/ · https://fosspost.org/linux-server-market-share-statistics/
- Alma vs Rocky: https://www.techtarget.com/searchdatacenter/tip/Rocky-Linux-vs-AlmaLinux-Which-is-better · https://tuxcare.com/blog/almalinux-vs-rocky-linux/
- Entry Linux market/skills: https://www.linuxcareers.com/resources/blog/2025/11/linux-career-opportunities-in-2025-skills-in-high-demand/ · https://www.ziprecruiter.com/Jobs/Linux-Entry-Level · https://www.coursera.org/articles/linux-career-path
- RHCSA ROI: https://certdemand.com/certs/rhcsa · https://electromech.cloud/blogs/is-red-hat-certification-still-valuable-2026/
- AWS Free Tier 2026: https://aws.amazon.com/blogs/aws/aws-free-tier-update-new-customers-can-get-started-and-explore-aws-with-up-to-200-in-credits/ · https://aws.amazon.com/free/free-tier-faqs/ · https://www.neowin.net/news/aws-free-tier-overhauled-new-users-get-200-in-credits-but-theres-a-catch/
- DevOps on-ramp: https://dev.to/_d7eb1c1703182e3ce1782/devops-career-guide-2026-entry-points-skills-and-roadmap-for-engineers-14m9

---
**Say `PLAN` is already done** → see the companion PLAN report for the executable steps.
