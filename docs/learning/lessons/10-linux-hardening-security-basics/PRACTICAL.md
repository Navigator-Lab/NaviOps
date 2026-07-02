# Lesson 10 — Pure Practical: Linux Hardening & Security Basics

> **Companion to [`README.md`](./README.md).** Pure practice: 3 scenario tasks, guided → ticket-driven
> → on-call. Do them after the README.
>
> **Lab:** `docker exec -it naviops-web bash`. **Artifact:** `scripts/security_audit.sh`.
> **Rules:** type it, diagnose before you fix, run ✅ **Verify** each task.

Each task: **Scenario · Objective · Given/constraints · Hints · ✅ Verify · Pitfalls · 🎯 Stretch.**

---

## Task 1 — Guided: baseline hardening checklist as code (fluency)

**Scenario.** `NAVI-101`. A fresh node needs a first-pass hardening: SSH tightened, unused services
off, world-writable files found, and a baseline report saved.

**Objective.** Apply a small, reversible hardening baseline and capture it in `scripts/security_audit.sh`.

**Given / constraints.** Every change reversible; no security regressions. CIS-style items only.

**Hints.**
1. SSH: `PermitRootLogin no`, `PasswordAuthentication no` (keys already set in L07) — validate with `sshd -t`.
2. Find world-writable: `find / -xdev -type f -perm -0002 2>/dev/null`. SUID review: `find / -perm -4000 2>/dev/null`.
3. Services: `systemctl list-unit-files --state=enabled` — disable what you don't need.

✅ **Verify.**
```bash
sshd -T | grep -E 'permitrootlogin no|passwordauthentication no' && echo "SSH HARDENED ✅"
scripts/security_audit.sh; echo "exit=$?"     # non-zero if a finding remains
```

**Pitfalls.**
- Disabling a service the app needs → self-inflicted outage; check dependencies first.
- Treating every SUID binary as bad — some are required (`sudo`, `passwd`); review, don't blanket-strip.
- Hardening SSH into a lockout (see L07 Task 2) — keep a second session open.

🎯 **Stretch.** Run `lynis audit system` (if installed) and turn its top 5 warnings into checks in your audit script.

---

## Task 2 — Ticket-driven: "audit found a suspicious SUID / world-writable file" (diagnose → fix)

**Scenario.** `NAVI-102` (P2). Security flags a world-writable file in a system path and an unexpected
SUID binary. Investigate whether it's a real risk and remediate minimally.

**Objective.** Determine each object's legitimacy (owner, package origin, expected mode) and fix the
genuine risks — **investigate before deleting.**

**Given / constraints.** Plant a world-writable file in a sensitive dir and an SUID copy of a shell.
Don't delete files that belong to a package; correct the mode instead.

**Hints.**
1. Who owns it, is it from a package? `stat`, `rpm -qf`/`dpkg -S <file>`. Orphan = suspicious.
2. World-writable in a system dir → `chmod o-w`. Rogue SUID shell → remove the SUID bit (`chmod u-s`) or delete if truly rogue.
3. Check recent changes: `find / -newermt '-1 day' -type f 2>/dev/null`.

✅ **Verify.**
```bash
find / -xdev -perm -0002 -type f 2>/dev/null | grep -q . && echo "STILL WORLD-WRITABLE ❌" || echo "CLEAN ✅"
find / -perm -4000 -type f 2>/dev/null | grep -vFf /tmp/known-suid.txt   # only expected SUIDs remain
```

**Pitfalls.**
- Deleting a package-owned file → breaks the package; fix the mode instead.
- Ignoring an SUID-root shell copy — that's a privilege-escalation backdoor.
- Not checking *how* it got there (log review) — you'll just get re-owned.

🎯 **Stretch.** Add a `find`-based tripwire to `security_audit.sh` that diffs SUID/world-writable inventory against a committed baseline.

---

## Task 3 — On-call: signs of compromise — triage a possibly-breached host (synthesis)

**Scenario.** `NAVI-103` (P1, time-boxed). Odd outbound traffic and a strange cron entry. Triage for
compromise, contain without destroying evidence, and write an incident note.

**Objective.** Enumerate persistence + suspicious activity (unknown users, cron, listeners, recent
files), contain the immediate risk, and document — **preserve evidence.**

**Given / constraints.** Plant a fake persistence artifact (a rogue cron line + a listener). Do **not**
wipe logs or reboot (destroys volatile evidence). Contain by disabling, not deleting.

**Hints.**
1. Persistence: `crontab -l`, `/etc/cron.*`, `systemctl list-unit-files --state=enabled`, `~/.ssh/authorized_keys`.
2. Live activity: `ss -tulpn` (unexpected listeners/outbound), `ps auxf`, `last`/`lastb`.
3. Contain: disable the rogue cron/unit, kill the listener's process, capture (`ps`, `ss`, file copies) to `/tmp/ir/` first.

✅ **Verify.**
```bash
crontab -l | grep -q '<rogue-marker>' && echo "STILL PRESENT ❌" || echo "PERSISTENCE REMOVED ✅"
ss -tulpn | grep -q '<rogue-port>' && echo "LISTENER STILL UP ❌" || echo "CONTAINED ✅"
test -f docs/learning/reports/NAVI-103-postmortem.md && echo "POSTMORTEM ✅"
```

**Deliverable.** `docs/learning/reports/NAVI-103-postmortem.md`: Impact · Detection · Root cause · Fix · Prevention (+ IoCs).

**Pitfalls.**
- Rebooting/wiping logs → destroys the evidence you need for scope.
- Deleting the rogue artifact before capturing it → no forensics, no root cause.
- Assuming one artifact = full cleanup; attackers plant multiple persistence mechanisms.

🎯 **Stretch.** Cross-reference with Lesson 23 (Wazuh) — which of these would a SIEM rule have caught automatically?

---

## Done?
- [ ] All ✅ Verify pass · [ ] investigated before deleting · [ ] evidence preserved · [ ] postmortem written.
- [ ] No hardening lockout. **Redaction:** fake IoCs only. → [README Step 7](./README.md).
