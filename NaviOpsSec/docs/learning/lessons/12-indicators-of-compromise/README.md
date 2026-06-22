# Lesson 12 — Indicators of Compromise

**Status:** ✅ ready for self-study (full depth) · **Date written:** 2026-06-20
**Schema:** 12-section SOC (`docs/learning/CLAUDE_TEACHING_RULES.md`)
**Focus:** host/network/file IOCs, hashes, the **IOC lifecycle**, and extracting + operationalizing
IOCs from evidence — the pivot points that scope an incident.
**Primary artifact:** `scripts/ioc_sweep.sh` (grown from Lesson 09).

> **How to use this lesson:** read §1–§7, do §8 (extract IOCs from a drill + sweep hosts), produce
> §9, quiz, reflect. Then Lesson 13.

---

## §1 — Concept (Scientific Theory)

### What it is
An **Indicator of Compromise (IOC)** is a forensic artifact that signals an intrusion occurred.
Categories:
- **Network IOCs:** IPs, domains, URLs, JA3/TLS fingerprints, user-agents.
- **Host IOCs:** file paths, process names, registry/keys (Linux: cron entries, `authorized_keys`,
  services), mutexes, usernames.
- **File IOCs:** **hashes** (MD5/SHA-1/SHA-256), file names, sizes, YARA signatures.

IOCs are the *atomic facts* you extract from one incident and **operationalize** (add to
watchlists, scope across hosts) to catch the same threat elsewhere.

### Why it exists
When you confirm one compromised host, the urgent question is **"where else?"** IOCs are the pivot:
the attacker IP, the dropped file's hash, the created account — sweep every host for them and you
scope the incident in minutes instead of guessing. IOCs also feed detection (watchlists) and intel
sharing (Lesson 09).

### The IOC lifecycle
```
 discover (in an incident) ─► validate (TP, not benign) ─► document (typed + sourced)
        ─► operationalize (watchlist/rule/sweep) ─► share (TI) ─► expire (decay, prune)
```

### Three-Level Depth (Lens A)
- **Level 1 — Beginner:** IOCs are the "clues" — the bad IP, the bad file's fingerprint, the weird
  account — that prove and trace an attack.
- **Level 2 — Analyst/SOC:** you **extract** IOCs from evidence, **sweep** all hosts for them
  (`ioc_sweep.sh`), and **add** them to SIEM watchlists so future occurrences alert instantly. You
  type them (network/host/file) and record source + confidence.
- **Level 3 — Adversary/Kernel:** hashes identify a file exactly (one bit changes → new SHA-256 →
  evasion, the Pyramid of Pain), so file-name/path/behavioral IOCs are more durable. IOCs are
  encoded as STIX and matched at scale; the durable end is **IOA/TTP** (behavior), which is why
  scoping uses both atomic IOCs *and* behavioral hunts (Lesson 25).

### Two Teaching Approaches (Lens B) — IOC types & durability
**Approach 1 (technical):** IOCs vary in fidelity and longevity — a SHA-256 is high-fidelity but
low-longevity (trivially changed); a behavioral pattern is lower-fidelity, higher-longevity. Choose
the indicator type per use: hashes for exact known-bad blocking, behavior for resilient detection.

**Approach 2 (analogy):** crime-scene evidence. A **fingerprint** (hash) is unique but a smart
criminal wears gloves next time; their **MO** (method) persists across crimes. **Where it breaks
down:** unlike fingerprints, file hashes change with a one-byte edit — far easier to defeat than
real fingerprints, which is the whole point of climbing the Pyramid.

### Visual (ASCII) — extract → sweep → scope
```
  ONE confirmed host ──extract──► IOCs: {203.0.113.50, sha256:abc.., user svc_tmp, /tmp/.x}
        │
        └─sweep all hosts──► host02: svc_tmp present!  host05: connected to 203.0.113.50!
                              => incident scope = web01 + host02 + host05  (not just web01)
```

---

## §2 — Linux Investigation Commands

```bash
# EXTRACT IOCs from evidence
grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' /var/log/auth.log | sort -u     # IPs
sha256sum /tmp/.x /usr/local/bin/suspect                                # file hashes
awk -F: '$3>=1000{print $1}' /etc/passwd                                # local accounts (rogue?)
ls -la ~/.ssh/authorized_keys /var/spool/cron/*                          # persistence IOCs
# SWEEP for an IOC across logs/hosts
grep -F -f ioc-ips.txt /var/log/*.log                                    # network IOC match
find / -name '.x' 2>/dev/null ; getent passwd svc_tmp                    # host IOC match
# VALIDATE a hash (approved/lab; reaches a third party)
# (VirusTotal / MalwareBazaar lookup of the SHA-256 via web/API w/ key)
```
| Linux | SIEM equivalent |
|---|---|
| `grep -F -f ioc-list` | Wazuh **CDB list** match |
| `sha256sum` + lookup | SIEM hash reputation / VT integration |
| account/cron/key checks | FIM + audit rules (host IOCs) |

---

## §3 — Real-World Threat Context & Use Cases

- **Scoping ("where else?"):** the #1 use — pivot from one host to the full blast radius.
- **Instant recognition:** a known hash/IP turns minutes of analysis into an immediate TP.
- **Watchlist detection:** operationalized IOCs alert on recurrence automatically.
- **The decay trap:** stale IOCs cause false positives + waste; prune by date/source.
- **Exam framing:** IOC types, hashing, and IOC vs IOA appear on Security+/CySA+/BTL1.

---

## §4 — Detection

- **IOC watchlist detection:** maintain typed IOC lists (`docs/detections/ioc-list.md`), match
  events against them (Wazuh CDB lists / Sigma). High precision, low longevity — refresh + expire.
- **Host-IOC detection:** wire the durable host IOCs (rogue account, new cron, new `authorized_keys`)
  to audit/FIM rules (Lessons 22, 24) — these survive better than hashes.
- **Prefer behavior for durability:** combine IOC matching with IOA/TTP detection so IOC rotation
  doesn't blind you (Pyramid of Pain, Lesson 09).

---

## §5 — Investigation & Triage

IOC extraction is the heart of investigation Phase 2 (`workflows/ir-workflow.md`): from the
evidence, pull every indicator, validate each (TP vs benign), type it, then **sweep** to scope. The
discipline: record each IOC with its **source** (which log/file) and **confidence** — facts vs
assessment.

---

## §6 — SOC Perspective

IOCs are the SOC's currency for scoping + sharing. A confirmed incident's IOCs go onto the
watchlist (catch recurrence) and into the team's TI (Lesson 09). The case (`SOC-NN`) records the
full IOC set as a first-class field (`soc/case-management.md`).

---

## §7 — Incident-Response Perspective

IOCs drive scoping (Phase 2), confirm eradication (Phase 4: are the IOCs *gone* everywhere?), and
validate recovery (Phase 5: do they *stay* gone?). In lessons-learned (Phase 6) the durable IOCs
become standing detections. The capstone (Lesson 35) requires a complete, typed IOC list.

---

## §8 — Practical Lab (build this yourself)

**Goal:** extract IOCs from an earlier drill and sweep your lab for them.

### Lens C — Manual → Automated → Why
- **Manual:** pull IOCs from one log by hand.
- **Automated:** grow `scripts/ioc_sweep.sh` to (a) extract candidate IOCs from evidence and (b)
  match a provided IOC list across logs/files — one tool for extract + sweep.
- **Why:** scoping speed = containment speed = lower impact. Production matches IOCs against every
  event automatically (SIEM watchlists).

### Steps
1. Take the capstone-style mini-drill from Lesson 11 (or run drills 2+5+6). From its evidence,
   extract: the attacker IP, any dropped file's hash, the created account, the cron/key artifact.
2. Add them, typed + sourced + dated, to `docs/detections/ioc-list.md`.
3. Grow `scripts/ioc_sweep.sh`: extract-IPs/hashes + `grep -F -f` match + host checks
   (`getent passwd`, `find` for the file). `bash -n` + `shellcheck` clean.
4. Run the sweep across your lab host(s); confirm it flags the planted IOCs. (Plant one on a second
   VM to prove cross-host scoping.)
5. Mark each IOC's Pyramid tier + decay date.

### Lens D — the raw artifact
```
$ sha256sum /tmp/.x
e3b0c44298fc1c149afbf4c8996fb924... /tmp/.x      ← the file IOC; one byte change = a new hash
$ getent passwd svc_tmp
svc_tmp:x:1002:1002::/home/svc_tmp:/bin/bash     ← the host IOC; durable, audit-detectable
```

---

## §9 — GitHub Artifact (the 6-artifact evidence package)

1. **Script:** `scripts/ioc_sweep.sh` (extract + sweep; committed, `shellcheck`-clean).
2. **Detection rule/config:** `docs/detections/ioc-list.md` (typed, sourced, Pyramid-ranked).
3. **Runbook:** `docs/runbooks/runbook-ioc-extraction.md` — how to extract + sweep IOCs.
4. **Playbook:** the extract → validate → operationalize → expire lifecycle play.
5. **Incident report + notes:** scoping report (extracted IOCs → swept → found on host02) + notes.
6. **SOC ticket:** `SOC-12` (Task: "IOC extraction + cross-host scoping") → Closed.

---

## §10 — Portfolio Artifact

- **Resume bullet:** "Built an IOC extraction + cross-host sweep tool (`ioc_sweep.sh`); scoped a
  simulated incident from one host to its full blast radius via typed, ranked indicators."
- **Interview talking point:** explain the IOC lifecycle + why you sweep IOCs to scope, and why
  hashes decay (Pyramid). 
- **Serves:** SOC T2 / IR (Stage 3). Core capstone skill.

---

## §11 — Certification Crossover Notes

- **Security+:** IOCs (2.x). **CySA+:** IOA/IOC + analysis. **SC-200:** indicators. **BTL1:** IOCs +
  forensics. Detail: `alignment/CERTIFICATION-MAPPING.md`.

---

## §12 — Security Notes (Lens E — Attacker & Defender)

**🔴 Attacker:** change file hashes trivially (recompile/pad), rotate IPs/domains, use generic
names — defeating atomic IOCs (bottom of the Pyramid). They reuse infra only carelessly.

**🔵 Defender:** extract + sweep IOCs fast for scoping (their best short-term use), but anchor
durable detection on host IOCs (accounts/cron/keys) + behavior/TTP that survive rotation. Prune
stale IOCs to avoid false positives. Share validated IOCs to help the community.

---

## Quiz (Interview-Style, Graded)

**Q1.** Name the three IOC categories with two examples each (Linux-flavored).
> **Your answer:**

**Q2.** Walk the IOC lifecycle from discovery to expiry. Why does expiry matter?
> **Your answer:**

**Q3.** Why are file hashes high-fidelity but low-durability, and what indicator types are more
durable?
> **Your answer:**

**Q4.** **Scenario:** you confirm web01 is compromised. Which IOCs do you extract first, and how do
you use them to answer "where else?"
> **Your answer:**

**Q5.** How do extracted IOCs feed eradication and recovery validation?
> **Your answer:**

*(Request the "Professional Answer" comparison under each before moving on.)*

---

## Reflection
*(After the quiz)* — What did you learn? · What confused you? · What would you do differently?

---

## Search Keywords For Further Understanding

**Core**
- `indicators of compromise types host network file`
- `ioc lifecycle extraction operationalization`
- `file hash md5 sha256 malware`
- `ioc sweep scope incident`
- `stix ioc format`

**Tools**
- `wazuh cdb list ioc`
- `sha256sum yara linux`

**Going further**
- `siem fundamentals` (L13) · `threat hunting` (L25) · `capstone` (L35)

**Red / Blue (Lens E):**
- 🔴 `hash change evasion`, `ip domain rotation`, `generic naming`
- 🔵 `ioc sweep scoping`, `durable host iocs`, `watchlist + behavior detection`

---

## Lesson Status
- [ ] §8 lab completed (IOCs extracted + cross-host sweep)
- [ ] 6-artifact evidence package committed (§9)
- [ ] Quiz answered + professional-answer comparisons (graded)
- [ ] Reflection + Search Keywords reviewed

When complete, run the Update Protocol, then move to **Lesson 13 — SIEM Fundamentals**.

---

*Lesson 12 written by Navi · 2026-06-20 · full-depth. Sources to cite at study time: MITRE ATT&CK,
SANS IOC/forensics, STIX/TAXII docs, abuse.ch/MalwareBazaar.*
