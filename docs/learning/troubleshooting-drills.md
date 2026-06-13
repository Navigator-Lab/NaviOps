# Troubleshooting Drills — Cross-Lesson Scenario Bank

> **Redaction convention applies** (see `LEARNING_STATE.md` header): all examples use
> placeholders (`<HOSTNAME>`, `10.0.x.x`, `<ACCOUNT_ID>`). Never paste real output.

This file is a shared **failure-drill bank**: scenarios you intentionally break, then
diagnose and fix under a time box. This is the single most-cited technique for both
RHCSA exam readiness and interview "walk me through how you'd debug X" questions —
the same muscle serves both. Each drill cross-links the lesson that covers the
underlying concept.

| Drill | Maps to lesson | Time-box |
|---|---|---|
| [SELinux denial / `.autorelabel` trap](#1-selinux-denial--autorelabel-trap) | 10 — Hardening & Security Basics | 10 min |
| [Broken `/etc/fstab` entry](#2-broken-etcfstab-entry) | 07 — SSH, Packages, Storage | 10 min |
| [Locked out by SSH config](#3-locked-out-by-ssh-config) | 07 — SSH, Packages, Storage | 10 min |
| [Broken sudo access](#4-broken-sudo-access) | 04 — Users, Groups, Processes | 10 min |
| [Failed systemd service](#5-failed-systemd-service) | 05 — systemd & journald | 8 min |
| [Full disk](#6-full-disk) | 07 / 17 — Storage & Backups | 8 min |
| [Firewall blocking a service](#7-firewall-blocking-a-service) | 09 — DNS/DHCP/NAT/Firewalls | 8 min |

---

## 1. SELinux denial / `.autorelabel` trap

**Problem**: A service (e.g. `httpd`) can't read files that have correct Unix `rwx`
permissions — works as root, fails as the service user.

**Symptoms**: `Permission denied` in the app log despite `ls -l` looking correct;
`journalctl -u <service>` shows AVC-style denials.

**Diagnosis**:
```bash
sudo ausearch -m avc -ts recent      # show recent SELinux denials
ls -lZ /path/to/file                  # check the SELinux context, not just rwx
getenforce                             # confirm SELinux is Enforcing
```

**Fix**:
```bash
sudo semanage fcontext -a -t httpd_sys_content_t "/path/to/dir(/.*)?"
sudo restorecon -Rv /path/to/dir
```

**Prevention**: After bulk file moves/restores (or disabling SELinux temporarily),
create `/.autorelabel` and reboot, OR run `restorecon -R` on the affected tree —
**never** leave SELinux permanently `Disabled` to "make it work" (top cited RHCSA +
production mistake).

---

## 2. Broken `/etc/fstab` entry

**Problem**: A bad line in `/etc/fstab` (typo'd UUID, wrong mount point) — system
fails to boot to multi-user target, or drops to emergency shell.

**Symptoms**: Boot hangs / emergency mode; `systemctl status` shows a `.mount` unit
failed.

**Diagnosis**:
```bash
sudo mount -a            # ALWAYS run this after editing fstab, before reboot
journalctl -b -u <mount-unit>
```

**Fix**: Boot into emergency mode (or rescue shell), `mount -o remount,rw /`, edit
`/etc/fstab` to fix/comment the bad line, then `mount -a` again to confirm clean
before rebooting.

**Prevention**: Treat `mount -a` as a mandatory pre-reboot check — it's the #1 RHCSA
exam gotcha because it's invisible until the next reboot.

---

## 3. Locked out by SSH config

**Problem**: An `sshd_config` change (e.g. `PermitRootLogin no`, wrong `Port`, bad
`AllowUsers`) locks out the only remote session.

**Symptoms**: `ssh: connect to host <HOSTNAME> port 22: Connection refused` /
`Permission denied (publickey)`.

**Diagnosis**: Use the console (not SSH) to check:
```bash
sudo sshd -t                      # validate config syntax BEFORE reload
sudo systemctl status sshd
```

**Fix**: From console access, revert the bad `sshd_config` line, `sudo sshd -t` to
validate, then `sudo systemctl reload sshd` (not `restart`, to avoid dropping live
sessions if any remain).

**Prevention**: Always `sshd -t` before reload; keep a second session open while
testing SSH config changes (matches the real incident already logged in
`docs/learning/lessons/02-git-github-fundamentals/TROUBLESHOOTING-GITHUB-SSH.md`,
which covers the client-side half of SSH auth).

---

## 4. Broken sudo access

**Problem**: A `visudo` edit introduces a syntax error or removes the operator's own
sudo rights.

**Symptoms**: `sudo: /etc/sudoers: syntax error` on every command; or "user is not in
the sudoers file."

**Diagnosis**:
```bash
sudo visudo -c            # check syntax without applying
```

**Fix**: `visudo` **always** edits a temp copy and validates before saving — if
locked out entirely, boot to single-user/rescue mode (root shell, no sudo needed) and
fix `/etc/sudoers` or `/etc/sudoers.d/` directly.

**Prevention**: Never edit `/etc/sudoers` with a plain text editor — `visudo` is the
only safe path because it validates syntax atomically.

---

## 5. Failed systemd service

**Problem**: A service fails to start after a config change (bad unit file, missing
binary, wrong `ExecStart` path).

**Symptoms**: `systemctl status <service>` shows `failed (Result: exit-code)`.

**Diagnosis**:
```bash
systemctl status <service>
journalctl -u <service> -n 50 --no-pager
systemd-analyze verify <unit-file>     # catches unit-file syntax errors
```

**Fix**: Fix the unit file or config, then:
```bash
sudo systemctl daemon-reload     # required after editing unit files
sudo systemctl restart <service>
```

**Prevention**: `daemon-reload` is the most-forgotten step after editing a unit file
— a service that "won't pick up" a change is almost always this.

---

## 6. Full disk

**Problem**: A filesystem hits 100% usage; services start failing to write
logs/data.

**Symptoms**: `No space left on device`; new log entries stop.

**Diagnosis**:
```bash
df -hT                                  # which filesystem is full
du -sh /var/log/* | sort -rh | head     # find the biggest consumers
```

**Fix**: Truncate/rotate large logs (`journalctl --vacuum-size=200M`,
`logrotate -f /etc/logrotate.conf`), or remove stale files in `/tmp`/`/var/tmp`.

**Prevention**: This is exactly what Lesson 07's `disk_report.sh` (threshold
alerting) and Lesson 18's CloudWatch disk-usage alarm are *for* — catch it before
100%.

---

## 7. Firewall blocking a service

**Problem**: A service is running and listening, but unreachable from another host.

**Symptoms**: `curl: (7) Failed to connect`; `ss -tlnp` shows the port listening
locally, but remote connections time out.

**Diagnosis**:
```bash
sudo firewall-cmd --list-all          # is the port/service allowed in the active zone?
sudo ss -tlnp | grep <port>            # confirm the service is actually listening
```

**Fix**:
```bash
sudo firewall-cmd --add-port=<port>/tcp --permanent
sudo firewall-cmd --reload
```

**Prevention**: A new service is "not working" remotely far more often because of
`firewalld` than the service itself — check the firewall *before* assuming the
service is misconfigured.
