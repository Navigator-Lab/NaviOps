# Lesson 07 — Pure Practical: SSH, Packages & Storage

> **Companion to [`README.md`](./README.md).** Pure practice: 3 scenario tasks, guided → ticket-driven
> → on-call. Do them after the README.
>
> **Lab:** two nodes — `docker exec -it naviops-web bash` and `naviops-db`. **Rules:** type it,
> diagnose before you fix, run ✅ **Verify** each task.

Each task: **Scenario · Objective · Given/constraints · Hints · ✅ Verify · Pitfalls · 🎯 Stretch.**

---

## Task 1 — Guided: passwordless key auth between two hosts (fluency)

**Scenario.** `NAVI-071`. Automation on `naviops-web` must run commands on `naviops-db` without a
password — key-based auth only.

**Objective.** Generate a keypair, install the public key, and confirm `ssh naviops-db` works with no
password and password auth is not relied upon.

**Given / constraints.** ed25519 key, correct perms (`700` `~/.ssh`, `600` private key). No private key ever leaves the host.

**Hints.**
1. `ssh-keygen -t ed25519 -C naviops-web`.
2. `ssh-copy-id user@naviops-db` (or append the `.pub` to `~/.ssh/authorized_keys`).
3. Test: `ssh -o BatchMode=yes user@naviops-db true` (BatchMode fails instead of prompting → proves keys work).

✅ **Verify.**
```bash
ssh -o BatchMode=yes user@naviops-db 'hostname' && echo "KEY AUTH ✅"
stat -c '%a' ~/.ssh/id_ed25519          # 600
```

**Pitfalls.**
- `~/.ssh` or key world-readable → sshd refuses the key silently (see `authorized_keys` perms too).
- Copying the *private* key to the remote — never; only the `.pub` goes.
- Debug with `ssh -v` to see why a key is rejected instead of guessing.

🎯 **Stretch.** Lock it down in `~/.ssh/config` (Host alias, IdentityFile, `IdentitiesOnly yes`) so `ssh naviops-db` just works.

---

## Task 2 — Ticket-driven: "I'm locked out after an SSH change" (diagnose → fix)

**Scenario.** `NAVI-072` (P1). *"I edited `sshd_config` to harden it and now I can't log in."* You
still have console/`docker exec` access. Restore secure access without disabling security.

**Objective.** Find the offending directive, fix it, and reload sshd **safely** (validate config
first). Keep hardening intact (no re-enabling root/password login carelessly).

**Given / constraints.** Recreate: a bad `sshd_config` (e.g. `AllowUsers` typo, wrong `Port` +
firewall, or `PubkeyAuthentication no`). Fix the specific fault.

**Hints.**
1. **Validate before reload:** `sshd -t` (syntax) / `sshd -T` (effective config) — never blind-reload a broken config.
2. `journalctl -u ssh -e` or `sshd -d` shows *why* auth is refused.
3. Fix minimally, `systemctl reload ssh`, test in a **second** session before closing the first.

✅ **Verify.**
```bash
sshd -t && echo "CONFIG VALID ✅"
ssh -o BatchMode=yes user@naviops-db 'echo in' && echo "ACCESS RESTORED ✅"
sshd -T | grep -E 'permitrootlogin|passwordauthentication'   # confirm hardening still on
```

**Pitfalls.**
- Reloading a broken config and closing your only session → truly locked out.
- Changing `Port` but not the firewall → connection refused.
- "Fixing" by `PermitRootLogin yes` / `PasswordAuthentication yes` — that undoes the hardening.

🎯 **Stretch.** Set `LoginGraceTime`, `MaxAuthTries`, and `AllowUsers` to a single account; re-validate with `sshd -T`.

---

## Task 3 — On-call: add and mount storage under pressure (synthesis)

**Scenario.** `NAVI-073` (P1, time-boxed). `naviops-db` data partition is full mid-incident. A new
block device is attached; you must make it usable and persistent, then move data — without losing the
`/etc/fstab` and rebooting into a broken mount.

**Objective.** Partition/format the new device, mount it, make it survive reboot via `fstab` **safely
tested**, and confirm free space.

**Given / constraints.** Simulate a device with a loopback file if no real disk:
`fallocate -l 1G /disk.img && losetup -f --show /disk.img`. Never edit `fstab` without a `mount -a`
dry-check.

**Hints.**
1. `lsblk` to see the device; `mkfs.ext4 <dev>`; `blkid` to get the UUID.
2. Mount by **UUID** (not `/dev/sdX`, which can renumber): add to `/etc/fstab`, then `mount -a` to validate *before* trusting a reboot.
3. `df -h` confirms the new space.

✅ **Verify.**
```bash
mount -a && echo "FSTAB SAFE ✅"          # if this errors, DO NOT reboot — fix fstab
findmnt <mountpoint> && df -h <mountpoint>
test -f docs/learning/reports/NAVI-073-postmortem.md && echo "POSTMORTEM ✅"
```

**Deliverable.** `docs/learning/reports/NAVI-073-postmortem.md`: Impact · Detection · Root cause · Fix · Prevention.

**Pitfalls.**
- `fstab` by `/dev/sdb1` → device renames on next boot → unbootable/emergency mode.
- Editing `fstab` and rebooting without `mount -a` — the classic self-inflicted outage (see troubleshooting-drills §2).
- `mkfs` on the wrong device — always confirm with `lsblk` first; this is destructive.

🎯 **Stretch.** Add mount options (`noatime`, `nofail`) and explain what `nofail` prevents at boot.

---

## Done?
- [ ] All ✅ Verify pass · [ ] `sshd -t`/`mount -a` validated before trusting · [ ] postmortem written.
- [ ] Hardening intact; UUID-based mount. **Redaction:** no real keys/UUIDs committed. → [README Step 7](./README.md).
