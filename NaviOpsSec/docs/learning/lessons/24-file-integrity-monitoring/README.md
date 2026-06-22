# Lesson 24 — File Integrity Monitoring

**Status:** ✅ ready for self-study (full depth) · **Date written:** 2026-06-20
**Schema:** 12-section SOC (`docs/learning/CLAUDE_TEACHING_RULES.md`)
**Focus:** Wazuh FIM (`syscheck`) + AIDE — baselines, what-changed, and detecting persistence/
tamper/webshells (T1565/T1070/T1543). The integrity half of CIA, made operational.
**Primary artifact:** `infra/wazuh/fim.conf` + `scripts/fim_check.sh`.

> **How to use this lesson:** read §1–§7, do §8 (baseline + trip FIM with a real change), produce §9,
> quiz, reflect. Then Lesson 25. **This + 07–16, 18–20 completes the Wave-2 (SOC T1) milestone.**

---

## §1 — Concept (Scientific Theory)

### What it is
**File Integrity Monitoring (FIM)** watches critical files/directories and alerts when they're
**created, modified, or deleted** — by comparing current state (hash + metadata) to a known **baseline**.
Wazuh's `syscheck` does this continuously across agents; **AIDE** is a standalone Linux equivalent.
It's the operational form of the integrity baseline you met in Lesson 02.

### Why it exists
Many high-impact attacker actions *change files*: dropping a webshell, editing `/etc/passwd` or
`sshd_config`, adding an `authorized_keys` line, modifying a binary (trojan), or truncating a log
(tamper). FIM turns "a file changed" into an alert — catching persistence + tampering that other
detections miss. It's also a compliance staple (PCI-DSS requires it).

### Three-Level Depth (Lens A)
- **Level 1 — Beginner:** take a fingerprint of important files; if a fingerprint changes, something
  edited the file — alert.
- **Level 2 — Analyst/SOC:** configure FIM on critical paths (`/etc`, `/root/.ssh`, web root, system
  binaries); it baselines (hash + perms + owner) and alerts on diffs with **what changed** (old vs
  new). Pair with `auditd` (Lesson 04) to add **who** changed it.
- **Level 3 — Adversary/Kernel:** `syscheck` can run scheduled (hash scans) or **real-time**
  (inotify) for instant detection. The alert shows hash/size/perm/owner deltas. FIM + the audit
  `who` (auid) together answer what+when+who. Real-time FIM beats scheduled because an attacker can
  change-and-revert between scans.

### Two Teaching Approaches (Lens B) — FIM
**Approach 1 (technical):** FIM = a baseline database of (path → hash + metadata) + a change detector
(scheduled rescan or inotify) that diffs current vs baseline and emits typed change events
(added/modified/deleted) with attribute deltas.

**Approach 2 (analogy):** **tamper-evident seals** on the important cabinets. You record each seal's
intact state (baseline); if a seal is broken or different, you know that cabinet was opened — even if
you didn't see it happen. **Where it breaks down:** a seal tells you *that* it changed, not *who* —
which is why you pair FIM with the audit log (the door-badge record).

### Visual (ASCII) — FIM detection
```
 BASELINE:  /etc/passwd → sha256:aaa, perm 644, owner root
            /var/www/  → {index.php, style.css}   (known set)
        │  (attacker drops a webshell + edits passwd)
        ▼
 NOW:      /etc/passwd → sha256:bbb  (CHANGED)        → FIM alert: modified
           /var/www/x.php (NEW)                        → FIM alert: added (webshell?)
   + auditd: auid=1000 ran useradd → WHO changed it. (FIM=what/when, audit=who)
```

---

## §2 — Linux Investigation Commands

```bash
# AIDE (standalone FIM)
aide --init ; mv /var/lib/aide/aide.db.new.gz /var/lib/aide/aide.db.gz   # baseline
aide --check                                # diff current vs baseline (what changed)
# manual baseline (the Lesson 02 seed)
find /etc /root/.ssh -type f -exec sha256sum {} \; > baseline.sha256
sha256sum -c baseline.sha256 2>/dev/null | grep -v ': OK'   # show only changes
# Wazuh FIM
grep -A20 "<syscheck>" /var/ossec/etc/ossec.conf           # FIM config
jq 'select(.syscheck) | {path:.syscheck.path, event:.syscheck.event}' /var/ossec/logs/alerts/alerts.json
bash scripts/fim_check.sh
```
| Linux | Wazuh |
|---|---|
| `aide --check` | `syscheck` FIM alerts |
| `sha256sum -c` | hash-based change detection |
| inotify | Wazuh real-time FIM (`realtime="yes"`) |

---

## §3 — Real-World Threat Context & Use Cases

- **Webshell detection:** a new file in the web root = a high-fidelity webshell alert (ties to
  Lesson 23).
- **Persistence detection:** changes to `authorized_keys`, cron, systemd units, `sshd_config`
  (Lesson 22).
- **Tamper detection:** changed system binaries (trojaned), truncated logs (T1070).
- **Compliance:** PCI-DSS/CIS require FIM on critical files.
- **Exam framing:** FIM, integrity controls, T1565/T1070 on Security+/CySA+/BTL1.

---

## §4 — Detection

- **FIM is a detection engine:** the config (which paths, real-time vs scheduled) *is* the detection
  design. Critical set: `/etc` (passwd/shadow/sudoers/ssh), `/root/.ssh` + user `.ssh`, web roots,
  system binary dirs, cron/systemd paths, log dir.
- **Real-time for the highest-value paths** (web root, `.ssh`, `/etc`) — catch change-and-revert.
- **FIM + audit = what + who:** combine for complete change attribution.
- **Tune:** exclude noisy legitimate-change paths (package updates, app caches) or you'll drown.

---

## §5 — Investigation & Triage

A FIM alert: what changed (old vs new hash/perms), when, and — via audit (auid) — who. Decide
authorized (a package update/admin change) vs malicious (a webshell, a passwd edit, a new key). Scope
(same change on other hosts? `ioc_sweep.sh`). Authorized-change FPs are common — pair with change
management + audit context.

---

## §6 — SOC Perspective

FIM is a high-value, lower-volume detection (once tuned) — changes to crown-jewel files are rare and
meaningful. The SOC tunes out package-update noise and watches the critical set in real time. `fim_
check.sh`/AIDE is the standalone fallback when Wazuh isn't on a host. Maps to `soc/soc-scenarios.md`
#7.

---

## §7 — Incident-Response Perspective

FIM is central to **eradication validation** (IR Phase 4/5): after cleaning, FIM confirms no
malicious files remain and none reappear. During investigation it reveals *what the attacker
touched* (webshell, persistence, tampered logs) — key timeline + IOC input. Capstone stages 4–5.

---

## §8 — Practical Lab (build this yourself)

**Goal:** baseline critical files, then trip FIM with real attacker-style changes.

### Lens C — Manual → Automated → Why
- **Manual:** `sha256sum` baseline + compare (Lesson 02).
- **Automated:** Wazuh `syscheck` (continuous, real-time, fleet-wide) + `fim_check.sh`/AIDE for
  standalone hosts.
- **Why:** manual hashing is point-in-time; FIM watches always and alerts instantly — and validates
  eradication. Production runs real-time FIM on critical paths.

### Steps
1. Configure FIM: save `infra/wazuh/fim.conf` (sanitized) with the critical path set, `realtime="yes"`
   on web root + `.ssh` + `/etc`. (Or AIDE if not running Wazuh on the host.)
2. Baseline it (Wazuh auto-baselines; AIDE `--init`).
3. **Trip it (drills 7,9,10, lab):** drop a fake webshell into the web root; append a key to
   `authorized_keys`; truncate a test log. Confirm FIM alerts (added/modified) with the deltas.
4. Build `scripts/fim_check.sh`: AIDE-check or `sha256sum -c` against a committed baseline; print only
   changes. `bash -n` + `shellcheck` clean.
5. **Validate eradication:** remove the planted changes, re-run FIM → prove clean. Pair one change
   with `auditd` to show *who* (auid).

### Lens D — the raw artifact
```
# Wazuh syscheck alert (what changed):
{"syscheck":{"path":"/var/www/html/x.php","event":"added","size_after":"842",
 "sha256_after":"e3b0c4..."},"rule":{"description":"File added to the system.","level":7}}
# + auditd (who): type=SYSCALL auid=1000 exe="/usr/bin/vi" key="webroot_changes"
```

---

## §9 — GitHub Artifact (the 6-artifact evidence package)

1. **Script:** `scripts/fim_check.sh` (committed, `shellcheck`-clean).
2. **Detection rule/config:** `infra/wazuh/fim.conf` (the FIM design — critical paths, real-time).
3. **Runbook:** `docs/runbooks/runbook-fim-alert.md` — authorized vs malicious change → action.
4. **Playbook:** `docs/playbooks/fim-play.md` (FIM + audit = what+who; eradication validation).
5. **Incident report + notes:** the webshell/key/log-truncation drill (detected + who + eradication
   validated) + notes.
6. **SOC ticket:** `SOC-24` (Task: "FIM design + trip + validate") → Closed.

---

## §10 — Portfolio Artifact

- **Resume bullet:** "Designed Wazuh FIM (`syscheck`) + AIDE coverage of critical paths with
  real-time monitoring; detected webshell drops, SSH-key persistence, and log tampering (T1565/T1070)
  and used FIM to validate eradication."
- **Interview talking point:** FIM + audit = what+who, why real-time beats scheduled, and FIM's role
  in eradication validation.
- **Serves:** SOC T1 → T2 (Stages 2–3). **Completes Wave-2 (SOC T1)** — write `PORTFOLIO.md`.

---

## §11 — Certification Crossover Notes

- **Security+:** integrity/FIM (4.x). **CySA+:** FIM + analysis. **SC-200:** file/endpoint
  monitoring. **BTL1:** FIM. PCI-DSS FIM requirement. Detail: `alignment/CERTIFICATION-MAPPING.md`.

---

## §12 — Security Notes (Lens E — Attacker & Defender)

**🔴 Attacker:** modify files for persistence (webshell, keys, cron — T1543/T1098), trojan binaries
(T1565), tamper logs (T1070), and try change-and-revert between scheduled scans to evade FIM; may
disable the agent first (T1562).

**🔵 Defender:** real-time FIM on critical paths (defeats change-and-revert), FIM + audit for
what+who, alert on web-root + `.ssh` + `/etc` + binary changes, tune out package-update noise, and
protect/alert on the FIM agent itself. FIM is both a detection and the eradication-validation tool.

---

## Quiz (Interview-Style, Graded)

**Q1.** What does FIM detect, and how does a baseline make that possible?
> **Your answer:**

**Q2.** Why pair FIM with `auditd` — what does each provide?
> **Your answer:**

**Q3.** Real-time vs scheduled FIM — what attack does real-time catch that scheduled can miss?
> **Your answer:**

**Q4.** **Scenario:** FIM alerts that a new `.php` file appeared in the web root at 02:30. What do
you check, how do you decide malicious vs benign, and what's the host link?
> **Your answer:**

**Q5.** How is FIM used to validate eradication after an incident?
> **Your answer:**

*(Request the "Professional Answer" comparison under each before moving on.)*

---

## Reflection
*(After the quiz)* — What did you learn? · What confused you? · What would you do differently?

---

## Search Keywords For Further Understanding

**Core**
- `file integrity monitoring wazuh syscheck`
- `aide linux file integrity`
- `fim real time inotify vs scheduled`
- `detect webshell file integrity`
- `mitre t1565 t1070 t1543`

**Tools**
- `wazuh syscheck configuration realtime`
- `aide init check`

**Going further**
- `threat hunting` (L25) · `containment eradication recovery` (L29) · `capstone` (L35)

**Red / Blue (Lens E):**
- 🔴 `data manipulation T1565`, `indicator removal T1070`, `change-and-revert evasion`
- 🔵 `real-time fim critical paths`, `fim + audit what+who`, `eradication validation`

---

## Lesson Status
- [ ] §8 lab completed (FIM baselined + tripped + eradication validated)
- [ ] 6-artifact evidence package committed (§9)
- [ ] Quiz answered + professional-answer comparisons (graded)
- [ ] Reflection + Search Keywords reviewed
- [ ] **Wave-2 PORTFOLIO.md** written (07–16, 18–20, 24 done)

When complete, run the Update Protocol, then move to **Lesson 25 — Threat Hunting Fundamentals**.

---

*Lesson 24 written by Navi · 2026-06-20 · full-depth. Sources to cite at study time: Wazuh FIM
docs, AIDE manual, MITRE T1565/T1070, PCI-DSS FIM requirement.*
