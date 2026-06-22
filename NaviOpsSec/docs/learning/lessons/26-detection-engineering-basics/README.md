# Lesson 26 — Detection Engineering Basics

**Status:** ✅ ready for self-study (full depth) · **Date written:** 2026-06-20
**Schema:** 12-section SOC (`docs/learning/CLAUDE_TEACHING_RULES.md`)
**Focus:** the detection lifecycle, signal vs noise, **detection-as-code**, testing + tuning, and
coverage metrics — engineering detections systematically instead of ad-hoc.
**Primary artifact:** `docs/detections/README.md` (the rule repo) + the lifecycle.

> **How to use this lesson:** read §1–§7, do §8 (take a detection through the full lifecycle),
> produce §9, quiz, reflect. Then Lesson 27.

---

## §1 — Concept (Scientific Theory)

### What it is
**Detection engineering** is building detections as a disciplined engineering practice: a
**lifecycle** (idea → develop → test → deploy → tune → maintain → retire), version-controlled
content (**detection-as-code**), measured by **coverage** (ATT&CK) and **quality** (true-positive vs
false-positive rate). It's the difference between "someone wrote a rule once" and "we systematically
build, test, and tune detections."

### Why it exists
Detections rot: log formats change, environments drift, attackers adapt, and untested rules silently
break. Without engineering discipline, a SOC's detection set degrades into noise + blind spots.
Treating detections like code (tested, reviewed, version-controlled, measured) keeps coverage real
and false positives low — the two things that decide whether a SOC functions.

### The detection lifecycle
```
 idea (hunt/incident/intel/ATT&CK gap) → develop (rule) → TEST (fires on TP, quiet on benign)
   → deploy → TUNE (reduce FP, keep recall) → maintain (re-test on drift) → retire (obsolete)
```

### Three-Level Depth (Lens A)
- **Level 1 — Beginner:** don't just write a rule and forget it — write it, test it works, deploy it,
  and keep fixing its false alarms.
- **Level 2 — Analyst/SOC:** every detection has an idea source (a hunt, an incident's lessons-
  learned, intel, an ATT&CK gap), a tested implementation (`wazuh-logtest` / a positive event), a
  documented expected-FP analysis, an ATT&CK tag, and a home in version control (`docs/detections/`).
  You measure coverage + FP rate and iterate.
- **Level 3 — Adversary/Kernel:** the engineering problem is the **signal/noise trade-off** — maximize
  recall (catch the attack, low false-negative) while minimizing false positives. You move both the
  right way via **context/enrichment** (who/what/baseline) rather than just threshold tweaking. Robust
  detections key on durable artifacts (TTP, Pyramid) and are tested against evasion, not just the
  happy path.

### Two Teaching Approaches (Lens B) — detection-as-code
**Approach 1 (technical):** detections are software artifacts — authored, peer-reviewed, unit-tested
(sample-log → expected-alert), versioned, deployed via pipeline, and monitored for efficacy (FP rate,
firing count). CI for rules = `wazuh-logtest`/`sigma test` regression on sample logs.

**Approach 2 (analogy):** **manufacturing quality control.** You don't ship a part you didn't test;
you measure defect rates (FPs), and you have a process to design, test, and improve parts (rules), not
artisanal one-offs. **Where it breaks down:** adversaries actively try to defeat your "parts," so QC
must include adversarial testing (purple teaming), unlike normal manufacturing.

### Visual (ASCII) — the signal/noise trade-off
```
  threshold LOW  ─► catches attack (high recall) BUT many false positives (noise) → fatigue
  threshold HIGH ─► few false positives BUT misses attacks (false negatives)      → blind
  the engineer's move: add CONTEXT (user/asset/baseline/intel) → catch more, alert less
        e.g. "10 failed logins" (noisy)  →  "10 failed THEN success, off-hours, critical asset" (sharp)
```

---

## §2 — Linux Investigation Commands

```bash
# test a detection before/while deploying (the CI of rules)
/var/ossec/bin/wazuh-logtest < sample_failed_login.log     # does it fire as expected?
# measure efficacy from alert data
jq '.rule.id' /var/ossec/logs/alerts/alerts.json | sort | uniq -c | sort -rn   # firing counts (noisy rules?)
# version-control the detections
git -C docs/detections log --oneline      # detection-as-code history (human-approved commits)
# regression-test a rule set against sample logs
bash scripts/rule_test.sh samples/        # pipe known TP + benign samples, assert outcomes
```
| Engineering step | Tool |
|---|---|
| test | `wazuh-logtest`, `sigma test`, `rule_test.sh` |
| measure | `jq` firing counts, FP-rate tracking |
| version | git (`docs/detections/`) |
| coverage | `attack-coverage.md` (Lesson 10) |

---

## §3 — Real-World Threat Context & Use Cases

- **From hunt/incident to standing detection:** the operationalization step of Lessons 25/28 lives
  here — the disciplined way to add the rule.
- **Tuning the noisy alert:** the most common detection-eng task — reduce a rule's FPs without going
  blind (add context, not just raise the threshold).
- **Coverage roadmap:** prioritize new detections by ATT&CK gaps + threat model + intel.
- **Detection-as-code:** rules in git, peer-reviewed, tested — modern SOC practice.
- **Exam framing:** detection lifecycle, tuning, and coverage on CySA+/SC-200/BTL1.

---

## §4 — Detection

This lesson *is* the meta-detection lesson — how to build the detections in Lessons 18–24 *well*:
1. **Source the idea** (hunt/incident/intel/gap). 2. **Develop** keyed on a durable artifact.
3. **Test** (fires on TP, quiet on benign — `rule_test.sh`/`wazuh-logtest`). 4. **Deploy + tag ATT&CK**.
5. **Tune** via context. 6. **Maintain** (re-test on drift). 7. **Retire** obsolete rules.
A detection isn't "done" at deploy — it's done when tested + tuned + measured.

---

## §5 — Investigation & Triage

Triage feedback is detection engineering's input: every FP closed in triage (Lesson 17) is a tuning
ticket here; every false negative found by hunting (Lesson 25) is a new-detection ticket. The
engineer closes the loop so the SOC's detection quality compounds instead of decays.

---

## §6 — SOC Perspective

Detection engineering is the function that keeps the SOC effective over time — it owns the rule repo,
the coverage map, and the FP-rate metric. It's the Stage-4 role this platform builds toward. The
practice (test + version + measure) is what separates a mature SOC from one drowning in stale, noisy
rules. Drives the Lesson-32 project.

---

## §7 — Incident-Response Perspective

The IR Phase-6 deliverable ("a new/tuned detection") is a detection-engineering task — done properly
(tested, tagged, committed), not a quick hack. The capstone's "lessons-learned detection" is graded
on whether it follows this lifecycle.

---

## §8 — Practical Lab (build this yourself)

**Goal:** take one detection through the full lifecycle, with tests + tuning + coverage.

### Lens C — Manual → Automated → Why
- **Manual:** write a rule and hope.
- **Automated:** `rule_test.sh` runs known TP + benign samples through the rule and asserts the
  expected outcome — regression testing for detections.
- **Why:** tested, version-controlled detections don't silently break; production runs this in CI
  before deploying rules.

### Steps
1. Set up `docs/detections/` as the rule repo (README + structure): one file per detection with
   idea-source, ATT&CK tag, rule, expected FPs, test status.
2. Take an existing rule (e.g. the brute-force rule, Lesson 15/19) through the lifecycle: document its
   idea source, write a `rule_test.sh` with a TP sample + a benign sample, run it, and record results.
3. **Tune with context:** improve a noisy rule by adding context (off-hours / critical-asset /
   failed-then-success) rather than just raising the threshold; show the FP drop.
4. Update `attack-coverage.md` (tested? tuned?) for the rule.
5. Commit the detection (detection-as-code) with a clear message (human-approved).

### Lens D — the raw artifact
The engineering artifact is the **test case**: a sample log line + the expected rule outcome, stored
beside the rule. That pairing is what makes a detection *maintainable* — when a log format drifts, the
test fails and tells you, instead of the rule silently going blind.

---

## §9 — GitHub Artifact (the 6-artifact evidence package)

1. **Script:** `scripts/rule_test.sh` (regression-test detections; committed, `shellcheck`-clean).
2. **Detection rule/config:** `docs/detections/` repo structure + one fully-lifecycled rule.
3. **Runbook:** `docs/runbooks/runbook-detection-lifecycle.md` — how to take a detection idea to
   production.
4. **Playbook:** the detection-engineering lifecycle play.
5. **Incident report + notes:** the tuned-rule case (FP rate before/after via context) + notes.
6. **SOC ticket:** `SOC-26` (Task: "detection lifecycle + tune a rule") → Closed.

---

## §10 — Portfolio Artifact

- **Resume bullet:** "Practiced detection-as-code: a version-controlled detection repo with tested,
  ATT&CK-tagged rules, FP-tuning via context, and coverage metrics — the detection-engineering
  lifecycle."
- **Interview talking point:** the signal/noise trade-off and how you tune via *context* not just
  thresholds; detection-as-code + testing. A senior detection-eng answer.
- **Serves:** Junior Detection Engineer (Stage 4). Core of the Lesson-32 project.

---

## §11 — Certification Crossover Notes

- **CySA+:** detection + tuning. **SC-200:** analytics-rule management. **BTL1:** detections.
  **Security+:** N/A directly. Detail: `alignment/CERTIFICATION-MAPPING.md`.

---

## §12 — Security Notes (Lens E — Attacker & Defender)

**🔴 Attacker:** exploit untested/stale rules (silently broken), evade threshold-only detections
(stay under), and use techniques in your coverage gaps. They bet your detections decayed.

**🔵 Defender:** engineer detections as tested, versioned, ATT&CK-mapped code; tune via context for
both high recall and low FP; re-test on drift; purple-team to validate against evasion; measure
coverage + FP rate. Disciplined detection engineering is what keeps you ahead of an adapting
adversary.

---

## Quiz (Interview-Style, Graded)

**Q1.** Walk the detection lifecycle from idea to retirement.
> **Your answer:**

**Q2.** Explain the signal/noise trade-off. Why is tuning via *context* better than just raising a
threshold?
> **Your answer:**

**Q3.** What does "detection-as-code" mean and what does testing a detection look like?
> **Your answer:**

**Q4.** **Scenario:** a rule fires 200 times/day, almost all false positives, but you can't just
disable it (it catches a real attack too). How do you fix it?
> **Your answer:**

**Q5.** What metrics tell you whether your detection program is healthy?
> **Your answer:**

*(Request the "Professional Answer" comparison under each before moving on.)*

---

## Reflection
*(After the quiz)* — What did you learn? · What confused you? · What would you do differently?

---

## Search Keywords For Further Understanding

**Core**
- `detection engineering lifecycle`
- `detection as code testing`
- `signal to noise detection tuning context`
- `detection coverage metrics att&ck`
- `false positive rate detection quality`

**Tools**
- `wazuh-logtest regression testing rules`
- `sigma test detection`

**Going further**
- `sigma rules` (L27) · `wazuh detection project` (L32) · `threat hunting` (L25)

**Red / Blue (Lens E):**
- 🔴 `evade threshold detection`, `exploit stale rules`, `coverage gap`
- 🔵 `detection-as-code`, `context-based tuning`, `purple team validation`, `coverage + fp metrics`

---

## Lesson Status
- [ ] §8 lab completed (one detection through the lifecycle; tuned with context; tested)
- [ ] 6-artifact evidence package committed (§9)
- [ ] Quiz answered + professional-answer comparisons (graded)
- [ ] Reflection + Search Keywords reviewed

When complete, run the Update Protocol, then move to **Lesson 27 — Sigma Rules Fundamentals**.

---

*Lesson 26 written by Navi · 2026-06-20 · full-depth. Sources to cite at study time: "Detection
Engineering" (Palantir/Elastic blogs), MITRE ATT&CK, Sigma, Wazuh testing docs.*
