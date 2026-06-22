# Lesson 11 — Cyber Kill Chain

**Status:** ✅ ready for self-study (full depth) · **Date written:** 2026-06-20
**Schema:** 12-section SOC (`docs/learning/CLAUDE_TEACHING_RULES.md`)
**Focus:** the 7 stages of an intrusion (recon → actions on objectives), the **Diamond Model**, and
mapping a real intrusion to the chain + ATT&CK — so you can detect *early* and predict *next*.
**Primary artifact:** `docs/learning/kill-chain-map.md` (a lab intrusion mapped end-to-end).

> **How to use this lesson:** read §1–§7, do §8 (map a staged lab intrusion to the chain), produce
> §9, quiz, reflect. Then Lesson 12.

---

## §1 — Concept (Scientific Theory)

### What it is
The **Lockheed Martin Cyber Kill Chain** models an intrusion as 7 sequential stages:
1. **Reconnaissance** — research/scan the target. 2. **Weaponization** — build the payload.
3. **Delivery** — get it to the target (phish, exploit). 4. **Exploitation** — execute it.
5. **Installation** — establish persistence. 6. **Command & Control (C2)** — remote control.
7. **Actions on Objectives** — steal/encrypt/destroy.

The **Diamond Model** complements it: every intrusion event has four linked vertices —
**Adversary**, **Capability** (tool/technique), **Infrastructure** (IPs/domains), **Victim** —
useful for analysis + pivoting.

### Why it exists
The chain encodes a powerful defensive idea: **the earlier in the chain you detect, the cheaper the
defense.** Catch recon/delivery → you stop the attack before damage. Catch only at "actions on
objectives" → the data's already gone. It gives the SOC a sense of *how far along* an intrusion is
and *what comes next*.

### Three-Level Depth (Lens A)
- **Level 1 — Beginner:** attacks happen in steps — look around, break in, dig in, take what they
  came for. Catch them early = less harm.
- **Level 2 — Analyst/SOC:** you locate an alert *on the chain* (is this recon or C2?) to gauge
  urgency and predict the next move. Each stage has detections (recon → scan/auth-fail alerts;
  installation → FIM/persistence; C2 → beaconing). Defense = a control/detection per stage
  ("courses of action": detect/deny/disrupt/degrade/deceive/destroy).
- **Level 3 — Adversary/Kernel:** the chain maps onto ATT&CK tactics (recon→Reconnaissance/Initial
  Access; installation→Persistence; C2→Command and Control; actions→Exfil/Impact). The earliest
  durable host artifacts (auth failures, new listeners, cron changes) are where you intervene to
  break the chain.

### Two Teaching Approaches (Lens B) — the kill chain
**Approach 1 (technical):** a sequential dependency graph — each stage enables the next; breaking
*any* link defeats the intrusion. Defenders aim to detect at the earliest feasible link and apply a
course of action.

**Approach 2 (analogy):** a **burglary**. Recon = casing the neighborhood; weaponization = packing
the lock-picks; delivery = walking to the door; exploitation = picking the lock; installation =
propping a window for next time; C2 = a walkie-talkie to a lookout; actions = loading the van with
your TV. Catch them casing the street and nothing's stolen; catch them only as the van pulls away
and you're too late. **Where it breaks down:** real intrusions loop and skip stages (especially
insider/cloud attacks) — ATT&CK's matrix captures that flexibility better than a strict line.

### Visual (ASCII) — chain + where you detect
```
 1 Recon ─► 2 Weaponize ─► 3 Delivery ─► 4 Exploit ─► 5 Install ─► 6 C2 ─► 7 Actions
   scan/        (off-box,     phish/        run         persist     beacon   exfil/
   auth-fail    not seen)     exploit       payload      (cron/key)          encrypt
   ▲ DETECT     —             ▲ DETECT      ▲ DETECT     ▲ DETECT    ▲ DET   ▲ too late
   cheapest defense ───────────────────────────────────────────────────► costliest
```

---

## §2 — Linux Investigation Commands

Each stage has a host artifact you can hunt:
```bash
# Recon / Delivery / Exploitation
grep -E "Failed password|Invalid user" /var/log/auth.log     # brute/recon (stage 1/3)
grep -E "UNION SELECT|\.\./" /var/log/nginx/access.log        # web exploit attempt (stage 3/4)
# Installation (persistence)
ls -la /etc/cron.* /var/spool/cron/ ~/.ssh/authorized_keys ; systemctl list-timers
# C2
ss -tunap state established                                    # beaconing/C2 peers (stage 6)
# Actions on objectives
find / -name '*.tar.gz' -newermt '-1 day' 2>/dev/null         # staged exfil archives (stage 7)
```
| Stage | Host artifact | Lesson |
|---|---|---|
| Recon/Delivery | auth/web logs | 18–20, 23 |
| Installation | cron/keys/timers | 22, 24 |
| C2 | established sockets | 07 |
| Actions | large/odd outbound, archives | 07, 35 |

---

## §3 — Real-World Threat Context & Use Cases

- **Urgency triage:** locating an alert on the chain sets severity — recon (low/medium) vs
  installation/C2 (high, active intrusion).
- **Predict the next move:** caught a brute force (delivery)? watch for the successful login
  (exploitation) and persistence (installation) next.
- **Communicate to leadership:** "we caught it at delivery, before any data was touched" is the
  exec-summary language that conveys impact (Lesson 30).
- **Exam framing:** the 7 stages, "detect early," and the Diamond Model appear on
  Security+/CySA+/BTL1.

---

## §4 — Detection

- **Detect-early bias:** invest detection effort at recon/delivery/installation, where stopping the
  chain is cheap. Recon detection (scan/auth-fail) buys the most time.
- **Stage coverage:** ensure you have at least one detection per stage (this overlaps the ATT&CK
  coverage map, Lesson 10). A gap at "installation" means an attacker who gets in stays in unseen.
- **Course-of-action matrix:** per stage, decide detect/deny/disrupt — e.g. C2 → detect (alert) +
  disrupt (block the peer).

---

## §5 — Investigation & Triage

The chain is a triage + scoping tool: place the alert on the chain → infer what *must have*
happened before (earlier stages — go find the evidence) and what's *likely next* (pivot to detect
it). It turns a single alert into a reconstructed (partial) intrusion you can scope.

---

## §6 — SOC Perspective

The SOC uses the chain to communicate intrusion *progress* ("attacker at stage 5 on web01,
contained before C2") and to structure playbooks by stage. It pairs with ATT&CK (techniques) — the
chain gives the narrative arc, ATT&CK the precise method. Leadership understands the chain; analysts
use ATT&CK.

---

## §7 — Incident-Response Perspective

The kill chain frames the IR narrative + the lessons-learned: "we detected at stage 6 (C2); we
should have caught stage 1 (recon) — add scan detection." It directly informs *where to add
detection* to catch the next intrusion earlier (Phase 6). The capstone (Lesson 35) is a full chain
to reconstruct.

---

## §8 — Practical Lab (build this yourself)

**Goal:** map a staged lab intrusion to the kill chain (and ATT&CK), stage by stage.

### Lens C — Manual → Automated → Why
- **Manual:** walk each stage and find its artifact by hand.
- **Automated:** a "stage sweep" script that checks each stage's host artifact in one run (auth
  fails, persistence, listeners, recent archives) — a kill-chain triage tool.
- **Why:** during a live incident you want a fast "how far along are they?" read. Production EDR
  presents this as an attack-story timeline.

### Steps
1. Stage the mini-chain (lab, benign — drills 1→4→6 from `threat-hunting-drills.md`): a few failed
   SSH logins → a successful login to a weak cred → a benign payload + listener → a cron entry.
2. For each kill-chain stage, find the artifact (use §2 commands) and record it with its ATT&CK
   technique in `docs/learning/kill-chain-map.md`.
3. Build `scripts/killchain_sweep.sh`: one run that checks each stage's artifact and prints which
   stages show activity. `bash -n` + `shellcheck` clean.
4. Note the *earliest* stage you could have detected — that's where you'd add a detection.
5. Write the Diamond Model for the intrusion (adversary/capability/infra/victim).

### Lens D — the raw artifact
The same raw lines you've collected, now *sequenced into a story*: failed logins (recon/delivery) →
accepted login (exploitation) → cron entry (installation) → outbound socket (C2). The kill chain is
the lens that turns scattered artifacts into one intrusion narrative.

---

## §9 — GitHub Artifact (the 6-artifact evidence package)

1. **Script:** `scripts/killchain_sweep.sh` (committed, `shellcheck`-clean).
2. **Detection rule/config:** the per-stage detection list (what catches each stage).
3. **Runbook:** `docs/runbooks/runbook-killchain-triage.md` — "place an alert on the chain, then…"
4. **Playbook:** the course-of-action (detect/deny/disrupt) per stage.
5. **Incident report + notes:** `kill-chain-map.md` of the staged intrusion + Diamond Model + notes.
6. **SOC ticket:** `SOC-11` (Task: "map a lab intrusion to the kill chain") → Closed.

---

## §10 — Portfolio Artifact

- **Resume bullet:** "Mapped a staged Linux intrusion to the Cyber Kill Chain and MITRE ATT&CK
  end-to-end, identifying the earliest detection point to break the chain."
- **Interview talking point:** walk an intrusion through the 7 stages *and* map to ATT&CK, and
  explain "detect early" — a classic SOC interview question.
- **Serves:** SOC T1 → T2 / IR (Stages 2–3). Sets up the capstone.

---

## §11 — Certification Crossover Notes

- **Security+:** attack frameworks (2.x). **CySA+:** kill chain + Diamond Model. **SC-200:** attack
  lifecycle. **BTL1:** frameworks. Detail: `alignment/CERTIFICATION-MAPPING.md`.

---

## §12 — Security Notes (Lens E — Attacker & Defender)

**🔴 Attacker:** plans along the chain, minimizes noisy early stages (passive recon, slow brute
force) to avoid the cheap-to-detect links, and rushes to persistence + C2 before you notice.

**🔵 Defender:** invest in early-stage detection (recon/delivery) to break the chain cheaply;
ensure no stage is a blind spot; use the chain to predict-and-pre-position. Every link you can
detect is a chance to stop the whole intrusion.

---

## Quiz (Interview-Style, Graded)

**Q1.** List the 7 kill-chain stages and give a Linux-detectable artifact for three of them.
> **Your answer:**

**Q2.** Why is "detect early in the chain" a core defensive principle? What's the cost difference
between catching recon vs actions-on-objectives?
> **Your answer:**

**Q3.** How does the kill chain relate to MITRE ATT&CK — when would you use each?
> **Your answer:**

**Q4.** **Scenario:** you detect C2 beaconing (stage 6) on a host. Which earlier stages must have
occurred, what evidence do you go find, and what do you do now?
> **Your answer:**

**Q5.** What are the four vertices of the Diamond Model, and how does it help you pivot?
> **Your answer:**

*(Request the "Professional Answer" comparison under each before moving on.)*

---

## Reflection
*(After the quiz)* — What did you learn? · What confused you? · What would you do differently?

---

## Search Keywords For Further Understanding

**Core**
- `lockheed martin cyber kill chain 7 stages`
- `kill chain courses of action detect deny disrupt`
- `diamond model intrusion analysis`
- `kill chain vs mitre att&ck`
- `detect early in kill chain`

**Tools**
- `linux persistence detection cron timers`
- `c2 beaconing detection`

**Going further**
- `indicators of compromise` (L12) · `incident response` (L28) · `capstone compromised server` (L35)

**Red / Blue (Lens E):**
- 🔴 `passive recon evade detection`, `rush to persistence c2`
- 🔵 `early stage detection`, `kill chain coverage`, `predict next attacker move`

---

## Lesson Status
- [ ] §8 lab completed (lab intrusion mapped to chain + ATT&CK + Diamond)
- [ ] 6-artifact evidence package committed (§9)
- [ ] Quiz answered + professional-answer comparisons (graded)
- [ ] Reflection + Search Keywords reviewed

When complete, run the Update Protocol, then move to **Lesson 12 — Indicators of Compromise**.

---

*Lesson 11 written by Navi · 2026-06-20 · full-depth. Sources to cite at study time: Lockheed
Martin Cyber Kill Chain whitepaper, Diamond Model (Caltagirone et al.), MITRE ATT&CK.*
