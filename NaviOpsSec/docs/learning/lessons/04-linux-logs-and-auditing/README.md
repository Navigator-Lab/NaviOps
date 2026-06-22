# Lesson 04 — Linux Logs & Auditing

**Status:** ✅ ready for self-study (full depth) · **Date written:** 2026-06-20
**Schema:** 12-section SOC (`docs/learning/CLAUDE_TEACHING_RULES.md`)
**Focus:** the Linux log landscape (`/var/log`, the journal) and the **audit subsystem**
(`auditd`/`auditctl`/`ausearch`/`aureport`) — where the evidence lives.
**Primary artifact:** `infra/detection-rules/audit.rules` (a starter audit ruleset).

> **How to use this lesson:** read §1–§7, do §8 (map your logs + deploy a small audit rule, lab),
> produce §9, answer the quiz, reflect. Then Lesson 05.

---

## §1 — Concept (Scientific Theory)

### What it is
Linux records what happens in **logs**. The two systems you must know:
- **Text logs** in `/var/log/` — `auth.log`/`secure` (logins, sudo, SSH), `syslog`/`messages`
  (general system), `kern.log` (kernel), service logs (`nginx/`, `apache2/`), `cron`.
- **The systemd journal** — a structured, queryable binary log read with `journalctl` (by unit,
  time, priority, field).
- **The Linux Audit subsystem (`auditd`)** — a kernel-level audit trail that records **syscalls**
  and **file/watch events** with precise detail (who ran what, who touched which file). This is
  the SOC's highest-fidelity host evidence.

### Why it exists
You can only detect and investigate what is **recorded**. Default logs catch a lot (logins,
service events) but miss the granular "who executed this binary / who modified `/etc/passwd`" —
that's what `auditd` adds. An analyst who knows the log map can find evidence fast; one who doesn't
is blind on the box.

### Three-Level Depth (Lens A)
- **Level 1 — Beginner:** Linux writes diary entries about what happens — logins, errors, programs
  running. `/var/log` is the diary; `journalctl` reads the modern one; `auditd` is the detailed
  security camera you can aim at specific files/actions.
- **Level 2 — Analyst/SOC:** you investigate from `auth.log`/`journalctl` for logins+services and
  from `ausearch`/`aureport` for syscall-level detail (execve, file access, privilege changes).
  These are the log sources a SIEM ingests — knowing them is knowing your detection's raw input.
- **Level 3 — Adversary/Kernel:** `auditd` hooks the kernel audit framework: rules match syscalls
  (`-a always,exit -F arch=b64 -S execve`) or watch paths (`-w /etc/passwd -p wa`). Each event is
  an `audit.log` record with `type=`, `uid/auid` (the *login* uid survives `su`!), `exe=`, `key=`.
  `auid` is gold: it ties an action back to the human who logged in, even after privilege changes.

### Two Teaching Approaches (Lens B) — auditd vs syslog
**Approach 1 (technical):** syslog/journal record application-level *messages* the program chose to
emit; `auditd` records kernel-level *events* the program can't suppress (it didn't choose to be
audited). For security, `auditd` is harder to evade and more precise.

**Approach 2 (analogy):** `auth.log` is the **visitor sign-in sheet** at the front desk (people
write what they want). `auditd` is the **building's CCTV + door-badge logs** — it records what
actually happened regardless of what anyone wrote on the sheet. **Where it breaks down:** CCTV can
be unplugged; a root attacker can stop `auditd` (T1562) — which is itself a detectable event.

### Visual (ASCII) — the log landscape
```
   application ─► syslog/journald ─► /var/log/{auth.log,syslog,...} + journal  (journalctl)
        kernel ─► audit framework ─► auditd ─► /var/log/audit/audit.log         (ausearch/aureport)
                                       ▲
                                   audit.rules  (-w watches, -a syscall rules, keys)
   all of the above ─► (Wazuh agent) ─► SIEM   (Lessons 13–16)
```

---

## §2 — Linux Investigation Commands

```bash
ls /var/log/                          # the log map (distro-dependent)
journalctl -u sshd -S today           # journal: one unit, since today
journalctl -p err -S -1h              # priority err+ in the last hour
journalctl _UID=1000 --since -1d      # by field (structured query)
grep -E "Accepted|Failed|sudo" /var/log/auth.log   # auth events fast
auditctl -l                           # list active audit rules
auditctl -w /etc/passwd -p wa -k passwd_changes     # watch a file (write+attr), tag it
ausearch -k passwd_changes -ts today  # query audit events by key
ausearch -m EXECVE -ts recent         # all program executions recently
aureport --auth ; aureport -x --summary   # auth report; executable summary
```
| Linux | SIEM equivalent |
|---|---|
| `auth.log` / journal | Wazuh log collection + 5500/5700 auth rules |
| `auditd` keys | Wazuh `audit` decoder + rules (high-fidelity host detection) |
| `aureport` summaries | Wazuh dashboards / aggregations |

---

## §3 — Real-World Threat Context & Use Cases

- **Login investigation:** `auth.log`/journal answers "who logged in, from where, when, success?"
  — the start of almost every host investigation.
- **Execution evidence:** `ausearch -m EXECVE` shows what ran — essential for confirming a
  suspicious process or a script's actions (Lesson 21).
- **File-change evidence:** an audit watch on `/etc/passwd`, `/etc/sudoers`, `~/.ssh/` catches
  persistence (Lesson 22) and the FIM signal (Lesson 24).
- **Exam framing:** Linux log locations, `journalctl`, and the purpose of `auditd` appear on
  Security+/CySA+/BTL1 (and are core Linux-analyst job skills).

---

## §4 — Detection

- **The audit *key* is your detection hook.** Tagging a rule with `-k passwd_changes` lets the SIEM
  (and `ausearch -k`) alert specifically on that class of event — clean, low-noise detection.
- **High-value watches** (a starter detection set): `/etc/passwd`, `/etc/shadow`, `/etc/sudoers`,
  `/etc/ssh/sshd_config`, `~/.ssh/authorized_keys`, and `execve` of shells from web dirs.
- **Tamper detection:** an `auditd`-stopped or audit-config-changed event is itself a detection
  (T1562 impair defenses) — defenders alert when the camera goes dark.
- Wazuh ships an `audit` decoder; your `audit.rules` keys map straight to Wazuh rule groups.

---

## §5 — Investigation & Triage

Investigating a host alert, work the logs in order: **auth** (who got in) → **execve** (what ran) →
**file watches** (what changed) → **journal/service logs** (what the service saw). Use `auid` to
attribute actions to the real human even after `su`/`sudo`. Keep facts vs assessment separate, and
**preserve** the relevant logs (copy off-box) before any containment — `auditd` logs are a prime
attacker target.

---

## §6 — SOC Perspective

`auditd` is the host-evidence backbone the SOC relies on for endpoint detection. On shift, audit
keys become named alerts ("passwd_changes fired on db01"), and the audit log's *presence* is itself
monitored (a sudden stop = investigate). Ties to `soc/soc-scenarios.md` #4 (rogue account) and #7
(file tamper).

---

## §7 — Incident-Response Perspective

In IR, `auditd` + `auth.log` are your **timeline source** (`workflows/ir-workflow.md` Phase 2): they
give the timestamped sequence of logins → executions → file changes that *is* the attack timeline.
**Preserve them first** (Phase 2 evidence-collection) — hash and copy off-box before containment,
because a root attacker can delete or truncate them (T1070).

---

## §8 — Practical Lab (build this yourself)

**Goal:** map your host's logs and deploy a small, high-value audit ruleset, then trip it.

### Lens C — Manual → Automated → Why
- **Manual:** read `auth.log`/`journalctl` for a login event.
- **Automated:** an `audit.rules` file deploys a *standing* detection set that records the events
  you care about automatically — no one has to remember to look.
- **Why:** production audit policy (e.g. the CIS/`auditd` baseline) is exactly this, version
  controlled — the seed of detection-as-code (Lesson 26).

### Steps
1. Map your logs: `ls /var/log`, then read one login with `journalctl -u sshd -S -1d` and one with
   `grep sshd /var/log/auth.log`.
2. Write `infra/detection-rules/audit.rules` with a few high-value rules:
   ```
   -w /etc/passwd -p wa -k passwd_changes
   -w /etc/sudoers -p wa -k sudoers_changes
   -w /etc/ssh/sshd_config -p wa -k sshd_config
   -a always,exit -F arch=b64 -S execve -F path=/usr/bin/nc -k netcat_exec
   ```
3. Load it (lab): `sudo auditctl -R infra/detection-rules/audit.rules` (or place in
   `/etc/audit/rules.d/`). Confirm `auditctl -l`.
4. **Trip it (drill):** `sudo useradd labtest` (touches `/etc/passwd`) → `ausearch -k passwd_changes
   -ts recent`. You just detected a (lab) account creation via the audit trail.
5. Clean up: `sudo userdel labtest`.

### Lens D — the raw artifact
```
type=SYSCALL ... auid=1000 uid=0 ... exe="/usr/sbin/useradd" key="passwd_changes"
type=PATH ... name="/etc/passwd" ...
# auid=1000 = the human who logged in; uid=0 = ran as root via sudo. Attribution survives sudo.
```

---

## §9 — GitHub Artifact (the 6-artifact evidence package)

1. **Script:** `scripts/audit_query.sh` — wrap `ausearch -k <key> -ts <when>` + `aureport` summaries.
2. **Detection rule/config:** `infra/detection-rules/audit.rules` (committed).
3. **Runbook:** `docs/runbooks/runbook-passwd-change.md` — "when passwd_changes fires, do X."
4. **Playbook:** `docs/playbooks/host-evidence-play.md` — the auth→execve→watch investigation order.
5. **Incident report + notes:** the account-creation drill (you created `labtest`; the audit rule
   caught it) + notes.
6. **SOC ticket:** `SOC-04` (Task: "deploy audit ruleset + catch account creation") → Closed.

---

## §10 — Portfolio Artifact

- **Resume bullet:** "Deployed a Linux `auditd` detection ruleset (passwd/sudoers/sshd/execve
  watches) and demonstrated host-level detection of account creation via the audit trail."
- **Interview talking point:** explain `auditd` vs syslog and why `auid` matters for attribution;
  show your `audit.rules` + the caught event.
- **Serves:** Security Analyst → SOC T1 (Stages 1–2). Strong Linux-analyst differentiator.

---

## §11 — Certification Crossover Notes

- **Security+:** logging/monitoring (4.x). **CySA+:** log analysis + data sources. **SC-200:**
  data sources/connectors (Linux). **BTL1:** SIEM & log analysis. Also reinforces NaviOps RHCSA
  logging. Detail: `alignment/CERTIFICATION-MAPPING.md`.

---

## §12 — Security Notes (Lens E — Attacker & Defender)

**🔴 Attacker:** after gaining root, attackers tamper with logs (T1070.002 clear linux logs),
stop/disable `auditd` (T1562.001), or avoid audited paths. They know `auth.log` and
`audit.log` are what convict them.

**🔵 Defender:** ship logs **off-box** in real time (Lesson 06) so on-box deletion doesn't lose
them; **alert on auditd stop / config change**; protect log integrity (append-only, remote
syslog). The watch on the audit config is the "who's watching the watchers" control.

---

## Quiz (Interview-Style, Graded)

**Q1.** What's the difference between syslog/journal logs and `auditd`, and why does the SOC value
`auditd` for security?
> **Your answer:**

**Q2.** What does `auid` represent in an audit record, and why is it more useful than `uid` for
attribution?
> **Your answer:**

**Q3.** Write an audit rule to watch `/etc/sudoers` for writes, tagged with a key, and the
`ausearch` command to query it.
> **Your answer:**

**Q4.** **Scenario:** an alert says a new user appeared on a host. Which logs/commands do you check,
in what order, to find who created it and how?
> **Your answer:**

**Q5.** Why must logs be shipped off-box, and which attacker technique does that defend against?
> **Your answer:**

*(Request the "Professional Answer" comparison under each before moving on.)*

---

## Reflection
*(After the quiz)* — What did you learn? · What confused you? · What would you do differently?

---

## Search Keywords For Further Understanding

**Core**
- `linux /var/log files explained security`
- `auditd auditctl ausearch aureport tutorial`
- `journalctl filter unit priority field`
- `auditd auid vs uid attribution`
- `auditd watch /etc/passwd rule key`

**Tools**
- `auditd rules.d best practices cis`
- `wazuh auditd integration`

**Going further**
- `journalctl grep awk analysis` (L05) · `syslog central logging` (L06) · `file integrity monitoring` (L24)

**Red / Blue (Lens E):**
- 🔴 `clear linux logs T1070.002`, `disable auditd T1562.001`
- 🔵 `remote syslog tamper-evident logs`, `alert on auditd stopped`, `auditd file watches`

---

## Lesson Status
- [ ] §8 lab completed (logs mapped; audit.rules deployed; account-creation caught)
- [ ] 6-artifact evidence package committed (§9)
- [ ] Quiz answered + professional-answer comparisons (graded)
- [ ] Reflection + Search Keywords reviewed

When complete, run the Update Protocol, then move to **Lesson 05 — journalctl · grep · awk · sed
for Analysis**.

---

*Lesson 04 written by Navi · 2026-06-20 · full-depth. Sources to cite at study time: man7 `auditctl(8)`/`ausearch(8)`,
RedHat auditd guide, CIS auditd benchmark, MITRE T1070/T1562.*
