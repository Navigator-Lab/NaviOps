# Lesson 30 — Report Writing for Security Analysts

**Status:** ✅ ready for self-study (full depth) · **Date written:** 2026-06-20
**Schema:** 12-section SOC (`docs/learning/CLAUDE_TEACHING_RULES.md`)
**Focus:** the **technical report** + the **executive summary** — timeline, RCA, evidence package,
lessons learned, audience-appropriate writing, and the rubric. The skill that makes your work
*count*.
**Primary artifact:** the full `docs/templates/` report set, used for real.

> **How to use this lesson:** read §1–§7, do §8 (write both reports for a prior incident), produce
> §9, quiz, reflect. Then Lesson 31 (the projects). **This + 21–24, 28–29 completes Wave-3.**

---

## §1 — Concept (Scientific Theory)

### What it is
Reporting turns an investigation into communicated value for two audiences:
- **Technical report** — for the security team: full detail, timeline (UTC), IOCs, RCA, evidence,
  every action. Reproducible + defensible (`templates/incident-report.md`).
- **Executive summary** — for non-technical leadership: what happened, business impact, what was
  done, recommendations — one page, no jargon (`templates/executive-summary.md`).
Plus the supporting docs: **RCA**, **evidence package**, **lessons learned** (the templates you've
been filling all platform long).

### Why it exists
An investigation nobody can understand or act on is wasted. Reporting is how findings become
decisions (leadership funds the fix), how the org learns (lessons learned → new detection), and how
work is judged — *the report is the deliverable a hiring manager actually reads.* It's often the
weakest skill of technical analysts, so it's a major differentiator.

### Three-Level Depth (Lens A)
- **Level 1 — Beginner:** write down what happened clearly — a detailed version for the techies and a
  short, plain version for the bosses.
- **Level 2 — Analyst/SOC:** structure the technical report (summary → assets → detection → timeline →
  findings/RCA → IOCs → actions → lessons learned → evidence) and distill the exec summary (impact +
  actions + recommendations). Separate **facts** from **assessment**; write in **UTC**, past tense,
  active voice.
- **Level 3 — Adversary/Kernel:** the report's spine is the **timeline** (the ordered, evidence-backed
  sequence) + the **RCA** (the root cause, via 5-Whys — Lesson's `rca.md`). Evidence must be
  reproducible + hashed (chain of custody). The lessons-learned must yield a concrete **new
  detection** (closing the loop to Lesson 26).

### Two Teaching Approaches (Lens B) — two audiences
**Approach 1 (technical):** a report is information architecture matched to the reader's decision: the
analyst needs reproducibility + detail; the executive needs impact + cost + recommendation. Same
incident, two abstraction levels.

**Approach 2 (analogy):** a **doctor's chart vs the conversation with the family.** The chart (technical
report) has every measurement + procedure for other clinicians. The family conversation (exec summary)
is "here's what happened, here's what we did, here's what it means, here's the plan" — no Latin.
**Where it breaks down:** unlike a chart, your technical report may also need to satisfy legal/audit —
so evidence integrity matters more.

### Visual (ASCII) — two reports from one incident
```
                       ┌──────────────────────────────────────────┐
   ONE INCIDENT ──────►│ TECHNICAL REPORT (security team)          │  detail, timeline, RCA,
                       │  summary·assets·detection·timeline·RCA·   │  IOCs, evidence, actions
                       │  IOCs·actions·lessons·evidence            │  → reproducible/defensible
                       ├──────────────────────────────────────────┤
                       │ EXECUTIVE SUMMARY (leadership)            │  impact·what we did·
                       │  what happened·impact·actions·recs        │  recommendations (1 page)
                       └──────────────────────────────────────────┘  → drives decisions/funding
```

---

## §2 — Linux Investigation Commands

Reporting consumes the evidence your tools produced; the "commands" here are assembling it:
```bash
# build the timeline from preserved evidence (on copies, not live logs)
cat evidence/auth.log evidence/syslog | grep -E 'sshd|sudo|useradd|cron' \
  | sort -k1,3 > timeline_raw.txt          # ordered events → the report timeline
sha256sum -c evidence/SHA256SUMS           # confirm evidence integrity for the report
# pull the IOC list + actions from your case notes (Lessons 12, 28-29)
```
| Report element | Source |
|---|---|
| timeline | preserved logs/audit (L05/28), ordered |
| IOCs | extraction (L12) |
| RCA | 5-Whys (`templates/rca.md`) |
| evidence + hashes | collection (L28, `evidence-package.md`) |
| lessons-learned detection | detection eng (L26) |

---

## §3 — Real-World Threat Context & Use Cases

- **Every incident ends in a report** — it's the standard SOC/IR deliverable.
- **Leadership decisions** (funding the fix, notifying regulators) come from the exec summary.
- **Audit/legal/compliance** rely on the technical report + evidence integrity.
- **Your portfolio + interviews** are *built* on incident reports — the single strongest artifact
  (`PORTFOLIO-GUIDE.md`).
- **Exam framing:** reporting, communication, and documentation on Security+/CySA+/BTL1.

---

## §4 — Detection

Reporting closes the detection loop: the **lessons-learned** section must specify the detection that
would have caught the incident sooner — and that detection gets *built* (Lesson 26) + committed.
A report without a resulting detection improvement is incomplete. The report also documents *which
detection* found the incident (provenance), feeding coverage metrics.

---

## §5 — Investigation & Triage

The report is the investigation, communicated. A clean report is only possible from a disciplined
investigation (facts vs assessment, preserved evidence, a complete timeline). Writing the report
often *reveals gaps* in the investigation ("I can't explain this hour") — which is why good analysts
draft the timeline *during* the investigation, not after.

---

## §6 — SOC Perspective

Reporting + communication are core SOC competencies (and common interview asks: "show me a report you
wrote"). The SOC standardizes report templates (`docs/templates/`) so quality is consistent + fast.
The exec summary is how the SOC demonstrates value to the business. Maps to `soc/case-management.md`.

---

## §7 — Incident-Response Perspective

This is IR Phase 4 (post-incident), made concrete. The lifecycle's value is only realized when the
incident is documented (technical + exec), the evidence packaged, and lessons learned drive
improvement. The capstone (Lesson 35) is graded heavily on *both* reports.

---

## §8 — Practical Lab (build this yourself)

**Goal:** write a complete technical report **and** an executive summary for a prior incident.

### Lens C — Manual → Automated → Why
- **Manual:** write each report from scratch.
- **Automated:** the templates (`docs/templates/`) + a timeline-builder one-liner give you a
  consistent, fast structure — fill, don't invent.
- **Why:** templates ensure nothing's missed + speed delivery; production SOCs/IR teams template
  reports for consistency + auditability.

### Steps
1. Take a completed incident (the L28/29 brute-force→shell→contained case).
2. **Technical report:** fill `templates/incident-report.md` end-to-end — build the timeline from
   preserved evidence, write the RCA (`templates/rca.md`, 5-Whys), list IOCs (L12), document every
   action (L29), and the evidence package (`templates/evidence-package.md`, hashed).
3. **Executive summary:** distill `templates/executive-summary.md` — impact + what-we-did +
   recommendations, no jargon, one page.
4. **Lessons learned:** `templates/lessons-learned.md` — and specify + commit the new detection
   (L26).
5. Sanitize everything (redaction convention). Have a non-technical person sanity-check the exec
   summary reads clearly.

### Lens D — the raw artifact
The timeline is the report's backbone — and it's literally your sorted, preserved log lines turned
into prose+table:
```
02:05Z  240 failed SSH logins from 203.0.113.50   [auth.log]              T1110
02:14Z  Accepted password svc_app from 203.0.113.50 [auth.log]           T1078
02:16Z  bash spawned by nginx, socket :4444        [ps/ss snapshot]      T1059
# evidence → ordered → annotated with ATT&CK = the spine both reports hang on.
```

---

## §9 — GitHub Artifact (the 6-artifact evidence package)

1. **Script:** `scripts/timeline_build.sh` — merge + sort preserved logs into a timeline skeleton.
2. **Detection rule/config:** the lessons-learned detection, committed (`docs/detections/`).
3. **Runbook:** `docs/runbooks/runbook-reporting.md` — how to write each report.
4. **Playbook:** the report-writing rubric (audiences, facts-vs-assessment, UTC, evidence).
5. **Incident report + notes:** the full technical report **+** executive summary for the incident +
   RCA + evidence package + lessons-learned (the whole set).
6. **SOC ticket:** `SOC-30` (Task: "full incident report + exec summary") → Closed.

---

## §10 — Portfolio Artifact

- **Resume bullet:** "Wrote technical incident reports + executive summaries (timeline, RCA, IOCs,
  evidence, lessons-learned) translating investigations into team-ready detail and leadership-ready
  impact."
- **Interview talking point:** the two-audience principle + facts-vs-assessment + the report driving
  a new detection. *Bring a sanitized report to the interview* — it's the strongest single artifact.
- **Serves:** SOC T2 / IR / Detection Engineer (Stages 3–4). **Completes Wave-3** — write
  `PORTFOLIO.md`.

---

## §11 — Certification Crossover Notes

- **Security+:** governance/communication (5.x). **CySA+:** reporting + communication (major).
  **SC-200:** incident documentation. **BTL1:** reporting. Detail: `alignment/CERTIFICATION-MAPPING.md`.

---

## §12 — Security Notes (Lens E — Attacker & Defender)

**🔴 Attacker:** benefits when reports are missing/vague — gaps in the timeline = unscoped intrusion =
they may still be in; un-communicated risk = unfunded fix = recurrence.

**🔵 Defender:** a complete, evidence-backed report scopes the intrusion fully (no hiding gaps),
drives the fix (exec summary → funding), and yields a new detection (lessons learned). Good reporting
is a security control: it's how the org actually *acts* on what you found.

---

## Quiz (Interview-Style, Graded)

**Q1.** Contrast the technical report and the executive summary — audience, content, length.
> **Your answer:**

**Q2.** What are the essential sections of a technical incident report?
> **Your answer:**

**Q3.** Why separate facts from assessment, and why write timelines in UTC?
> **Your answer:**

**Q4.** **Scenario:** leadership asks "how bad was it and what do we do?" Draft the 4-sentence exec-
summary answer for a contained brute-force→unauthorized-login incident.
> **Your answer:**

**Q5.** Why must the lessons-learned section produce a concrete new detection?
> **Your answer:**

*(Request the "Professional Answer" comparison under each before moving on.)*

---

## Reflection
*(After the quiz)* — What did you learn? · What confused you? · What would you do differently?

---

## Search Keywords For Further Understanding

**Core**
- `security incident report structure`
- `executive summary vs technical report`
- `incident timeline rca writing`
- `facts vs assessment analysis writing`
- `lessons learned new detection`

**Tools**
- `incident report template`
- `5 whys root cause analysis`

**Going further**
- `security monitoring project` (L31) · `soc operations project` (L34) · `capstone` (L35)

**Red / Blue (Lens E):**
- 🔴 `timeline gaps unscoped intrusion`, `un-communicated risk`
- 🔵 `complete evidence-backed report`, `exec summary drives fix`, `lessons-learned detection`

---

## Lesson Status
- [ ] §8 lab completed (technical report + exec summary + RCA + evidence + lessons-learned written)
- [ ] 6-artifact evidence package committed (§9)
- [ ] Quiz answered + professional-answer comparisons (graded)
- [ ] Reflection + Search Keywords reviewed
- [ ] **Wave-3 PORTFOLIO.md** written (21–24, 28–30 done)

When complete, run the Update Protocol, then move to **Lesson 31 — Security Monitoring Project**.

---

*Lesson 30 written by Navi · 2026-06-20 · full-depth. Sources to cite at study time: SANS report
writing, NIST SP 800-61 (documentation), CySA+ communication objectives.*
