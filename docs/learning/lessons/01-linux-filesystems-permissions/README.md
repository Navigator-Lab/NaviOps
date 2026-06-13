# Lesson 01 — Linux Filesystems & Permissions

**Status:** in progress · **Date started:** 2026-06-10
**Gate Rule:** Concept → Real-World Use → Alternatives → Hands-On → Verification → Quiz → Reflection
(see `docs/learning/CLAUDE_TEACHING_RULES.md`)

---

## Step 1 — Concept

### What it is

Linux organizes everything — files, directories, devices, sockets, even running
processes (`/proc`) — into a single tree rooted at `/`. Two ideas matter most for this
lesson:

1. **The Filesystem Hierarchy Standard (FHS)** — a convention for *what lives where*:

| Path | Purpose |
|---|---|
| `/` | root of everything |
| `/bin`, `/usr/bin` | user executables |
| `/sbin`, `/usr/sbin` | system admin executables |
| `/etc` | system-wide configuration files (text) |
| `/home` | per-user home directories |
| `/var` | variable data: logs (`/var/log`), spool, caches |
| `/tmp` | temporary files, cleared on reboot |
| `/opt` | optional/third-party software |
| `/proc`, `/sys` | virtual filesystems exposing kernel/process info |
| `/dev` | device files (disks, terminals, etc.) |
| `/mnt`, `/media` | mount points for external/extra filesystems |

2. **The permission model** — every file/directory has an **owner** (user), a
   **group**, and a set of **permission bits** for three classes: *owner*, *group*,
   *others*. Each class can have **r**ead, **w**rite, **e**xecute.

```
-rwxr-xr--  1 alice devs  4096 Jun 10 09:00 deploy.sh
 │└┬┘└┬┘└┬┘
 │ │  │  └─ others: r-- (read only)
 │ │  └──── group:  r-x (read + execute)
 │ └─────── owner:  rwx (read, write, execute)
 └───────── file type (- = regular file, d = directory, l = symlink)
```

For a **file**: `r` = read contents, `w` = modify/delete contents, `x` = execute as a
program/script.
For a **directory**: `r` = list contents (`ls`), `w` = create/delete/rename entries
inside it, `x` = "traverse" — `cd` into it or access files inside by path, even if you
can't list them.

Permissions are also expressed as **octal numbers** — each `rwx` triplet is 3 bits =
0–7:

```
r = 4, w = 2, x = 1
rwx = 4+2+1 = 7
r-x = 4+0+1 = 5
r-- = 4+0+0 = 4
```

So `rwxr-xr--` = `754`.

### Why it exists

Multi-user systems need a way to isolate users from each other and from the system
itself — your shell history shouldn't be world-writable, and a regular user shouldn't
be able to overwrite `/etc/shadow`. The owner/group/other + rwx model is a simple,
fast, kernel-enforced way to do that on every file operation, with near-zero overhead.

### What problem it solves

- **Isolation** — users can't read/modify each other's files by default.
- **Least privilege** — a service can run as a dedicated user that only has access to
  what it needs (e.g. `www-data` can read `/var/www` but not `/etc/shadow`).
- **Safety** — accidental `rm` of a system file is blocked unless you have write
  permission on the *directory* containing it (not just the file).

### Three-Level Depth (Lens A)

- **Level 1 — Beginner:** every file/directory has an owner, a group, and `rwx` bits
  for owner/group/others. `chmod`, `chown`, `chgrp` change them.
- **Level 2 — SysAdmin:** you read/set permissions with `ls -l`/`stat`/`chmod`/`chown`,
  use `750`/`640`-style modes for services, `setgid` for shared team directories, and
  `getfacl`/`setfacl` when `rwx`'s three slots aren't enough.
- **Level 3 — Kernel/C (Lens D):** every permission check happens **inside the
  kernel**, on every `open()`/`stat()`/`exec()` syscall. The permission bits live in
  the file's **inode** as part of `st_mode` (a `mode_t` bitmask — the same octal value
  `chmod` sets). In C:
  ```c
  #include <sys/stat.h>
  struct stat st;
  stat("notes.txt", &st);
  printf("mode: %o\n", st.st_mode & 0777);   // prints e.g. 640
  ```
  When a process calls `open("notes.txt", O_RDONLY)`, the kernel compares the calling
  process's **effective UID/GID** against the inode's owner/group/`st_mode` bits
  *before* returning a file descriptor — `chmod 600 ~/.ssh/id_rsa` works because the
  next `open()` by another user is rejected at this exact check, not because some
  daemon "scans" permissions afterward.

### Analogy (Lens B)

Think of a file's permission bits like an **apartment building**:
- The **owner** has their own key (`rwx` for the owner triplet) — full access to their
  unit.
- The **group** is like building staff with a master key to common areas only (`rwx`
  for group) — they can get into shared spaces but not redecorate your apartment
  unless you grant write access.
- **Others** are like visitors at the front desk (`rwx` for others) — by default they
  can't even see what's behind locked doors.
- A **directory's `x` bit** is the building's front-door lock: without it, having a key
  to apartment 4B (`rwx` on the file) is useless — you can't get past the lobby to
  reach the apartment door at all. This is why a `700` directory blocks access to a
  `755` file inside it (Quiz Q2).

This analogy holds well for owner/group/other + traversal, but it breaks down for
**setuid** (Step 1's `passwd` example) — there's no everyday-building equivalent of "a
visitor can temporarily borrow the owner's key for one specific task and then it's
revoked automatically."

---

## Step 2 — Real-World Use

### Real production scenarios

- **Web server**: Nginx runs as `www-data`. Files in `/var/www/html` are owned by
  `www-data:www-data` with `750` so the web server can read/serve them but other users
  can't browse the document root.
- **Shared project directory**: a team directory `/srv/project` is owned by a shared
  group `devs`, with the **setgid bit** (`g+s`) set so new files inherit the group —
  everyone on the team can collaborate without manually `chgrp`-ing every new file.
- **SSH keys**: `~/.ssh/id_rsa` *must* be `600` (owner read/write only). SSH refuses to
  use a private key that's group/world-readable — this is a real, common "why won't SSH
  work" interview/troubleshooting scenario.
- **Cron/log directories**: `/var/log` is typically `755` but individual log files are
  often `640`, owned by `root:adm`, so the `adm` group (sysadmins) can read logs without
  being root.
- **Setuid binaries**: `/usr/bin/passwd` is `rwsr-xr-x` (setuid root) — it runs with
  root privileges *temporarily* so a normal user can update their own password entry in
  `/etc/shadow`, which they otherwise can't write to.

### How SysAdmins use it

- `ls -l` constantly, to sanity-check ownership/permissions before debugging "permission
  denied" errors.
- `chmod`/`chown`/`chgrp` to fix access issues — almost always combined with `-R` for
  directory trees, but **carefully**, because recursive changes can break things (e.g.
  making all files in `~/.ssh` `777` recursively breaks SSH entirely).
- `find` to audit: e.g. `find / -perm -4000` to list all setuid binaries (a common
  security audit step — setuid root binaries are a privilege-escalation attack surface).
- `df -h` / `du -sh` to check disk usage by filesystem/directory — one of the most
  common "server is full" first commands.
- `mount` / `/etc/fstab` to understand what's mounted where (relevant when `/var` or
  `/home` is on a separate partition/EBS volume).

### Common mistakes

- `chmod 777` "to make it work" — disables all access control; a classic security
  finding in audits and a common cause of "it worked in dev, got hacked in prod."
- Forgetting that **directory** `x` permission is what allows traversal — a file can be
  `777` but inaccessible if a parent directory lacks `x` for that user.
- Recursive `chown`/`chmod` on `/` or `/home` by mistake (e.g. a typo'd path) — can lock
  you out of the system or break `sudo`/SSH (which check permission strictness).
- Confusing **user** vs **effective user** when debugging setuid/sudo behavior.

### When NOT to use file permissions alone

- For fine-grained access control beyond owner/group/other (e.g. "user A can write but
  user B can only read, both non-owners"), plain `rwx` isn't enough — that's what
  **ACLs** (`setfacl`/`getfacl`) or application-level auth are for.
- For *confidentiality* against a root user or anyone with physical access — file
  permissions don't protect against root or disk-level access; that needs **encryption**
  (LUKS, encrypted EBS, etc.).

### Interview Angle

A classic interview question: *"A web app can't read a file even though `ls -l` shows
`644` and the right owner — what do you check next?"* The expected answer is **SELinux
context** (`ls -lZ`, `ausearch -m avc`), not more `chmod`. This is the exact scenario
in [`troubleshooting-drills.md` §1](../../troubleshooting-drills.md#1-selinux-denial--autorelabel-trap)
— interviewers use it because it separates candidates who only know `chmod` from
those who understand the full access-control stack (DAC + MAC).

---

## Step 3 — Alternatives

| Approach | What it adds | Pros | Cons |
|---|---|---|---|
| **Standard rwx (owner/group/other)** | baseline model used everywhere | simple, fast, universally supported | coarse — only 3 identities per file |
| **POSIX ACLs** (`setfacl`/`getfacl`) | per-user/per-group extra rules on top of rwx | fine-grained ("user bob: rw, group qa: r") without changing ownership | not all tools/backups preserve ACLs; easy to forget they exist (`ls -l` shows a `+` but not the detail) |
| **SELinux / AppArmor (MAC)** | mandatory access control beyond DAC (discretionary) — labels/policies enforced by the kernel regardless of file owner | strong containment even if a process is compromised or misconfigured; standard on RHEL (SELinux) / Ubuntu (AppArmor) | steep learning curve; "permission denied" can come from SELinux *even when rwx looks fine* — a very common real-world debugging trap |
| **Capabilities** (`setcap`) | grant a binary a specific privileged capability (e.g. `CAP_NET_BIND_SERVICE`) instead of full root via setuid | least-privilege alternative to setuid-root | per-binary, less familiar, not a full replacement for setuid in all cases |
| **Encryption (LUKS, fscrypt)** | confidentiality at rest | protects data even if filesystem permissions are bypassed (stolen disk) | doesn't replace access control — orthogonal concern |

**Takeaway for this lesson:** standard rwx + ownership is the foundation everything
else builds on — ACLs/SELinux/AppArmor *layer on top of*, not replace, it. We'll master
rwx first; ACLs and SELinux/AppArmor are flagged in `LEARNING_STATE.md` as future
topics (Security skill area).

---

## Step 4 — Hands-On Task

> Run these on your local Linux dev environment (this VS Code / Claude Code session's
> shell). No real infrastructure is touched — this is local filesystem practice only.

**Lens C (Bash automation) note:** every command below is run **manually** first to
build the mental model. The automation opportunity — and what production engineers
actually run — is a permissions/setuid **audit script** (`scripts/user_audit.sh`,
future lesson): instead of a human running `find /usr/bin /usr/sbin -perm -4000` by
hand on each server, a cron job runs it nightly, diffs the output against a known-good
baseline, and alerts on new setuid binaries. Manual `ls -l`/`chmod` stays essential for
*fixing* a specific permission issue; automation is for *detecting drift at scale*.

### 4.1 — Explore the FHS

```bash
ls -ld / /etc /var /var/log /tmp /home
```

### 4.2 — Read permissions on a real file

```bash
ls -l ~/.bashrc
stat ~/.bashrc
```

Note the owner, group, and the `Access`/`Octal` mode `stat` reports.

### 4.3 — Create a practice sandbox

We'll create a small sandbox under this project (gitignored — see `4.6`) to practice
without touching anything real:

```bash
mkdir -p ~/naviops-sandbox/lesson01
cd ~/naviops-sandbox/lesson01
touch script.sh notes.txt
mkdir shared_dir
ls -l
```

### 4.4 — Practice `chmod` (symbolic and octal)

```bash
# Make script.sh executable for the owner only
chmod u+x script.sh
ls -l script.sh

# Set notes.txt to owner read/write, group read, others nothing -> 640
chmod 640 notes.txt
ls -l notes.txt

# Set shared_dir to rwxr-x--- (owner full, group can enter+list, others nothing) -> 750
chmod 750 shared_dir
ls -ld shared_dir
```

### 4.5 — Practice `chown`/`chgrp` (read-only check — don't run as root)

```bash
# See your current user/group
id

# Try changing group ownership to your own primary group (no-op but shows the command)
chgrp "$(id -gn)" notes.txt
ls -l notes.txt
```

> Changing *owner* (`chown user:group`) normally requires root — note this down for the
> quiz, but don't run `sudo chown` on real files yet.

### 4.6 — Wire the sandbox into NaviOps' `.gitignore`

Practice sandboxes shouldn't be committed. Confirm `~/naviops-sandbox/` is outside the
repo (it is — it's in `$HOME`, not under `NaviOps/`), so no `.gitignore` change is
needed. **Note this as your first "why" for `.gitignore` discipline** — you'll revisit
this when sandboxes *do* live inside the repo (e.g. Docker volumes in later lessons).

### 4.7 — Find setuid binaries (read-only audit)

```bash
find /usr/bin /usr/sbin -perm -4000 -type f 2>/dev/null
```

This is a real security-audit command — make a note of 2–3 binaries it lists (e.g.
`passwd`, `sudo`, `mount`) for the quiz.

### Optional: failure drill

When you're ready for a timed challenge, try
[`troubleshooting-drills.md` §1 (SELinux denial)](../../troubleshooting-drills.md#1-selinux-denial--autorelabel-trap)
in your sandbox VM — this is the natural next step once `rwx`/ownership feels solid,
and it's the most-cited RHCSA + interview gotcha.

---

## Step 5 — Verification

### How to verify success

After Step 4, run:

```bash
ls -l ~/naviops-sandbox/lesson01
```

Expected output (permissions should match what you set):

```
-rwxr--r--  1 <you> <group>    0 ... script.sh     # x added for owner
-rw-r-----  1 <you> <group>    0 ... notes.txt     # 640
drwxr-x---  2 <you> <group> 4096 ... shared_dir    # 750
```

Confirm:
- `script.sh` shows `x` in the **owner** triplet only.
- `notes.txt` shows `rw-r-----` (owner rw, group r, others none).
- `shared_dir` shows `rwxr-x---`.

### Troubleshooting

- **"Permission denied" running `./script.sh`**: check `x` bit with `ls -l` — if
  missing, `chmod u+x script.sh`.
- **`chmod: changing permissions: Operation not permitted`**: you don't own the file —
  check with `ls -l` and `id`; you likely need `sudo` (but never `sudo chmod` on your
  sandbox files — that's a sign something's wrong, e.g. wrong directory).
- **`find` returns nothing for setuid binaries**: try with `sudo find ...` — some
  distros restrict listing without elevated read on certain dirs (note this as a
  permission-on-directory example in itself).

### Redaction check (Rule 10)

This lesson uses only:
- A local sandbox path under `~/naviops-sandbox/` (no real hostnames/IPs/account IDs).
- Generic file/group names (`alice`, `devs`, `www-data`) as illustrative examples, not
  real system data.
- `id` / `stat` / `ls -l` output is **not pasted into this file** — the learner runs
  these locally and compares against the *expected* patterns shown above.

✅ No real account IDs, IPs, hostnames, ARNs, or secrets appear in this file.

---

## Step 6 — Quiz

> **Instructions:** Answer each question directly under it, in your own words,
> scenario-style. Aim for interview-quality answers. Once answered, ask Navi for the
> Professional Answer comparison for each.

1. A file shows `-rw-r--r-- 1 alice devs notes.txt`. What octal number is this, and what
   can `alice`, members of `devs`, and everyone else do with it?

   > **Your answer: Octal Number is 644. Alice the owner can read and Write , Group devs and others can read only**

2. You run `chmod 700 ~/scripts` and now even though `deploy.sh` inside it is `755`,
   another user gets "Permission denied" trying to run
   `~/scripts/deploy.sh`. Why? What permission bit on `~/scripts` itself is the cause?

   > **Your answer: another user has the permission 0 which is no permission to read write or excute , he will not be able to access the folder and What ever inside it even if have the permission to run this file.The fix is to give the user the permisson to access that folder by change the octal to 711 using command chmod 711 ~/scripts; There is no need for 755 here since the task is to run a specific script not to read or write or List the directory content , so the least privilige is preffered**

3. Your private SSH key `~/.ssh/id_rsa` is `644`. SSH refuses to use it. What command
   fixes it, and *why* does SSH care about this at all (what's the security risk if it
   didn't)?

   > **Your answer:The Private ssh key only the owner should have access to it because it contains the private key that can be used to access the server. The command to fix it is chmod 600 ~/.ssh/id_rsa**

4. A teammate says "just `chmod -R 777` the project directory, it'll fix the permission
   errors." Explain why this is a bad idea, and propose a better fix using what you
   learned (ownership, group, setgid, or ACLs).

   > **Your answer: it is a bad idea because it will give all the users the permission to read write and excute the files and folders which is a security risk. The best way to fix this is to give the users the permission to access that folder by change the octal to 711 using command chmod 711 ~/scripts; There is no need for 755 here since the task is to run a specific script not to read or write or List the directory content , so the least privilige is preffered**

5. What's the difference between `chmod`, `chown`, and `chgrp`? Which one(s) typically
   require root, and why?

   > **Your answer:The chmod command is used to change the permissions of a file or directory. The chown command is used to change the owner of a file or directory. The chgrp command is used to change the group of a file or directory. The chown and chgrp commands typically require root because they are used to change the ownership of a file or directory**

6. You found a binary with permissions `rwsr-xr-x` owned by `root`. What does the `s`
   mean, what is this mechanism called, and give one real example where it's
   legitimately needed.

   > **Your answer: The 's' in the permissions stands for setuid (set user ID). It is a special permission that allows a user to execute a program with the privileges of the owner of the file, rather than their own privileges. It is called the setuid mechanism. One real example where it is legitimately needed is the passwd command, which allows a user to change their password. The passwd command is owned by root, and when a user runs it, it needs to be able to modify the password file, which is also owned by root. The setuid bit allows the user to do this without having to be root themselves**

7. For a **directory**, what does the `x` (execute) bit actually control? Give an
   example of a directory that's `r--` (no `x`) and explain what would and wouldn't
   work on it.

   > **Your answer: The 'x' (execute) bit on a directory allows a user to enter (cd into) the directory and access files within it, provided they have the necessary read permissions on those files. If a directory is 'r--' (read-only) with no execute permission, users can read the names of files listed in the directory (if they also have 'r'), but they cannot cd into it or access the files inside it, even if they have read/write permissions on those specific files. For example, if a directory /data is 'r--' for a user, they can run 'ls /data' to see the filenames, but 'cd /data' or 'cat /data/file.txt' will fail with 'Permission denied'**

8. Name one alternative to plain `rwx` permissions for fine-grained access control, and
   describe a scenario where you'd need it (e.g. "user A read-only, user B read-write,
   neither is the owner").

   > **Your answer: One alternative to plain rwx permissions for fine-grained access control is Access Control Lists (ACLs). ACLs allow you to set permissions for specific users or groups beyond the standard owner/group/other model. For example, you might need a scenario where user A has read-only access to a file, user B has read-write access, and user C has no access, even if all three are members of the same group. ACLs allow you to achieve this level of fine-grained control**

---

## Step 7 — Reflection

> To be filled in by the operator after completing Steps 4–6.

1. **What did you learn?**
   _(your answer here)_
  -- I Learnt how linux file system permissions work and how to use chmod, chown, and chgrp commands. 
  
2. **What confused you?**
   _(your answer here)_
  -- I was confused about the execute bit on directories.

3. **What would you do differently next time?**
   _(your answer here)_
  -- I would practice more with the commands and try to understand the execute bit on directories better.

---

## Step 8 — Search Keywords For Further Understanding

**Core**
- `linux file permissions explained`
- `chmod octal vs symbolic notation`
- `linux directory execute permission vs read permission`
- `setuid setgid sticky bit linux explained`

**Tools**
- `getfacl setfacl tutorial linux`
- `find perm 4000 setuid audit`
- `ssh key permissions 600 unprotected private key`

**Going further (future lessons)**
- `selinux vs apparmor explained`
- `linux file permissions interview questions`
- `umask explained linux defaults`

---

## Lesson Status

- [x] Hands-on task completed (Step 4)
- [x] Verification passed (Step 5)
- [x] Quiz answered + professional-answer comparisons requested (Step 6)
- [x] Reflection completed (Step 7)
- [x] Search Keywords reviewed (Step 8)
