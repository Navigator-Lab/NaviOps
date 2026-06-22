# Lesson 16 — Log-Analysis Workflows

**Status:** ✅ ready for self-study (full depth) · **Date written:** 2026-06-20
**Schema:** 12-section SOC (`docs/learning/CLAUDE_TEACHING_RULES.md`)
**Focus:** the repeatable path from raw log → alert → triage → conclusion, hunting in the SIEM,
query patterns, and turning ad-hoc analysis into a documented, reusable workflow.
**Primary artifact:** `docs/playbooks/log-analysis-workflow.md`.

> **How to use this lesson:** read §1–§7, do §8 (codify a repeatable analysis workflow + run it in
> Wazuh), produce §9, quiz, reflect. Then Lesson 17.

---

## §1 — Concept (Scientific Theory)

### What it is
A **log-analysis workflow** is the documented, repeatable sequence an analyst follows to go from a
question (or an alert) to a defensible conclusion: **scope the question → pick the source → query →
extract/aggregate → corroborate → conclude → document.** It's the methodology that makes analysis
consistent across analysts and shifts — the difference between "I poked around" and "I followed the
workflow."

### Why it exists
Ad-hoc grepping doesn't scale or transfer. A workflow makes analysis **repeatable** (same steps →
same quality), **fast** (no reinventing the approach each time), and **defensible** (you can show
your method). It's also how Linux-first analysis (Lessons 04–05) and the SIEM (13–15) combine into
one practiced loop.

### Three-Level Depth (Lens A)
- **Level 1 — Beginner:** have a recipe for "how do I investigate a log question" instead of winging
  it each time.
- **Level 2 — Analyst/SOC:** the loop — pick the right source, write the query (Wazuh search or
  Linux pipe), aggregate (top-N/timeline), corroborate across sources, and write the finding. You
  build a **query library** of the patterns you reuse (top sources, user activity, time-window
  timeline, rare events).
- **Level 3 — Adversary/Kernel:** good workflows include **baseline comparison** (what's normal for
  this host/user?) and **rare-event analysis** (stacking/frequency analysis to surface the unusual)
  — the techniques that catch low-and-slow attacks single queries miss. This is the bridge to
  hunting (Lesson 25).

### Two Teaching Approaches (Lens B) — workflow vs ad-hoc
**Approach 1 (technical):** a workflow is a parameterized procedure (inputs: question, source,
time-window; steps: filter→aggregate→corroborate; output: finding + evidence) that any analyst can
execute identically.

**Approach 2 (analogy):** a **diagnostic flowchart** in a clinic. A doctor doesn't improvise every
visit — symptom → ordered tests → read results → diagnosis. The flowchart means any doctor reaches
the same standard. **Where it breaks down:** novel attacks (like novel diseases) need hunting +
hypothesis (Lesson 25) beyond the standard workflow.

### Visual (ASCII) — the analysis loop
```
  QUESTION/ALERT ─► pick SOURCE ─► QUERY (SIEM search | Linux pipe) ─► AGGREGATE (top-N/timeline)
        ▲                                                                     │
        │                                                                     ▼
   document finding ◄── CONCLUDE (TP/FP, scope) ◄── CORROBORATE (other sources, baseline)
```

---

## §2 — Linux Investigation Commands

The workflow runs the same query two ways — on the box and in the SIEM:
```bash
# Linux-first (fallback / ground truth)
grep "Failed password" /var/log/auth.log | awk '{print $(NF-3)}' | sort | uniq -c | sort -rn
journalctl -S -2h -o short-iso | grep -Ei 'sshd|sudo|useradd' | sort   # window timeline

# SIEM (Wazuh dashboard / API) — same intent, fleet-wide
#   search: rule.groups:authentication_failed AND data.srcip:* | top data.srcip
#   filter time window; pivot by agent.name / data.srcuser
jq 'select(.rule.groups[]?=="authentication_failed") | .data.srcip' /var/ossec/logs/alerts/alerts.json \
  | sort | uniq -c | sort -rn      # the same aggregation over Wazuh alerts
```
| Workflow step | Linux | Wazuh |
|---|---|---|
| filter | `grep` | search query |
| aggregate | `sort\|uniq -c` | top-N visualization |
| timeline | `journalctl -o short-iso` | time-ordered events panel |
| corroborate | multiple logs | multiple sources/agents in one search |

---

## §3 — Real-World Threat Context & Use Cases

- **Consistent triage:** every analyst investigates an alert the same way → comparable quality +
  faster onboarding.
- **Reusable query library:** the 10 queries you run weekly, saved + named, cut MTTR.
- **Baseline-driven analysis:** comparing to "normal" surfaces the abnormal (the seed of hunting).
- **Documented method = defensible findings** (audits, court, post-incident review).
- **Exam framing:** structured log analysis + correlation are core CySA+/BTL1 skills.

---

## §4 — Detection

- **Workflows generate detections:** a query you run repeatedly to find something bad should become
  a *rule* (promote it to Wazuh, Lesson 15). The workflow is the incubator for detection content.
- **Saved searches / scheduled queries** are detections-in-waiting — run on a schedule, they alert.
- **Rare-event / stacking analysis** (least-frequent values) is a detection technique that single
  thresholds miss — formalized in hunting (Lesson 25).

---

## §5 — Investigation & Triage

This lesson *is* the investigation engine for triage: alert → workflow → conclusion. The query
library + the workflow doc mean a T1 reaches a defensible TP/FP + scope quickly and identically to
peers. Corroboration across sources is what raises confidence from "maybe" to "confirmed."

---

## §6 — SOC Perspective

Documented workflows + a shared query library are a hallmark of a mature SOC — they reduce variance,
speed onboarding, and lower MTTR. They live alongside runbooks (`docs/runbooks/`) and the case
process (`soc/case-management.md`). "Show me your investigation workflow" is a senior-interview ask.

---

## §7 — Incident-Response Perspective

IR Phase 2 (investigation) executes these workflows at speed across the estate via the SIEM
(scope/timeline/IOC search). A good workflow makes the difference between a clean, complete timeline
and a report with gaps. Post-incident, you refine the workflow with what you learned.

---

## §8 — Practical Lab (build this yourself)

**Goal:** codify a reusable log-analysis workflow + query library and run it in both Linux and
Wazuh.

### Lens C — Manual → Automated → Why
- **Manual:** investigate one alert ad-hoc.
- **Automated:** a saved workflow + named queries (and `log_triage.sh`) so the next investigation is
  a checklist, not improvisation.
- **Why:** consistency + speed under pressure; production saves searches + schedules them as
  detections.

### Steps
1. Write `docs/playbooks/log-analysis-workflow.md`: the 7-step loop (scope→source→query→aggregate→
   corroborate→conclude→document) with a worked example (a failed-login alert).
2. Build a query library: 5 patterns you'll reuse (top sources, user activity over a window,
   time-window timeline, rare/least-frequent events, cross-source corroboration) — each in *both*
   Linux and Wazuh form.
3. Run the workflow end-to-end on a lab alert (use a drill): produce a finding with evidence.
4. Identify one query worth promoting to a Wazuh rule (feeds Lesson 18+).
5. Add the workflow + library links to your triage runbook.

### Lens D — the raw artifact
The workflow's power is corroboration: the failed-login alert (`auth.log`) becomes *conclusive* when
the workflow pulls the matching `accepted` login + the new process (`audit.log`) + the outbound
socket (`ss`) into one timeline. One source = suspicion; corroborated sources = confirmation.

---

## §9 — GitHub Artifact (the 6-artifact evidence package)

1. **Script:** `scripts/log_triage.sh` extended into the workflow's first pass (or `query_lib.sh`
   of the named queries).
2. **Detection rule/config:** the candidate query promoted toward a Wazuh rule (note in
   `docs/detections/`).
3. **Runbook:** `docs/runbooks/runbook-investigation.md` — the standard investigation steps.
4. **Playbook:** `docs/playbooks/log-analysis-workflow.md` (the deliverable).
5. **Incident report + notes:** a finding produced by running the workflow on a lab alert + notes.
6. **SOC ticket:** `SOC-16` (Task: "documented log-analysis workflow + query library") → Closed.

---

## §10 — Portfolio Artifact

- **Resume bullet:** "Standardized a SOC log-analysis workflow + reusable query library (Linux +
  Wazuh), cutting investigation variance and enabling corroborated, defensible findings."
- **Interview talking point:** walk your investigation workflow and show the query library — proves
  method, not just tool-knowledge.
- **Serves:** SOC T1 → T2 (Stages 2–3). Bridge to hunting (Lesson 25).

---

## §11 — Certification Crossover Notes

- **CySA+:** analysis + correlation. **SC-200:** hunting/KQL workflows. **BTL1:** investigations.
  **Security+:** monitoring (4.x). Detail: `alignment/CERTIFICATION-MAPPING.md`.

---

## §12 — Security Notes (Lens E — Attacker & Defender)

**🔴 Attacker:** count on inconsistent, shallow analysis — they hide in the gaps an ad-hoc analyst
skips (a source not checked, a window too short, no baseline comparison).

**🔵 Defender:** a disciplined workflow with baseline + rare-event analysis closes those gaps and
catches low-and-slow activity. Corroboration across sources defeats single-source evasion. Promote
recurring hunt queries into standing detections.

---

## Quiz (Interview-Style, Graded)

**Q1.** Lay out a repeatable log-analysis workflow from question/alert to documented conclusion.
> **Your answer:**

**Q2.** Why does corroborating across multiple sources raise confidence — give an SSH-compromise
example.
> **Your answer:**

**Q3.** What is baseline / rare-event analysis, and what does it catch that a single threshold
misses?
> **Your answer:**

**Q4.** **Scenario:** you're handed "investigate suspicious activity on web01 last night." Walk your
workflow — sources, queries, how you conclude.
> **Your answer:**

**Q5.** When should a recurring analysis query become a Wazuh rule?
> **Your answer:**

*(Request the "Professional Answer" comparison under each before moving on.)*

---

## Reflection
*(After the quiz)* — What did you learn? · What confused you? · What would you do differently?

---

## Search Keywords For Further Understanding

**Core**
- `log analysis workflow methodology soc`
- `siem query patterns investigation`
- `baseline rare event stacking analysis`
- `corroboration multiple log sources`
- `saved search scheduled detection`

**Tools**
- `wazuh dashboard search query`
- `jq alerts.json aggregation`

**Going further**
- `alert triage` (L17) · `threat hunting` (L25) · `detection engineering` (L26)

**Red / Blue (Lens E):**
- 🔴 `hide in analysis gaps`, `low and slow`, `single-source evasion`
- 🔵 `baseline analysis`, `cross-source corroboration`, `promote query to detection`

---

## Lesson Status
- [ ] §8 lab completed (workflow + query library; run on a lab alert)
- [ ] 6-artifact evidence package committed (§9)
- [ ] Quiz answered + professional-answer comparisons (graded)
- [ ] Reflection + Search Keywords reviewed

When complete, run the Update Protocol, then move to **Lesson 17 — Alert Triage Fundamentals**.

---

*Lesson 16 written by Navi · 2026-06-20 · full-depth. Sources to cite at study time: SANS log
analysis, Wazuh search docs, CySA+ analysis objectives.*
