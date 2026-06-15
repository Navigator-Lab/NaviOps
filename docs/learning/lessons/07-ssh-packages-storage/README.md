# Lesson 07 — SSH Hardening, Package Management & Storage (LVM)

**Status:** ready for self-study · **Date written:** 2026-06-11
**Gate Rule:** Concept → Real-World Use → Alternatives → Hands-On → Verification → Quiz → Reflection → Search Keywords

> **How to use this lesson:** same as Lessons 03–06.

---

## Step 1 — Concept

### What it is

Three related "keep the system usable and reachable" topics:
- **SSH** — the encrypted protocol/service for remote login and file transfer; Lesson
  02 already used SSH for GitHub auth, this lesson covers **server-side SSH** (the
  `sshd` daemon) and hardening it.
- **Package management** — `apt` (Debian/Ubuntu) / `dnf` (RHEL/AlmaLinux/Fedora)
  install, update, and remove software, tracking dependencies.
- **Storage / LVM** — Logical Volume Manager sits between raw disks/partitions and
  filesystems, allowing flexible resizing.

### Why it exists

- **SSH hardening** exists because SSH is the #1 internet-facing attack surface on any
  Linux server — automated bots constantly try `root`/`admin` + common passwords
  against port 22.
- **Package managers** exist because manually compiling/installing software and
  tracking which files belong to which version, with which dependencies, doesn't scale
  — and creates "dependency hell."
- **LVM** exists because raw disk partitions are **fixed-size** — if `/var` fills up,
  resizing a plain partition often requires backup/repartition/restore. LVM lets you
  grow (and in some cases shrink) volumes live.

### What problem it solves

| Problem | Solution |
|---|---|
| "Bots are hammering port 22 with password guesses" | Disable password auth, key-only, `fail2ban` |
| "I need `htop` installed" | `apt install htop` / `dnf install htop` — handles dependencies |
| "`/var/log` is full but `/home` has space free" | LVM: extend the `/var` logical volume into that free space |
| "New hire needs SSH access without sharing the root password" | Per-user SSH keys + `AllowUsers` |

### Three-Level Depth (Lens A)

- **Level 1 — Beginner:** `ssh user@host` connects; `ssh-keygen -t ed25519` generates
  a keypair; `ssh-copy-id user@host` installs your public key on the server. `apt
  update && apt install <pkg>` (Debian/Ubuntu) or `dnf install <pkg>`
  (RHEL/AlmaLinux). `df -h` shows disk usage per filesystem; `du -sh <dir>` shows a
  directory's size.
- **Level 2 — SysAdmin:** Per [ZeonEdge's 2026 SSH hardening guide](https://zeonedge.com/blog/ssh-hardening-2026-complete-guide-linux-server)
  and [Linuxize's hardening best practices](https://linuxize.com/post/ssh-hardening-best-practices/),
  the **5 highest-impact `/etc/ssh/sshd_config` changes** are:
  ```
  PasswordAuthentication no
  PermitRootLogin no
  MaxAuthTries 3
  AllowUsers <your-username>
  ```
  plus installing **fail2ban** (bans IPs after repeated failed attempts). **Ed25519**
  is the recommended key type for 2026 — shorter, faster, and at least as secure as
  RSA-4096. Always test a new SSH config in a **second session** before logging out —
  a syntax error or `AllowUsers` typo can lock you out entirely.
  For storage, per [DigitalOcean's LVM intro](https://www.digitalocean.com/community/tutorials/an-introduction-to-lvm-concepts-terminology-and-operations):
  LVM has 3 layers — **PV** (Physical Volume — a disk/partition initialized for LVM),
  **VG** (Volume Group — a pool combining one or more PVs), **LV** (Logical Volume —
  a resizable "virtual partition" carved from a VG, formatted with a filesystem like
  ext4/xfs and mounted via `/etc/fstab`). `pvs`/`vgs`/`lvs` show each layer;
  `lvextend` + `resize2fs`/`xfs_growfs` grows a mounted filesystem live.
- **Level 3 — Systems/Kernel (Lens D):** SSH server-side authentication, when key-based,
  works via **public-key cryptography**: the server has your *public* key in
  `~/.ssh/authorized_keys`; during the handshake the server sends a challenge, your
  client signs it with the *private* key (`~/.ssh/id_ed25519`, mode `600` — Lesson 01
  callback), and the server verifies the signature with the public key — your private
  key **never leaves your machine**. This is fundamentally different from password
  auth (a shared secret transmitted, even if encrypted-in-transit). At the filesystem
  level, LVM is implemented via the kernel's **device-mapper** framework — a PV/VG/LV
  is a stack of virtual block devices, each one a mapping table the kernel consults on
  every I/O to translate a logical block address to a physical one; `dmsetup` shows
  these mappings directly. Package managers (`dpkg`/`rpm` underneath `apt`/`dnf`)
  maintain a database of installed files/versions/dependencies (e.g.,
  `/var/lib/dpkg/status`) — `apt`/`dnf` are dependency-resolution layers on top.

### Analogy (Lens B)

- **SSH key auth** = a lock that only opens for a key with a *unique cut* (your
  private key) — the server only stores a description/photo of the correct key shape
  (public key) and checks if what you present matches, without ever holding a copy of
  your physical key.
- **LVM** = instead of fixed cardboard boxes (partitions) that can't change size, LVM
  is a set of modular shelving units (PVs) you can combine into one storage room (VG),
  then partition that room with movable walls (LVs) — you can move a wall to give one
  section more space without touching the others, as long as the room (VG) has free
  capacity.
- **Package managers** = an app store with a dependency graph: installing "Photo
  Editor" automatically also installs "Image Library v2" if it's not already present,
  and the store remembers exactly what's installed so it can cleanly remove it later.

The LVM "movable walls" analogy breaks down when a VG runs out of *total* free space —
no amount of wall-moving creates new square footage; you need to add a new PV (disk).

---

## Step 2 — Real-World Use

### How SysAdmins use this daily

```bash
# SSH hardening (after confirming key-based login works!)
sudo nano /etc/ssh/sshd_config   # PasswordAuthentication no, PermitRootLogin no, etc.
sudo sshd -t                     # TEST config syntax before restarting
sudo systemctl restart sshd
# Keep your current session open; open a NEW session to confirm you can still log in

# Package management
sudo apt update && sudo apt upgrade -y     # Debian/Ubuntu
sudo dnf check-update && sudo dnf upgrade  # RHEL/AlmaLinux
apt list --installed | grep <pkg>          # is it installed?
apt-cache policy <pkg>                     # what version is available?

# Storage
df -h                  # filesystem usage
du -sh /var/log/*      # what's eating space in /var/log
lsblk                  # block devices and their mount points
sudo pvs && sudo vgs && sudo lvs   # LVM layers, if in use
```

### Common mistakes

| Mistake | Impact | Fix |
|---|---|---|
| Disabling password auth **before** confirming key auth works | **Total lockout** | Test key login in a 2nd session first; never close your only session while editing `sshd_config` |
| `sudo systemctl restart sshd` without `sshd -t` first | Syntax error → sshd fails to restart → locked out (if your session drops) | Always `sshd -t` first |
| `apt upgrade` / `dnf upgrade` without reading what's changing on a production box | Unexpected major-version jumps can break things | `apt list --upgradable` first; consider `apt-mark hold` for critical packages |
| Letting `/var/log` or `/tmp` fill the **root** filesystem | Whole system can become unresponsive (no space for any writes, including swap) | Separate LVs for `/var`, `/tmp`, `/home` on production; monitor with `df` (Lesson 06's cron/timer) |
| `rm -rf` to "free space" instead of finding *what's* using it | Might delete logs needed for an active incident | `du -sh` to find the actual large files/dirs first |

### When NOT to

- Don't disable `PermitRootLogin` on a system where you haven't yet confirmed a
  non-root user has working `sudo` — you'd lose admin access entirely.
- LVM adds a layer of complexity — for a single-disk VM that will never need
  resizing, plain partitions are simpler and have one less layer to debug. NaviOps'
  lab VMs (per `naviops-strategy`) are a reasonable place to practice LVM precisely
  *because* they're disposable.

### Interview Angle

**Question:** "You're about to set `PasswordAuthentication no` and
`PermitRootLogin no` on a remote server you can only reach via SSH. What's your
exact procedure, and what could still go wrong even if you follow it?"

A junior answer lists the config changes and maybe mentions `sshd -t`. A senior
answer sequences it as a safety chain: confirm key-based login works for a non-root
user *first*, in a way that doesn't depend on the change being tested (`ssh-copy-id`,
then a real login from a fresh session); edit `sshd_config`; run `sudo sshd -t` to
catch syntax errors before reload; `systemctl restart sshd` while keeping the
*original* session open; then open a **brand-new** session to confirm login still
works before closing the original. The senior also flags the residual risk: a
`fail2ban` rule or firewall change applied around the same time can still lock you
out even if `sshd_config` itself is correct — which is why changes are made one at a
time, verified independently.

---

## Step 3 — Alternatives

| Topic | Alternative | Trade-off |
|---|---|---|
| SSH hardening | **FIDO2/hardware security keys** (2026 gold standard per ZeonEdge) | Stronger, but requires hardware — overkill for a learning lab, standard for production |
| SSH hardening | Changing the SSH port (security through obscurity) | Reduces *automated* scan noise slightly but is **not** a real security control — don't rely on it alone |
| Package management | Building from source / `tar.gz` releases | Full control, but no dependency tracking, no easy uninstall/update — avoid unless the package manager truly lacks what you need |
| Storage | Plain partitions (`fdisk`/`parted`) | Simpler, but inflexible resizing — [Red Hat's LVM-vs-partitioning piece](https://www.redhat.com/sysadmin/lvm-vs-partitioning) frames LVM as the production default when flexibility matters |
| Storage | ZFS/Btrfs (filesystem-level volume management + snapshots) | More features (snapshots, checksums) but a bigger learning curve — note for a future lesson |

---

## Step 4 — Hands-On Task (build this yourself)

**Goal:** Harden SSH on your VM (per `naviops-strategy`'s VM-first lab plan), and
write `scripts/disk_report.sh`.

### Lens C — Manual → Automated → Why

**Manual:**
```bash
ssh-keygen -t ed25519 -C "naviops-lab"
ssh-copy-id youruser@vm-alma
ssh youruser@vm-alma   # confirm key login works BEFORE touching sshd_config
```

Then edit `/etc/ssh/sshd_config` on the VM:
```
PasswordAuthentication no
PermitRootLogin no
MaxAuthTries 3
AllowUsers youruser
```
```bash
sudo sshd -t && sudo systemctl restart sshd
# from a NEW terminal/session, confirm: ssh youruser@vm-alma still works
```

**Automated (`scripts/disk_report.sh`) — build this yourself** (reuse the Lesson 03
header + `log()` pattern). Spec:

- **`check_disk_usage()`** — `log` a heading, then `df -h --output=target,size,used,pcent`
  (filter out `/snap` noise if on Ubuntu).
- **`check_high_usage_alert()`** — set a `threshold` (e.g. 80); read `df`'s
  target/percent columns in a loop, strip the `%` (parameter expansion: `${pcent%\%}`),
  and print a `WARNING` line for any mount at or over the threshold. This integer
  comparison + string-trim is the part that proves you can write real Bash.
- **`check_largest_dirs()`** — take a target dir as `$1` (default `/var/log`), then
  `du -sh "$target"/*/ | sort -rh | head -5`.
- **`main()`** — start banner → the three checks → completion banner; end with `main "$@"`.

Wire it into Lesson 06's cron/timer once it works.

**Why this matters:** disk-full incidents are one of the most common (and most
preventable) production outages. This script is your early-warning system — wire it
into Lesson 06's cron/timer.

### What to build, step by step

1. On your lab VM (per `naviops-strategy` — VM-first, host never touched): set up
   key-based SSH login, confirm it works, **then** harden `sshd_config` per Step 4's
   manual section. Test in a second session before closing the first.
2. Practice package management: install `htop` and `fail2ban`
   (`apt install`/`dnf install`), check what got installed
   (`apt list --installed | grep fail2ban`), enable fail2ban
   (`systemctl enable --now fail2ban`).
3. (If your VM has spare disk/a second virtual disk) Practice LVM: create a PV, VG,
   and LV, format it (`mkfs.ext4`), mount it, add to `/etc/fstab`, then `lvextend` +
   `resize2fs` to grow it live. If you don't have spare disk, read through
   [LinuxHandbook's hands-on LVM guide](https://linuxhandbook.com/lvm-guide/) and be
   ready to do this when your VM is provisioned.
4. Write `scripts/disk_report.sh` per the structure above.
5. Commit `scripts/disk_report.sh` (and SSH/LVM notes — **redacted**, no real
   IPs/hostnames) on `lesson/07-ssh-packages-storage`.

### Optional: failure drills

When you're ready for timed challenges, try [`troubleshooting-drills.md` §2 (Broken /etc/fstab entry)](../../troubleshooting-drills.md#2-broken-etcfstab-entry), [§3 (Locked out by SSH config)](../../troubleshooting-drills.md#3-locked-out-by-ssh-config), and [§6 (Full disk)](../../troubleshooting-drills.md#6-full-disk) in your sandbox VM.

---

## Step 5 — Verification

```bash
# SSH: confirm hardening took effect (run from a SEPARATE session first!)
ssh -o PreferredAuthentications=password youruser@vm-alma  # should FAIL
ssh youruser@vm-alma                                        # should SUCCEED (key)
ssh root@vm-alma                                            # should FAIL (PermitRootLogin no)

# fail2ban
sudo systemctl status fail2ban
sudo fail2ban-client status sshd

# LVM (if practiced)
sudo pvs && sudo vgs && sudo lvs
df -h | grep <your-lv-mount>

# disk_report.sh
bash -n scripts/disk_report.sh
./scripts/disk_report.sh
```

### Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| Locked out of SSH after hardening | `AllowUsers` typo, or key not actually working before disabling passwords | Use VM console (not SSH) to revert `/etc/ssh/sshd_config`, restart sshd |
| `sshd -t` reports an error | Syntax error in `sshd_config` | Fix the reported line; re-test before restarting |
| `apt`/`dnf install` fails with dependency errors | Stale package cache | `apt update` / `dnf clean all && dnf makecache` |
| `lvextend` succeeds but `df` doesn't show new size | Filesystem not resized after the LV | `resize2fs <lv>` (ext4) or `xfs_growfs <mount>` (xfs) |
| `disk_report.sh` `du` step very slow | Scanning huge directory trees | Limit depth or target specific known-large dirs |

### Redaction check ✅

No real VM IPs/hostnames in committed notes — use `vm-alma` / `<VM_IP>` placeholders
per `LEARNING_STATE.md`'s redaction convention.

---

## Step 6 — Quiz (Interview-Style, Graded)

**Q1.** Walk through exactly what happens (cryptographically) when you `ssh` into a
server using key-based auth. Why is this more secure than password auth, even over an
encrypted channel?

> **Your answer:**

**Q2.** **Scenario:** You're about to set `PasswordAuthentication no` and
`PermitRootLogin no` on a remote server you can only access via SSH. What's your exact
safety procedure, in order, and why?

> **Your answer:**

**Q3.** What's the difference between `apt update` and `apt upgrade`? What does
`dnf check-update` correspond to?

> **Your answer:**

**Q4.** Explain the PV → VG → LV hierarchy in LVM. If `/var` (an LV) is full but
`/home` (another LV in the same VG) has 50GB free, what's the high-level fix?

> **Your answer:**

**Q5.** **Scenario:** `df -h` shows `/` at 98% used, but `du -sh /*` doesn't add up to
anywhere near that. What's a likely explanation? (Hint: think about the `rename()`/
open-file-descriptor mechanism from Lesson 06.)

> **Your answer:**

**Q6.** What does `fail2ban` do, and how does it complement (not replace)
`PasswordAuthentication no`?

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

**🔴 Attacker (how it's abused — Step 2):** SSH `authorized_keys` is a favourite backdoor (drop a key = silent persistence); weak auth invites brute force; package managers are a supply-chain target (typosquats, unsigned repos). ATT&CK **T1098.004** (SSH Authorized Keys), **T1110** (Brute Force), **T1195** (Supply Chain).

**🔵 Defender (detect & harden — Step 5):** Key-only SSH + `fail2ban`, **monitor `~/.ssh/authorized_keys` for changes** (auditd/FIM), verify package signatures/checksums, pin trusted repos, and mount untrusted filesystems `nosuid,nodev,noexec`.

## Step 8 — Search Keywords For Further Understanding

**Core**
- `ssh key based authentication how it works`
- `sshd_config hardening checklist`
- `lvm pv vg lv explained`
- `apt vs dnf package management commands`

**Tools**
- `fail2ban setup sshd jail`
- `lvextend resize2fs xfs_growfs example`
- `ssh-audit tool linux`

**Going further (future lessons)**
- `ansible ssh hardening playbook`
- `device mapper linux explained`
- `linux disk full troubleshooting deleted file still open`

---

**Red / Blue (Lens E — study attacker & defender in parallel):**
- 🔴 **Red (attacker):** `ssh authorized_keys backdoor`, `MITRE ATT&CK T1098.004 ssh keys`, `ssh brute force attack`, `package supply chain typosquatting`
- 🔵 **Blue (defender):** `ssh key-only authentication hardening`, `fail2ban ssh protection`, `file integrity monitoring authorized_keys`, `verify package signatures gpg`

## Lesson Status

- [ ] Hands-on task completed (Step 4)
- [ ] Verification passed (Step 5)
- [ ] Quiz answered + professional-answer comparisons requested (Step 6)
- [ ] Reflection completed (Step 7)
- [ ] Search Keywords reviewed (Step 8)

When complete, run the Update Protocol, then move to **Lesson 08 — Networking I (OSI/
TCP-IP & Subnetting)**.

---

*Lesson 07 written by Navi v28 · 2026-06-11 · WebSearch sources:
[ZeonEdge SSH hardening 2026](https://zeonedge.com/blog/ssh-hardening-2026-complete-guide-linux-server),
[Linuxize SSH hardening best practices](https://linuxize.com/post/ssh-hardening-best-practices/),
[DigitalOcean LVM concepts](https://www.digitalocean.com/community/tutorials/an-introduction-to-lvm-concepts-terminology-and-operations),
[Red Hat LVM vs partitioning](https://www.redhat.com/sysadmin/lvm-vs-partitioning),
[LinuxHandbook LVM guide](https://linuxhandbook.com/lvm-guide/)*
