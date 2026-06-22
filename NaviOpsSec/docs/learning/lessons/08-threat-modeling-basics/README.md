# Lesson 08 — Threat Modeling Basics

**Status:** ✅ ready for self-study (full depth) · **Date written:** 2026-06-20
**Schema:** 12-section SOC (`docs/learning/CLAUDE_TEACHING_RULES.md`)
**Focus:** thinking like an attacker about *your own* assets — assets → threats → controls,
**STRIDE**, attack surface, trust boundaries, and data-flow diagrams — to decide what to detect.
**Primary artifact:** `docs/learning/threat-model-sample.md` (a STRIDE model of the lab).

> **How to use this lesson:** read §1–§7, do §8 (model your lab + derive detections), produce §9,
> quiz, reflect. Then Lesson 09.

---

## §1 — Concept (Scientific Theory)

### What it is
**Threat modeling** is the structured exercise of asking, for a given system: *what are we
protecting, who would attack it and how, and what could go wrong?* — then deriving the controls and
**detections** that matter. For a defender it answers the prioritization question: with limited
time, *which* detections should I build first? (It feeds Lesson 26's coverage decisions.)

**STRIDE** is the common threat taxonomy:
- **S**poofing (pretending to be someone) · **T**ampering (altering data) · **R**epudiation
  (denying an action, no proof) · **I**nformation disclosure (leaking data) · **D**enial of service
  · **E**levation of privilege.

### Why it exists
You can't detect everything; you can't even *think* of everything ad-hoc. A model forces
systematic coverage — walking each data flow and asking "what's the spoofing risk here? the
tampering risk?" — so you don't miss a whole class of attack. It's prevention *and* detection
planning.

### Three-Level Depth (Lens A)
- **Level 1 — Beginner:** list what's valuable, imagine how a bad guy would attack it, decide how
  to stop *and* notice it.
- **Level 2 — Analyst/SOC:** draw the system's **data flow**, mark **trust boundaries** (where data
  crosses from less-trusted to more-trusted — the internet→web app, web app→DB), and apply STRIDE
  at each boundary to enumerate threats → then map each threat to a **detection** you can build.
- **Level 3 — Adversary/Kernel:** map STRIDE threats to **MITRE ATT&CK** techniques (spoofing→
  T1078 valid accounts; tampering→T1565; EoP→T1068/T1548) so the model directly drives detection
  coverage measured against ATT&CK (Lesson 10).

### Two Teaching Approaches (Lens B) — trust boundaries
**Approach 1 (technical):** a trust boundary is any point where data or control passes between
components with different privilege/trust levels; it's where validation and monitoring must
concentrate, because crossing it is where most attacks happen (input from the internet, privilege
transitions).

**Approach 2 (analogy):** a building's **security checkpoints** — the lobby door (public→tenant),
the server-room badge reader (tenant→admin). You put the guard + camera *at the checkpoints*, not
in the middle of a room. **Where it breaks down:** software has many subtle boundaries (a function
trusting user input) that aren't as visible as a physical door — the diagram makes them visible.

### Visual (ASCII) — data-flow + trust boundaries + STRIDE
```
   INTERNET  ══boundary══►  [ web01 app ]  ══boundary══►  [ db01 ]
   (untrusted)                 │  ▲                          │
     S: fake user (T1078)      │  │ I: leak data (T1005)     │ T: tamper records (T1565)
     D: flood (T1499)          ▼  │                          ▼
                          E: priv-esc (T1068)          R: no audit = repudiation
   → each STRIDE item at each boundary → a detection to build (auth, FIM, egress, audit)
```

---

## §2 — Linux Investigation Commands

Threat modeling is a paper exercise, but you *ground* it on the real system:
```bash
ss -tulnp                       # actual attack surface (what's exposed)
systemctl list-units --type=service --state=running   # running services = components
getent passwd | awk -F: '$3>=1000'   # accounts (spoofing targets)
sudo -l ; getent group sudo     # privilege paths (EoP targets)
find / -perm -4000 -type f 2>/dev/null   # SUID binaries (EoP surface)
```
| Linux | Model element |
|---|---|
| listening ports | entry points / attack surface |
| services + accounts | components + spoofing targets |
| SUID / sudo | elevation-of-privilege paths |

---

## §3 — Real-World Threat Context & Use Cases

- **Detection prioritization:** the model tells the SOC which detections to build first (the
  highest-risk boundaries) — the input to Lesson 26's coverage plan.
- **New-system onboarding:** before a system goes live, model it to decide what logging/detection
  it needs.
- **Incident scoping:** a model tells you *what else* an attacker who reached component X could
  reach (trust boundaries = blast radius).
- **Exam framing:** STRIDE, attack surface, and trust boundaries appear on Security+/CySA+.

---

## §4 — Detection

The whole output of a threat model is a **detection backlog**: each STRIDE threat at each boundary
→ "what log/signal would reveal this, and do we have a rule?" Examples:
- Spoofing (T1078) → failed-then-success auth detection (Lesson 18–19).
- Tampering (T1565) → FIM (Lesson 24).
- Info disclosure (T1005/T1041) → egress/exfil detection (Lesson 07).
- EoP (T1068/T1548) → sudo/SUID abuse detection (Lesson 21–22).
This is how modeling becomes coverage (Lesson 10 maps it to ATT&CK; Lesson 26 builds it).

---

## §5 — Investigation & Triage

A threat model accelerates triage: when an alert fires on component X, the model tells you the
likely *next* moves (which boundary the attacker would cross next) so you scope proactively. It
turns "an alert fired" into "an alert fired *here*, so check *there* next."

---

## §6 — SOC Perspective

SOCs use (lightweight) threat models to decide detection coverage and to brief analysts on
crown-jewel assets ("if you see anything near db01, escalate"). It connects business risk
(Lesson 02) to detection engineering (Lesson 26) — the strategic layer above the alert queue.

---

## §7 — Incident-Response Perspective

In lessons-learned (IR Phase 6), you update the threat model with what the incident revealed (a
boundary you under-protected) and add the missing detection. The model is a living document that
each incident sharpens.

---

## §8 — Practical Lab (build this yourself)

**Goal:** threat-model your lab web server and turn the model into a detection backlog.

### Lens C — Manual → Automated → Why
- **Manual:** draw the DFD + apply STRIDE by hand.
- **Automated:** a small script that *inventories* the real attack surface (ports, services,
  SUID, accounts) so the model is grounded in reality, not guesses.
- **Why:** attack surface drifts; an inventory script keeps the model honest. Production tools
  (CSPM/attack-surface mgmt) automate this continuously.

### Steps
1. Draw the data-flow diagram for your lab (internet → web01 → db01), mark the trust boundaries.
2. Inventory the real surface: run the §2 commands; list actual ports/services/SUID/accounts.
3. Apply STRIDE at each boundary; for each threat, write the **ATT&CK technique** and the
   **detection** that would catch it.
4. Write it up in `docs/learning/threat-model-sample.md` (DFD + STRIDE table + detection backlog).
5. Pick the top 3 detections from the backlog — those become priorities for Lessons 18–24.

### Lens D — the raw artifact
The "boundary" is concrete in the logs: every internet→web01 request is a line in the access log;
every web01→db01 query crosses the app→DB boundary. The model points you at *which* logs to detect
on.

---

## §9 — GitHub Artifact (the 6-artifact evidence package)

1. **Script:** `scripts/attack_surface.sh` — inventory ports/services/SUID/accounts.
2. **Detection rule/config:** the detection backlog (model → rules to build) in the threat model.
3. **Runbook:** `docs/runbooks/runbook-threat-model.md` — how to model a new asset.
4. **Playbook:** the STRIDE-per-boundary play.
5. **Incident report + notes:** N/A drill — instead the threat model itself as the deliverable +
   notes on the top-3 priorities.
6. **SOC ticket:** `SOC-08` (Task: "threat-model the lab + detection backlog") → Closed.

---

## §10 — Portfolio Artifact

- **Resume bullet:** "Threat-modeled a multi-tier app with STRIDE and trust boundaries, mapping
  each threat to a MITRE ATT&CK technique and a concrete detection backlog."
- **Interview talking point:** explain STRIDE + trust boundaries and how a model *drives detection
  priorities* — a maturity signal beyond pure alert-chasing.
- **Serves:** SOC T2 → Detection Engineer (Stages 3–4).

---

## §11 — Certification Crossover Notes

- **Security+:** threats/attacks + architecture (2.x). **CySA+:** threat management. **BTL1:**
  fundamentals. **SC-200:** N/A directly. Detail: `alignment/CERTIFICATION-MAPPING.md`.

---

## §12 — Security Notes (Lens E — Attacker & Defender)

**🔴 Attacker:** an attacker builds the *same* model from the outside (recon → attack surface →
weakest boundary). Threat modeling is literally adopting the attacker's planning process.

**🔵 Defender:** by modeling first, you pre-position detection at the boundaries the attacker will
target, shrinking dwell time. The model → ATT&CK mapping is what makes coverage measurable
(Lesson 10/26).

---

## Quiz (Interview-Style, Graded)

**Q1.** What does STRIDE stand for, and give a concrete example of each against a web server.
> **Your answer:**

**Q2.** What is a trust boundary, and why do you concentrate controls/detection there?
> **Your answer:**

**Q3.** How does a threat model help a SOC *prioritize* which detections to build?
> **Your answer:**

**Q4.** **Scenario:** model a simple internet-facing web app + database in 3 minutes — name the
boundaries and the top two threats with their detections.
> **Your answer:**

**Q5.** Why map STRIDE threats to MITRE ATT&CK techniques?
> **Your answer:**

*(Request the "Professional Answer" comparison under each before moving on.)*

---

## Reflection
*(After the quiz)* — What did you learn? · What confused you? · What would you do differently?

---

## Search Keywords For Further Understanding

**Core**
- `stride threat modeling explained`
- `data flow diagram trust boundary`
- `attack surface analysis`
- `threat modeling to detection mapping`
- `crown jewels asset prioritization`

**Tools**
- `find suid binaries linux`
- `microsoft threat modeling stride`

**Going further**
- `mitre att&ck` (L10) · `detection engineering` (L26) · `risk register` (L02)

**Red / Blue (Lens E):**
- 🔴 `attacker recon attack surface`, `weakest trust boundary`
- 🔵 `detection coverage by boundary`, `stride to att&ck mapping`

---

## Lesson Status
- [ ] §8 lab completed (threat model + detection backlog written)
- [ ] 6-artifact evidence package committed (§9)
- [ ] Quiz answered + professional-answer comparisons (graded)
- [ ] Reflection + Search Keywords reviewed

When complete, run the Update Protocol, then move to **Lesson 09 — Threat Intelligence Fundamentals**.

---

*Lesson 08 written by Navi · 2026-06-20 · full-depth. Sources to cite at study time: Microsoft
STRIDE, OWASP Threat Modeling, MITRE ATT&CK, CompTIA Security+ domain 2.*
