# Lesson 04 — Linux Users, Groups & Process Management

**Status:** ready for self-study · **Date written:** 2026-06-11
**Gate Rule:** Concept → Real-World Use → Alternatives → Hands-On → Verification → Quiz → Reflection → Search Keywords

> **How to use this lesson:** same as Lesson 03 — read Steps 1–3, build Step 4
> yourself, verify with Step 5, answer the Step 6 quiz then ask Navi for the
> professional-answer comparison, fill in Step 7, browse Step 8.

---

## Step 1 — Concept

### What it is

**Users and groups** are Linux's identity layer — every process and file is owned by a
user (UID) and a group (GID), and permission checks (Lesson 01) compare the
*requesting* process's UID/GID against the *target* file's owner/group. **Process
management** is how Linux tracks, schedules, and controls every running program — each
one a *process* with a unique PID, a state, and resource usage.

### Why it exists

Multi-user systems need **isolation** (your processes can't read my files) and
**accountability** (who/what is consuming CPU/RAM, who started this process). Without
user/group separation, any program could read/modify anything — there'd be no
boundary between "my web server" and "your database."

### What problem it solves

| Problem | Solution |
|---|---|
| New employee needs an account with specific group access | `useradd` + `usermod -aG` |
| A runaway process is consuming 100% CPU | `ps`/`top` to find it, `kill`/`nice` to manage it |
| "Which service is this process, and who started it?" | `ps -ef`, `/proc/<pid>/` |
| Service accounts shouldn't allow interactive login | `useradd -s /usr/sbin/nologin` |

### Three-Level Depth (Lens A)

- **Level 1 — Beginner:** `useradd <name>` creates a user, `usermod -aG <group> <name>`
  adds them to a group (the `-a` = **append**, critical — without it `-G` *replaces*
  all existing group memberships), `groupadd <name>` creates a group. `ps aux` lists
  running processes; `kill <pid>` asks a process to terminate.
- **Level 2 — SysAdmin:** User/group data lives in four files —
  `/etc/passwd` (username:UID:GID:home:shell), `/etc/shadow` (hashed passwords +
  aging policy, mode `600`), `/etc/group` (group names + members), `/etc/gshadow`.
  Per [Owais.io's 2025 guide](https://www.owais.io/blog/2025-10-06_linux-user-group-management-beginners/)
  and [oneuptime's 2026 guide](https://oneuptime.com/blog/post/2026-01-24-user-management-useradd-usermod/view),
  best practice: always pair `useradd` with `-m` (create home dir) and `-s` (set
  shell — `/bin/bash` for humans, `/usr/sbin/nologin` for service accounts). For
  processes: `top`/`htop` for live monitoring, `nice`/`renice` to adjust CPU
  scheduling priority (-20 highest, 19 lowest), `kill -<signal> <pid>` to send
  specific signals (not just "kill").
- **Level 3 — Systems/Kernel (Lens D):** Every process has a **PCB (Process Control
  Block)** in the kernel — `struct task_struct` in Linux source — containing its PID,
  UID/GID (`struct cred`), state, open file descriptors, and memory mappings. The
  `/proc/<pid>/` filesystem is a **direct window into this struct** — `/proc/<pid>/status`
  shows UID/GID/state, `/proc/<pid>/fd/` shows open file descriptors. Process states
  (seen in `ps aux` STAT column): `R` (running/runnable), `S` (interruptible sleep —
  waiting for I/O or a signal), `D` (uninterruptible sleep — usually disk I/O, *can't*
  even be killed with SIGKILL), `Z` (zombie — process exited but parent hasn't called
  `wait()` yet, so its exit status lingers in the process table), `T` (stopped, e.g.
  by `SIGSTOP`/Ctrl+Z). **Signals** are software interrupts delivered by the kernel —
  `kill -9 <pid>` sends `SIGKILL` (signal 9, cannot be caught/ignored — the kernel
  force-removes the process), `kill -15 <pid>` (default) sends `SIGTERM` (can be
  caught by the program for graceful shutdown — close files, flush buffers, *then*
  exit). This is why `kill` (SIGTERM) before `kill -9` (SIGKILL) is the correct order
  — SIGTERM gives the process a chance to clean up.

### Analogy (Lens B)

- **Users/groups** = building access cards. Your card (UID) is yours alone; group
  membership (e.g., "Engineering") is a *badge category* that opens shared doors
  (group-owned files/directories) without needing a separate card per door.
- **Processes** = workers in a factory, each with a badge number (PID), a current
  activity (state: working=R, on break waiting for materials=S, in a meeting they
  can't be pulled from=D), and a supervisor (parent process). **Signals** are
  messages sent to a worker: "please wrap up and go home" (SIGTERM — they can finish
  their current task first) vs. "security is escorting you out right now" (SIGKILL —
  no negotiation).

This analogy holds for individual processes but breaks down for **zombies** — a
factory worker who already left but whose timesheet (exit status) is still sitting on
the supervisor's desk because the supervisor hasn't signed off on it yet. The "worker"
isn't doing anything (no CPU/memory use beyond the table entry), but the entry
persists until the parent calls `wait()`.

---

## Step 2 — Real-World Use

### How SysAdmins use this daily

```bash
# Onboarding a new team member with sudo + docker group access
sudo useradd -m -s /bin/bash -G sudo,docker newhire
sudo passwd newhire

# Creating a service account (no login)
sudo useradd -r -s /usr/sbin/nologin svc_appuser

# Investigating high CPU usage
top                          # live view, sorted by CPU by default
ps aux --sort=-%cpu | head   # snapshot, top CPU consumers

# Gracefully then forcefully stopping a stuck process
kill <pid>        # SIGTERM — ask nicely
sleep 5
kill -9 <pid>     # SIGKILL — force, only if SIGTERM didn't work
```

### Common mistakes

| Mistake | Impact | Fix |
|---|---|---|
| `usermod -G docker user` (no `-a`) | **Removes** the user from every other group — silent privilege loss | Always `usermod -aG` |
| `useradd` without `-m` | No home directory created — login/SSH config issues | `useradd -m` |
| Service accounts with `/bin/bash` shell | Unnecessary attack surface (someone can `su` into it and get a shell) | `-s /usr/sbin/nologin` |
| Reaching for `kill -9` first | Process can't clean up — corrupted temp files, locked DB rows, orphaned children | Try `kill` (SIGTERM) first, wait, then `-9` |
| Editing `/etc/passwd`/`/etc/shadow` directly | Syntax errors can lock out **all** logins | Use `usermod`/`vipw` (which locks the file properly) |

### When NOT to

- Don't create a new Linux user for every application config change — use **groups**
  and shared directories with setgid (Lesson 01 carry-over) instead of loosening
  individual user permissions.
- Don't `kill -9` a process touching a database or writing a file mid-transaction
  unless SIGTERM has genuinely failed — risk of data corruption.

### Interview Angle

**Question:** "A teammate ran `usermod -G docker alice` to give Alice Docker access.
The next day, Alice can't SSH in normally, and several of her cron jobs are failing.
What happened, and how do you fix it without making things worse?"

A **junior** answer might just re-add the missing groups one by one from memory. A
**senior** answer first diagnoses: `usermod -G` (no `-a`) **replaces** the entire group
list, so Alice likely lost `sudo`, `adm`, or whatever groups her cron jobs and SSH
session depended on (e.g., group-owned key directories, log access). The senior fixes
it by checking `/etc/group` (or a backup of it, or `last`/audit logs) to recover the
*original* membership list, then runs `usermod -aG <original-groups> alice` — the `-a`
is the actual fix, and the senior explains *why* `-aG` should be the default habit
going forward, not just patches this one instance.

---

## Step 3 — Alternatives

### User/group management alternatives

| Tool | Use case |
|---|---|
| `useradd`/`usermod`/`groupadd` (this lesson) | Direct, scriptable, works everywhere |
| `adduser` (Debian/Ubuntu wrapper) | Friendlier interactive prompts, but a wrapper — `useradd` is the portable underlying tool |
| **Ansible `user`/`group` modules** | Declarative, idempotent — define desired state once, apply to many hosts (Lesson 13) |
| **LDAP/Active Directory + SSSD** | Centralized identity for many machines — beyond a single-host scope but standard in enterprises |

### Process management alternatives

| Tool | Use case |
|---|---|
| `ps`, `kill` (this lesson) | Universal, scriptable |
| `top`/`htop` | Interactive live monitoring (`htop` — nicer UI, not always preinstalled) |
| `pgrep`/`pkill` | Find/signal processes **by name** instead of PID — `pkill -f myapp` |
| `systemctl` (Lesson 05) | For services managed by systemd — `systemctl restart` is preferred over manually killing+restarting a service's process |

**For NaviOps:** use `useradd`/`usermod` directly for now (single-host); Ansible
(Lesson 13) becomes the right tool once managing more than one machine.

---

## Step 4 — Hands-On Task (build this yourself)

**Goal:** Extend `scripts/user_audit.sh` (Lesson 03) with process-monitoring checks —
or create `scripts/process_monitor.sh` if you prefer to keep concerns separate
(either is fine; document your choice in the script header comment).

### Lens C — Manual → Automated → Why

**Manual:**
```bash
# List all users with login shells (potential interactive accounts)
awk -F: '$7 !~ /(nologin|false)/ {print $1, $7}' /etc/passwd

# Top 5 processes by memory
ps aux --sort=-%mem | head -6

# Find zombie processes
ps aux | awk '$8 == "Z"'
```

**Automated** — add three functions to your audit script (reusing the `log()` helper
from Lesson 03). Write them yourself; each is a thin wrapper around one of the manual
commands above:

- **`check_login_capable_accounts()`** — wrap the `awk` over `/etc/passwd` that prints
  accounts whose shell isn't `nologin`/`false`.
- **`check_top_processes()`** — wrap `ps aux --sort=-%mem | head -6`.
- **`check_zombie_processes()`** — wrap `ps aux | awk '$8 ~ /Z/'`; print "none found"
  when empty.

Then call all three from `main()`. The point is reuse: the same `log()`/`main()` pattern
from Lesson 03 now grows with new checks — you implement the bodies.

**Why this matters:** an account with an interactive shell that *shouldn't* have one
(e.g., a service account someone created with plain `useradd`) is a real finding in
security audits (ties forward to Lesson 10/23). Zombie processes accumulating over
time can exhaust the process table (`PID_MAX`) — a real production incident class.

### What to build, step by step

1. On your own user account (don't experiment on real production accounts), practice:
   `sudo useradd -m -s /bin/bash testuser`, `sudo usermod -aG <some-group> testuser`,
   inspect `/etc/passwd` and `/etc/group` before/after, then `sudo userdel -r
   testuser` to clean up.
2. Add the three functions above to your audit script.
3. Run the script and review the output — does your system have any zombies? Any
   accounts with shells that shouldn't have them?
4. Call the new functions from `main()`.
5. Commit on `lesson/04-linux-users-groups-processes`.

### Lens D — small focused C example

Demonstrating a **zombie process** (parent doesn't call `wait()`):

```c
#include <stdio.h>
#include <unistd.h>

int main(void) {
    pid_t pid = fork();
    if (pid == 0) {
        _exit(0);            // child exits immediately
    } else {
        sleep(30);           // parent sleeps WITHOUT calling wait()
        // for 30 seconds, run `ps aux | grep Z` in another terminal —
        // you'll see the child as <defunct> (zombie)
    }
    return 0;
}
```

This is the exact mechanism behind the `Z` state from Step 1 — the child's exit
status sits in the kernel's process table until `wait()` (or the parent itself exits,
at which point `init`/PID 1 adopts and reaps it).

### Optional: failure drill

When you're ready for a timed challenge, try [`troubleshooting-drills.md` §4 (Broken sudo access)](../../troubleshooting-drills.md#4-broken-sudo-access) in your sandbox VM.

---

## Step 5 — Verification

```bash
# Confirm useradd/userdel round-trip cleanly
sudo useradd -m -s /bin/bash testuser
id testuser                       # shows UID, GID, groups
sudo userdel -r testuser
id testuser                       # should now error: "no such user"

# Confirm script still passes syntax check and runs
bash -n scripts/user_audit.sh
./scripts/user_audit.sh
```

### Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| `usermod: group 'docker' does not exist` | Group not created yet | `groupadd docker` first, or install Docker (creates it) |
| New user can't log in via SSH | Shell set to `/usr/sbin/nologin` or home dir missing | Check `/etc/passwd` entry; recreate with `-m -s /bin/bash` |
| `userdel: user testuser is currently used by process X` | A process (e.g., a leftover shell) is still running as that user | `pkill -u testuser` first, then `userdel` |
| Zombie processes never go away | Parent process itself is stuck/buggy | Restart or kill the **parent** — killing the zombie itself does nothing (it's already dead) |

### Redaction check ✅

Confirm no real usernames (other than your own local test account names like
`testuser`) appear in committed output.

---

## Step 6 — Quiz (Interview-Style, Graded)

> Answer inline, then ask Navi for the professional-answer comparison.

**Q1.** What is the difference between `usermod -G docker alice` and
`usermod -aG docker alice`? Why is this a famous "gotcha"?

> **Your answer:**

**Q2.** Where does Linux store (a) usernames/UIDs, (b) hashed passwords, and (c)
group memberships? Why are these split into separate files?

> **Your answer:**

**Q3.** **Scenario:** `top` shows a process in state `D` consuming little CPU but the
system feels frozen. What does state `D` mean, and why might `kill -9` not work on it?

> **Your answer:**

**Q4.** Explain the difference between `SIGTERM` and `SIGKILL`. Why should you almost
always try `SIGTERM` first?

> **Your answer:**

**Q5.** What is a zombie process? Does it consume CPU or memory? How do you actually
get rid of one?

> **Your answer:**

**Q6.** **Scenario:** You're asked to create a service account for a new application
that should never be used for interactive login. Write the `useradd` command and
explain each flag.

> **Your answer:**

**Q7.** How would you find and kill all processes matching the name `myapp` without
knowing the PID in advance?

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

**🔴 Attacker (how it's abused — Step 2):** Attackers enumerate accounts (`/etc/passwd`, `id`, `getent`), then escalate via sudo misconfig — `sudo -l` reveals NOPASSWD or GTFOBins-abusable commands. They masquerade malicious processes and add rogue users/UID-0 accounts. ATT&CK **T1087** (Account Discovery), **T1548.003** (Sudo), **T1036** (Masquerading).

**🔵 Defender (detect & harden — Step 5):** Audit `sudoers` (`visudo -c`, no broad NOPASSWD), alert on new users / any second UID-0 account, lock unused accounts, and baseline processes so anomalies (unexpected parent, odd path) stand out in `ps`/auditd.

## Step 8 — Search Keywords For Further Understanding

**Core**
- `linux useradd usermod groupadd explained`
- `etc passwd etc shadow etc group format`
- `linux process states D R S Z T meaning`
- `signals sigterm sigkill difference`

**Tools**
- `htop vs top vs ps aux`
- `pgrep pkill examples`
- `proc filesystem pid status explained`

**Going further (future lessons)**
- `ansible user module idempotent`
- `systemd manage service vs kill process`
- `linux process table pid_max exhaustion`

---

**Red / Blue (Lens E — study attacker & defender in parallel):**
- 🔴 **Red (attacker):** `sudo -l privilege escalation`, `MITRE ATT&CK T1548.003 sudo abuse`, `linux account enumeration /etc/passwd`, `process masquerading T1036`
- 🔵 **Blue (defender):** `sudoers audit visudo`, `detect rogue UID 0 account`, `auditd process monitoring`, `least privilege linux users`

## Lesson Status

- [ ] Hands-on task completed (Step 4)
- [ ] Verification passed (Step 5)
- [ ] Quiz answered + professional-answer comparisons requested (Step 6)
- [ ] Reflection completed (Step 7)
- [ ] Search Keywords reviewed (Step 8)

When complete, run the Update Protocol, then move to **Lesson 05 — systemd, Services
& journald**.

---

*Lesson 04 written by Navi v28 · 2026-06-11 · WebSearch sources:
[Owais.io Linux user/group management](https://www.owais.io/blog/2025-10-06_linux-user-group-management-beginners/),
[oneuptime useradd/usermod guide](https://oneuptime.com/blog/post/2026-01-24-user-management-useradd-usermod/view),
[LinuxBlog.io useradd/usermod/groupadd](https://linuxblog.io/linux-useradd-usermod-groupadd/)*
