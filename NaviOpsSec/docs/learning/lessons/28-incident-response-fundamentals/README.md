# Lesson 28 — Incident Response Fundamentals

**Status:** ✅ ready for self-study (full depth) · **Date written:** 2026-06-20
**Schema:** 12-section SOC (`docs/learning/CLAUDE_TEACHING_RULES.md`)
**Focus:** the NIST SP 800-61 lifecycle, IR roles, the IR plan, **evidence handling + chain of
custody**, and comms — the framework that turns detection into a managed response.
**Primary artifact:** `docs/templates/incident-report.md` (you fill the lifecycle).

> **How to use this lesson:** read §1–§7, do §8 (run a small incident through the full lifecycle),
> produce §9, quiz, reflect. Then Lesson 29.

---

## §1 — Concept (Scientific Theory)

### What it is
**Incident Response (IR)** is the structured process for handling a confirmed security incident. The
**NIST SP 800-61** lifecycle:
1. **Preparation** — plan, tools, runbooks, training (before anything happens).
2. **Detection & Analysis** — confirm + scope the incident (your Lessons 13–25).
3. **Containment, Eradication & Recovery** — stop it, remove it, restore (Lesson 29).
4. **Post-Incident Activity** — lessons learned + improvement (Lesson 30 + detection eng).

(The SANS variant: Preparation → Identification → Containment → Eradication → Recovery → Lessons
Learned — same idea, more granular.) The platform's `workflows/ir-workflow.md` is the operational
form.

### Why it exists
Under incident pressure, ad-hoc response loses evidence, misses persistence, and mis-communicates. A
defined lifecycle + plan + roles makes response *repeatable and defensible* — you know the next step,
who does it, and how to preserve evidence for the report (and possibly court).

### Three-Level Depth (Lens A)
- **Level 1 — Beginner:** when something bad is confirmed, follow a plan: figure out what happened,
  stop it, clean up, recover, and learn from it.
- **Level 2 — Analyst/SOC:** you execute the lifecycle with **roles** (IC/incident commander,
  investigators, comms), a **plan** (who to call, when to notify), **evidence handling** (preserve +
  hash + chain of custody, `templates/evidence-package.md`), and **documentation** throughout.
- **Level 3 — Adversary/Kernel:** the golden rule — **preserve volatile evidence before
  containment** (memory, processes, sockets, `/tmp` vanish when you isolate/reboot). Chain of custody
  (who handled what, when, hash) is what makes evidence admissible + the timeline trustworthy. The
  order of operations is itself a skill.

### Two Teaching Approaches (Lens B) — the IR lifecycle
**Approach 1 (technical):** IR is a state machine with defined transitions + entry/exit criteria per
phase; preparation + post-incident are the loops that make each future run faster. Evidence integrity
is a cross-cutting invariant.

**Approach 2 (analogy):** a **fire department**. Preparation = drills + equipment ready.
Identification = confirm it's a real fire + how big. Containment = stop it spreading. Eradication =
put it out. Recovery = make the building safe + reopen. Lessons learned = the after-action review →
new fire codes. **Where it breaks down:** in cyber you must *preserve the scene* (evidence) while
fighting the fire — firefighters don't photograph every flame first, but you must capture volatile
evidence before you "extinguish."

### Visual (ASCII) — NIST 800-61 lifecycle
```
   ┌────────────┐   ┌──────────────────┐   ┌────────────────────────────────┐   ┌───────────────┐
   │PREPARATION │──►│ DETECTION &       │──►│ CONTAINMENT · ERADICATION ·    │──►│ POST-INCIDENT │
   │(plan/tools)│   │ ANALYSIS          │   │ RECOVERY  (Lesson 29)          │   │ (Lessons      │
   └─────▲──────┘   │ (scope+timeline)  │   │  ⚠ preserve evidence FIRST     │   │  learned, 30) │
         │          └──────────────────┘   └────────────────────────────────┘   └──────┬────────┘
         └───────────────────  improvements feed back into Preparation  ◄───────────────┘
```

---

## §2 — Linux Investigation Commands

IR uses every prior skill; the IR-specific move is **evidence collection** (preserve before
containment):
```bash
# snapshot volatile state to off-box evidence dir, hashing as you go
mkdir -p evidence && cd evidence
ps auxf > ps.txt ; ss -tunap > sockets.txt ; lsof -n > lsof.txt    # volatile: processes/network
last > last.txt ; lastb > lastb.txt                                 # logins
cp /var/log/auth.log auth.log ; cp /var/log/syslog syslog          # logs (also already off-box, L06)
sha256sum * > SHA256SUMS                                            # integrity of the evidence
# verify later
sha256sum -c SHA256SUMS
bash scripts/evidence_collect.sh /path/to/case   # automate the above (order matters!)
```
| IR step | Tool |
|---|---|
| preserve volatile | `ps`/`ss`/`lsof` snapshot + hash |
| preserve logs | copy off-box (L06) + hash |
| chain of custody | `evidence-package.md` + SHA256SUMS |
| analysis | Lessons 21–25 |

---

## §3 — Real-World Threat Context & Use Cases

- **The confirmed intrusion:** when triage (Lesson 17) confirms + escalates, IR takes over with the
  lifecycle.
- **Evidence for consequences:** legal/HR/insurance/regulatory outcomes depend on properly handled
  evidence + chain of custody.
- **Comms:** who to notify (leadership, legal, affected users, regulators) and when — part of the
  plan, not improvised.
- **Exam framing:** NIST 800-61 phases, IR roles, chain of custody, and order-of-volatility on
  Security+/CySA+/SC-200/BTL1.

---

## §4 — Detection

Detection (Lessons 13–25) is IR Phase 2's front end — IR begins where detection confirms. The link
back: IR Phase 4 (post-incident) produces the **new detection** (Lesson 26) so the next occurrence is
caught in Phase 2 faster. Detection and IR are the two halves of the same loop.

---

## §5 — Investigation & Triage

IR's Detection & Analysis phase *is* the investigation you've practiced (scope, timeline, IOCs,
RCA — Lessons 21–25), now under an incident structure with evidence discipline. The triage decision
(Lesson 17) is the gate that starts IR. The difference: IR adds formal evidence handling +
documentation + roles + comms around the same analysis.

---

## §6 — SOC Perspective

The SOC is IR's detection + first-response engine; for major incidents, a dedicated IR/T3 team runs
the lifecycle with the SOC feeding it. Knowing the lifecycle + your role in it (T1 detect/escalate →
T2 investigate/contain → IR command) is core SOC literacy. Maps to `soc/escalation-matrix.md`.

---

## §7 — Incident-Response Perspective

This lesson *is* the IR framework; Lesson 29 drills the CER phase + Lesson 30 the reporting. The
operational form is `workflows/ir-workflow.md`. Internalize: preparation makes response fast,
evidence-before-containment is non-negotiable, and post-incident improvement is what makes the next
one easier.

---

## §8 — Practical Lab (build this yourself)

**Goal:** run a small confirmed incident through the full lifecycle with proper evidence handling.

### Lens C — Manual → Automated → Why
- **Manual:** collect evidence ad-hoc (risking loss/order mistakes).
- **Automated:** `evidence_collect.sh` snapshots volatile state → logs in the right order, hashing
  everything — repeatable, defensible collection.
- **Why:** under pressure, a script ensures you preserve correctly *before* containment; production
  uses IR collection tools/playbooks.

### Steps
1. Take a confirmed incident from an earlier drill (e.g. brute-force → successful login → reverse
   shell, Lessons 18/21).
2. **Preparation check:** confirm your runbooks/templates/tools are ready (they are — `docs/`).
3. **Detection & Analysis:** scope + build the timeline + extract IOCs (Lessons 12, 21).
4. **Evidence handling:** run/author `scripts/evidence_collect.sh` — snapshot volatile state, copy
   logs, hash all (SHA256SUMS), and fill `templates/evidence-package.md` with chain of custody —
   **before** any containment.
5. Fill `templates/incident-report.md` through the lifecycle (containment/eradication/recovery come in
   Lesson 29). Open `SOC-28`.

### Lens D — the raw artifact (order of volatility)
```
MOST volatile → LEAST:  CPU/registers → memory (RAM) → network state (ss) → processes (ps)
   → /tmp + temp files → logs on disk → archived/off-box logs
# Collect in THIS order — isolating/rebooting destroys the top of the list first.
```

---

## §9 — GitHub Artifact (the 6-artifact evidence package)

1. **Script:** `scripts/evidence_collect.sh` (order-of-volatility collection + hashing; committed,
   `shellcheck`-clean).
2. **Detection rule/config:** N/A (process lesson) — reference the detections that started the
   incident.
3. **Runbook:** `docs/runbooks/runbook-ir-lifecycle.md` — the phase-by-phase IR steps.
4. **Playbook:** `workflows/ir-workflow.md` referenced + an IR-roles/comms play.
5. **Incident report + notes:** `templates/incident-report.md` filled through Detection & Analysis +
   `evidence-package.md` with chain of custody + investigation notes.
6. **SOC ticket:** `SOC-28` (Incident: the worked lifecycle) → through to Investigating (closed in
   L29).

---

## §10 — Portfolio Artifact

- **Resume bullet:** "Executed the NIST SP 800-61 IR lifecycle on a simulated intrusion with proper
  evidence handling (order of volatility, hashing, chain of custody) and full documentation."
- **Interview talking point:** the lifecycle phases, *why evidence-before-containment*, and order of
  volatility — classic IR interview questions.
- **Serves:** Incident Responder / SOC T2 (Stage 3). Core of the capstone.

---

## §11 — Certification Crossover Notes

- **Security+:** IR process (4.x). **CySA+:** IR (major). **SC-200:** incident management. **BTL1:**
  IR. Detail: `alignment/CERTIFICATION-MAPPING.md`.

---

## §12 — Security Notes (Lens E — Attacker & Defender)

**🔴 Attacker:** destroy evidence (T1070 — clear logs, wipe history, delete dropped files), and act
fast so a slow/ad-hoc responder loses volatile state. They count on a disorganized response.

**🔵 Defender:** preparation + a defined lifecycle = fast, evidence-preserving response; collect in
order of volatility *before* containment; off-box logging (L06) defeats on-box log destruction;
chain of custody makes evidence hold up. A practiced IR process is what denies the attacker the
chaos they need.

---

## Quiz (Interview-Style, Graded)

**Q1.** Name the NIST 800-61 phases and what happens in each.
> **Your answer:**

**Q2.** Why must you preserve evidence *before* containment, and what is the order of volatility?
> **Your answer:**

**Q3.** What is chain of custody and why does it matter?
> **Your answer:**

**Q4.** **Scenario:** a host is confirmed compromised with an active reverse shell. What do you do in
the first 10 minutes, in what order, and why?
> **Your answer:**

**Q5.** How does post-incident activity connect IR back to detection engineering?
> **Your answer:**

*(Request the "Professional Answer" comparison under each before moving on.)*

---

## Reflection
*(After the quiz)* — What did you learn? · What confused you? · What would you do differently?

---

## Search Keywords For Further Understanding

**Core**
- `nist sp 800-61 incident response lifecycle`
- `order of volatility evidence collection`
- `chain of custody digital forensics`
- `incident response roles incident commander`
- `preserve evidence before containment`

**Tools**
- `linux evidence collection script`
- `sha256sum chain of custody`

**Going further**
- `containment eradication recovery` (L29) · `report writing` (L30) · `capstone` (L35)

**Red / Blue (Lens E):**
- 🔴 `indicator removal T1070`, `anti-forensics`, `destroy volatile evidence`
- 🔵 `order of volatility collection`, `chain of custody`, `off-box logging`, `ir preparation`

---

## Lesson Status
- [ ] §8 lab completed (incident run through Detection & Analysis; evidence collected + hashed)
- [ ] 6-artifact evidence package committed (§9)
- [ ] Quiz answered + professional-answer comparisons (graded)
- [ ] Reflection + Search Keywords reviewed

When complete, run the Update Protocol, then move to **Lesson 29 — Containment · Eradication ·
Recovery**.

---

*Lesson 28 written by Navi · 2026-06-20 · full-depth. Sources to cite at study time: NIST SP
800-61r2, SANS IR, RFC 3227 (order of volatility / evidence collection).*
