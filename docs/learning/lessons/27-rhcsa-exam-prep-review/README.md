# Lesson 27 — RHCSA Exam Prep & Curriculum Review

**Status:** ready for self-study · **Date written:** 2026-06-11
**Gate Rule:** Concept → Real-World Use → Alternatives → Hands-On → Verification → Quiz → Reflection → Search Keywords

> **How to use this lesson:** the **final lesson**. This is a **mapping and
> gap-analysis** exercise — RHCSA's EX200 objectives are mapped against
> Lessons 01-26, gaps are identified for targeted drilling, and a study plan
> is built. This lesson does not introduce major new concepts; it
> **organizes and consolidates** what you've already learned into
> certification-exam form.

---

## Step 1 — Concept

### What it is

The **RHCSA (Red Hat Certified System Administrator) EX200** exam is a
**performance-based** (hands-on, not multiple-choice) certification covering
core Linux system administration on RHEL. Per [Red Hat's official EX200
page](https://www.redhat.com/en/services/training/ex200-red-hat-certified-system-administrator-rhcsa-exam)
and [dotlinux's RHCSA study
objectives](https://www.dotlinux.net/blog/study-objectives-for-the-rhcsa-exam-preparation-guide/),
the exam covers four domains: **Basic System Management** (files,
permissions, users/groups, networking), **Operating Running Systems**
(software/process/storage management, systemd, cron, logging), **Advanced
System Administration** (boot/kernel troubleshooting, bash scripting), and
**Managing Network Services** (SSH, firewalls, time services, Apache, SELinux,
network storage, containers).

### Why it exists

You've spent 26 lessons building **practical, project-based** skills — but
RHCSA validates a **specific, standardized subset** of Linux fundamentals
under exam conditions (timed, no internet, performance-based tasks). Many of
your lessons cover RHCSA objectives **and go beyond them**; a few RHCSA
objectives (LVM, SELinux contexts, GRUB2/boot troubleshooting, NFS) were
**touched on lightly or not at all** — this lesson identifies exactly which.

### What problem it solves

| Problem | Solution |
|---|---|
| "I've done 26 lessons — am I ready for RHCSA?" | This lesson's mapping table shows exactly what's covered vs. what needs dedicated practice |
| "RHCSA is hands-on/timed — my lessons were untimed/exploratory" | Step 4's drilling exercises are timed, exam-style tasks |
| "I never did LVM, SELinux contexts, or GRUB2 troubleshooting in depth" | Identified as gaps below — dedicated practice tasks provided |
| "What should I review first with limited time before the exam?" | Priority ordering based on gap analysis |

### Three-Level Depth (Lens A)

- **Level 1 — Beginner:** RHCSA is **performance-based** — you're given a
  fresh VM and a list of tasks ("create a user with these properties",
  "configure this service to start on boot") and must complete them
  correctly within the time limit. There's no partial credit for "I know the
  command but typo'd it."
- **Level 2 — SysAdmin:** Per [the RHCSA EX200 study
  guide](https://www.dotlinux.net/blog/study-objectives-for-the-rhcsa-exam-preparation-guide/),
  effective prep means **recreating exam objectives daily** under time
  pressure — e.g., "today: create a PV, VG, LV, format as XFS, mount
  persistently — in under 10 minutes." Per [Sander van Vugt's RHCSA 9 cert
  guide](https://www.sandervanvugt.com/red-hat-rhcsa-9-cert-guide-ex200/),
  identifying your **weak areas** through practice (not just reading) is the
  highest-value prep activity — which is exactly this lesson's gap-analysis
  approach.
- **Level 3 — Systems/Kernel (Lens D):** Several RHCSA objectives are
  **deliberately deeper at the kernel/boot level** than this curriculum has
  gone: **GRUB2/boot troubleshooting** (resetting root password via
  `rd.break` — interrupting the boot process before `init`/`systemd` starts,
  dropping into an emergency shell with the root filesystem mounted
  read-only, requiring `mount -o remount,rw /sysroot`), **`dracut -f`**
  (regenerating the initramfs — the temporary root filesystem the kernel uses
  before mounting the real root, Lesson 04's boot sequence taken one level
  deeper), and **SELinux contexts** (`ls -Z`, `chcon`, `restorecon`,
  `semanage fcontext` — Lesson 10 covered SELinux/AppArmor *conceptually* as
  LSMs, but RHCSA requires *hands-on* context troubleshooting: "why does
  Apache get 'permission denied' on a file with correct Unix permissions?" →
  wrong SELinux context).

### Analogy (Lens B)

- **This lesson's mapping table** = a pre-flight checklist cross-referenced
  against your actual flight hours logbook — "you have 200 hours total, but
  only 2 hours of night landings (an exam requirement) — here's where to
  focus before your check ride."
- **GRUB2/`rd.break` recovery** = knowing how to get into a building when the
  normal front-door key (systemd boot) doesn't work — an emergency
  maintenance access point that bypasses normal startup, used carefully and
  put back exactly as found.
- **SELinux context troubleshooting** = a building where doors check **two**
  things to let you through: your keycard's permissions (Unix permissions,
  familiar from Lesson 04) **and** a separate "zone label" on both you and
  the door (SELinux context) — both must match, and Lesson 10 taught you the
  zone-label *concept* exists, but RHCSA requires you to actually **read and
  fix mismatched zone labels**.

The "pre-flight checklist" analogy holds well — this lesson genuinely *is*
that checklist, not a new concept requiring a "breaks down" caveat.

---

## Step 2 — Real-World Use

### Curriculum → RHCSA Objective Mapping

| RHCSA EX200 Domain/Objective | Covered in | Status |
|---|---|---|
| Access a shell, run commands, file management (`cp`/`mv`/`find`/links) | Lessons 01-03 | ✅ Strong |
| Users/groups, permissions (chmod/chown/umask/sudo) | Lessons 03-04 | ✅ Strong |
| Bash scripting (loops, conditionals, `set -euo pipefail`) | Lessons 03, 06, 07 | ✅ Strong |
| systemd: services, targets, units | Lesson 05 | ✅ Strong |
| Scheduling (cron, `at`, systemd timers) | Lesson 06 | ✅ Strong |
| Logging (`journalctl`) | Lessons 05, 19 | ✅ Strong |
| Process management, signals | Lesson 04 | ✅ Strong |
| Software management (`dnf`/`rpm`) | Lessons 01-02 (Linux fundamentals) | ⚠️ Practiced on Debian/Ubuntu — RHCSA uses `dnf`/RHEL |
| Storage: partitions, filesystems, mounts, `/etc/fstab` | Lesson 07 | ⚠️ Partial — **LVM not covered** |
| Network configuration (`nmcli`, IP/routing) | Lessons 08-09 | ✅ Strong |
| SSH configuration/hardening | Lesson 07 | ✅ Strong |
| Firewalls (`firewalld` specifically) | Lesson 09 (covered `ufw`/`iptables`) | ⚠️ RHCSA uses `firewalld` — not directly practiced |
| SELinux (booleans, contexts, troubleshooting) | Lesson 10 | ⚠️ Conceptual only — **hands-on contexts not practiced** |
| Containers (`podman`) | Lessons 11-12 (Docker) | ⚠️ RHCSA uses `podman` — concepts transfer, syntax differs |
| Boot process, GRUB2, kernel/initramfs troubleshooting | Lesson 04 (conceptual) | ❌ **Gap — not hands-on practiced** |
| Network storage (NFS, autofs) | Not covered | ❌ **Gap** |
| Apache HTTPD basic configuration | Not covered (Traefik/Nginx in Lessons 21/24) | ❌ **Gap — RHCSA specifically wants `httpd`** |
| Time synchronization (`chronyd`) | Not covered | ❌ **Gap** |

### How this maps to your job search

Per your locked NaviOps strategy decisions: RHCSA validates the Linux
fundamentals (Lessons 01-10) that underlie **everything** else you built —
an interviewer seeing "RHCSA + this 26-lesson portfolio + capstone chaos
project" sees both the **standardized credential** and the **practical,
beyond-the-standard** depth. The gaps identified above (LVM, SELinux
contexts, `firewalld`, GRUB2, NFS, `httpd`, `chronyd`, `podman`) are **all
RHEL-specific or exam-specific tooling differences** — not new *concepts* —
your underlying understanding (permissions, services, networking, storage)
transfers directly.

### Common mistakes (exam-specific)

| Mistake | Impact | Fix |
|---|---|---|
| Not practicing on actual RHEL/AlmaLinux/Rocky (using only Ubuntu/Debian) | `dnf` vs `apt`, `firewalld` vs `ufw`, SELinux vs AppArmor — syntax differences cost time under pressure | Do Step 4's drills on AlmaLinux/Rocky specifically (free RHEL-compatible) |
| Forgetting to make changes **persistent** (survive reboot) | A task that "works now" but doesn't survive reboot fails the exam | Always: `/etc/fstab` for mounts, `systemctl enable` for services, `nmcli con mod` (not just `ip addr add`) for network config |
| Not verifying work before moving on | Errors compound; partial credit is limited | After each task, verify exactly as Lesson 03's "Verification" step taught — habit transfers directly |
| Spending too long on one task | Time runs out before easier tasks are attempted | Time-box practice attempts (Step 4) — skip and return if stuck |
| Forgetting `restorecon`/`semanage` after manually moving files (SELinux context not inherited) | Service fails with "permission denied" despite correct Unix permissions | Always check `ls -Z` after moving files into service directories |

### Interview Angle

**Scenario:** "You move a custom web app's files into `/web/html` and
configure Apache to serve from there. Permissions look correct
(`644`, owned by `apache:apache`), but every request returns `403
Forbidden`. Walk me through your diagnosis."

A junior answer stops at "permissions are fine, so it must be a config
issue" and starts re-reading the Apache config — missing the actual cause.
A senior answer immediately suspects **SELinux context**, because this is
the textbook RHCSA/RHEL failure signature: Unix permissions can be entirely
correct while SELinux denies access based on a separate **context** label.
They'd run `ls -Z /web/html` to confirm the directory has the wrong context
(likely `default_t` instead of `httpd_sys_content_t`, since it's outside
the default `/var/www/html`), use `audit2why` against `/var/log/audit/
audit.log` to confirm SELinux is the blocker, then fix it **persistently**
with `semanage fcontext -a -t httpd_sys_content_t '/web/html(/.*)?'`
followed by `restorecon -Rv /web/html` — explaining why `chcon` alone is
insufficient (it doesn't survive a relabel). This dual-permission-system
mental model — Unix permissions AND SELinux context must both pass — is
exactly what separates RHCSA-ready troubleshooting from Ubuntu/AppArmor-only
experience.

---

## Step 3 — Alternatives

| Topic | Alternative | Note |
|---|---|---|
| RHCSA (this lesson) | LFCS (Linux Foundation Certified SysAdmin), CompTIA Linux+ | RHCSA is the most recognized for RHEL-based-shop job postings; LFCS is distro-agnostic; Linux+ is more entry-level |
| Self-study (this lesson) | Official Red Hat training courses (RH124/RH134) | Official courses are comprehensive but costly; self-study with a lab VM + practice exams (per [Sander van Vugt's guide](https://www.sandervanvugt.com/red-hat-rhcsa-9-cert-guide-ex200/)) is a proven path for motivated learners |
| AlmaLinux/Rocky for practice | Paid RHEL Developer Subscription (free for individuals) | Either works — RHEL Developer Subscription is literally free and is "the real thing" if you want zero syntax-difference risk |

---

## Step 4 — Hands-On Task (build this yourself)

**Goal:** Close the identified gaps with timed, exam-style drills on
AlmaLinux/Rocky (or RHEL Developer Subscription), and produce a final
self-assessment.

### Lens C — Manual → Automated → Why

This lesson is inherently about **manual, hands-on, timed practice** — the
opposite of automation — because RHCSA explicitly tests "can you do this
yourself, under pressure, without scripts/AI assistance." The "why" here is
different from every prior lesson: **the skill being built is fluency under
constraint**, not a reusable artifact.

### What to build, step by step

For each gap identified in Step 2's table, complete a **timed** drill (10-15
min each) on a fresh AlmaLinux/Rocky VM:

1. **LVM** (gap): Create a PV from a new disk/partition, create a VG, create
   an LV, format as XFS, mount persistently via `/etc/fstab`. Then: extend
   the LV and filesystem online (`lvextend` + `xfs_growfs`).
2. **`firewalld`** (gap): `firewall-cmd --add-service=http --permanent`,
   `--reload`, verify with `--list-all`. Compare mentally to Lesson 09's
   `ufw`/`iptables` — same concept (allow-list rules), different tool.
3. **SELinux contexts** (gap): Install `httpd`, create a custom document
   root (e.g., `/web/html` instead of `/var/www/html`), observe the
   "Forbidden" error despite correct Unix permissions, diagnose with
   `ls -Z`/`audit2why`, fix with `semanage fcontext` + `restorecon`.
4. **GRUB2/boot troubleshooting** (gap): Practice resetting the root password
   via `rd.break` (interrupt GRUB, `rd.break`, remount `/sysroot` rw, `chroot
   /sysroot`, `passwd root`, fix SELinux relabel on next boot,
   `reboot`). **This is a destructive operation on a VM you control only —
   never practice on shared/production systems.**
5. **NFS** (gap): Configure an NFS server export (`/etc/exports`), mount it
   from a client, persist via `/etc/fstab` with `_netdev`.
6. **`httpd`** (gap): Install, enable, start `httpd`; configure a basic
   virtual host; confirm `firewalld` allows it (ties #2 + #6 together).
7. **`chronyd`** (gap): Confirm time sync status (`chronyc tracking`),
   configure an NTP source.
8. **`podman`** (syntax gap): Run a container with `podman run`, compare
   command syntax to your Lesson 11 `docker run` muscle memory — note
   differences (rootless by default, `podman generate systemd`).

For each drill: **time yourself**, note where you got stuck/needed to look
something up, and record this in a self-assessment table.

9. Create `docs/rhcsa/self-assessment.md` — for each of the 8 drills:
   time taken, confidence (1-5), what you'd review again.
10. Based on the self-assessment, write a **prioritized study plan** for the
    weeks before your actual RHCSA exam attempt — order by (lowest
    confidence) × (highest objective weight).
11. Commit `docs/rhcsa/self-assessment.md` and the study plan on
    `lesson/27-rhcsa-exam-prep-review`.

---

## Step 5 — Verification

```bash
# LVM
lsblk; vgs; lvs; df -h /mnt/<your-lv-mount>

# firewalld
firewall-cmd --list-all

# SELinux
ls -Z /web/html
getenforce   # should be Enforcing
curl http://localhost/   # should succeed after restorecon

# GRUB2/rd.break (after recovery)
whoami   # confirm root login works with new password
getenforce   # confirm SELinux still Enforcing after relabel

# NFS
mount | grep nfs
cat /etc/fstab | grep nfs

# httpd
systemctl is-enabled httpd
curl http://localhost/

# chronyd
chronyc tracking

# podman
podman ps
systemctl --user status <generated-service>
```

### Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| `lvextend`/`xfs_growfs` doesn't increase available space | Forgot `xfs_growfs` after `lvextend` (LV resize ≠ filesystem resize) | XFS filesystems must be grown separately from the LV; `xfs_growfs` is online-safe |
| `firewall-cmd --add-service` works but doesn't survive reboot | Forgot `--permanent` flag (or forgot `--reload` after) | `--permanent` writes to config; `--reload` applies without losing runtime-only rules accidentally — both needed for "test now AND persist" |
| `httpd` still "Forbidden" after `chcon` | `chcon` is **not persistent** across `restorecon`/relabeling | Use `semanage fcontext -a` (persistent rule) + `restorecon -Rv` (apply it) — not `chcon` alone |
| `rd.break` recovery: `passwd` succeeds but next boot still won't let you log in | SELinux relabel not triggered — `/etc/shadow` has wrong context after `chroot` edit | `touch /.autorelabel` before exiting chroot, or run `restorecon -v /etc/shadow` |
| NFS mount fails with "Connection refused" | `firewalld` on the NFS server doesn't allow NFS service | `firewall-cmd --add-service=nfs --permanent --add-service=rpc-bind --add-service=mountd` |

### Redaction check ✅

`docs/rhcsa/self-assessment.md` is personal study notes — no special
redaction needed beyond the standing convention (no real hostnames/IPs if you
reference your lab environment).

---

## Step 6 — Quiz (Interview-Style, Graded)

**Q1.** Walk through the LVM stack: PV → VG → LV → filesystem. Why is this
layered design more flexible than partitioning a disk directly (which Lesson
07 covered)?

> **Your answer:**

**Q2.** **Scenario:** `httpd` returns "403 Forbidden" for a file in
`/web/html/index.html` even though `ls -l` shows `644` permissions owned by
`apache:apache`. What's the likely cause, and what two commands fix it?

> **Your answer:**

**Q3.** Explain what happens, step by step, when you use `rd.break` to reset
a forgotten root password. Why is `/.autorelabel` (or `restorecon`) necessary
afterward?

> **Your answer:**

**Q4.** Compare `firewalld` (`firewall-cmd`) to Lesson 09's `ufw`/`iptables`
conceptually — same underlying kernel mechanism (netfilter), different
management tool. Why does RHEL default to `firewalld`?

> **Your answer:**

**Q5.** Looking at the gap-analysis table in Step 2: which gap do you think
is the **highest priority** to close given your overall NaviOps career goals
(per your locked strategy — Linux/cloud sysadmin track), and why?

> **Your answer:**

**Q6.** This is the last lesson of a 27-lesson curriculum. Looking back at
Lesson 01 vs. now — what's the single biggest shift in how you approach a
new Linux/infrastructure problem?

> **Your answer:**

---

## Step 7 — Reflection

*(Fill in after the quiz — this is the final reflection of the entire
curriculum; consider writing a bit more than usual)*

- What did you learn?
- What confused you?
- What would you do differently?
- Looking back across all 27 lessons — what are you most proud of, and
  what's your plan from here (RHCSA exam date, job applications, further
  specialization)?

---

## Lens E — Attacker & Defender (Red / Blue)

> Red/Blue framing (Gate Rule **Lens E**, D14). Build *both* mindsets: know how the
> tools in this lesson are abused, and how a defender detects and stops them.
> Frameworks: [GTFOBins](https://gtfobins.github.io/) · [MITRE ATT&CK](https://attack.mitre.org/) · [LOLBAS](https://lolbas-project.github.io/).

**🔴 Attacker (how it's abused — Step 2):** The RHCSA objectives are exactly the misconfigs attackers exploit: weak permissions, an open `firewalld`, permissive/disabled SELinux, and loose `sudo`. Studying the exam *is* studying the hardening baseline.

**🔵 Defender (detect & harden — Step 5):** Drill each RHCSA security objective as a blue-team control — `firewalld` default-deny, **SELinux enforcing** (and how to debug it without disabling it), scoped `sudo`, SSH key auth — and for each ask 'what attack does this stop?'

## Step 8 — Search Keywords For Further Understanding

**Core**
- `rhcsa ex200 objectives 2026`
- `lvm pv vg lv xfs growfs tutorial`
- `selinux semanage fcontext restorecon httpd`
- `grub2 rd.break reset root password rhel`

**Tools**
- `firewalld firewall-cmd permanent reload`
- `nfs server client exports fstab`
- `podman vs docker rootless containers`
- `chronyd chronyc time sync rhel`

**Going further (beyond this curriculum)**
- `rhce ex294 ansible automation exam` (the natural next certification after RHCSA, building directly on Lesson 13's Ansible foundation)
- `aws certified sysops administrator` (builds on Lessons 15-18, 25)
- `terraform associate certification` (builds on Lessons 20, 25)

---

**Red / Blue (Lens E — study attacker & defender in parallel):**
- 🔴 **Red (attacker):** `rhcsa security misconfigurations`, `linux privilege escalation weak permissions`, `attacker abuses permissive selinux firewall`
- 🔵 **Blue (defender):** `firewalld default deny zones`, `selinux enforcing troubleshooting audit2allow`, `sudo configuration hardening`, `ssh key authentication rhcsa`

## Lesson Status

- [ ] Hands-on task completed (Step 4)
- [ ] Verification passed (Step 5)
- [ ] Quiz answered + professional-answer comparisons requested (Step 6)
- [ ] Reflection completed (Step 7)
- [ ] Search Keywords reviewed (Step 8)

When complete, run the Update Protocol. **This is the final lesson of the
NaviOps 27-lesson curriculum** — congratulations on completing the full
roadmap. Next steps: schedule your RHCSA exam attempt based on Step 4's
self-assessment, and consider RHCE (Ansible, building on Lesson 13) or AWS/
Terraform certifications (building on Lessons 15-20, 25) as your next
milestones.

---

*Lesson 27 written by Navi v28 · 2026-06-11 · WebSearch sources:
[Red Hat EX200 — RHCSA Exam Official Page](https://www.redhat.com/en/services/training/ex200-red-hat-certified-system-administrator-rhcsa-exam),
[dotlinux Study Objectives for the RHCSA Exam & Preparation Guide](https://www.dotlinux.net/blog/study-objectives-for-the-rhcsa-exam-preparation-guide/),
[Sander van Vugt Red Hat RHCSA 9 Cert Guide: EX200](https://www.sandervanvugt.com/red-hat-rhcsa-9-cert-guide-ex200/)*
