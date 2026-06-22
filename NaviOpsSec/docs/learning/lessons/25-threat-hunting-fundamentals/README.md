# Lesson 25 — Threat Hunting Fundamentals

**Status:** ✅ ready for self-study (full depth) · **Date written:** 2026-06-20
**Schema:** 12-section SOC (`docs/learning/CLAUDE_TEACHING_RULES.md`)
**Focus:** hypothesis-driven hunting, the hunt loop, ATT&CK-driven hunts, finding what alerts
*missed* (false negatives), and turning a hunt into a detection.
**Primary artifact:** `docs/playbooks/hunt-template.md`.

> **How to use this lesson:** read §1–§7, do §8 (run a hypothesis-driven hunt in your lab), produce
> §9, quiz, reflect. Then Lesson 26.

---

## §1 — Concept (Scientific Theory)

### What it is
**Threat hunting** is *proactively* searching for threats that **evaded** your detections — driven by
a **hypothesis**, not an alert. Where triage is reactive ("an alert fired, is it real?"), hunting is
active ("if an attacker did X, what evidence would exist? — let me go look"). It targets **false
negatives**: the attacks your rules don't catch.

### Why it exists
No detection set is complete; attackers use techniques you don't alert on (coverage gaps, novel
TTPs). Hunting finds those *before* they become an incident — and every successful hunt becomes a new
detection, shrinking the gap. It's how a SOC goes from reactive to proactive (and the path to
detection engineering, Lesson 26).

### The hunt loop
```
 hypothesis → gather data → analyze (search/baseline/stack) → findings (TP / nothing+coverage)
        → operationalize (new detection) → refine hypothesis ↺
```

### Three-Level Depth (Lens A)
- **Level 1 — Beginner:** instead of waiting for an alarm, go looking — "if a hacker were hiding
  here, what would I see?" — and check.
- **Level 2 — Analyst/SOC:** form an ATT&CK-anchored hypothesis ("an attacker has cron persistence,
  T1053"), pull the data (cron logs/audit/FIM across hosts), analyze (baseline + stack rare values),
  and conclude. "Found nothing + confirmed coverage" is a valid, valuable result.
- **Level 3 — Adversary/Kernel:** core techniques are **baselining** (what's normal?) and **stacking
  / least-frequency analysis** (the rarest values are often the malicious ones — the one host with
  an odd cron, the single process no other host runs). Hunting leans on the durable end of the
  Pyramid (TTP/behavior), since IOCs you'd just alert on.

### Two Teaching Approaches (Lens B) — hunting vs alerting
**Approach 1 (technical):** alerting is a known-signature trigger (recall-limited by your rules);
hunting is exploratory analysis over telemetry to surface anomalies/TTP evidence the rules don't
encode — converting discoveries into new rules (raising recall).

**Approach 2 (analogy):** a smoke detector (alerting) only goes off for what it's built to sense. A
**fire marshal walking the building looking for hazards** (hunting) finds the frayed wire no detector
covers — then installs a new detector there. **Where it breaks down:** hunting is human-driven +
hypothesis-bound, so it's not exhaustive — it complements, not replaces, alerting.

### Visual (ASCII) — stacking / least-frequency
```
 Hypothesis: "rogue cron persistence somewhere in the fleet (T1053)"
 Stack cron entries across all hosts:
   "0 * * * * /usr/bin/backup"      → on 48 hosts   (common = normal)
   "* * * * * /tmp/.x"              → on 1 host      (RARE = hunt lead ✗)
 → the least-frequent value is the anomaly worth investigating.
```

---

## §2 — Linux Investigation Commands

```bash
# stacking across hosts (least-frequency = anomaly) — run per host, aggregate
for h in host01 host02 web01; do ssh $h 'crontab -l 2>/dev/null; ls /etc/cron.d'; done \
  | sort | uniq -c | sort -n | head      # rarest first
# baseline-driven hunt: processes/listeners not seen elsewhere
ss -tulnp | awk '{print $5}' | sort -u   # compare across hosts for outliers
ausearch -m EXECVE -ts today | awk '{print $NF}' | sort | uniq -c | sort -n | head   # rare execs
# SIEM hunt (Wazuh): query telemetry for the hypothesized TTP, then stack
jq '.data.srcip' /var/ossec/logs/alerts/alerts.json | sort | uniq -c | sort -n | head
bash scripts/ioc_sweep.sh    # sweep a hypothesized indicator fleet-wide
```
| Hunt technique | Linux | Wazuh/SIEM |
|---|---|---|
| stacking / least-freq | `sort\|uniq -c\|sort -n` | aggregation, ascending |
| baselining | compare across hosts | inventory + behavior analytics |
| TTP search | audit/process/net queries | ATT&CK-mapped searches |

---

## §3 — Real-World Threat Context & Use Cases

- **Find the dwell-time intrusion:** hunting catches attackers who slipped past detection and are
  living quietly (long dwell).
- **Validate coverage:** a hunt that finds nothing *confirms* you'd have caught it — real assurance.
- **Feed detection engineering:** every hunt finding (or gap) → a new rule (Lesson 26).
- **ATT&CK-driven program:** systematically hunt techniques you don't yet detect (coverage map,
  Lesson 10).
- **Exam framing:** hypothesis-driven hunting + the hunt loop on CySA+/BTL1/SC-200.

---

## §4 — Detection

Hunting and detection are a cycle: a hunt finds an evasive TTP → you write a **detection** for it
(promote the hunt query to a Wazuh/Sigma rule, Lessons 15/27) → the gap closes → hunt the next
hypothesis. The platform's hunt → detection pipeline is the engine of improving coverage. "Found
nothing" still feeds the coverage map (this technique is confirmed-covered/clean).

---

## §5 — Investigation & Triage

A hunt *lead* (an anomaly from stacking/baselining) flows into normal investigation (Lessons 21–24):
scope, timeline, IOCs, TP/FP. Hunting is the *front end* that produces leads triage/investigation
then work. Keep facts vs assessment + document the hypothesis + method (reproducibility).

---

## §6 — SOC Perspective

Mature SOCs allocate time to hunting (not just queue-clearing) — it's a maturity marker and a T3/
detection-eng function. Hunts are documented (`hunt-template.md`) and scheduled around the threat
picture (intel + ATT&CK gaps). The output (new detections) directly improves the whole SOC's MTTD.

---

## §7 — Incident-Response Perspective

Hunting both *prevents* incidents (catch dwell-time intrusions early) and *follows* them: post-
incident, hunt the attacker's TTPs across the fleet to ensure they're not elsewhere (scoping beyond
the known hosts). Lessons-learned often spawns a hunt + a new detection.

---

## §8 — Practical Lab (build this yourself)

**Goal:** run a full hypothesis-driven hunt and convert the finding into a detection.

### Lens C — Manual → Automated → Why
- **Manual:** eyeball cron/process lists per host.
- **Automated:** a stacking script that aggregates a TTP's artifact across hosts and surfaces the
  rarest (anomaly) — repeatable hunts.
- **Why:** stacking by hand doesn't scale past a few hosts; automation makes least-frequency analysis
  practical. Production uses the SIEM's aggregation + scheduled hunts.

### Steps
1. Write `docs/playbooks/hunt-template.md`: hypothesis → data sources → queries → analysis →
   findings → operationalize.
2. Pick a hypothesis (ATT&CK-anchored), e.g. "cron persistence exists somewhere (T1053)". Plant one
   benign rogue cron on a lab host (so there's a positive to find).
3. Hunt: stack cron entries across your lab hosts (least-frequency first); find the outlier; TP it;
   build a mini-timeline.
4. **Operationalize:** turn the finding into a Wazuh/audit detection for rogue cron (or a Sigma rule,
   Lesson 27). Add it to the coverage map.
5. Document the hunt (incl. "coverage confirmed" for the technique).

### Lens D — the raw artifact
The hunt's power is *contrast*: a `/tmp/.x` cron entry isn't suspicious in isolation — it's
suspicious because **no other host has it** (least-frequency). Hunting is finding the artifact that's
abnormal *relative to the baseline*, not abnormal in absolute terms.

---

## §9 — GitHub Artifact (the 6-artifact evidence package)

1. **Script:** `scripts/hunt_stack.sh` (stack a TTP artifact across hosts, rarest-first) — or extend
   `ioc_sweep.sh`.
2. **Detection rule/config:** the new detection the hunt produced (Wazuh/Sigma) in `docs/detections/`.
3. **Runbook:** `docs/runbooks/runbook-hunt.md` — how to run a hunt.
4. **Playbook:** `docs/playbooks/hunt-template.md` (the deliverable).
5. **Incident report + notes:** the hunt report (hypothesis → finding → new detection / coverage
   confirmed) + notes.
6. **SOC ticket:** `SOC-25` (Task: "hypothesis-driven hunt + new detection") → Closed.

---

## §10 — Portfolio Artifact

- **Resume bullet:** "Ran hypothesis-driven, ATT&CK-anchored threat hunts (stacking / least-frequency
  analysis) and converted findings into new committed detections, closing coverage gaps."
- **Interview talking point:** hunting vs alerting, the hunt loop, and stacking/least-frequency — and
  that "found nothing" is a valid result. A clear maturity signal.
- **Serves:** Detection Engineer / Threat Hunter (Stage 4). Drives the Lesson-33 project.

---

## §11 — Certification Crossover Notes

- **CySA+:** threat hunting (major). **SC-200:** hunting/KQL. **BTL1:** threat hunting. **Security+:**
  N/A directly. Detail: `alignment/CERTIFICATION-MAPPING.md`.

---

## §12 — Security Notes (Lens E — Attacker & Defender)

**🔴 Attacker:** evade signature alerts (living-off-the-land, novel TTPs, low-and-slow) and rely on
dwell time — counting on you only *reacting* to alerts, never *looking*.

**🔵 Defender:** hunt proactively for the TTPs you don't alert on; use baselining + stacking to find
the anomaly the attacker assumed you'd miss; convert each hunt into a standing detection. Hunting is
how you take the initiative back from a careful adversary.

---

## Quiz (Interview-Style, Graded)

**Q1.** How does threat hunting differ from alert triage, and what does it specifically target?
> **Your answer:**

**Q2.** Walk the hunt loop from hypothesis to operationalized detection.
> **Your answer:**

**Q3.** What is stacking / least-frequency analysis, and why are the rarest values often the
malicious ones?
> **Your answer:**

**Q4.** **Scenario:** hypothesis — "an attacker established persistence we don't detect." How do you
hunt it across the fleet, and what makes "found nothing" still valuable?
> **Your answer:**

**Q5.** Why should every hunt finding become a detection?
> **Your answer:**

*(Request the "Professional Answer" comparison under each before moving on.)*

---

## Reflection
*(After the quiz)* — What did you learn? · What confused you? · What would you do differently?

---

## Search Keywords For Further Understanding

**Core**
- `hypothesis driven threat hunting`
- `threat hunting loop methodology`
- `stacking least frequency analysis hunting`
- `att&ck driven hunting coverage`
- `hunt to detection pipeline`

**Tools**
- `wazuh threat hunting queries`
- `sort uniq -c stacking linux`

**Going further**
- `detection engineering` (L26) · `sigma rules` (L27) · `threat hunting project` (L33)

**Red / Blue (Lens E):**
- 🔴 `living off the land evasion`, `novel ttp`, `dwell time`
- 🔵 `baselining`, `least-frequency stacking`, `hunt-to-detection`

---

## Lesson Status
- [ ] §8 lab completed (hypothesis-driven hunt + new detection)
- [ ] 6-artifact evidence package committed (§9)
- [ ] Quiz answered + professional-answer comparisons (graded)
- [ ] Reflection + Search Keywords reviewed

When complete, run the Update Protocol, then move to **Lesson 26 — Detection Engineering Basics**.

---

*Lesson 25 written by Navi · 2026-06-20 · full-depth. Sources to cite at study time: SANS threat
hunting, MITRE ATT&CK, "Sqrrl/PEAK hunt loop", David Bianco Pyramid of Pain.*
