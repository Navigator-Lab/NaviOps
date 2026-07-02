# Lesson 27 — Pure Practical: RHCSA Exam Prep & Review

> **Companion to [`README.md`](./README.md).** RHCSA is a **performance-based** exam — no multiple
> choice, all live tasks. This file is pure timed practice: 3 exam-style task sets, guided → realistic →
> full mock. Do them on a disposable VM/container you can rebuild.
>
> **Lab:** a RHEL-like node (`naviops-web`, or a Rocky/Alma VM). See also `docs/learning/RHCSA-SERVICE-LABS.md`.
> **Rules:** hands on keyboard only, `man` allowed, no internet — mirror exam conditions. ✅ **Verify** each set.

Each task: **Scenario · Objective · Given/constraints · Hints · ✅ Verify · Pitfalls · 🎯 Stretch.**

---

## Task 1 — Guided: the RHCSA core-skills warm-up (fluency)

**Scenario.** `NAVI-271`. Drill the highest-frequency RHCSA objectives until they're automatic: users/
groups/sudo, permissions/ACLs, a systemd service, cron, and a `fstab` mount.

**Objective.** Complete each mini-task correctly; every ✅ check passes. Time yourself.

**Given / constraints.** `man` only, no internet. Changes must **persist across reboot** (RHCSA grades a
rebooted machine).

**Hints.**
1. User+group+sudo; `setfacl` for a specific-user grant; a `oneshot` service enabled at boot.
2. A cron/timer job; a persistent extra mount by **UUID** in `/etc/fstab` (`mount -a` to validate).
3. Reboot and re-run the checks — persistence is the exam's real test.

✅ **Verify.**
```bash
id <user> && getent group <grp>
getfacl <file> | grep -q 'user:<user>:'
systemctl is-enabled <svc>            # enabled (survives reboot)
findmnt <mnt> && grep -q UUID /etc/fstab
```

**Pitfalls.**
- Changes that work now but don't survive reboot (not `enable`d, not in `fstab`) → 0 marks on RHCSA.
- Breaking `fstab` and rebooting into emergency mode (validate with `mount -a` first).
- Reaching for the internet — the exam is offline; practice offline.

🎯 **Stretch.** Do the whole set again under a 20-minute timer.

---

## Task 2 — Realistic: SELinux + services lab (diagnose → fix)

**Scenario.** `NAVI-272`. Deploy a web server serving from a non-default docroot and hit the classic
RHCSA wall: SELinux denies it. Diagnose and fix with contexts, not by disabling SELinux.

**Objective.** The service serves content from the custom path with SELinux **enforcing** — fix via
correct contexts/booleans.

**Given / constraints.** `setenforce 0` is **forbidden** (RHCSA fails you for disabling SELinux). Fix
the label/boolean.

**Hints.**
1. Denied? `ausearch -m avc -ts recent` / `sealert`. Wrong context is usual.
2. `semanage fcontext -a -t httpd_sys_content_t '/customroot(/.*)?'` → `restorecon -Rv /customroot`.
3. Non-standard port? `semanage port -a -t http_port_t -p tcp <port>`. Boolean needed? `setsebool -P`.

✅ **Verify.**
```bash
getenforce                           # Enforcing (never Permissive/Disabled)
curl -sf http://localhost/ >/dev/null && echo "SERVES UNDER SELINUX ✅"
ls -Zd /customroot | grep -q httpd_sys_content_t && echo "CONTEXT OK ✅"
```

**Pitfalls.**
- `setenforce 0` to "make it work" — instant RHCSA fail; and it masks the real skill.
- `chcon` (non-persistent) instead of `semanage fcontext`+`restorecon` (survives relabel).
- Forgetting the port/boolean dimension of SELinux.

🎯 **Stretch.** Do the NFS/Apache/BIND/firewalld set in `RHCSA-SERVICE-LABS.md` under time pressure.

---

## Task 3 — Full mock: timed end-to-end exam (synthesis)

**Scenario.** `NAVI-273` (time-boxed, ~2–3 h). Run a full mock: a task list spanning storage (LVM),
users, permissions, services, networking, SELinux, containers — on a fresh VM, then **reboot and grade**.

**Objective.** Complete the task list, reboot, and pass the objective grading script. Score yourself.

**Given / constraints.** Fresh disposable VM. Offline, `man` only. **Grade after reboot** (mirrors the
exam). Timebox strictly.

**Hints.**
1. Read all tasks first; do quick wins + anything with reboot-persistence risk early.
2. LVM: create PV/VG/LV, format, persistent mount by UUID. Verify each as you go.
3. Reboot, then run every ✅ check — unpersisted work scores zero.

✅ **Verify.**
```bash
# after reboot, run your grading checklist; example spot-checks:
lsblk | grep -q lvm && findmnt <lv-mount>
systemctl is-enabled <svc> && getenforce
test -f docs/learning/reports/NAVI-273-mock-score.md && echo "SCORED ✅"
```

**Deliverable.** `docs/learning/reports/NAVI-273-mock-score.md`: per-objective pass/fail · total score · weak areas to redrill.

**Pitfalls.**
- Grading before reboot → false confidence.
- Spending too long on one hard task → running out of time for easy marks.
- Not re-drilling the objectives you failed.

🎯 **Stretch.** Rebuild the VM and beat your time; target < the exam's 2.5 h with all checks green.

---

## Done?
- [ ] All ✅ Verify pass **after reboot** · [ ] SELinux stayed enforcing · [ ] mock scored + weak areas noted.
- [ ] Practiced offline, `man`-only. → [README Step 7](./README.md).
