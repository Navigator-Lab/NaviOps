# Lesson 27 — Sigma Rules Fundamentals

**Status:** ✅ ready for self-study (full depth) · **Date written:** 2026-06-20
**Schema:** 12-section SOC (`docs/learning/CLAUDE_TEACHING_RULES.md`)
**Focus:** the Sigma schema (logsource/detection/condition), converting Sigma → Wazuh/Elastic with
`sigma`/`sigmac`, and why portable, shareable detection content matters.
**Primary artifact:** `docs/detections/sigma/` (your first Sigma rules + conversions).

> **How to use this lesson:** read §1–§7, do §8 (write a Sigma rule + convert it to Wazuh), produce
> §9, quiz, reflect. Then Lesson 28.

---

## §1 — Concept (Scientific Theory)

### What it is
**Sigma** is the vendor-neutral, YAML-based standard for writing detection rules — "the Snort/YARA of
logs." A Sigma rule describes a detection in a portable way (logsource + detection fields + a
condition), and a **converter** (`sigma convert` / `sigmac`) translates it into a specific backend's
query (Wazuh, Elastic/KQL, Splunk SPL, etc.). Write once, deploy anywhere.

### Why it exists
Detections written directly in one SIEM's syntax are trapped there — you can't share them, migrate
them, or use community detection libraries (SigmaHQ has thousands). Sigma decouples *what to detect*
from *which SIEM* — making detection content portable, shareable, and version-controllable
(detection-as-code, Lesson 26). It future-proofs your skill beyond Wazuh.

### Three-Level Depth (Lens A)
- **Level 1 — Beginner:** Sigma is a standard way to write "if logs show X, alert" that any SIEM can
  understand after a quick conversion.
- **Level 2 — Analyst/SOC:** you write a rule with `logsource` (what kind of log), `detection`
  (field/value selections), and a `condition` (how selections combine), then `sigma convert` it to
  your backend. You consume community rules (SigmaHQ) and contribute your own.
- **Level 3 — Adversary/Kernel:** the rule is a logical predicate over normalized fields; the
  converter maps Sigma's taxonomy to the backend's field names + query language (the field-mapping is
  the tricky part). Portability requires the backend's logs to be normalized to the expected fields —
  tying back to why normalization (Lesson 13) is foundational.

### Two Teaching Approaches (Lens B) — Sigma portability
**Approach 1 (technical):** Sigma is an abstraction layer: a backend-agnostic rule IR + per-backend
converters, analogous to a compiler emitting different machine code from one source. The condition
language (selections + and/or/not/aggregation) is the IR's logic.

**Approach 2 (analogy):** writing a recipe in a **universal format** that any kitchen can follow after
converting measurements to local units. The recipe (Sigma) is the same; the conversion adapts it to
the local stove (SIEM). **Where it breaks down:** if a kitchen lacks an ingredient (a field the SIEM
doesn't parse), the converted recipe fails — field mapping/normalization must line up.

### Visual (ASCII) — Sigma → backends
```
                        ┌──► sigma convert → Wazuh rule (local_rules.xml)
  sigma_rule.yml ───────┼──► sigma convert → Elastic/KQL query
  (portable IR)         ├──► sigma convert → Splunk SPL
                        └──► sigma convert → ...
  one rule, many SIEMs.  community library (SigmaHQ) ──► import → convert → deploy
```

---

## §2 — Linux Investigation Commands

```bash
# install + convert (pySigma / sigma-cli)
pip install sigma-cli                                   # the modern converter
sigma convert -t wazuh docs/detections/sigma/ssh_bruteforce.yml    # → Wazuh rule
sigma convert -t elasticsearch docs/detections/sigma/ssh_bruteforce.yml   # → ES query
# validate a rule's structure
sigma check docs/detections/sigma/ssh_bruteforce.yml
# (legacy) sigmac -t wazuh -c <fieldmap> rule.yml
```
A minimal Sigma rule (SSH brute force):
```yaml
title: SSH Brute Force (multiple failed logins)
id: 0001-ssh-bruteforce
logsource: { product: linux, service: sshd }
detection:
  sel: { message|contains: 'Failed password' }
  timeframe: 60s
  condition: sel | count(srcip) >= 8
level: high
tags: [attack.credential_access, attack.t1110]
```
| Sigma element | Maps to |
|---|---|
| `logsource` | which log/decoder (Wazuh group) |
| `detection`/`condition` | the rule match + frequency |
| `tags` | ATT&CK technique (Lesson 10) |

---

## §3 — Real-World Threat Context & Use Cases

- **Portable detections:** write once, deploy to whatever SIEM the job uses — your skill transfers
  beyond Wazuh.
- **Community library:** import + adapt SigmaHQ rules (thousands, ATT&CK-tagged) instead of writing
  from scratch.
- **Sharing + collaboration:** contribute detections back; teams exchange Sigma, not vendor syntax.
- **Detection-as-code:** Sigma YAML in git, reviewed + tested (Lesson 26).
- **Exam framing:** Sigma + portable detection on CySA+/BTL1; rule logic on SC-200.

---

## §4 — Detection

Sigma is *how you author* the detections from Lessons 18–24 portably:
1. Write the detection logic once in Sigma (logsource + detection + condition + ATT&CK tags).
2. `sigma convert -t wazuh` to deploy it to your stack.
3. Test the converted rule (`wazuh-logtest`, Lesson 15) — conversion can need field-map tweaks.
4. Version it in `docs/detections/sigma/` (detection-as-code).
The same Sigma rule could deploy to a future Elastic/Splunk SOC unchanged — that's the payoff.

---

## §5 — Investigation & Triage

When you triage an alert that came from a Sigma-derived rule, the Sigma source (with its ATT&CK tags
+ description + references) is excellent context for *why* it fired and *what it means*. Well-authored
Sigma rules carry their own documentation — speeding triage.

---

## §6 — SOC Perspective

Sigma is the SOC's lingua franca for detection content — it's how teams share, version, and migrate
detections. A detection engineer who writes Sigma + converts to the local SIEM is immediately
productive in *any* SOC. The Sigma library in `docs/detections/sigma/` is portable portfolio
evidence.

---

## §7 — Incident-Response Perspective

The IR Phase-6 "new detection" is best authored as Sigma — portable, documented, ATT&CK-tagged, and
deployable to the current (and any future) SIEM. The capstone's lessons-learned detection can be a
Sigma rule + its Wazuh conversion.

---

## §8 — Practical Lab (build this yourself)

**Goal:** write a Sigma rule, convert it to Wazuh, and confirm it fires.

### Lens C — Manual → Automated → Why
- **Manual:** hand-write a Wazuh rule (Lesson 15) — locked to Wazuh.
- **Automated:** write Sigma once + `sigma convert` to Wazuh (and Elastic) — portable, reusable.
- **Why:** portability + community reuse + version control. Production CI converts + tests Sigma on
  commit.

### Steps
1. Install `sigma-cli`. Write a Sigma rule in `docs/detections/sigma/` for a detection you already
   built (SSH brute force, T1110, or rogue-account creation T1136).
2. `sigma check` it (valid structure), then `sigma convert -t wazuh` → a Wazuh rule.
3. Deploy the converted rule (lab), generate the telemetry (the matching drill), and confirm it fires
   (`wazuh-logtest` / dashboard). Fix field-mapping if needed.
4. Also `sigma convert -t elasticsearch` to *see* the same rule become a different backend's query
   (the portability payoff).
5. Commit the Sigma rule + the conversion + a note in `docs/detections/`.

### Lens D — the raw artifact
The portability is concrete: the same `condition: sel | count(srcip) >= 8` becomes a Wazuh
`<frequency>8</frequency><same_source_ip/>` rule *and* an Elastic aggregation query — one logic,
two syntaxes. Sigma is the source; the backend rule is the compiled output.

---

## §9 — GitHub Artifact (the 6-artifact evidence package)

1. **Script:** `scripts/sigma_build.sh` — convert + check all Sigma rules in `docs/detections/sigma/`
   to Wazuh (a tiny build step).
2. **Detection rule/config:** `docs/detections/sigma/` (≥1 Sigma rule + its Wazuh conversion).
3. **Runbook:** `docs/runbooks/runbook-sigma.md` — author → check → convert → test → deploy.
4. **Playbook:** the portable-detection authoring play.
5. **Incident report + notes:** the rule built in Sigma, converted, and confirmed firing + notes.
6. **SOC ticket:** `SOC-27` (Task: "Sigma rule + conversion") → Closed.

---

## §10 — Portfolio Artifact

- **Resume bullet:** "Authored portable Sigma detection rules (ATT&CK-tagged) and converted them to
  Wazuh + Elastic, demonstrating vendor-neutral detection-as-code."
- **Interview talking point:** why Sigma matters (portability, community, sharing) and the
  logsource/detection/condition structure — shows detection-engineering maturity + transferable
  skill.
- **Serves:** Junior Detection Engineer (Stage 4). Used in Lessons 32–33 + the capstone.

---

## §11 — Certification Crossover Notes

- **CySA+:** detection content. **BTL1:** Sigma. **SC-200:** rule logic (analog). **Security+:** N/A.
  Detail: `alignment/CERTIFICATION-MAPPING.md`.

---

## §12 — Security Notes (Lens E — Attacker & Defender)

**🔴 Attacker:** study public Sigma rules (SigmaHQ is open) to learn what defenders detect and craft
evasions; rely on your detections being non-portable/stale.

**🔵 Defender:** leverage the community library for breadth, author + share your own, version + test
(Lesson 26), and keep ATT&CK tags current. Portable, tested, tagged Sigma is resilient, transferable
detection content — and converting it forces you to keep normalization honest.

---

## Quiz (Interview-Style, Graded)

**Q1.** What problem does Sigma solve, and what are its three core sections?
> **Your answer:**

**Q2.** What does `sigma convert` do, and what can go wrong in the conversion (field mapping)?
> **Your answer:**

**Q3.** Why is portable detection content valuable to a SOC and to your career?
> **Your answer:**

**Q4.** **Scenario:** you wrote a great Wazuh-only brute-force rule, and the company is migrating to
Elastic. How would Sigma have saved you here?
> **Your answer:**

**Q5.** How do Sigma's ATT&CK tags connect to your coverage map (Lesson 10)?
> **Your answer:**

*(Request the "Professional Answer" comparison under each before moving on.)*

---

## Reflection
*(After the quiz)* — What did you learn? · What confused you? · What would you do differently?

---

## Search Keywords For Further Understanding

**Core**
- `sigma rules yaml logsource detection condition`
- `sigma convert sigmac backend`
- `sigmahq community rules`
- `portable detection as code`
- `sigma att&ck tags`

**Tools**
- `sigma-cli pysigma`
- `sigma convert wazuh elasticsearch`

**Going further**
- `incident response` (L28) · `wazuh detection project` (L32) · `threat hunting project` (L33)

**Red / Blue (Lens E):**
- 🔴 `study public detections for evasion`, `non-portable stale rules`
- 🔵 `sigma community library`, `portable detection-as-code`, `att&ck-tagged rules`

---

## Lesson Status
- [ ] §8 lab completed (Sigma rule written + converted + confirmed firing)
- [ ] 6-artifact evidence package committed (§9)
- [ ] Quiz answered + professional-answer comparisons (graded)
- [ ] Reflection + Search Keywords reviewed

When complete, run the Update Protocol, then move to **Lesson 28 — Incident Response Fundamentals**.

---

*Lesson 27 written by Navi · 2026-06-20 · full-depth. Sources to cite at study time: SigmaHQ
specification, sigma-cli/pySigma docs, MITRE ATT&CK.*
