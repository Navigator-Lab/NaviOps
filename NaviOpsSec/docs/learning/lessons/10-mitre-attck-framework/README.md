# Lesson 10 — MITRE ATT&CK Framework

**Status:** ✅ ready for self-study (full depth) · **Date written:** 2026-06-20
**Schema:** 12-section SOC (`docs/learning/CLAUDE_TEACHING_RULES.md`)
**Focus:** tactics vs techniques vs sub-techniques, the matrix, mapping detections to ATT&CK,
the **Navigator** + coverage gaps — the common language of detection.
**Primary artifact:** `docs/detections/attack-coverage.md` (your coverage map).

> **How to use this lesson:** read §1–§7, do §8 (map your existing detections to ATT&CK + find
> gaps), produce §9, quiz, reflect. Then Lesson 11.

---

## §1 — Concept (Scientific Theory)

### What it is
**MITRE ATT&CK** is a curated knowledge base of real-world adversary behavior, organized as:
- **Tactics** — the attacker's *goal* at a stage (the "why"): Initial Access, Execution,
  Persistence, Privilege Escalation, Defense Evasion, Credential Access, Discovery, Lateral
  Movement, Collection, Command & Control, Exfiltration, Impact.
- **Techniques** — *how* they achieve a tactic (e.g. T1110 Brute Force for Credential Access).
- **Sub-techniques** — specific variants (T1110.001 Password Guessing).
- **Procedures** — the concrete real-world implementations seen in the wild.

It's the industry-standard vocabulary that ties detection, hunting, intel, and IR together.

### Why it exists
Before ATT&CK, everyone described attacks differently — you couldn't measure "are we covered?"
ATT&CK gives a shared, behavior-based map so a SOC can say "we detect T1110 and T1059 but have a
gap at T1053" — turning detection coverage into something measurable and communicable.

### Three-Level Depth (Lens A)
- **Level 1 — Beginner:** ATT&CK is a big chart of the things attackers do, grouped by their goal.
  Each cell is a technique with an ID like T1110.
- **Level 2 — Analyst/SOC:** you **tag** every alert/detection with its technique ID, so triage,
  reports, and dashboards speak one language. You measure **coverage** (which techniques you can
  detect) and find **gaps** to close.
- **Level 3 — Adversary/Kernel:** techniques map to concrete artifacts (T1110 → repeated auth-fail
  log lines; T1053 → cron/systemd-timer changes; T1070 → log truncation). Detection engineering
  (Lesson 26) is literally "for technique T, what artifact does it produce, and what rule catches
  it?" ATT&CK is the index of that work.

### Two Teaching Approaches (Lens B) — tactics vs techniques
**Approach 1 (technical):** tactics are columns (the adversary's objectives across the attack
lifecycle); techniques are the rows within a column (the methods). One technique can serve multiple
tactics. Coverage is measured per-technique, prioritized by tactic relevance.

**Approach 2 (analogy):** a **cookbook**. Tactics are the *courses* (appetizer, main, dessert =
goals); techniques are the *recipes* within each course; sub-techniques are recipe *variations*.
The attacker assembles a meal (a campaign) by picking one recipe per course. **Where it breaks
down:** attackers skip courses, repeat them, or improvise — the matrix is a map of options, not a
fixed sequence (that's more the kill chain, Lesson 11).

### Visual (ASCII) — the matrix shape
```
 TACTICS →  Initial   Execution  Persistence  Priv-Esc  Defense   ...  Exfil   Impact
            Access                                       Evasion
 TECH ↓     T1190     T1059      T1053        T1068     T1070          T1041   T1486
            T1078     T1204      T1098        T1548     T1562          T1048   T1485
            T1110     ...        T1547        ...       ...            ...     ...
   ▢ = you have a detection   ▣ = gap        → coverage map = which cells are green
```

---

## §2 — Linux Investigation Commands

ATT&CK is a framework, but you ground each technique in its Linux artifact:
```bash
# T1110 Brute Force  → repeated failed auth
grep -c "Failed password" /var/log/auth.log
# T1059 Execution    → shells/interpreters spawned
ausearch -m EXECVE -ts recent | grep -E 'bash|python|perl|nc'
# T1053 Persistence (cron) → schedule changes
ls -la /etc/cron.* /var/spool/cron/ ; systemctl list-timers
# T1070 Defense Evasion → log tampering
journalctl --verify ; ls -la /var/log/
# T1087 Discovery → account enumeration
grep -E "getent|/etc/passwd" /var/log/audit/audit.log 2>/dev/null
```
| Technique | Linux artifact | SIEM rule (later) |
|---|---|---|
| T1110 | auth.log failures | Wazuh frequency rule (L19) |
| T1053 | cron/timer change | FIM + audit watch (L24) |
| T1070 | log gap/truncation | log-silence + FIM (L06/24) |

---

## §3 — Real-World Threat Context & Use Cases

- **Common language:** every modern SOC tags alerts, intel, and reports with ATT&CK IDs — it's
  expected vocabulary in interviews and on the job.
- **Coverage measurement:** "what % of relevant techniques can we detect?" drives detection
  roadmaps (Lesson 26) and the Wazuh-detection project (Lesson 32).
- **Threat-informed defense:** map a threat group's known TTPs (from intel, Lesson 09) onto the
  matrix and prioritize *those* techniques.
- **Exam framing:** ATT&CK tactics/techniques and its use for detection mapping are on
  CySA+/Security+/BTL1/SC-200.

---

## §4 — Detection

- **Tag everything:** each detection you build (Lessons 18–24) carries its technique ID. The
  `attack-coverage.md` map ties rule → technique → tested? → tuned?.
- **Prioritize by threat-informed defense:** cover the techniques your threat model (L08) + intel
  (L09) say matter most, not every cell.
- **Find gaps:** the Navigator (ATT&CK's visualization) lets you color your coverage and *see* the
  holes — a gap is a planned detection.
- This lesson turns the platform's detections from a pile of rules into a *measured* coverage map.

---

## §5 — Investigation & Triage

ATT&CK accelerates investigation: identify the technique of the current alert, then ATT&CK tells
you the *adjacent* tactics (what the attacker likely did before/next) so you pivot intelligently —
e.g. T1110 (brute force) → look for T1078 (the successful login) → T1059 (execution) → T1053
(persistence). The matrix is a "what to check next" guide.

---

## §6 — SOC Perspective

ATT&CK is the SOC's reporting + metrics backbone: dashboards by tactic, coverage maps for
leadership, and a shared language across T1/T2/IR/detection-eng. "We're strong on Execution but
weak on Lateral Movement" is an ATT&CK-coverage statement that drives staffing + tooling decisions.

---

## §7 — Incident-Response Perspective

Every IR timeline is annotated with ATT&CK technique per stage (`templates/incident-report.md`) —
it's how the report communicates *what kind* of attack this was and lets lessons-learned target the
uncovered techniques. Mapping an intrusion to ATT&CK is a standard IR deliverable.

---

## §8 — Practical Lab (build this yourself)

**Goal:** map the detections you've already built (Lessons 04–09) to ATT&CK and identify your top
gaps.

### Lens C — Manual → Automated → Why
- **Manual:** list your detections and look up each technique.
- **Automated:** keep `attack-coverage.md` as a living table; a tiny script can count
  covered-vs-total per tactic.
- **Why:** coverage drifts as you add rules; an automatable map keeps the roadmap honest.
  Production teams use ATT&CK Navigator JSON for this.

### Steps
1. List every detection/artifact from Lessons 04–09 (audit rules, IOC sweep, connection baseline).
2. Build `docs/detections/attack-coverage.md`: technique ID | name | tactic | rule/artifact |
   tested? | tuned?. Mark covered vs gap.
3. Identify the **top 5 gaps** that matter for your threat model (L08) + intel (L09) — these become
   the detection priorities for Lessons 18–24 and the Wazuh project (L32).
4. (Optional) Export to ATT&CK Navigator to visualize coverage.
5. Write a one-paragraph "coverage posture" summary (what you detect, top gaps).

### Lens D — the raw artifact
Each technique is just a pointer to a concrete log/audit/network artifact you've already met. The
map's value: it forces you to ask "for T1053, do I actually have the cron/timer artifact wired to
an alert?" — turning vague confidence into a checked box.

---

## §9 — GitHub Artifact (the 6-artifact evidence package)

1. **Script:** `scripts/coverage_count.sh` — count covered vs total techniques per tactic from the
   map.
2. **Detection rule/config:** `docs/detections/attack-coverage.md` (the coverage map).
3. **Runbook:** `docs/runbooks/runbook-attack-mapping.md` — how to map an alert/incident to ATT&CK.
4. **Playbook:** the "tag every detection with a technique" play.
5. **Incident report + notes:** re-tag an earlier drill's report with ATT&CK technique per stage +
   notes on adjacent tactics to check.
6. **SOC ticket:** `SOC-10` (Task: "ATT&CK coverage map + top gaps") → Closed.

---

## §10 — Portfolio Artifact

- **Resume bullet:** "Built a MITRE ATT&CK coverage map of the SOC's detections, identified
  priority gaps, and tagged all alerts/reports with technique IDs for threat-informed defense."
- **Interview talking point:** explain tactics vs techniques and how you'd measure + improve
  coverage — a core detection-engineering conversation.
- **Serves:** Detection Engineer (Stage 4). Foundational for Lessons 26 + 32.

---

## §11 — Certification Crossover Notes

- **CySA+:** ATT&CK + attack frameworks. **Security+:** frameworks (2.x). **SC-200:** ATT&CK in
  Defender/Sentinel. **BTL1:** ATT&CK. Detail: `alignment/CERTIFICATION-MAPPING.md`.

---

## §12 — Security Notes (Lens E — Attacker & Defender)

**🔴 Attacker:** red teams use ATT&CK to *plan* coverage of their TTPs and find your blind spots;
adversaries favor techniques defenders rarely detect (living-off-the-land, T1218/T1059).

**🔵 Defender:** use the *same* matrix to measure + close coverage, prioritized by threat-informed
defense. Purple-teaming = exercising your detections against ATT&CK techniques to validate the map
is real, not aspirational.

---

## Quiz (Interview-Style, Graded)

**Q1.** Define tactic, technique, and sub-technique in ATT&CK, with an example chain.
> **Your answer:**

**Q2.** Why is ATT&CK valuable to a SOC beyond being a list — what does it let you *measure*?
> **Your answer:**

**Q3.** Given an alert for T1110 (brute force), which adjacent techniques would you check for next,
and why?
> **Your answer:**

**Q4.** **Scenario:** leadership asks "are we covered against ransomware actors targeting our
sector?" How do you use ATT&CK + threat intel to answer concretely?
> **Your answer:**

**Q5.** What is "threat-informed defense" and how does it change which techniques you prioritize?
> **Your answer:**

*(Request the "Professional Answer" comparison under each before moving on.)*

---

## Reflection
*(After the quiz)* — What did you learn? · What confused you? · What would you do differently?

---

## Search Keywords For Further Understanding

**Core**
- `mitre att&ck tactics techniques explained`
- `att&ck navigator coverage map`
- `threat informed defense`
- `mapping detections to mitre att&ck`
- `att&ck linux matrix`

**Tools**
- `att&ck navigator json layer`
- `wazuh mitre att&ck mapping`

**Going further**
- `cyber kill chain` (L11) · `detection engineering` (L26) · `sigma rules` (L27) · `wazuh detection project` (L32)

**Red / Blue (Lens E):**
- 🔴 `living off the land T1218 T1059`, `att&ck red team planning`
- 🔵 `att&ck coverage gaps`, `purple team validation`, `threat informed defense`

---

## Lesson Status
- [ ] §8 lab completed (coverage map + top gaps identified)
- [ ] 6-artifact evidence package committed (§9)
- [ ] Quiz answered + professional-answer comparisons (graded)
- [ ] Reflection + Search Keywords reviewed

When complete, run the Update Protocol, then move to **Lesson 11 — Cyber Kill Chain**.

---

*Lesson 10 written by Navi · 2026-06-20 · full-depth. Sources to cite at study time:
attack.mitre.org, ATT&CK Navigator docs, MITRE "Getting Started with ATT&CK".*
