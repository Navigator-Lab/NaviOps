# Lesson 05 — Linux Fundamentals for Support

**Status:** ✅ ready for self-study (full depth) · **Date written:** 2026-06-21
**Schema:** 12-section IT-Support (`docs/learning/CLAUDE_TEACHING_RULES.md`)
**Focus:** enough Linux to **support** it — the shell, the filesystem layout, files & permissions,
packages, services (`systemctl`), logs (`journalctl`), and basic network checks — so a Windows-first
tech isn't helpless when a ticket lands on a Linux box. This is also the on-ramp to the NaviOps
(Linux/SysAdmin) sibling.
**Primary artifact:** `scripts/linux_triage.sh` + a Linux triage runbook.

> **How to use this lesson:** read §1–§7, do §8 (work a real shell — a VM/WSL/container), produce
> §9, take the quiz, reflect. Then Lesson 06.

---

## §1 — Concept (Theory)

### What it is
**Linux** is the OS running most servers, much cloud infrastructure, network/IoT appliances, and
some developer/engineer desktops. Supporting it means working from the **shell** (terminal) — there's
often no GUI — using a small, composable toolkit to inspect files, permissions, services, logs, and
the network. The concepts mirror Windows (processes, services, logs, users, permissions) but the
*surfaces* are commands, not consoles.

### Why a Windows-first tech needs it
Tickets don't respect your comfort zone. A web app is down (the server is Linux), an engineer can't
sign in to their Ubuntu laptop, a network appliance needs a log pulled. Knowing the **Windows↔Linux
map** (`services.msc`→`systemctl`, Event Viewer→`journalctl`, Task Manager→`top`) lets you transfer
everything you already know.

### Three-Level Depth (Lens A)
- **Level 1 — User:** Linux is "the black screen where you type commands"; files live in folders;
  there's no C: drive.
- **Level 2 — Technician:** Linux is a **shell + a tree filesystem (`/`) + services managed by
  `systemctl` + logs in `journalctl`/`/var/log`**. You navigate (`cd`,`ls`,`pwd`), read files
  (`cat`,`less`,`tail`), check services and logs, and fix permissions (`chmod`,`chown`).
- **Level 3 — Engineer:** everything is a **file** (devices, sockets, process info under `/proc`);
  permissions are **owner/group/other × read/write/execute** (the rwx bits) plus ownership; processes
  have PIDs and signals; `systemd` is PID 1 managing units; the package manager (`apt`/`dnf`) owns
  installed software. This is *why* "permission denied" or "service failed" has a precise, inspectable
  cause.

### Two Teaching Approaches (Lens B) — the filesystem & permissions
**Approach 1 (technical):** Linux has a single rooted tree (`/`) — no drive letters; everything mounts
into it. Each file has an **owner**, a **group**, and a 3×3 **permission matrix** (read/write/execute
for owner/group/other), shown as `-rwxr-xr--`. Access is decided by which class you fall into and the
bits set. Services are `systemd` **units** you start/enable/inspect uniformly.

**Approach 2 (analogy):** the filesystem is **one big building with one front door (`/`)** and floors
branching off (`/home`, `/etc`, `/var`); a USB drive isn't a new building (D:) — it's a **room you
attach (mount) inside** the existing building. Permissions are like a **document with an owner, a
department (group), and "everyone else,"** each allowed to read / edit / run it or not. **Where it
breaks down:** unlike paper, the *execute* bit (run it as a program) has no real Windows-folder analog
and trips up newcomers ("the script won't run" = missing `+x`).

### Visual (ASCII) — the tree + a permission string
```
   /                      (root — the one and only top)
   ├── home/jdoe/         user home (≈ C:\Users\jdoe)
   ├── etc/               config files (≈ registry/Settings)
   ├── var/log/           logs (≈ Event Viewer)   ← syslog, app logs
   ├── bin /usr/bin       programs (≈ Program Files / PATH)
   └── mnt /media         mounted drives (USB, shares)

   ls -l result:   -rwxr-x---  1 jdoe  devs  4096  app.sh
                   │└┬┘└┬┘└┬┘     owner group              owner=jdoe (rwx), group=devs (r-x), other=(---)
                   │ owner group other       → "permission denied" for anyone not jdoe/devs
                   └ type (-=file, d=dir)
```

---

## §2 — Tools & Commands

| Task | Linux command | Windows analog |
|---|---|---|
| Where am I / list | `pwd` · `ls -lah` | `cd` · `dir` |
| Move around | `cd /path` | `cd` |
| Read a file | `cat` · `less` · `tail -f` | `type` · `Get-Content -Wait` |
| Find files / text | `find` · `grep -r` | `Get-ChildItem -Recurse` · `Select-String` |
| Permissions / ownership | `chmod` · `chown` | NTFS ACLs (L07) |
| Processes | `ps aux` · `top`/`htop` · `kill` | Task Manager · `Stop-Process` |
| Services | `systemctl status/start/enable <svc>` | `services.msc` / `Get-Service` |
| Logs | `journalctl -u <svc>` · `journalctl -xe` · `/var/log/` | Event Viewer / `Get-WinEvent` |
| Packages | `apt`/`dnf install` · `apt list --installed` | winget / Add-Remove Programs (L25) |
| Network | `ip a` · `ping` · `ss -tulpn` | `ipconfig` · `ping` · `netstat` (L08) |
| Disk | `df -h` · `du -sh *` · `lsblk` | Disk Mgmt / `Get-PhysicalDisk` (L06) |
| Who am I / sudo | `whoami` · `id` · `sudo <cmd>` | `whoami` · Run as admin (UAC) |

```bash
systemctl status nginx            # is the web service up? why did it fail?
journalctl -u nginx --since "1 hour ago"   # that service's recent logs
df -h                             # disk space (a top cause of "server broke")
chmod +x deploy.sh                # make a script executable
sudo systemctl restart sshd       # restart a service (needs privilege)
```

---

## §3 — Real-World Support Context & Use Cases

- **Servers are mostly Linux.** When "the website/app is down," you're often SSH'd into a Linux box
  checking a service and its logs. Even at help-desk level you may be the hands that run a command an
  engineer dictates.
- **"Disk full" is the classic Linux incident** (`df -h` → logs filled `/var`). Knowing this one
  pattern earns trust fast.
- **Permission denied** is the #2 — the rwx/ownership model explains it precisely.
- **SSH** is how you reach these boxes (Lesson 24 covers remote access broadly); identity/keys matter.
- **The bridge:** this lesson is deliberately the gateway to **NaviOps** (the full Linux/SysAdmin
  platform) — go there to go deep.
- **Exam framing:** A+ Core 2 covers basic Linux commands & concepts; Linux depth lives in
  Linux+/LFCS (and NaviOps).

---

## §4 — Demonstration (worked walkthrough)

> **Ticket INC-0607-L (P1):** *"The team intranet site is down — page won't load at all."* (The
> intranet runs `nginx` on a Linux server, `web01.corp.example`.)

1. **Confirm scope:** site down for everyone → likely the **server/service**, not one user → P1.
2. **Reach the box:** `ssh jdoe@web01.corp.example` (or via the engineer/runbook).
3. **Check the service:** `systemctl status nginx` → shows **failed/inactive**? That's the lead.
4. **Why did it fail?** `journalctl -u nginx --since "30 min ago"` → e.g. "no space left on device".
5. **Confirm the real cause:** `df -h` → `/var` is **100%** (logs filled the disk).
6. **Resolve:** clear/rotate the offending logs (carefully), free space, `sudo systemctl restart
   nginx`, confirm `active (running)` and the page loads.
7. **Prevent + document:** flag log rotation (root cause), write the note, raise a problem if it'll
   recur.

The pattern is *identical* to Windows triage — service state → logs → underlying resource → fix →
verify — just with `systemctl`/`journalctl`/`df` instead of consoles.

---

## §5 — Troubleshooting Workflow (the diagnostic spine)

**Problem class: a Linux service/app is down or a user can't do something on a Linux box.**

### 1 · Symptoms
"Service/website down" · "permission denied" · "command not found" · "disk full / can't write" ·
"can't SSH in" · a script "won't run."

### 2 · Possible Causes (most-likely first)
1. **Service stopped/failed** (`systemctl`).
2. **Disk full** (`df -h`) — blocks writes, crashes services.
3. **Permissions/ownership** wrong (rwx/owner) → "permission denied".
4. **Missing execute bit / wrong path** → "command not found" / script won't run.
5. **Wrong privilege** (needs `sudo`).
6. **Network/firewall** (can't reach a port — L08).

### 3 · Diagnostic Steps (ordered)
| # | Check | If… | …then |
|---|---|---|---|
| 1 | `systemctl status <svc>` | failed/inactive | read why → restart/fix |
| 2 | `journalctl -u <svc> -xe` | error message | act on the stated cause |
| 3 | `df -h` (and `du -sh /var/log/*`) | a mount ~100% | free space / rotate logs |
| 4 | `ls -l <file>` + `id` | denied / wrong owner | `chmod`/`chown` appropriately |
| 5 | `which <cmd>` / `echo $PATH` | not found | fix path / install package |
| 6 | `ss -tulpn` / `ping` | port not listening / no route | service/network/firewall (L08) |

### 4 · Resolution Steps
`sudo systemctl restart/enable <svc>`; free disk + enable log rotation; correct permissions/ownership
(`chmod 750`, `chown user:group`); add `+x` or fix `$PATH`; re-run with `sudo` where appropriate;
open the firewall port (with change approval).

### 5 · Escalation Criteria
Escalate to a **Linux sysadmin / the NaviOps-level team** for: application-config issues, anything
needing root changes you're not authorized for, kernel/driver problems, or production database/web
stacks. Attach: `systemctl status`, the `journalctl` excerpt, `df -h`, exact error, what you ran.
**Never** run destructive commands (`rm -rf`, disk/`dd` operations) on a server you don't own — danger
zone (`navi.project.md`).

### 6 · Post-Incident Documentation
Ticket note (service, root cause, commands run), runbook for the recurring pattern (e.g. disk-full),
problem ticket + RCA for production outages (L31/L32).

---

## §6 — Ticket Simulation

> **Ticket ENT-05 / INC-0520 (P2):** *"My deploy keeps failing with 'permission denied' when I run
> ./deploy.sh on the build server. Worked last week. — Hema, engineer, build01.corp.example."*

**Triage:** single user, blocked from a work task on a Linux box, reproducible → **P2**. "Permission
denied" on a script = the **execute bit** or **ownership**, classic Lens-D Linux issue.

**Worked resolution:**
1. **Look at the file:** `ls -l deploy.sh` →
   `-rw-r--r-- 1 root root 812 deploy.sh` — note: **no `x`**, owned by **root**, Hema is "other".
2. **Diagnose:** the script lost its execute bit (or was recreated by a root process) → Hema (other)
   has only read. That's why `./deploy.sh` → permission denied.
3. **Confirm identity/authorization:** Hema should own/run it → check policy; this is a legit build
   script she runs.
4. **Resolve (least privilege):** restore execute for the right scope —
   `sudo chmod 750 deploy.sh` and `sudo chown hema:devs deploy.sh` so owner+group can run it, "other"
   can't. Re-run → succeeds.
5. **Root cause:** ask *why the bit was lost* — often a git checkout or a root cron recreated it; note
   it so it doesn't recur.

**The professional ticket note:**
```
SUMMARY: deploy.sh on build01 lost its execute bit + was owned by root → "permission denied" for Hema.
Restored ownership (hema:devs) + perms (750); deploy runs. Flagged the root-owned recreation as root cause.
SYMPTOM: ./deploy.sh → "permission denied", previously worked.
DIAGNOSIS: ls -l → -rw-r--r-- root:root (no x; Hema is "other", read-only).
CAUSE: missing execute bit + wrong ownership (recreated by a root process).
RESOLUTION: sudo chown hema:devs deploy.sh ; sudo chmod 750 deploy.sh ; verified Hema can execute.
FOLLOW-UP: identified root cron that recreates the file as root → ticket to fix the cron's umask/chown
so it stops re-breaking. KB on "permission denied on a script" linked.
```

---

## §7 — Service Desk / ITIL Perspective

- **Category:** Server/Application (Linux). Often crosses to **Problem** when it's a recurring
  pattern (disk-full, perms reset).
- **Priority:** a downed shared service/website is P1; a single engineer blocked is P2/P3.
- **Escalation:** the **Linux/sysadmin team** owns deep config and root. Your job at support level:
  gather the precise evidence (`systemctl`/`journalctl`/`df`) so they resolve fast — that package is
  the deliverable.
- **Bridge note:** going deep on Linux is the **NaviOps** platform; this lesson is the literacy that
  lets you escalate intelligently and grow into it.

---

## §8 — Practical Lab (build this yourself)

**Goal:** get comfortable in a shell and build a reusable triage script. Use a **lab VM, WSL, or a
container** — never a production box.

### Lens C — Manual → Automation → Why
- **Manual:** run `systemctl status`, `journalctl`, `df -h`, `ls -l` one at a time.
- **Automated:** `linux_triage.sh` runs the standard checks in order and prints a snapshot —
  the same triage every time, on any box.
- **Why:** in an outage you want one consistent command that captures service+logs+disk+net at once,
  not five typed-from-memory commands; it's also attachable to the escalation ticket.

### Steps
1. **Set up a shell:** a Linux VM, WSL (`wsl --install`), or a container.
2. **Navigate + inspect:** `pwd`, `ls -lah /`, `cat /etc/os-release`, `whoami`, `id`.
3. **Permissions drill:** `touch t.sh; ls -l t.sh` (no x) → `chmod +x t.sh; ls -l` (now `x`) →
   feel the rwx model. Try `chown` (needs sudo).
4. **Service + logs:** `systemctl status ssh` (or any unit) and `journalctl -u ssh --since today`.
5. **Disk:** `df -h` and `du -sh /var/log/*` — find what would fill a disk.
6. **Write `scripts/linux_triage.sh`** (os-release + `systemctl --failed` + `df -h` + top processes +
   `ss -tulpn`); make it `+x`; `shellcheck` it clean.
7. **Write the runbook** `docs/runbooks/linux-triage.md`.

### Lens D — the raw artifact (a failed unit + the disk-full cause)
```
$ systemctl status nginx
   nginx.service - A high performance web server
   Active: failed (Result: exit-code)   ← the service is DOWN
$ df -h
   /dev/sda1   20G   20G   0  100% /var     ← the real cause: no space → nginx couldn't write/start
#   The status tells you WHAT failed; journalctl + df tell you WHY. Fix the why (disk), not just
#   "restart it" (which fails again at 100%).
```

---

## §9 — GitHub Artifact (the 6-artifact evidence package)

1. **Runbook:** `docs/runbooks/linux-triage.md` — service → logs → disk → net → fix → verify.
2. **Troubleshooting Guide:** `docs/troubleshooting/linux-service-or-permission.md` — the full spine.
3. **Ticket Notes:** `docs/tickets/ENT-05-permission-denied-script.md` — the worked ENT-05.
4. **KB Article:** `docs/kb/` — "Permission denied running a script on Linux (rwx + execute bit)".
5. **Incident Report:** the nginx disk-full outage as a mini incident report (template) if shared.
6. **Portfolio Artifact:** §10 bullet + the Windows↔Linux map talking point.
7. **Script:** `scripts/linux_triage.sh` (`shellcheck`-clean).

---

## §10 — Portfolio Artifact

- **Resume bullet:** *"Built a Bash Linux-triage script (service status, failed units, disk, top
  processes, listening ports) and a runbook, enabling fast first-line diagnosis of Linux server
  incidents and clean escalation to the sysadmin team."*
- **Interview talking point:** the **Windows↔Linux map** (`services.msc`→`systemctl`, Event
  Viewer→`journalctl`) and the rwx/ownership model behind "permission denied" — shows you transfer
  knowledge, not memorize.
- **Serves:** IT Support, Junior SysAdmin, Infrastructure Support (and the on-ramp to NaviOps).

---

## §11 — Certification Crossover Notes

- **CompTIA A+ (Core 2):** basic Linux commands & concepts, filesystem, permissions.
- **Linux+ / LFCS:** the deep version (pursue via the NaviOps platform). **Net+:** `ip`/`ss`/`ping`
  overlap (L08). Detail in `alignment/CERTIFICATION-MAPPING.md`.

---

## §12 — Support Notes (Lens E — Service & Security)

**🤝 Service:** when an engineer dictates commands, repeat them back before running and confirm the
target host — on Linux there's no "undo" and one typo on the wrong box is an outage. Communicate what
you're about to do.

**🔒 Security:** `sudo`/root is the keys to the kingdom — use **least privilege**, never run untrusted
commands as root, and treat **SSH keys/credentials** as secrets (never commit or paste them —
`navi.project.md` HR#1, danger zones). `chmod 777` "to make it work" is a security smell — grant the
*minimum* (owner/group), not world-writable. Watch for the destructive commands in the danger-zone
list.

---

## Quiz (Interview-Style, Graded)

**Q1.** Give the Linux equivalents of: Event Viewer, `services.msc`, Task Manager, and "what's my
disk space."
> **Your answer:**

**Q2.** A website on a Linux server is down. Walk me through your first three commands and what each
tells you.
> **Your answer:**

**Q3.** A user gets "permission denied" running `./script.sh`. What are the two most likely causes and
how do you check?
> **Your answer:**

**Q4.** **Scenario:** `systemctl status` shows a service "failed", you restart it, and it fails again
within seconds. What do you check next and why?
> **Your answer:**

**Q5.** Why is `chmod 777` usually the wrong fix for a permission problem?
> **Your answer:**

*(Request the "Professional Answer" comparison under each before moving on.)*

---

## Reflection
*(After the quiz)* — What did you learn? · What confused you? · What would you do differently?

---

## Search Keywords For Further Understanding

**Core**
- `linux for beginners shell commands`
- `linux file permissions rwx chmod chown explained`
- `systemctl status start enable service`
- `journalctl read service logs`
- `linux disk full df du var log`

**Tools**
- `ss -tulpn listening ports`
- `wsl install windows subsystem for linux`

**Going further**
- `filesystems and storage` (L06) · `user accounts and permissions` (L07) ·
  `networking fundamentals` (L08) · **NaviOps** (the full Linux/SysAdmin platform)

**Service / Security (Lens E):**
- 🤝 `confirming target host before running commands`
- 🔒 `linux least privilege sudo`, `ssh key security`, `why chmod 777 is dangerous`

---

## Lesson Status
- [ ] §8 lab completed (shell tour + perms drill + linux_triage.sh + runbook)
- [ ] 6-artifact evidence package committed (§9)
- [ ] Quiz answered + professional-answer comparisons (graded)
- [ ] Reflection + Search Keywords reviewed

When complete, run the Update Protocol, then move to **Lesson 06 — Filesystems & Storage**.

---

*Lesson 05 written by Navi · 2026-06-21 · full-depth. Sources to cite at study time: CompTIA A+
220-1102 (Linux basics), Linux man pages (`systemctl`, `journalctl`, `chmod`); deep dive → NaviOps.*
