# Lesson 33 — Threat Hunting Project

**Status:** ✅ ready for self-study (full depth) · **Date written:** 2026-06-20
**Schema:** 12-section SOC (`docs/learning/CLAUDE_TEACHING_RULES.md`) · **Type:** Project
**Focus:** run a full **hypothesis-driven hunt** through host + SIEM data, document findings (incl.
"coverage confirmed"), and **convert a finding into a new detection**.
**Full plan:** [`capstones/33-threat-hunting-project.md`](../../capstones/33-threat-hunting-project.md).

> Read §1–§7, execute §8 (the project), produce §9, quiz, reflect. Then Lesson 34.

---

## §1 — Concept (Scientific Theory)
This project applies Lesson 25 (hunting) + 26–27 (detection eng/Sigma) end-to-end: form an
ATT&CK-anchored hypothesis, hunt it across telemetry with stacking/baselining, document the result,
and **operationalize** it as a new detection. It proves you can take the *initiative* — find what
alerts missed and turn it into permanent coverage.

**Lens A:** *Beginner* — go looking for a specific hidden attack + then build an alarm for it.
*Analyst* — hypothesis → data → stack/baseline → findings (TP or coverage-confirmed) → new rule.
*Adversary/Kernel* — the hunt targets a durable TTP (Pyramid), uses least-frequency analysis to find
the anomaly, and closes the gap with a tested detection.

**Lens B (a hunt):** *technical* — a documented, reproducible exploratory analysis converting a
hypothesis into evidence + a detection. *Analogy* — a **detective working a hunch** (not a 911 call):
gather clues, follow the lead, and afterward install a tripwire so it's caught automatically next
time. *Breaks down:* hunts are scoped by hypothesis — they complement, not replace, broad detection.

```
 hypothesis (ATT&CK T-xxxx) → gather telemetry → STACK/baseline → finding (TP | coverage✓)
        → operationalize: new Sigma/Wazuh detection → coverage map updated
```

---

## §2 — Linux Investigation Commands
```bash
# stack a TTP artifact across hosts (least-frequency = lead)
for h in host01 host02 web01; do ssh $h 'crontab -l; systemctl list-timers --all'; done \
  | sort | uniq -c | sort -n | head
ausearch -m EXECVE -ts today | awk '{print $NF}' | sort | uniq -c | sort -n   # rare execs
bash scripts/hunt_stack.sh ; bash scripts/ioc_sweep.sh    # fleet hunt + sweep
sigma convert -t wazuh docs/detections/sigma/<new_hunt_rule>.yml   # operationalize
```

---

## §3 — Real-World Threat Context & Use Cases
Hunting catches dwell-time intrusions + validates coverage; the hunt report + the new detection are
exactly what a Threat Hunter / Detection Engineer interview wants. Applied CySA+/SC-200/BTL1 hunting
objectives.

## §4 — Detection
The project's output *is* a new detection: the hunt finds an evasive TTP (or confirms coverage) → you
write + test + commit the rule (Sigma → Wazuh) → the coverage map grows. Hunt → detection is the
engine of improving MTTD.

## §5 — Investigation & Triage
A hunt lead flows into full investigation (Lessons 21–24): scope, timeline, IOCs, TP/FP. Document the
hypothesis + method for reproducibility; "found nothing + coverage confirmed" is a valid, recorded
result.

## §6 — SOC Perspective
Hunting is the proactive, maturity-marking SOC function (T3/detection-eng). The documented hunt +
resulting detection demonstrate the SOC taking initiative, not just clearing a queue.

## §7 — Incident-Response Perspective
Hunting prevents incidents (catch dwell-time intrusions) and follows them (hunt the attacker's TTPs
fleet-wide to confirm no other hosts). The new detection is the lessons-learned improvement.

---

## §8 — Practical Lab (the project)
Execute [`capstones/33-threat-hunting-project.md`](../../capstones/33-threat-hunting-project.md):
1. Form an ATT&CK-anchored hypothesis (e.g. cron persistence T1053 / beaconing T1071).
2. Gather the relevant telemetry (cron/audit/network/Wazuh).
3. Hunt (stack/baseline; stage a benign positive if needed); analyze + TP/FP.
4. Document the hunt (`docs/playbooks/hunt-template.md` filled): hypothesis, data, queries, findings,
   coverage confirmed.
5. Operationalize: turn the strongest finding/gap into a new Sigma→Wazuh detection; update coverage.

**Lens C:** `hunt_stack.sh` makes stacking repeatable. **Lens D:** the lead is the *least-frequent*
artifact — abnormal relative to baseline, not in isolation.

---

## §9 — GitHub Artifact (the 6-artifact evidence package)
1. **Script:** `scripts/hunt_stack.sh` (or extended `ioc_sweep.sh`). 2. **Detection/config:** the new
detection (`docs/detections/sigma/` + Wazuh). 3. **Runbook:** the hunt runbook. 4. **Playbook:**
the filled `hunt-template.md`. 5. **Incident report + notes:** the hunt report (hypothesis → finding →
new detection / coverage confirmed). 6. **SOC ticket:** `SOC-33` → Closed. (Rubric in the plan.)

## §10 — Portfolio Artifact
- **Resume bullet:** "Ran a hypothesis-driven, ATT&CK-anchored threat hunt across host + SIEM
  telemetry, documented findings + coverage, and converted the result into a new committed detection."
- **Interview talking point:** the hunt loop + stacking + "found nothing is valuable" + hunt→detection.
  **Serves:** Threat Hunter / Junior Detection Engineer (Stage 4).

## §11 — Certification Crossover Notes
Applied threat-hunting across CySA+/SC-200/BTL1. Detail: `alignment/CERTIFICATION-MAPPING.md`.

## §12 — Security Notes (Lens E)
**🔴** evasive/low-and-slow/novel TTPs counting on you only reacting. **🔵** proactive hunting +
baselining + least-frequency analysis + converting findings to standing detections takes the
initiative back.

---

## Quiz (Interview-Style, Graded)
**Q1.** State a good hunt hypothesis and why it must be ATT&CK-anchored + specific.
> **Your answer:**

**Q2.** How does stacking / least-frequency surface a lead?
> **Your answer:**

**Q3.** Why is "found nothing" a valuable hunt result?
> **Your answer:**

**Q4.** **Scenario:** hypothesis — undetected outbound beaconing (T1071). How do you hunt it and turn
a finding into a detection?
> **Your answer:**

**Q5.** How does this project improve the SOC's MTTD over time?
> **Your answer:**

*(Request the "Professional Answer" comparison under each before moving on.)*

---

## Reflection
*(After the project)* — What did you learn? · What confused you? · What would you do differently?

## Search Keywords For Further Understanding
- `threat hunting project hypothesis` · `stacking least frequency hunt` · `hunt to detection sigma` ·
  `att&ck driven hunting` · 🔴 `low and slow novel ttp` · 🔵 `baselining hunt-to-detection`

---

## Lesson Status
- [ ] Project executed (hunt run + documented + new detection committed)
- [ ] 6-artifact evidence package committed (§9) · [ ] Quiz graded · [ ] Reflection + keywords
- [ ] **Wave-4 (Jr Detection Engineer) PORTFOLIO.md** written (25–27, 32–33 done)

When complete, run the Update Protocol, then move to **Lesson 34 — SOC Operations Project**.

---
*Lesson 33 written by Navi · 2026-06-20 · full-depth. Plan: `capstones/33-threat-hunting-project.md`.*
