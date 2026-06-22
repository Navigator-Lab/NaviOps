# Lesson 35 — Security Analyst Capstone (the compromised server)

**Status:** ✅ ready for self-study (full depth) · **Date written:** 2026-06-20
**Schema:** 12-section SOC (`docs/learning/CLAUDE_TEACHING_RULES.md`) · **Type:** Capstone
**Focus:** the full incident on a **compromised Linux server** — investigate, IOCs, timeline,
contain, recover, **technical report + executive summary + evidence package + lessons learned**.
**Full plan:** [`capstones/35-security-analyst-capstone.md`](../../capstones/35-security-analyst-capstone.md)
· **Scenario:** [`workflows/compromised-server-scenario.md`](../../workflows/compromised-server-scenario.md)
· **Rubric:** [`CAPSTONE-GUIDE.md`](../../CAPSTONE-GUIDE.md).

> **Danger zone:** the staged attack is **benign, self-owned, lab-only** (`navi.project.md` #2). You
> play the defender. Read §1–§7, execute §8 (the full incident), produce §9, quiz, reflect. **This is
> the final lesson** — it completes Wave-5 (SecOps Engineer) + the platform.

---

## §1 — Concept (Scientific Theory)
The capstone integrates **everything**: detection (13–24) → investigation (21–25) → IR lifecycle
(28–29) → reporting (30), against a realistic staged intrusion (recon → brute force → execution →
persistence → log tampering → discovery/lateral → exfil). You play **defender**: detect, investigate,
scope, contain, eradicate, recover, and report — both technical and executive. It proves you can do a
SOC analyst's core job end-to-end.

**Lens A:** *Beginner* — a server got hacked; figure out what happened, kick the attacker out, fix it,
and write it up. *Analyst* — work host + SIEM evidence to reconstruct the kill chain, extract IOCs,
build the timeline (ATT&CK-mapped), run CER (evidence-first), and produce the full report set.
*Adversary/Kernel* — chain the per-lesson skills into one coherent investigation; the artifacts (logs/
audit/FIM/network/process) you've learned to read *are* the evidence that reconstructs the intrusion.

**Lens B (the capstone):** *technical* — an end-to-end incident exercise spanning the full detection→
IR→report pipeline against a multi-stage intrusion. *Analogy* — the **board exam / final clinical
rotation**: a real (simulated) patient, no scaffolding, you run the whole case and present it.
*Breaks down:* it's still a lab (benign, self-owned) — but it's the closest proxy to the real job.

```
 staged chain: recon→brute force→exec→persistence→log-tamper→discovery→exfil  (you=defender)
   DETECT (SIEM+host) → INVESTIGATE (timeline+IOCs, ATT&CK) → CONTAIN → ERADICATE → RECOVER
        → TECHNICAL REPORT + EXEC SUMMARY + EVIDENCE PACKAGE + LESSONS-LEARNED (new detection)
```

---

## §2 — Linux Investigation Commands
The whole toolkit, integrated:
```bash
bash scripts/log_triage.sh ; bash scripts/failed_logins.sh        # detect (L18)
bash scripts/proc_investigate.sh ; bash scripts/user_audit.sh     # investigate (L21/22)
bash scripts/fim_check.sh ; bash scripts/ioc_sweep.sh             # FIM + scope (L24/12)
bash scripts/evidence_collect.sh case/                            # preserve (L28)
bash scripts/contain.sh <attacker_ip> <account>                  # contain (L29)
bash scripts/timeline_build.sh case/ > timeline.txt               # report timeline (L30)
```

---

## §3 — Real-World Threat Context & Use Cases
This *is* the job: "a server is compromised — take it from here." The full incident package (technical
report + exec summary + evidence + lessons-learned) is the strongest single portfolio artifact and the
exact thing a SOC/IR interview's scenario round simulates. Applied capstone across all certs.

## §4 — Detection
Every stage must be **detected** (host evidence + a SIEM alert) — the capstone tests your detection
coverage (Lessons 13–24, the L32 set). A stage you can't detect is a lessons-learned gap → a new
detection (the deliverable).

## §5 — Investigation & Triage
The capstone is investigation at full depth: reconstruct each stage from evidence (don't peek at the
staging script), TP/FP, scope across hosts (IOC sweep), build the ATT&CK-mapped timeline, find the
root cause (entry point) and all persistence.

## §6 — SOC Perspective
The capstone runs the whole SOC loop on one incident — detect, triage, escalate (to yourself as IR),
case-manage, and report. It's the integration of every `soc/` module + every detection + the IR
lifecycle.

## §7 — Incident-Response Perspective
This is the full NIST 800-61 lifecycle (Lessons 28–29) executed: preserve → contain → eradicate
(complete + validated) → recover (validated clean) → lessons learned. Evidence-first throughout;
chain of custody; both reports. The non-negotiables are graded.

---

## §8 — Practical Lab (the capstone)
Execute [`workflows/compromised-server-scenario.md`](../../workflows/compromised-server-scenario.md) +
[`capstones/35-security-analyst-capstone.md`](../../capstones/35-security-analyst-capstone.md):
1. **Stage** the benign, self-owned 7-stage chain on a lab VM (then switch to defender).
2. **Investigate** host + SIEM; reconstruct each stage.
3. **IOCs** (host/network/file) extracted + typed.
4. **Timeline** (UTC), mapped to ATT&CK + kill chain.
5. **Contain** (evidence preserved first) → **Eradicate** (all persistence + vector, validated) →
   **Recover** (validated clean + monitoring).
6. **Technical report** + **Executive summary** + **Evidence package** (hashed, chain of custody) +
   **Lessons learned** (commit the new detection).

**Lens C:** the whole script suite runs the incident. **Lens D:** every conclusion traces to a raw
artifact (the auth line, the audit record, the FIM diff, the socket) — that's what makes the report
defensible.

---

## §9 — GitHub Artifact (the 6-artifact evidence package — the whole incident)
1. **Script:** the full `scripts/` suite, applied (+ any capstone glue). 2. **Detection/config:** the
new lessons-learned detection committed. 3. **Runbook:** the incident runbook. 4. **Playbook:** the
end-to-end IR play. 5. **Incident report + notes:** technical report + exec summary + evidence package
(hashed) + lessons-learned — the complete set in `docs/runbooks/capstone/` (sanitized). 6. **SOC
ticket:** `SOC-35` → Closed.

## §10 — Portfolio Artifact
- **Resume bullet (the headline):** "Investigated a compromised Linux server end-to-end: detected the
  intrusion in a Wazuh SIEM, reconstructed the MITRE ATT&CK timeline, extracted IOCs, contained +
  recovered the host, and delivered a technical report + executive summary + evidence package."
- **Interview talking point:** narrate the whole incident from your own report — the scenario round,
  pre-rehearsed. **Serves:** the platform's destination — Security Analyst → SOC T2 → IR → SecOps
  Engineer.
- **Write the final `lessons/35-security-analyst-capstone/PORTFOLIO.md`** rolling up the whole
  platform (all waves) into the master portfolio summary.

## §11 — Certification Crossover Notes
Applied capstone integrating Security+/CySA+/SC-200/BTL1. Detail: `alignment/CERTIFICATION-MAPPING.md`.

## §12 — Security Notes (Lens E)
**🔴** the full kill chain (recon T1046 → brute force T1110 → valid accounts T1078 → execution T1059
→ persistence T1053/T1098 → defense evasion/log-tamper T1070 → discovery T1087 → lateral T1021 →
exfil T1041). **🔵** detect each stage, investigate evidence-first, contain → eradicate (validated) →
recover, and close the gap with a new detection. Authorization: lab/self-owned, benign, sanitized.

---

## Quiz (Interview-Style, Graded — defend your investigation)
**Q1.** For each attack stage, what detected it and what's the ATT&CK technique?
> **Your answer:**

**Q2.** Walk your IR response end-to-end (preserve→contain→eradicate→recover), naming the validation
gates.
> **Your answer:**

**Q3.** How did you reconstruct the timeline and determine the root cause / entry point?
> **Your answer:**

**Q4.** **Scenario:** leadership asks for the impact + what you did in 60 seconds — give the exec
summary verbally.
> **Your answer:**

**Q5.** What new detection did you add, and how would it have caught this earlier?
> **Your answer:**

*(Request the "Professional Answer" comparison under each — graded to close the platform.)*

---

## Reflection
*(After the capstone)* — What surprised you? · Which phase was hardest? · What would you add to your
detection coverage?

## Search Keywords For Further Understanding
- `linux compromise investigation end to end` · `incident response report compromised server` · `mitre
  att&ck intrusion timeline` · `ioc extraction scoping` · 🔴 `full kill chain recon→exfil` · 🔵
  `detect→investigate→contain→recover→report`

---

## Lesson Status
- [ ] Capstone executed (staged chain detected + investigated + contained + recovered)
- [ ] Full incident package committed (technical report + exec summary + evidence + lessons-learned)
- [ ] New lessons-learned detection committed (§9)
- [ ] `SOC-35` Closed
- [ ] Quiz (investigation defense) graded + Reflection + keywords
- [ ] **Final `PORTFOLIO.md`** written (whole-platform roll-up)

**This is the final lesson.** When complete, run the Update Protocol and produce the **final Portfolio
Summary** rolling up all waves — the platform is complete; you're ready to apply (`JOB_MILESTONES.md`,
`INTERVIEW-PREP.md`). The bridge stands: NaviOps (Linux) + NaviOpsNetwork (networking/NOC) + NaviOpsSec
(security operations).

---

*Lesson 35 written by Navi · 2026-06-20 · full-depth. Plan: `capstones/35-security-analyst-capstone.md`;
scenario: `workflows/compromised-server-scenario.md`. Sources: NIST SP 800-61r2, MITRE ATT&CK, the
Cyber Kill Chain.*
