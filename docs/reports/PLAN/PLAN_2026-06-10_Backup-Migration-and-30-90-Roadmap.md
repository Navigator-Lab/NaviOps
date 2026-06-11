# PLAN — Backup/Migration + 30-Day & 90-Day Employability Roadmap

**Date:** 2026-06-10 · **Mode:** PLAN (forward-only blueprint) · **Tier:** Enterprise
**Requires EXP:** `docs/reports/EXP/EXP_REPORT_2026-06-10_NaviOps-Career-Strategy.md`
**Protocol:** P01 · **Safety:** every destructive step gates on a *verified, restore-tested* backup.

<success_criteria>
A junior can execute these steps in order, each atomic (one action, one verify, one rollback),
without ever risking the irreplaceable files, and reach "Linux-Support-interviewable" by Day ~30
and "SysAdmin + cloud + RHCSA-ready" by Day ~90.
</success_criteria>

<output_contract>
Phase A = Backup & Verify (do first, ~half a day). Phase B = Lab Bring-up (VM-first, host
untouched). Phase C = 30-Day Roadmap (weekly, lesson-mapped). Phase D = 90-Day Roadmap. Phase E =
the rollback/recovery runbook. Forward-only: this is a blueprint to execute, not a changelog.
</output_contract>

> **HITL gate (Axiom 6):** This PLAN is a blueprint. Execute it step-by-step in normal sessions
> (each lesson via `/navi`, under the Gate Rule). Nothing here is auto-run. No `git push`,
> `terraform apply`, or OS write happens without your explicit go on that specific command.

---

## PHASE A — Backup & Verify (do this before anything else; ~3–4 hrs)

> Even though the recommended path (VM-first) never wipes your host, you back up **first** so that
> (a) you're safe regardless, and (b) `backup.sh` later in the roadmap dogfoods a process you've
> already lived. 3-2-1: 3 copies, 2 media, 1 off-site.

**A1 — Inventory the irreplaceable set.**
- BEFORE: files scattered, no list. AFTER: one explicit list of what must survive.
- Action: list your must-keep paths (personal docs, photos, `~/.ssh`, code not on GitHub, password
  vault export, browser bookmarks, `~/.gnupg`, `~/.aws` if it exists).
- `-> verify:` `du -sh` each path resolves and totals a sane size; save the list to
  `~/backup-manifest.txt` (kept locally, **not** committed — it may name private paths).
- Rollback: n/a (read-only).

**A2 — First copy to an external drive (rsync).**
- BEFORE: data only on the laptop SSD. AFTER: a full copy on external drive #1.
- Action: `rsync -aAXH --info=progress2 /home/<you>/ /mnt/backup1/home-YYYYMMDD/`
  (plus any out-of-home paths from A1).
- `-> verify:` `rsync -aAXH --checksum --dry-run /home/<you>/ /mnt/backup1/home-YYYYMMDD/`
  prints **no file diffs** (empty = identical).
- Rollback: delete the copy; source untouched (rsync without `--delete` never harms the source).

**A3 — Checksum manifest (proof of integrity).**
- BEFORE: copy exists but unverified bit-for-bit. AFTER: a checksum manifest you can re-check anytime.
- Action (on the *irreplaceable* subset): `cd /mnt/backup1/home-YYYYMMDD && find . -type f -print0 | xargs -0 sha256sum > ../manifest-YYYYMMDD.sha256`
- `-> verify:` `sha256sum -c ../manifest-YYYYMMDD.sha256 | grep -v ': OK$'` returns **nothing**.
- Rollback: delete the manifest; harmless.

**A4 — Real restore test (the step everyone skips — don't).**
- BEFORE: you *hope* the backup restores. AFTER: you've proven one file restores correctly.
- Action: copy one known file from the backup to `/tmp/restore-test/` and diff it against the original.
- `-> verify:` `diff <original> /tmp/restore-test/<file>` is empty (identical).
- Rollback: `rm -rf /tmp/restore-test`.

**A5 — Off-site copy #3 (encrypted).**
- BEFORE: both copies are in your house (fire/theft = total loss). AFTER: one copy off-site.
- Action: encrypt the irreplaceable set and sync off-site — e.g.
  `tar -czf - <paths> | gpg -c > irreplaceable-YYYYMMDD.tar.gz.gpg` then upload via `rclone` to any
  cloud remote (or Proton/Drive). Code-only can also go to a **private** GitHub repo.
- `-> verify:` re-download the archive, `gpg -d | tar -tzf -` lists the files without error.
- Rollback: delete the remote object; nothing local changes.
- ⚠️ **Hard Rule #1:** the public NaviOps repo never receives any of this. Secrets stay encrypted/off-repo.

**Gate:** Phases B–D may proceed once A2+A3+A4 pass. Phase E (dual-boot/replace) additionally
requires A5 **and** a tested recovery USB (E-prep).

---

## PHASE B — Lab Bring-up (VM-first; host OS untouched)

**B1 — Install a hypervisor on the host.**
- Linux host → `KVM` + `virt-manager` (`dnf`/`apt` install `qemu-kvm libvirt virt-manager`).
  Win/Mac host → **VirtualBox** (free).
- `-> verify:` `virsh list --all` (KVM) or VirtualBox GUI opens; CPU virtualization confirmed
  (`egrep -c '(vmx|svm)' /proc/cpuinfo` > 0 on Linux).
- Rollback: uninstall the package; host otherwise unchanged.

**B2 — Create `vm-alma` (AlmaLinux 9, headless, 2 GB / 2 vCPU / 20 GB disk).**
- Download AlmaLinux 9 ISO (verify its checksum against the project's published value first).
- `-> verify:` VM boots to login; `cat /etc/os-release` shows AlmaLinux 9; `getenforce` = `Enforcing`.
- **Snapshot it now** named `clean-install` — this is your zero-cost rollback for every future lesson.
- Rollback: revert to `clean-install` snapshot, or delete the VM. Host untouched.

**B3 — (When networking lessons arrive, ~Wk2–3) add `vm-ubuntu` (Ubuntu 24.04 LTS, headless).**
- `-> verify:` both VMs ping each other on a host-only/NAT network; `ssh` between them works.
- Rollback: delete `vm-ubuntu`; `vm-alma` and host unaffected.

> From here, **every lesson = snapshot → do the work → if broken, revert.** That's why VMs beat
> dual-boot for learning: breaking the system *is the lesson*, and recovery is one click.

---

## PHASE C — 30-Day Roadmap (Junior Linux Support / SysAdmin interviewable)

Each week is run as Gate-Rule lessons via `/navi`, on `vm-alma`, producing a real NaviOps component
+ a branch/PR (push enabled after Lesson 02). "Ship" = the artifact committed (redacted).

### Week 1 — Linux fluency + first platform script
- **Lesson 02 — Git/GitHub** (already queued): branch + small change + **first push** of NaviOps.
  → *Ship:* repo is public; commit/PR habit established.
- **Lessons 03–04 — Users/groups/sudo · Processes/systemd/journald.** Write a `systemd` unit + timer.
  → *Ship:* `scripts/healthcheck.sh` v1 (disk/mem/cpu/services/logins) run by a systemd timer on vm-alma.
- `-> verify:` `systemctl status naviops-healthcheck.timer` active; a report lands in `docs/reports/`.
- Spaced-review the 3 flagged Lesson-01 items during reflections.

### Week 2 — Security fundamentals (the RHEL differentiator)
- **Lessons 05–06 — SSH hardening · SELinux + firewalld.** Harden vm-alma's `sshd`; hit a real
  SELinux denial and fix it with `ausearch`/`semanage` (don't disable it); open a service port with
  `firewall-cmd`.
  → *Ship:* `scripts/user-audit.sh` (sudo holders, stale accounts, weak SSH perms, password age).
- `-> verify:` `getenforce`=Enforcing with your service working; `firewall-cmd --list-all` shows the
  intended ports; audit script flags a planted bad-permission file.

### Week 3 — Bash automation + containers + backups
- **Lessons 07–08 — Bash (functions/args/error handling/logging) · Docker+Podman.** Containerise a
  sample service (e.g. a small web/monitoring app) with Compose; meet `podman` rootless on vm-alma.
  → *Ship:* `scripts/log-triage.sh`, `scripts/backup.sh` (rsync+checksum+retention — your own 3-2-1),
  `infra/compose/` sample stack.
- `-> verify:` `shellcheck scripts/*.sh` clean; `docker compose up` serves the app; `backup.sh`
  produces a verified checksum manifest.

### Week 4 — Networking + the Incident-Response capstone (the hiring clincher)
- **Lessons 09–10 — Networking hands-on (`ss`, `tcpdump`, `nmcli`, routing vm-alma↔vm-ubuntu) ·
  Incident Response.** Deliberately break things (fill the disk; stop a service; cause an SSH/SELinux
  lockout), diagnose live, and write the fix as a runbook.
  → *Ship:* `docs/learning/lessons/.../runbooks/` with ≥2 STAR-form incident write-ups + an
  `INTERVIEW.md` (top-20 Q&A). Milestone `PORTFOLIO.md` (resume bullets + talking points).
- `-> verify:` you can narrate each incident from memory in STAR form; runbooks reproduce the fix.

**Day-30 Definition of Done (maps to PROJECT_MISSION Junior DoD):** users/systemd/journald without
help · Git PR workflow · a real Bash script with error handling · firewall + SELinux basics · a
Compose service troubleshot · ≥1 documented incident · NaviOps has ≥4 working scripts + a public repo.
→ **Start applying to Linux Support / Junior SysAdmin roles now.**

---

## PHASE D — 90-Day Roadmap (SysAdmin + Cloud + IaC + RHCSA-ready)

### Weeks 5–8 — AWS (time-boxed; the Free-Plan clock starts on account creation)
> ⚠️ New AWS accounts: **$100 credits, Free Plan expires in ~6 months or when credits run out.**
> So: open the account only when you're ready to *use* it, and **tear everything down nightly.**
- **IAM** (users/roles/policies, MFA, least privilege) → **EC2** (launch an AlmaLinux AMI, SSH in) →
  **VPC + Security Groups** (subnets, routing — mirrors your VM networking) → **S3** (back up
  NaviOps reports; lifecycle rules) → **CloudWatch** (metrics + an alarm on your EC2).
  → *Ship:* a real EC2-hosted NaviOps node + CloudWatch alarm; S3 as off-site backup target.
- `-> verify:` you can launch/secure/terminate an instance and explain the bill; `aws sts get-caller-identity`
  works under a least-priv IAM user. **Free Skill Builder:** "AWS Cloud Practitioner Essentials",
  "Getting Started with Compute/Storage/Networking" — *after* doing the lab, to consolidate.
- Rollback/cost-safety: `terraform destroy` or console-terminate nightly; set an AWS **Budget alert** at $5.

### Weeks 9–12 — Config Mgmt + IaC + CI + Observability
- **Ansible** — inventory of vm-alma/vm-ubuntu; playbook that re-creates your Week-1–4 hardening
  idempotently (replace `setup.sh` with a role — the interview story).
- **Terraform** — codify the Week-5–8 AWS resources; `plan`/`apply`/`destroy`; state gitignored.
- **GitHub Actions** — CI that runs `shellcheck` + `ansible-lint` + `terraform validate` on every PR.
- **Monitoring** — Prometheus + Grafana (or CloudWatch) on the Compose stack; one real alert.
  → *Ship:* `infra/ansible/`, `infra/terraform/`, `.github/workflows/ci.yml`, a monitoring dashboard,
  a 3rd milestone `PORTFOLIO.md`.
- `-> verify:` a fresh `vm` configured end-to-end by `ansible-playbook` with zero manual steps; CI
  green on a PR; an alert fires on a simulated outage.

### ~Day 75–120 — Sit RHCSA (skills-first payoff)
- By now you've *done* systemd, dnf, SELinux, firewalld, LVM/storage, users, SSH, networking on
  AlmaLinux → you're ~80% RHCSA-ready from project work alone. Do 2–3 weeks of timed practice on the
  EX200 objective list, then book it (~$400).
- `-> verify:` pass timed practice scenarios (fix-a-broken-system style) before paying for the exam.

### Application-Trigger Map — when to apply for which role (added 2026-06-10, single-laptop confirmed)
> Strategy for a *fast* first job: **apply in waves; don't wait for Day 90.** Public repo + runbooks
> substitute for experience. Each milestone *widens* the role net — it doesn't replace the prior one.

| Milestone | ~Day | Skills gathered | ✅ Apply for |
|---|---|---|---|
| **M0 Foundations** | 0–7 | Git/GitHub, users/sudo, systemd/journald, public repo live | Build LinkedIn+CV; watch boards (not yet applying) |
| **M1 Support-ready** 🎯 | ~14 | + SSH hardening, SELinux/firewalld, `healthcheck.sh`/`user-audit.sh` | **Help Desk T2 (Linux) · IT/Linux Support Engineer · NOC Tech · Junior SysAdmin (entry)** — fastest first paycheck; **start applying** |
| **M2 SysAdmin-ready** 🎯 | ~30 | + Docker/Podman, networking hands-on, log triage, backups, **2 incident runbooks** | **Junior Linux SysAdmin · Infra Support · Linux Support (stronger) · Datacenter Tech** |
| **M3 Cloud-capable** | ~60 | + AWS IAM/EC2/VPC/S3/CloudWatch, Terraform+Ansible basics, CI | **Cloud Support Engineer (AWS) · Junior Cloud/Infra Engineer** — most remote-friendly |
| **M4 Infra/DevOps-leaning** | ~90 | + monitoring stack, full IaC, **RHCSA passed** | **Infra Operations Engineer · Cloud Engineer · Junior DevOps · Platform/SRE (junior)** |

**Fast-first-role tactics:** push repo public after Lesson 02 · lead CV with NaviOps (not "seeking
role") · apply broad at M1 (Support/Help-Desk = highest volume, lowest bar) · the 2 incident
runbooks (M2) are the interview weapon. Applying is a **parallel track from ~Day 14**, not a final step.

**Single-laptop note (16 GB, confirmed only machine):** run VMs **headless** (no GUI, `ssh` in).
1 VM (`vm-alma`, 2 GB) always-on; 2 VMs only during networking labs (close browser first); avoid 3
(use a container or a brief 3rd VM for the Month-2 Ansible target). KVM if host is Linux, else
VirtualBox. Snapshot `clean-install` after each VM build → every lesson is one-click-recoverable.

**Day-90 Definition of Done (maps to Mid-Level DoD):** multi-service Compose stack with monitoring ·
real AWS infra provisioned+destroyed via Terraform · multi-host log/incident RCA documented ·
NaviOps runs automated health checks + reports · ≥3 portfolio milestones with resume bullets · RHCSA
booked/passed. → **Apply to SysAdmin / Cloud Support / Infra Ops; position toward DevOps (6-mo goal).**

---

## PHASE E — Rollback / Recovery Runbook

**Everyday (VM) rollback — zero risk:**
- Lesson broke vm-alma? `virsh snapshot-revert vm-alma clean-install` (or VirtualBox "restore
  snapshot"). Host and files untouched. This is why VM-first wins.

**If you ever choose dual-boot/replace later (gated — not the recommended path):**
1. **Pre-req:** A2+A3+A4+A5 all passed *and* you've made a **bootable live-USB** (e.g. Ventoy +
   AlmaLinux/Ubuntu ISO) and **booted it once successfully** (proves recovery works before you need it).
2. If install fails / system won't boot:
   - Boot the live USB → mount the old disk → confirm `/home` still readable (it usually is).
   - If the disk is intact: copy anything newer than your last backup off it now.
   - If the disk is wiped: restore from external drive #1 (A2), verify against the manifest (A3),
     and pull the off-site copy (A5) if the drive is also lost.
3. `-> verify recovery:` `sha256sum -c manifest-YYYYMMDD.sha256` on the restored data returns all-OK.

**Golden rule:** never run an installer that writes to disk until a **restore-tested** backup (A4)
and a **booted** recovery USB both exist. Until then, stay VM-only — which costs you nothing.

---

## Decisions to log (→ `docs/DECISIONS.md`)
- **D6:** Primary learning OS = AlmaLinux 9 (Rocky equal), Ubuntu LTS as required secondary —
  proven by RHEL=43% enterprise-server share + RHCSA alignment vs Ubuntu's cloud dominance (EXP §1).
- **D7:** Migration strategy = Hybrid VM-first; host never wiped. Dual-boot/replace gated behind
  verified+restore-tested backup + booted recovery USB.
- **D8:** Sequencing locks: Docker Wk3 (with Podman), AWS Wk5–8 (Free-Plan 6-mo clock), K8s deferred
  past Day 90, RHCSA ~Day 75–120 skills-first.
- **D9:** First-role target = Linux Support → Junior SysAdmin (land), Cloud Support (remote), DevOps
  (6-mo goal) — per market ranking (EXP §8).

## Next action
Execute **Phase A** (backup) this session or next, then resume **Lesson 02** (already queued in
`LEARNING_STATE.md`) as Week-1 step one. Run each lesson with `/navi` under the Gate Rule.
