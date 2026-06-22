# Lesson 22 — User Account Investigation

**Status:** ✅ ready for self-study (full depth) · **Date written:** 2026-06-20
**Schema:** 12-section SOC (`docs/learning/CLAUDE_TEACHING_RULES.md`)
**Focus:** rogue accounts + persistence — `T1136`/`T1098`, sudo abuse, `/etc/passwd` diffs, login
history, and key/cron persistence. The "who's here that shouldn't be" investigation.
**Primary artifact:** `scripts/user_audit.sh`.

> **How to use this lesson:** read §1–§7, do §8 (plant + find a rogue account & persistence, lab),
> produce §9, quiz, reflect. Then Lesson 23.

---

## §1 — Concept (Scientific Theory)

### What it is
After access, attackers **establish + maintain** identity-based footholds: create a new account
(T1136), modify an existing one / add it to sudo (T1098), or plant credential-based persistence
(an SSH key in `authorized_keys` (T1098.004), a cron job (T1053), a systemd service/timer (T1543)).
This investigation answers: *which accounts exist, which changed, who's logging in, and what
persistence is planted?*

### Why it exists
Persistence is what makes an intrusion *last* — kill the process, reboot, and the attacker still
gets back in via their key/cron/account. Finding + removing all persistence is the difference
between "contained" and "they're back tomorrow." It's a top eradication concern (IR Phase 4).

### Three-Level Depth (Lens A)
- **Level 1 — Beginner:** check for new/strange user accounts, who can use `sudo`, who's been
  logging in, and any "backdoors" (extra SSH keys, scheduled jobs).
- **Level 2 — Analyst/SOC:** diff `/etc/passwd`/`/etc/shadow`/`/etc/group` vs a baseline; review
  `last`/`lastlog`/`auth.log` for the account's logins; inspect `~/.ssh/authorized_keys`, crontabs,
  and systemd timers for persistence; check `/etc/sudoers(.d)`. The audit watches from Lesson 04
  make these *alertable*.
- **Level 3 — Adversary/Kernel:** account creation hits `/etc/passwd` (uid/gid, shell) + `useradd`
  in logs + an `auditd` PATH/SYSCALL record (Lesson 04). Persistence lives in many places — the
  attacker needs one you miss. `auid` ties the change to the human session that made it. UID 0
  accounts *other than root* (duplicate-root) are a classic backdoor.

### Two Teaching Approaches (Lens B) — persistence
**Approach 1 (technical):** persistence = any mechanism that re-grants access/execution after
disruption (accounts, keys, scheduled tasks, services, shell profiles). Eradication requires
enumerating *all* mechanisms; missing one defeats the whole response.

**Approach 2 (analogy):** an intruder who, while inside your house, **copies a key, props a window,
and bribes the cleaner to let them in weekly.** Changing the front-door lock (killing the process)
isn't enough — you must find *every* way back in. **Where it breaks down:** software persistence has
dozens of hiding spots (more than a house), so you need a checklist, not intuition.

### Visual (ASCII) — persistence locations to sweep
```
   ACCOUNTS:  /etc/passwd (new user? UID 0 dup?)   /etc/sudoers.d/*  (new sudo grant?)
   KEYS:      ~/.ssh/authorized_keys (extra key?)  /root/.ssh/authorized_keys
   SCHEDULE:  crontab -l / /etc/cron.* / /var/spool/cron/*   systemctl list-timers
   SERVICES:  /etc/systemd/system/*.service (rogue unit?)    rc.local, shell profiles
   → eradication = clear ALL of these; miss one = attacker returns
```

---

## §2 — Linux Investigation Commands

```bash
# accounts
awk -F: '{print $1, $3, $7}' /etc/passwd            # users, UID, shell
awk -F: '$3==0 {print $1}' /etc/passwd               # UID 0 accounts (should be ONLY root)
getent group sudo wheel                               # who has sudo
diff <(sort baseline_passwd) <(sort /etc/passwd)     # what changed vs baseline
# login history
last -n 20 ; lastlog | grep -v 'Never'               # who logged in / last per user
grep -E "useradd|usermod|passwd|sudoers" /var/log/auth.log   # account-change events
ausearch -k passwd_changes -ts recent                # audit trail (from Lesson 04)
# persistence
ls -la ~/.ssh/authorized_keys /root/.ssh/authorized_keys
for u in $(awk -F: '$3>=1000{print $1}' /etc/passwd); do crontab -l -u "$u" 2>/dev/null; done
systemctl list-timers --all ; ls -la /etc/systemd/system/
bash scripts/user_audit.sh
```
| Linux | Wazuh / SIEM |
|---|---|
| `/etc/passwd` diff | FIM on `/etc/passwd` (Lesson 24) |
| `useradd` in auth.log | Wazuh account-created rule (T1136) |
| authorized_keys change | FIM on `.ssh/` (T1098.004) |

---

## §3 — Real-World Threat Context & Use Cases

- **The 3am new admin:** a new privileged account is a near-certain incident → who made it, from
  what session, scope.
- **Backdoor SSH key:** the most common, quietest persistence — an extra line in `authorized_keys`.
- **Cron/timer beacon or re-shell:** persistence that re-launches the foothold.
- **Sudo abuse / duplicate-root:** privilege escalation + a hidden admin.
- **Exam framing:** account/identity attacks, persistence, T1136/T1098/T1053 on Security+/CySA+/BTL1.

---

## §4 — Detection

- **Account creation:** Wazuh rule on `useradd`/`/etc/passwd` change (+ audit key from Lesson 04),
  tagged T1136. High-signal.
- **authorized_keys change:** FIM on `.ssh/` directories (Lesson 24), T1098.004.
- **sudoers change / new sudo member:** audit watch + Wazuh rule.
- **UID 0 duplicate:** a check/alert for any non-root UID 0.
- **Cron/timer change:** FIM + audit on cron/systemd paths, T1053/T1543.
These are durable host detections (persistence is hard for attackers to avoid logging).

---

## §5 — Investigation & Triage

Given a rogue-account alert: who/when created it (`auth.log`/audit `auid`), from what session (tie to
a prior login/IP), what it did (`last`, history), and **what persistence accompanies it** (sweep all
locations). Scope across hosts (`ioc_sweep.sh` for the account/key). Authorized change (a sysadmin
did it) vs malicious — confirm with the change record + the human.

---

## §6 — SOC Perspective

New-account + persistence detections are high-value, lower-volume alerts (less fatigue than auth
failures). The SOC pairs them with change management ("was this account planned?"). `user_audit.sh`
is the standard "audit the accounts + persistence on this host" tool. Maps to `soc/soc-scenarios.md`
#4 + #7.

---

## §7 — Incident-Response Perspective

This is the **eradication** lesson (IR Phase 4): you cannot close an incident until *all*
persistence is found + removed. The checklist (accounts/keys/cron/timers/services/profiles) is the
eradication backbone. Missing one = recurrence (Phase 5 validation fails). Capstone stage 4.

---

## §8 — Practical Lab (build this yourself)

**Goal:** plant rogue-account + persistence (lab), then find + eradicate all of it.

### Lens C — Manual → Automated → Why
- **Manual:** check each persistence location by hand.
- **Automated:** `user_audit.sh` sweeps accounts (incl. UID 0 dups), sudo, login history, and all
  persistence spots in one run.
- **Why:** eradication requires *completeness* — a script ensures no location is forgotten;
  production EDR + FIM continuously watch these.

### Steps
1. **Plant (drills 5–7, lab):** `sudo useradd -m -s /bin/bash svc_tmp` + add to sudo; append a test
   key to `~/.ssh/authorized_keys`; add a benign crontab entry.
2. **Detect:** diff `/etc/passwd` vs a baseline, find `svc_tmp` in `auth.log`/audit (with `auid`),
   find the extra key + cron. Confirm Wazuh/audit rules fired (Lesson 04).
3. Build `scripts/user_audit.sh`: list users + UID 0 dups + sudo members; show recent login history;
   dump all crontabs, timers, and authorized_keys. `bash -n` + `shellcheck` clean.
4. **Eradicate (completeness drill):** remove the user, the key, and the cron — then re-run
   `user_audit.sh` to *prove* nothing remains. This is the eradication-validation habit.
5. Document which detection caught each persistence type.

### Lens D — the raw artifact
```
$ awk -F: '$3==0{print}' /etc/passwd
root:x:0:0:root:/root:/bin/bash
backup:x:0:0::/home/backup:/bin/bash      ← a SECOND UID 0 = duplicate-root backdoor (T1098)
$ grep useradd /var/log/auth.log
... useradd[4001]: new user: name=svc_tmp, UID=1002 ... (auid ties it to the human session)
```

---

## §9 — GitHub Artifact (the 6-artifact evidence package)

1. **Script:** `scripts/user_audit.sh` (committed, `shellcheck`-clean).
2. **Detection rule/config:** Wazuh account-created + sudoers + authorized_keys rules (`infra/`),
   tagged T1136/T1098/T1053.
3. **Runbook:** `docs/runbooks/runbook-rogue-account.md` — investigate + eradicate an account.
4. **Playbook:** `docs/playbooks/persistence-eradication-play.md` (the full sweep checklist).
5. **Incident report + notes:** the plant→detect→eradicate→validate drill + notes.
6. **SOC ticket:** `SOC-22` (Task: "user/persistence investigation + eradication") → Closed.

---

## §10 — Portfolio Artifact

- **Resume bullet:** "Built user + persistence auditing (`user_audit.sh`): detected rogue accounts,
  duplicate-root, backdoor SSH keys, and cron persistence (T1136/T1098/T1053), and validated
  complete eradication."
- **Interview talking point:** "where does Linux persistence hide, and how do you ensure you got it
  all?" — the eradication-completeness mindset.
- **Serves:** SOC T2 / IR (Stage 3). Core capstone eradication skill.

---

## §11 — Certification Crossover Notes

- **Security+:** IAM/persistence/IR (4.x). **CySA+:** identity analysis + IR. **SC-200:** identity
  (Entra analog). **BTL1:** persistence/forensics. Builds on NaviOps users/cron. Detail:
  `alignment/CERTIFICATION-MAPPING.md`.

---

## §12 — Security Notes (Lens E — Attacker & Defender)

**🔴 Attacker:** create accounts (T1136), add SSH keys (T1098.004), duplicate-root, cron/timer/
service persistence (T1053/T1543), modify `.bashrc`/profiles, hide accounts with odd UIDs. They
plant *multiple* so you miss one.

**🔵 Defender:** alert on account creation, sudoers + `authorized_keys` + cron/timer changes (audit +
FIM); enforce key-only auth + central identity; baseline accounts; and **eradicate by checklist** —
enumerate every persistence class, then validate it's gone. Completeness beats cleverness.

---

## Quiz (Interview-Style, Graded)

**Q1.** Name five places Linux persistence can hide, and the command to check each.
> **Your answer:**

**Q2.** What is a duplicate-root account and how do you find it?
> **Your answer:**

**Q3.** When you find a rogue account, what do you determine before removing it?
> **Your answer:**

**Q4.** **Scenario:** a new sudo-capable user appeared at 03:00 with a fresh SSH key. Walk your
investigation + eradication, and how you'd *prove* eradication is complete.
> **Your answer:**

**Q5.** Why is eradication completeness the deciding factor between "contained" and "they're back
tomorrow"?
> **Your answer:**

*(Request the "Professional Answer" comparison under each before moving on.)*

---

## Reflection
*(After the quiz)* — What did you learn? · What confused you? · What would you do differently?

---

## Search Keywords For Further Understanding

**Core**
- `linux persistence techniques detection`
- `rogue account /etc/passwd uid 0 duplicate root`
- `authorized_keys backdoor detection`
- `cron systemd timer persistence`
- `mitre t1136 t1098 t1053 t1543`

**Tools**
- `last lastlog auth.log account changes`
- `wazuh account created rule`

**Going further**
- `web attack analysis` (L23) · `file integrity monitoring` (L24) · `containment eradication recovery` (L29)

**Red / Blue (Lens E):**
- 🔴 `create account T1136`, `ssh key persistence T1098.004`, `scheduled task T1053`, `systemd service T1543`
- 🔵 `account/sudoers/keys/cron alerting`, `eradication checklist`, `key-only auth`, `eradication validation`

---

## Lesson Status
- [ ] §8 lab completed (planted + detected + eradicated + validated)
- [ ] 6-artifact evidence package committed (§9)
- [ ] Quiz answered + professional-answer comparisons (graded)
- [ ] Reflection + Search Keywords reviewed

When complete, run the Update Protocol, then move to **Lesson 23 — Web Attack Analysis**.

---

*Lesson 22 written by Navi · 2026-06-20 · full-depth. Sources to cite at study time: MITRE
T1136/T1098/T1053/T1543, man7 `useradd`/`crontab`, Wazuh persistence rules.*
