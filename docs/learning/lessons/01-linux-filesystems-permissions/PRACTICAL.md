# Lesson 01 — Pure Practical: Linux Filesystems & Permissions

> **Companion to [`README.md`](./README.md).** Pure practice: 3 scenario-driven tasks, guided →
> ticket-driven → on-call. Do them after the README.
>
> **Lab:** `./infra/bootstrap.sh up` → `docker exec -it naviops-web bash`. **Node:** `naviops-web`.
> **Rules:** type it, diagnose before you fix, run the ✅ **Verify** after each task. Answers in the
> gitignored `docs/learning/reference-solutions/` — only after you try.

Each task: **Scenario · Objective · Given/constraints · Hints · ✅ Verify · Pitfalls · 🎯 Stretch.**

---

## Task 1 — Guided: lock down a shared deploy directory (fluency)

**Scenario.** `NAVI-011`. A `/srv/naviops` directory holds app files a `deployers` group edits and
everyone else only reads.

**Objective.** Create the dir + group so that group members can create/edit files, files stay
group-owned automatically, and "other" has read-only.

**Given / constraints.** Work as root/sudo in `naviops-web`. No world-write anywhere.

**Hints.**
1. `groupadd deployers`; `chgrp -R deployers /srv/naviops`.
2. `chmod 2775 /srv/naviops` — the leading `2` is the **setgid** bit (new files inherit the group).
3. Add your user: `usermod -aG deployers <user>`; re-login or `newgrp deployers`.

✅ **Verify.**
```bash
stat -c '%A %G' /srv/naviops        # drwxrwsr-x deployers   (note the 's')
sudo -u <user> touch /srv/naviops/probe && stat -c '%G' /srv/naviops/probe   # → deployers
```

**Pitfalls.**
- `chmod 775` (no setgid) → new files owned by the creator's primary group, breaking collaboration.
- Forgetting to re-login after `usermod -aG` → group membership not active in the shell.
- `777` "to make it work" — never; that's world-writable.

🎯 **Stretch.** Add a default **ACL** so any new file is group-writable regardless of umask:
`setfacl -d -m g:deployers:rwx /srv/naviops`; prove with `getfacl`.

---

## Task 2 — Ticket-driven: "I can't write to my own file" (diagnose → fix)

**Scenario.** `NAVI-012` (P3). A dev: *"deploy script fails with Permission denied writing
`/srv/naviops/releases/current`, but I own the folder!"* You have shell access. No detail on why.

**Objective.** Restore the dev's ability to write, having **first identified** the exact cause from
the permission bits — don't just `chmod 777`.

**Given / constraints.** Recreate the fault: a file owned by root with `644`, inside a dir the dev
owns. Fix by correcting *ownership or mode of the right object*, not blanket-opening it.

**Hints.**
1. `ls -l` the file **and** `ls -ld` the parent dir — write perms depend on the *file* for edits, the
   *directory* for create/delete/rename.
2. `namei -l /srv/naviops/releases/current` walks every component's perms — find the failing link.
3. Fix minimally: `chown`/`chmod` only the offending object.

✅ **Verify.**
```bash
sudo -u <dev> sh -c 'echo test >> /srv/naviops/releases/current' && echo "WRITE OK ✅"
stat -c '%a %U' /srv/naviops/releases/current   # least-privilege mode, correct owner
```

**Pitfalls.**
- Confusing "can't edit file" (file's write bit) with "can't delete file" (parent dir's write bit + sticky).
- `chmod -R 777 /srv` — opens the whole tree; a real security finding.
- Fixing the symptom on one file while the dir's `t`/setgid is still wrong for the next file.

🎯 **Stretch.** The `/srv/naviops/tmp` dir is shared but users delete each other's files. Add the
**sticky bit** (`chmod +t`) and prove user A can't `rm` user B's file.

---

## Task 3 — On-call: disk full from a permissions-mangled log (synthesis)

**Scenario.** `NAVI-013` (P1, 15 min). Alert: *"naviops-web `/` at 98%."* A runaway process wrote a
huge file somewhere; you must find the biggest offenders and reclaim space **without** deleting
something critical.

**Objective.** Find the top space consumers, identify one safe-to-truncate log, reclaim space, and
write a 5-line incident note.

**Given / constraints.** Simulate: `fallocate -l 500M /var/log/naviops-bloat.log` (or `dd`). You may
**not** `rm -rf /var/log` — target the specific file; prefer truncation over delete for open files.

**Hints.**
1. `df -h` (which mount), then `du -xh / 2>/dev/null | sort -rh | head` (biggest dirs).
2. Is anything still writing it? `lsof +L1` / `lsof /var/log/naviops-bloat.log` — if held open, `: > file` (truncate) beats `rm` (which leaks space until the fd closes).
3. Confirm reclaim with `df -h`.

✅ **Verify.**
```bash
df -h / | awk 'NR==2{print $5}'          # well under the alert threshold
test -f docs/learning/reports/NAVI-013-postmortem.md && echo "POSTMORTEM ✅"
```

**Deliverable.** `docs/learning/reports/NAVI-013-postmortem.md`: Impact · Detection · Root cause · Fix · Prevention.

**Pitfalls.**
- `rm` on a file another process holds open → space *not* freed until restart (classic gotcha).
- `du` without `-x` crosses into `/proc`/mounts and misleads you.
- Deleting logs a running service needs → new failures.

🎯 **Stretch.** Fold the detection into `scripts/disk_report.sh`: report top-5 dirs + any file >100M,
exit non-zero above a threshold — so the monitor catches it before the page.

---

## Done?
- [ ] All ✅ Verify pass · [ ] diagnosed Task 2 before fixing · [ ] postmortem written.
- [ ] No `777`/world-write introduced. **Redaction:** generic paths/users only. → [README Step 7](./README.md).
