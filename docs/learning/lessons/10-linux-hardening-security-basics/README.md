# Lesson 10 — Linux Hardening & Security Basics

**Status:** ready for self-study · **Date written:** 2026-06-11
**Gate Rule:** Concept → Real-World Use → Alternatives → Hands-On → Verification → Quiz → Reflection → Search Keywords

> **How to use this lesson:** same as Lessons 03–09. This lesson **consolidates**
> Lessons 04 (users/processes), 06 (cron/automation), 07 (SSH hardening), 09
> (firewalls) into a structured hardening pass — and adds auditd, AIDE, sysctl, and
> SELinux/AppArmor.

---

## Step 1 — Concept

### What it is

**Hardening** is the practice of reducing a system's **attack surface** — disabling
unnecessary services, enforcing least privilege, applying kernel-level security
controls, and adding intrusion-detection layers — so that even if one defense fails,
others limit the damage (**defense in depth**).

Key tools this lesson covers:
- **`sysctl`** — runtime kernel parameter tuning (network hardening flags).
- **`auditd`** — logs security-relevant system events (who changed what, when).
- **AIDE** (Advanced Intrusion Detection Environment) — file-integrity monitoring
  (detects unauthorized file changes via checksums).
- **SELinux / AppArmor** — Mandatory Access Control (MAC); confines what processes
  can do even if running as root.

### Why it exists

Lessons 04/07/09 covered individual controls (user permissions, SSH config,
firewall rules) — each is **one layer**. A single misconfiguration or 0-day in any
one layer shouldn't mean total compromise. Defense in depth means: if an attacker
gets a shell via a vulnerable web app, **AppArmor/SELinux** can still stop that
process from reading `/etc/shadow`; **auditd** logs the attempt; **AIDE** flags any
file it modified; **fail2ban** (Lesson 07) already slowed their initial SSH
brute-force.

### What problem it solves

| Problem | Solution |
|---|---|
| "A compromised web server process shouldn't be able to read SSH keys" | SELinux/AppArmor confinement |
| "Someone changed `/etc/passwd` — who, and when?" | `auditd` rules on sensitive files |
| "Has any system binary been tampered with?" | AIDE integrity database |
| "This server keeps getting SYN-flooded / IP-spoofed probes" | `sysctl` network hardening |
| "Compliance audit asks: prove your hardening baseline" | Documented checklist + tool outputs |

### Three-Level Depth (Lens A)

- **Level 1 — Beginner:** `sysctl -a | grep ip_forward` shows current kernel network
  settings; `getenforce` (RHEL/Alma) shows if SELinux is `Enforcing`/`Permissive`/
  `Disabled`; `aa-status` (Ubuntu) shows AppArmor profile status; `systemctl status
  auditd` shows if audit logging is active.
- **Level 2 — SysAdmin:** Per [SysWard's 2026 hardening checklist](https://sysward.com/blog/2026-05-06-linux-server-hardening-checklist/)
  and [oneuptime's Ubuntu hardening guide](https://oneuptime.com/blog/post/2026-03-02-how-to-harden-ubuntu-server-a-complete-security-checklist/view):
  a complete baseline includes — fail2ban protecting SSH (Lesson 07), `sysctl`
  network parameters hardened (disable IP forwarding unless this host is a router,
  reject ICMP redirects, enable TCP SYN cookies, enable reverse-path filtering),
  SUID/SGID binaries reviewed and minimized (`find / -perm -4000 -type f 2>/dev/null`),
  `auditd` running with rules on `/etc/passwd`, `/etc/shadow`, `/etc/sudoers`,
  AIDE database initialized with scheduled checks (ties to Lesson 06's cron/timers),
  unneeded services disabled (`systemctl list-unit-files --state=enabled`), and
  AppArmor/SELinux in **enforcing** mode (not permissive — permissive only logs,
  doesn't block). RHEL/AlmaLinux defaults to SELinux; Ubuntu/Debian defaults to
  AppArmor — know which your distro uses.
- **Level 3 — Systems/Kernel (Lens D):** SELinux/AppArmor implement **Mandatory
  Access Control** via the kernel's **LSM (Linux Security Module)** framework —
  hooks inserted at security-relevant points in the kernel (file open, socket
  create, etc.) where the LSM checks a **policy** before allowing the operation,
  *in addition to* normal Unix permissions (DAC — Discretionary Access Control from
  Lesson 04). This is why a process running as `root` can still be blocked by
  SELinux — DAC says "root can read anything," but the LSM/MAC layer is a second,
  independent check. `auditd` works similarly: it's a userspace daemon
  (`auditd`/`auditctl`) that reads events from a kernel **audit subsystem**
  (`CONFIG_AUDIT`) which can tag syscalls (e.g., "log every `open()` on
  `/etc/shadow`") — implemented via the same kernel hook infrastructure used for
  `ptrace`/security checks.

### Analogy (Lens B)

- **Defense in depth** = a bank: a security guard at the door (firewall/fail2ban),
  a vault door (SSH key auth, Lesson 07), security cameras recording everyone inside
  (auditd), a safe-deposit-box system where each employee can only open their own
  drawer regardless of which room they're in (SELinux/AppArmor — confinement
  independent of "are you an employee"), and a daily count of the vault's contents
  to detect if anything's missing (AIDE).
- **SELinux/AppArmor vs. file permissions** = a hotel keycard system layered on top
  of room locks: the room lock (Unix permissions) might open for anyone with the
  physical key, but the keycard system (MAC) additionally checks "is this person's
  card authorized for this floor *right now*" — two independent checks, both must
  pass.

The bank analogy breaks down for **SELinux contexts/labels** — there's no clean
"every object in the bank has an invisible label saying which roles can touch it,
checked automatically" equivalent in physical security; that's the actual mechanism
(file/process security **contexts**, e.g., `httpd_sys_content_t`).

---

## Step 2 — Real-World Use

### How SysAdmins use this daily

```bash
# Kernel hardening parameters
sysctl net.ipv4.ip_forward                  # should be 0 unless this is a router
sysctl net.ipv4.conf.all.accept_redirects   # should be 0
sysctl net.ipv4.tcp_syncookies              # should be 1

# SELinux (AlmaLinux/RHEL)
getenforce
sudo setenforce 1            # set to Enforcing (temporary, until reboot)
sudo sestatus

# AppArmor (Ubuntu)
sudo aa-status

# auditd
sudo systemctl status auditd
sudo auditctl -l                            # list current audit rules
sudo ausearch -f /etc/passwd                # search audit log for events on a file

# SUID/SGID audit
find / -perm -4000 -type f 2>/dev/null      # find SUID binaries (potential risk)

# Enabled services audit
systemctl list-unit-files --state=enabled
```

**Real production scenarios:**
1. **New server provisioning checklist** — before a server goes into production, run
   through a hardening checklist (this lesson's Step 4 deliverable).
2. **Post-incident**: "did the attacker modify any system binaries?" — check AIDE's
   report (`aide --check`).
3. **Compliance audit** (PCI-DSS, SOC2, CIS Benchmarks) — auditors ask for evidence
   of MAC enforcement, audit logging, and a documented hardening baseline.

### Common mistakes

| Mistake | Impact | Fix |
|---|---|---|
| Disabling SELinux entirely because "it's annoying" (`setenforce 0` permanently) | Removes a major defense layer; common root cause in breach post-mortems | Use `setenforce 0` (Permissive) **temporarily** to debug, check `ausearch -m avc` for denials, write/adjust policy — don't disable |
| Treating hardening as a one-time task | Drift — new packages install services that re-enable themselves, new SUID binaries appear | Periodic re-audit (cron/timer running an audit script — Lesson 06) |
| `sysctl` changes not persisted | Setting reverts on reboot | Edit `/etc/sysctl.d/99-hardening.conf`, then `sysctl -p` |
| Enabling `auditd` with zero rules | Daemon runs but logs nothing useful | Add explicit `-w /etc/passwd -p wa -k passwd_changes` style rules |
| Confusing AppArmor "complain" mode with "enforce" | Mode only **logs** violations, doesn't block them — false sense of security | `aa-enforce` the relevant profiles |

### When NOT to

- Don't enable strict SELinux/AppArmor enforcement on a production system **without
  testing in permissive/complain mode first** — a misconfigured policy can break
  legitimate application functionality (a very common "why did my app suddenly stop
  working after a security update" cause).

### Interview Angle

**Question:** "After a routine SELinux enforcing rollout, a web app starts returning
500 errors when writing to its log directory — `ls -l` shows the permissions are
correct and the app's Unix user owns the directory. What's going on, and how do you
fix it without disabling SELinux?"

A junior answer either says "disable SELinux, the permissions are fine" or stops at
`setenforce 0` as the fix. A senior answer recognizes this as the textbook DAC-vs-MAC
split from Lesson 04/10: Unix permissions (DAC) say the write is allowed, but
SELinux's LSM hook is a second, independent check on the file's **security
context** — the log directory likely has the wrong label (not
`httpd_sys_rw_content_t` or similar). The senior runs `ausearch -m avc -ts recent`
to confirm a denial was logged, then either relabels the directory
(`restorecon -Rv`) or, if the access is legitimate but unmodeled, generates a
targeted policy module with `audit2allow` — never a blanket `setenforce 0`, which
removes the whole defense layer.

---

## Step 3 — Alternatives

| Tool | Alternative | Note |
|---|---|---|
| AIDE | **Tripwire**, **Wazuh** (full HIDS) | AIDE is simple/free; Wazuh is a full host-based intrusion detection + SIEM (relevant to Lesson 23) |
| Manual hardening checklist | **CIS Benchmarks** + automated scanners (`OpenSCAP`, `Lynis`) | `lynis audit system` gives an automated hardening score + recommendations — good for self-checking your manual work |
| `auditd` | **systemd journal** alone | journald captures application logs; auditd captures **kernel-level security events** (syscalls) — different layers, often used together |
| SELinux (RHEL/Alma) | AppArmor (Ubuntu/Debian) | Don't fight your distro's default — learn the one your distro ships with |

---

## Step 4 — Hands-On Task (build this yourself)

> ▶ **Do this on the lab**: start the environment first — `./infra/bootstrap.sh up` (once: `pull`), then
> `docker exec -it naviops-web bash`. **Node:** naviops-web. **Artifact:** harden then re-check; build `scripts/security_audit.sh`.
> Reference solution (after you try): `docs/learning/reference-solutions/` (gitignored answer key).

**Goal:** Produce a hardening pass on your lab VM and `scripts/hardening_audit.sh` —
a script that checks your system against the baseline and reports gaps.

### Lens C — Manual → Automated → Why

**Manual:**
```bash
getenforce
sysctl net.ipv4.ip_forward
sudo auditctl -l
find / -perm -4000 -type f 2>/dev/null | wc -l
```

**Automated (`scripts/hardening_audit.sh`) — build this yourself** (same audit-script
pattern from Lessons 03/04/09, now for security baseline). Spec:

- **`check_mac_status()`** — detect the Mandatory Access Control system: if `getenforce`
  exists, report SELinux mode; else if `aa-status` exists, report AppArmor; else warn
  that no MAC system was found.
- **`check_sysctl_hardening()`** — loop over the parameters that matter
  (`net.ipv4.ip_forward`, `net.ipv4.conf.all.accept_redirects`,
  `net.ipv4.tcp_syncookies`) and `log` each one's `sysctl -n` value.
- **`check_auditd()`** — `systemctl is-active auditd`; note clearly if it's not running.
- **`check_suid_binaries()`** — `find / -perm -4000 -type f` and count them (`wc -l`),
  capturing the list to the log too.
- **`main()`** — banner → the four checks → completion banner; end with `main "$@"`.

This is the "first day on a new server, assess its posture fast" script — write it in
your own voice and compare its findings to `lynis audit system` (Step 4 below).

**Why this matters:** this is the same audit-script pattern from Lessons 03/04/09,
now extended to security-baseline checks — and it's the kind of "first day on a new
server" script that proves you can assess a system's security posture quickly.

### What to build, step by step

1. Check current MAC status (`getenforce`/`aa-status`), `auditd` status, and current
   `sysctl` network parameters.
2. Create `/etc/sysctl.d/99-hardening.conf` with at least: `net.ipv4.ip_forward=0`
   (unless your VM needs to route — most labs don't), `net.ipv4.conf.all.accept_redirects=0`,
   `net.ipv4.tcp_syncookies=1`. Apply with `sysctl -p /etc/sysctl.d/99-hardening.conf`.
3. If `auditd` isn't running, install/enable it; add a rule watching `/etc/passwd`
   and `/etc/shadow` (`auditctl -w /etc/passwd -p wa -k passwd_changes`), make it
   persistent in `/etc/audit/rules.d/`.
4. Run `lynis audit system` (if available) for a baseline score — compare its
   findings to your manual checks.
5. Write `scripts/hardening_audit.sh` per the structure above.
6. Document your before/after findings in the lesson's Reflection (Step 7).
7. Commit on `lesson/10-linux-hardening-security-basics`.

### Optional: failure drills

When you're ready for timed challenges, try [`troubleshooting-drills.md` §1 (SELinux denial / .autorelabel trap)](../../troubleshooting-drills.md#1-selinux-denial--autorelabel-trap) in your sandbox VM.

---

## Step 5 — Verification

```bash
bash -n scripts/hardening_audit.sh
./scripts/hardening_audit.sh

# Confirm sysctl persisted
sysctl net.ipv4.ip_forward   # should match your /etc/sysctl.d/99-hardening.conf value

# Confirm auditd rule fires
sudo cat /etc/shadow > /dev/null
sudo ausearch -k passwd_changes | tail -5

# If lynis is available
sudo lynis audit system | tail -30
```

### Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| `sysctl` change doesn't persist after reboot | Set with `sysctl -w` only (runtime), not in `/etc/sysctl.d/` | Add to `/etc/sysctl.d/99-hardening.conf`, run `sysctl -p` |
| `getenforce` returns `Disabled` | SELinux disabled at boot (`/etc/selinux/config` or kernel cmdline) | Set `SELINUX=permissive` first, test, then `enforcing` after reboot |
| App breaks after enabling SELinux enforcing | Policy doesn't allow the app's normal behavior | `ausearch -m avc -ts recent`, use `audit2allow` to generate a policy module — don't just disable SELinux |
| `auditctl -l` shows no rules after reboot | Rules added with `auditctl` directly are **not persistent** | Add rules to `/etc/audit/rules.d/*.rules` |

### Redaction check ✅

No real findings (e.g., actual SUID binary paths with usernames) need redaction
beyond the standard hostname/IP convention — but don't commit full `lynis` reports
if they reveal internal hostnames/IPs without redaction.

---

## Step 6 — Quiz (Interview-Style, Graded)

**Q1.** Explain the difference between DAC (Discretionary Access Control — standard
Unix permissions) and MAC (SELinux/AppArmor). Why can a process running as `root`
still be blocked by SELinux?

> **Your answer:**

**Q2.** **Scenario:** After enabling SELinux enforcing mode, your web app can't write
to its log directory anymore — but the Unix permissions (`ls -l`) look correct. What
do you check, and what command would generate a fix?

> **Your answer:**

**Q3.** What's the difference between `auditd` and journald (Lesson 05)? Give an
example of something each would capture that the other wouldn't.

> **Your answer:**

**Q4.** Why is "defense in depth" important — give a concrete example using at least
3 layers from Lessons 04/07/09/10 and how each would slow down or stop an attacker
even if a previous layer failed.

> **Your answer:**

**Q5.** What does `net.ipv4.ip_forward=1` mean (tie back to Lesson 09), and why would
a hardening checklist generally recommend it be `0`?

> **Your answer:**

**Q6.** What does AIDE detect, and why would you run it on a schedule (tie back to
Lesson 06)?

> **Your answer:**

---

## Step 7 — Reflection

*(Fill in after the quiz)*

- What did you learn?
- What confused you?
- What would you do differently?

---

## Lens E — Attacker & Defender (Red / Blue)

> Red/Blue framing (Gate Rule **Lens E**, D14). Build *both* mindsets: know how the
> tools in this lesson are abused, and how a defender detects and stops them.
> Frameworks: [GTFOBins](https://gtfobins.github.io/) · [MITRE ATT&CK](https://attack.mitre.org/) · [LOLBAS](https://lolbas-project.github.io/).

**🔴 Attacker (how it's abused — Step 2):** This lesson is the blue-team baseline — so study the red side it defeats: attackers run LinPEAS/linenum to enumerate weak SSH, sudo, SUID, kernel, and writable-service findings, then chain them to root and **impair defenses** (disable fail2ban/SELinux/auditd). ATT&CK **T1562** (Impair Defenses), **T1068** (Exploitation for Privilege Escalation).

**🔵 Defender (detect & harden — Step 5):** Apply CIS Benchmarks systematically: SSH hardening, `fail2ban`, **SELinux enforcing**, `auditd`, least privilege, removed SUID, locked accounts. Map each control to the specific attack it blocks — that mapping *is* the lesson.

## Step 8 — Search Keywords For Further Understanding

**Core**
- `linux mandatory access control selinux apparmor explained`
- `auditd rules cheat sheet`
- `sysctl network hardening parameters explained`
- `aide file integrity monitoring setup`

**Tools**
- `lynis audit system linux hardening score`
- `audit2allow selinux denial fix`
- `cis benchmark linux hardening`

**Going further (future lessons)**
- `wazuh host intrusion detection setup`
- `ansible hardening role cis`
- `aws security hub vs lynis`

---

**Red / Blue (Lens E — study attacker & defender in parallel):**
- 🔴 **Red (attacker):** `linpeas linux privilege escalation`, `MITRE ATT&CK T1562 impair defenses`, `linux privesc enumeration`, `disable selinux fail2ban attacker`
- 🔵 **Blue (defender):** `CIS benchmark linux hardening`, `selinux enforcing mode`, `auditd security rules`, `lynis security audit`

## Lesson Status

- [ ] Hands-on task completed (Step 4)
- [ ] Verification passed (Step 5)
- [ ] Quiz answered + professional-answer comparisons requested (Step 6)
- [ ] Reflection completed (Step 7)
- [ ] Search Keywords reviewed (Step 8)

When complete, run the Update Protocol, then move to **Lesson 11 — Docker
Fundamentals**.

---

*Lesson 10 written by Navi v28 · 2026-06-11 · WebSearch sources:
[SysWard Linux Server Hardening Checklist 2026](https://sysward.com/blog/2026-05-06-linux-server-hardening-checklist/),
[oneuptime Ubuntu Hardening Checklist](https://oneuptime.com/blog/post/2026-03-02-how-to-harden-ubuntu-server-a-complete-security-checklist/view),
[cybersecuritynews Hardening Linux Servers](https://cybersecuritynews.com/hardening-linux-servers/)*
