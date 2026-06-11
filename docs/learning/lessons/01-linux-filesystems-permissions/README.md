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

Answer in your own words, scenario-style. Aim for interview-quality answers.

1. A file shows `-rw-r--r-- 1 alice devs notes.txt`. What octal number is this, and what
   can `alice`, members of `devs`, and everyone else do with it?
  -- octal number is 644.; Alice can Write and Read, members of devs and others can read only.

  **Professional Answer:** ✅ Correct on all counts. `rw-r--r--` = `644`: owner
  (`alice`) gets read+write, the `devs` group gets read-only, and everyone else gets
  read-only. Worth adding for an interview: nobody (including `alice`) can *execute*
  this file — `644` is the standard default for plain data/config files (vs `755` for
  scripts/binaries), and it's what `umask 022` produces by default for new files.

2. You run `chmod 700 ~/scripts` and now even though `deploy.sh` inside it is `755`,
   another user gets "Permission denied" trying to run
   `~/scripts/deploy.sh`. Why? What permission bit on `~/scripts` itself is the cause?
  -- because other users don't have access to the directory, they can't access the files inside it. the `x` permission bit on the directory is the cause.

  **Professional Answer:** ✅ Correct. `chmod 700 ~/scripts` removes `x` (and `r`/`w`)
  for group and others on the **directory itself**. Without `x` on the directory, no
  other user can *traverse* into `~/scripts` to reach `deploy.sh` by path — the kernel
  checks the permission bits of every directory component in a path, not just the
  final file. The file's own `755` becomes irrelevant because the path to it is
  blocked. Interview follow-up to be ready for: this is also why you can sometimes
  `cd` into a directory you can't `ls` (you have `x` but not `r`) — the inverse case.

3. Your private SSH key `~/.ssh/id_rsa` is `644`. SSH refuses to use it. What command
   fixes it, and *why* does SSH care about this at all (what's the security risk if it
   didn't)?
  -- chmod 600 ~/.ssh/id_rsa ; 644 means group and other can read which is security compromisation ssh detect automatic and pause any connections until fixed.

  **Professional Answer:** ✅ The fix (`chmod 600 ~/.ssh/id_rsa`) and the core reason
  (group/other readability of a private key is a security risk) are both right. One
  correction on mechanism: SSH doesn't "pause connections until fixed" — it **outright
  refuses to use that key** for the connection attempt, printing a loud
  `WARNING: UNPROTECTED PRIVATE KEY FILE!` and falling back to other auth methods (or
  failing). The risk it's guarding against: if any other local user (or a
  group-readable backup/share) can read your private key, they can impersonate you to
  every server that trusts that key — `600` (owner read/write only) is the minimum
  that keeps the key secret even from other accounts on the same machine.

4. A teammate says "just `chmod -R 777` the project directory, it'll fix the permission
   errors." Explain why this is a bad idea, and propose a better fix using what you
   learned (ownership, group, setgid, or ACLs).
  -- This is a bad idea because it gives full read write and execute permissions to everyone on the project directory and all files inside it including system files. A better fix would be to use `chmod -R 775` on the project directory and all files inside it which would give full read write and execute permissions to the owner and group members and read and execute permissions to others. 

  **Professional Answer:** 🔶 Partially correct — the "why it's bad" needs tightening,
  and `chmod -R 775` is an improvement but not the professional answer.
  - **On "system files":** `chmod -R 777 <project-dir>` only affects files *inside that
    directory tree* — it doesn't touch unrelated system files. The real danger is
    narrower but still serious: it makes **every file world-writable**, including
    scripts and configs. Any other user on the box (or a compromised process running
    as another user) can now modify or replace your code/config — a classic
    "supply-chain inside a shared host" risk. It also makes every *file* executable
    (`777`), even data files that were never meant to run.
  - **On `chmod -R 775`:** still applies the **same mode to files and directories
    alike** — every file gets `x` whether it needs it or not, and "775" still gives
    *all* group members full write access, which may be broader than intended.
  - **The professional fix:**
    1. Set correct **group ownership**: `chgrp -R devs project/` so the right team
       owns the tree.
    2. Set the **setgid bit on directories** (`chmod g+s` or `find project -type d
       -exec chmod g+s {} \;`) so new files automatically inherit the `devs` group —
       no more manual `chgrp` per new file.
    3. Use **different modes for files vs directories** — typically `664`/`660` for
       files and `775`/`770` for directories (directories need `x` to be traversable;
       most files don't need `x`).
    4. If you need *different* access levels for different users on the same file
       (e.g. "Bob: read-write, Carol: read-only", neither is the owner), use **ACLs**
       (`setfacl`) instead of widening `rwx` for everyone.

5. What's the difference between `chmod`, `chown`, and `chgrp`? Which one(s) typically
   require root, and why?
  -- chmod mean change permission, chown mean change owner, chgrp mean change group. typically requires root because it changes file ownership and permissions which are security sensitive operations.

  **Professional Answer:** 🔶 The definitions are right, but "typically requires root"
  is only fully true for one of the three:
  - **`chmod`** (change mode/permissions): the **file owner** can run this without
    root — no root needed.
  - **`chgrp`** (change group): the **file owner** can change the group **to any group
    they themselves belong to**, without root. Only changing it to a group you're *not*
    a member of requires root.
  - **`chown`** (change owner): on Linux, **only root** can change a file's owner to a
    different user — even the current owner can't "give away" their file to someone
    else. This prevents users from dodging disk-quota accounting by transferring files
    to other users.
  Why the distinction matters in practice: in a CI/deploy script you'll often see
  `chgrp` and `chmod` run as a normal service account, but `chown` wrapped in `sudo`.

6. You found a binary with permissions `rwsr-xr-x` owned by `root`. What does the `s`
   mean, what is this mechanism called, and give one real example where it's
   legitimately needed.
  -- The 's' in `rwsr-xr-x` means that the file is a setuid binary. This means that the file will run with the permissions of the file owner, rather than the permissions of the user who is running the file. This is a security mechanism that is used to allow users to run programs with elevated privileges. One real example where it's legitimately needed is the `passwd` command, which allows users to change their passwords. 

  **Professional Answer:** ✅ Correct and well explained — this is the **setuid bit**,
  and `passwd` is the textbook example (it must write to `/etc/shadow`, which only root
  can write, on behalf of any user changing their own password). Two extra points an
  interviewer might probe:
  - The `s` replaces the owner's `x` position; if the owner didn't have `x` at all,
    an uppercase `S` appears instead (setuid set, but not executable — usually a
    misconfiguration).
  - This is also why `find / -perm -4000` (Step 4.7) is a real **security audit**
    command: every setuid-root binary is a potential privilege-escalation vector if
    it has a bug, so sysadmins periodically diff this list against a known-good
    baseline.

7. For a **directory**, what does the `x` (execute) bit actually control? Give an
   example of a directory that's `r--` (no `x`) and explain what would and wouldn't
   work on it.
  -- For a directory, the `x` (execute) bit actually controls whether or not a user can access the contents of the directory. If a directory is `r--`, users can't access the contents of the directory, even if they have read permissions on the directory itself. 

  **Professional Answer:** 🔶 Directionally right, but the precise split between `r`
  and `x` on a directory is the most-tested detail here, and the answer glosses over
  it:
  - `r` on a directory = you can **list the names** of entries inside it (`ls`).
  - `x` on a directory = you can **traverse/access** entries inside it by path (`cd`
    into it, `cat file-inside-it`, `stat`, run a script located there, etc.) — this
    works *regardless of whether you have `r`*.
  - With `r--` (read, no execute) on a directory: `ls dir/` **works** and shows
    filenames, but `cd dir/`, `cat dir/file.txt`, or `./dir/script.sh` all **fail**
    with "Permission denied" — you can see *that* something is named `file.txt` but
    can't open or stat it.
  - The inverse (`--x`, execute no read) is also real and common: you can `cd` into
    the directory and access a file *if you already know its exact name*, but `ls`
    won't show you anything. This is sometimes used deliberately (e.g.
    `/home` often being `711` — traverse-only — so users can reach their own
    `~/public_html` without listing other users' home directories).

8. Name one alternative to plain `rwx` permissions for fine-grained access control, and
   describe a scenario where you'd need it (e.g. "user A read-only, user B read-write,
   neither is the owner").
  -- Access Control Lists (ACLs) are one alternative to plain `rwx` permissions. They allow for more fine-grained access control by allowing you to specify permissions for individual users and groups. For example, you could use ACLs to give user A read-only access to a file, user B read-write access to the same file, and neither user read-write or execute access to the file.

  **Professional Answer:** ✅ Correct. ACLs (`setfacl`/`getfacl`) are exactly the
  right tool for "user A read-only, user B read-write, neither is the owner" — plain
  `rwx` only has three slots (owner/group/other) and can't express two different
  *non-owner individuals* with different permissions on the same file without ACLs (or
  creating extra groups for every combination, which doesn't scale). One practical
  note for the field: a file with ACLs shows a `+` after its permission string in
  `ls -l` (e.g. `-rw-rw-r--+`) — that `+` is your only hint from `ls` that `getfacl`
  is worth running. SELinux/AppArmor (Step 3) are also valid answers at a different
  layer (mandatory access control vs. discretionary).

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
- [x] Quiz answered + professional-answer comparison written (Step 6)
- [x] Reflection completed (Step 7)
- [x] Search Keywords written (Step 8)

**Lesson 01 complete — 2026-06-10.** Quiz: 5/8 fully correct on first pass, 3/8
partially correct with gaps noted above (directory `r` vs `x` distinction, `chown`
root requirement nuance, and the "better fix" for bad recursive `chmod`). These three
are good candidates to revisit in Lesson 02's reflection or a later spaced-review.

Run the **Update Protocol** (`docs/learning/CLAUDE_TEACHING_RULES.md`) to update
`LEARNING_STATE.md`, `docs/STATUS.md`, `docs/CHANGELOG.md`, and `docs/TODO.md`, then
move to **Lesson 02 — Git & GitHub Fundamentals**.
