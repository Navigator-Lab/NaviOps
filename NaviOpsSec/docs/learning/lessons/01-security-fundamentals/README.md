# Lesson 01 — Security Fundamentals

**Status:** ✅ ready for self-study (full depth) · **Date written:** 2026-06-22
**Schema:** 12-section SOC (`docs/learning/CLAUDE_TEACHING_RULES.md`)
**Focus:** what security operations *is*, the threat/attack/control model, defense-in-depth, blue vs
red, and the SOC's job — the foundation the whole track builds on.
**Primary artifact:** `docs/playbooks/soc-intro.md` + `scripts/log_triage.sh` (started here).

> **How to use this lesson:** this is Lesson 01 — the orientation. Read §1–§7, do §8 (run your first
> Linux triage by hand, then start `log_triage.sh`), answer the quiz, reflect. Then Lesson 02.

---

## §1 — Concept (Scientific Theory)

### What it is
**Security operations** is the continuous discipline of **defending systems and data from attackers**
— detecting malicious activity, investigating it, responding, and improving so it's harder next time.
A **SOC (Security Operations Center)** is the people + process + technology that runs this loop, often
24/7. As a defender ("blue team") your job is not to build the app — it's to *watch it, catch the
attacker, and limit the damage*.

### The core model: threat → vulnerability → attack → control
- **Asset:** something worth protecting (data, a server, a credential, uptime).
- **Threat:** a potential cause of harm (an attacker, malware, an insider, a flood).
- **Vulnerability:** a weakness a threat can exploit (unpatched software, weak password, open port).
- **Attack:** a threat actively exploiting a vulnerability against an asset.
- **Control:** a safeguard that reduces risk by removing the vulnerability or detecting/stopping the
  attack. (Risk math is Lesson 02.)

### Control types (you'll classify everything as one of these)
| Type | When it acts | Example |
|---|---|---|
| **Preventive** | before | firewall, MFA, patching, least privilege |
| **Detective** | during/after | IDS, log monitoring, the SOC alert |
| **Corrective** | after | isolate host, restore backup, reset creds |
| **Deterrent** | before (discourage) | warning banners, visible logging |
| **Compensating** | substitute | extra monitoring when a fix isn't yet possible |

### Defense-in-depth
No single control is perfect, so you **layer** them — network (firewall/segmentation), host (EDR,
hardening), identity (MFA, least privilege), application (input validation), data (encryption),
and **monitoring across all of them** so an attacker who beats one layer is caught at the next. (This
mirrors the OSI per-layer idea on the networking track.)

### Blue vs Red (and Purple)
- **Red team / attacker:** simulates real adversaries to find what gets through.
- **Blue team / defender (you):** detects, responds, and hardens.
- **Purple:** red + blue working together so every attack technique becomes a new detection.
You build *both* mindsets here: to defend a technique well, you must understand how it's attacked.

### Three-Level Depth (Lens A)
- **Level 1 — Beginner:** security ops is the team that watches for hackers and responds when
  something looks wrong. Attackers exploit weaknesses; controls reduce the risk.
- **Level 2 — Analyst/SOC:** the work is an **alert queue** + investigation. You decide true-vs-false
  positive, severity, and whether to close-and-tune or escalate — fast, consistently, against an SLA.
  Your raw material is **logs** (Module 2), correlated by a SIEM (Module 4).
- **Level 3 — Adversary/Kernel:** attacks follow a **kill chain** (recon → initial access → execution
  → persistence → lateral movement → exfiltration), catalogued by **MITRE ATT&CK**. Defense quality =
  detection **coverage** of those techniques + low **MTTD/MTTR** (Lesson 03). Attackers win via
  coverage gaps and dwell time.

### Two Teaching Approaches (Lens B) — defense-in-depth
**Approach 1 (technical):** independent, overlapping controls at each layer so the failure of one
doesn't equal compromise; monitoring spans all layers to catch what slips through.

**Approach 2 (analogy):** a **medieval castle** — moat, outer wall, inner wall, guards, and a locked
keep. An attacker past the moat still faces the walls and guards. *Where it breaks down:* castles are
static; a SOC actively *watches* and *adapts*, turning each breach attempt into a stronger wall (new
detection).

### Visual (ASCII) — the security operations loop
```
        ┌────────────► DETECT (logs/IDS/SIEM alert)
        │                   │
   IMPROVE                TRIAGE  (true/false positive, severity)
 (new detection)            │
        ▲               INVESTIGATE (scope: what/where/how bad)
        │                   │
        └──────────────── RESPOND (contain → eradicate → recover → document)
```

---

## §2 — Linux Investigation Commands

A defender's "first look" on a Linux host — the toolkit `log_triage.sh` will automate:
```bash
last -n 20 ; lastb -n 20         # recent successful + FAILED logins
who ; w                          # who's logged in right now
journalctl -S -30m -p warning    # what warned/errored in the last 30 min
grep -i 'failed password' /var/log/auth.log | tail   # SSH brute-force signal (Debian)
ss -tunap                        # active connections + the process behind each
ps aux --sort=-%cpu | head       # unexpected/expensive processes
sudo ausearch -m USER_LOGIN -ts recent   # audit log of logins (if auditd, Lesson 04)
```
| Linux first-look | SIEM equivalent |
|---|---|
| `grep failed password` | a "brute force" correlation rule |
| `last`/`lastb` | authentication dashboard |
| manual eyeballing | the alert + enrichment panel |

---

## §3 — Real-World Threat Context & Use Cases

- **The everyday threats a SOC catches:** brute-force/credential stuffing, phishing → malware,
  exploitation of unpatched services, privilege escalation, lateral movement, data exfiltration,
  ransomware, and insider misuse.
- **Why monitoring exists:** prevention always fails *eventually* (a user clicks, a patch lags) — so
  **detection + response** is what limits the damage when it does.
- **Where you start a career:** SOC Tier-1 analyst — triage the queue, close false positives, escalate
  the real ones. This track builds exactly that skill set toward Security Analyst / SOC roles.
- **Exam framing:** the threat/vuln/attack/control vocabulary, control types, and defense-in-depth are
  foundational on Security+, CySA+, and BTL1.

---

## §4 — Detection

Detection is the heartbeat of security operations. A good detection is **actionable**: it says *what*
happened, *where*, *how bad*, and links a runbook. Sources you'll learn to detect from:
- **Authentication logs** (failed/successful logins, sudo) — the most common Tier-1 signal.
- **Process & network activity** (unexpected processes, outbound beaconing).
- **System/audit logs** (`auditd`, Lesson 04) and, later, **SIEM correlation** (Wazuh, Module 4).
The §8 `log_triage.sh` you start here is your first hand-built detector: it surfaces failed logins and
anomalies so they don't hide in raw log noise.

---

## §5 — Investigation & Triage

The Tier-1 decision flow on any signal:
1. **True or false positive?** (is this real malicious activity or expected behavior?)
2. **Severity?** (impact on confidentiality/integrity/availability — Lesson 02 — × asset value).
3. **Scope?** (one host/account, or many?)
4. **Enrich** (who/what/when; is the source IP/user known-bad or known-good?).
5. **Decide:** close + tune (FP), handle (low sev), or **escalate** (confirmed/serious).
The judgment that defines a good analyst: escalate the **right** things — not so early you waste Tier-2,
not so late the attacker spreads. (Formalized in Lesson 03's escalation matrix.)

---

## §6 — SOC Perspective

This whole lesson *is* the SOC orientation. Internalize the loop (detect → triage → investigate →
respond → improve), that your raw material is **logs**, and that your output is a **decision** on each
alert (close/handle/escalate) recorded in a ticket. Everything later — log analysis (Module 2), threat
knowledge (Module 3), SIEM/Wazuh (Module 4), detection & IR (Modules 5–6) — plugs into this backbone.

---

## §7 — Incident-Response Perspective

The IR lifecycle (NIST SP 800-61) you'll run for real later: **Prepare → Detect & Analyze →
Contain → Eradicate → Recover → Lessons Learned.** As a Tier-1 analyst you live mostly in *Detect &
Analyze* and you *initiate* the rest by escalating with a complete handover. Knowing the full
lifecycle from Day 1 means your triage notes capture what the responders will need.

---

## §8 — Practical Lab (build this yourself)

**Goal:** run a manual Linux security triage, then start `scripts/log_triage.sh` — your first
automated first-look.

### Lens C — Manual → Automated → Why
- **Manual:** hunt failed logins, current sessions, and odd connections by hand with §2 commands.
- **Automated:** `log_triage.sh` runs them in order, counts failed logins per source IP, and flags
  thresholds — the consistent first-pass on every host.
- **Why:** SOCs live on consistency; a triage script means two analysts reach the same first-look on
  the same host, fast, under pressure.

### Steps
1. Run each §2 command on your machine and interpret the output (note what "normal" looks like — your
   own baseline).
2. Build `scripts/log_triage.sh` (skeleton — adjust log path for your distro):

```bash
#!/usr/bin/env bash
# log_triage.sh — first-pass host security triage. Lesson 01 (extended in L03/L05).
set -euo pipefail
AUTH=${1:-/var/log/auth.log}      # RHEL/Fedora: /var/log/secure
echo "== current sessions =="; who
echo "== recent failed logins (top sources) =="
if [ -r "$AUTH" ]; then
  grep -i 'failed password' "$AUTH" | grep -oE 'from [0-9.]+' | awk '{print $2}' \
    | sort | uniq -c | sort -rn | head
else
  echo "(no read access to $AUTH — try: journalctl -u ssh -p warning)"
fi
echo "== listening + connected sockets =="; ss -tunap 2>/dev/null | head
echo "== top processes by CPU =="; ps aux --sort=-%cpu | head -6
# TODO (operator): add a threshold flag (e.g. >10 failures from one IP => FLAG) + exit code.
```

3. `bash -n log_triage.sh` → `shellcheck log_triage.sh` → run it.
4. **Break-it/see-it drill:** generate failed logins in a VM (`ssh baduser@localhost` a few times with
   a wrong password), re-run the script, and confirm the offending source/count surfaces.
5. Write `docs/playbooks/soc-intro.md` — your one-page "what security ops is + how I triage a host."

### Lens D — the raw evidence
A single failed SSH login is one line:
```
... sshd[1234]: Failed password for invalid user admin from 10.0.0.99 port 4444 ssh2
```
A detector's value is turning *many* such lines into one counted, triaged signal ("12 failures from
10.0.0.99 → possible brute force").

---

## §9 — GitHub Artifact (the 6-artifact evidence package)

1. **Script:** `scripts/log_triage.sh` (committed, shellcheck-clean).
2. **Detection rule/config:** N/A yet (orientation) — instead, the triage thresholds you choose.
3. **Runbook:** `docs/runbooks/runbook-host-first-look.md` — the manual triage steps.
4. **Playbook:** `docs/playbooks/soc-intro.md` — what security ops is + your triage approach.
5. **Incident report + notes:** a worked mock "failed-login burst" first-look.
6. **SOC ticket:** `SOC-01` (Task: "host triage + log_triage.sh v1") → Closed.

---

## §10 — Portfolio Artifact

- **Resume bullet:** "Built a Linux host security-triage script (`log_triage.sh`) surfacing
  brute-force and session/connection anomalies; documented a first-look runbook and triage playbook."
- **Interview talking point:** define threat/vulnerability/attack/control and defense-in-depth, and
  walk through how you'd first-triage a suspicious Linux host.
- **Serves:** Security Analyst → SOC Tier-1 (Stage 1).

---

## §11 — Certification Crossover Notes

- **Security+:** general security concepts, control types, defense-in-depth (1.x/2.x).
- **CySA+:** security operations + the analyst mindset. **BTL1:** SOC fundamentals.
  Detail: `alignment/CERTIFICATION-MAPPING.md`.

---

## §12 — Security Notes (Lens E — Attacker & Defender)

> Frameworks: [MITRE ATT&CK](https://attack.mitre.org/).

**🔴 Attacker:** the most common Day-1 signal you'll defend against is **Brute Force** (`T1110`) —
password guessing/spraying against SSH/RDP/web logins — often the first step of the kill chain
(initial access via valid accounts, `T1078`).

**🔵 Defender:** rate-limit and lock out (fail2ban), require **MFA**, alert on failed-login bursts per
source/account (your `log_triage.sh` is the seed of this), and disable unused remote access. Verify by
generating lab brute-force traffic and confirming it's detected and blocked.

---

## Quiz (Interview-Style, Graded)

**Q1.** Define asset, threat, vulnerability, attack, and control, and give one example of each.
> **Your answer:**

**Q2.** Name the control types (preventive/detective/corrective…) and classify: a firewall, an IDS, a
backup restore, MFA.
> **Your answer:**

**Q3.** What is defense-in-depth and why does a SOC rely on it rather than one strong control?
> **Your answer:**

**Q4.** **Scenario:** you're handed a Linux server that "seems compromised." What are the first
commands you run and what are you looking for?
> **Your answer:**

**Q5.** What's the difference between the blue team and the red team, and what is "purple teaming"?
> **Your answer:**

**Q6.** Why is detection-and-response essential even with strong prevention in place?
> **Your answer:**

*(Request the "Professional Answer" comparison under each before moving on.)*

---

## Reflection
*(After the quiz)* — What did you learn? · What confused you? · What would you do differently?

---

## Search Keywords For Further Understanding

**Core**
- `security operations soc fundamentals`
- `threat vulnerability risk control definitions`
- `security control types preventive detective corrective`
- `defense in depth layered security`
- `blue team red team purple team`

**Tools**
- `linux auth.log failed password analysis`
- `last lastb login history linux`
- `fail2ban ssh brute force`

**Going further**
- `cia triad risk` (L02) · `soc tiers mttd mttr` (L03) · `linux logs auditing` (L04)

**Red / Blue (Lens E):**
- 🔴 `ssh brute force T1110`, `valid accounts T1078`, `password spraying`
- 🔵 `fail2ban lockout`, `mfa enforcement`, `detect failed login burst`

---

## Lesson Status
- [ ] §8 lab completed (manual triage + log_triage.sh v1 + failed-login drill)
- [ ] 6-artifact evidence package committed (§9)
- [ ] Quiz answered + professional-answer comparisons (graded)
- [ ] Reflection + Search Keywords reviewed

When complete, run the Update Protocol, then move to **Lesson 02 — CIA Triad · Risk · Threat · Vulnerability**.

---

*Lesson 01 written by Navi · 2026-06-22 · full-depth. Sources to cite at study time: NIST SP 800-61r2,
NIST CSF, CompTIA Security+ SY0-701, MITRE ATT&CK T1110/T1078.*
