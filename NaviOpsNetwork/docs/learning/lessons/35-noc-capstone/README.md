# Lesson 35 — NOC Capstone

**Status:** ✅ ready for self-study (full depth) · **Date written:** 2026-06-20
**Schema:** 12-section (`docs/learning/CLAUDE_TEACHING_RULES.md`)
**Focus:** run a simulated 24/7 NOC shift end-to-end — monitor → alert → ticket → triage → escalate
→ handover.
**Primary artifact:** the shift ticket trail + incident runbooks + handover (full plan:
[`capstones/35-noc-capstone.md`](../../capstones/35-noc-capstone.md)).

> **How to use this lesson:** this is a **simulation**, not a reading — you operate a NOC shift
> against your monitoring stack while faults are injected. The detailed plan is in
> `docs/learning/capstones/35-noc-capstone.md`. Prereqs: Lessons 01–27 + all NOC modules. Lab only.

---

## §1 — Concept (Scientific Theory)

The NOC Capstone integrates the **monitoring + operations** modules into the actual job: operating
a Network Operations Center shift. It proves you can do what a NOC Technician is hired for — watch
dashboards (normal vs abnormal), handle alerts (`noc/alert-handling.md`), open/route tickets
(`noc/ticketing.md`), triage and troubleshoot (Lesson 18), escalate with a clean handoff
(`noc/escalation-matrix.md`), document incidents (Lesson 26), and hand over cleanly
(`noc/shift-handover.md`) — all under realistic time pressure, measured by MTTD/MTTR
(`noc/sla-concepts.md`).

You run a **simulated shift** against the monitoring stack you built (Lesson 22/23). A driver (a
script or a second person) injects faults from `troubleshooting-drills.md` at unknown times; you
operate the shift as if it were real.

---

## §2 — Linux Networking Commands (the NOC operating loop)
Per alert, you run the full diagnostic toolkit from the curriculum:
```bash
# the bottom-up method (L18) + the right tool per scenario (noc/noc-scenarios.md):
net_diag.sh ; mtr -rwc 50 <dest> ; dig +short <name> ; nc -vz <host> <port>
dns_check.sh ; latency_monitor.sh ; capture_triage.sh <if> "<bpf>"   # your own scripts
journalctl --since "..."   ; nft list ruleset   ; ip route            # state + evidence
```
The Grafana/Zabbix dashboard is the NOC screen; the alerts are the work queue.

---

## §3 — Real-World Use Cases
This *is* the NOC Technician job, simulated end-to-end — the most direct possible proof for a NOC
interview. "Walk me through a shift / an incident you handled" is answered by this capstone's
artifacts.

---

## §4 — Troubleshooting Section
Each injected fault (3–4 over the shift, mixed severity, from the 8 drills) is triaged and resolved
with the bottom-up method and the scenario playbooks (`noc/noc-scenarios.md`): DNS outage, high
latency, firewall block, interface flap, etc. Evidence is captured *into the ticket* before any
change.

---

## §5 — Common Mistakes
The NOC-discipline failures: wrong severity/scope on triage; changing things before capturing
evidence; weak escalation (no handoff packet); alert fatigue (ignoring the queue); no documentation;
a sloppy handover that drops an open incident. The grading rubric (capstone plan) checks each.

---

## §6 — NOC Perspective
This lesson *is* the NOC perspective, fully exercised. It synthesizes every `docs/learning/noc/`
module into one operating loop:
```
alert ─► triage (sev+scope) ─► open ticket ─► acknowledge ─► diagnose (runbook + evidence)
   ─► fix OR escalate (handoff packet) ─► verify ─► resolve+document (RCA) ─► tune the alert
   ... and at shift end: write the handover (with the deliberately-still-open incident)
```

---

## §7 — Incident-Response Perspective
Every injected fault is a full IR lifecycle (Lesson 26): detect (the alert) → triage → contain →
diagnose (RCA) → fix → recover → document. The capstone requires one incident **escalated** with a
complete Tier-2 handoff packet, and reports **MTTD/MTTR** per incident — making the IR + SLA theory
concrete and measured.

---

## §8 — Practical Lab (the capstone itself)
Follow [`capstones/35-noc-capstone.md`](../../capstones/35-noc-capstone.md): stand up the monitoring
stack as the NOC screen, define alerts so faults *fire* as alerts, then run the shift — injecting
3–4 incidents (a Sev1 DNS outage, Sev2 latency, Sev2 firewall-block, Sev3 iface flap) and operating
each through the loop.

**Lens C (automation):** a fault-injection driver (`tc netem`, stop a service, add a drop rule) +
your detection/diagnostic scripts = a repeatable NOC simulation. **Lens D:** the alerts are driven
by real metrics/logs (Lessons 22–25), so the simulation exercises the actual signal path.

---

## §9 — GitHub Artifact (evidence 5-tuple)
1. **Script:** the fault-injection driver + your diagnostic scripts used during the shift.
2. **Config:** the monitoring stack + alert rules that fired (`infra/monitoring/`).
3. **Drill:** the injected incidents (3–4), each resolved/escalated.
4. **NAVI ticket:** `NAVI-35` master Incident referencing one `NAVI-NN` per injected fault.
5. **Incident reports:** one runbook per incident + the **shift handover** doc + shift metrics
   (MTTD/MTTR). Plus the milestone **`PORTFOLIO.md`**.

---

## §10 — Portfolio Artifact
- **Resume bullet:** "Ran a simulated 24/7 NOC shift end-to-end: monitored a Grafana/Zabbix
  dashboard, triaged and resolved N injected incidents with full ticket trails, escalated a Sev1
  with a complete handoff packet, reported MTTD/MTTR, and produced a clean shift handover."
- **Interview talking point:** the entire NOC operating loop, demonstrated — the single most
  compelling NOC-hire artifact (it *is* the job).
- **Serves:** NOC Technician (Stage 1) — the capstone of the primary near-term target.

---

## §11 — RHCSA Crossover Notes
The diagnostic toolkit (`journalctl`, `ss`, `ip`, log review) and structured operations apply to
RHEL administration; the discipline transfers to any ops role. (NOC tooling itself is N/A for RHCSA.)

---

## §12 — Security Notes (Lens E — Attacker & Defender)
Include at least one **security-flavored** alert in the shift (a port-scan or brute-force signal,
Lesson 28) so the NOC loop covers the **NOSC** (blended NOC/security) reality: triage it (TP/FP +
ATT&CK), contain (block the source, Lesson 15), escalate to security. This shows you can handle the
security alerts increasingly landing in the NOC.

---

## Quiz (Interview-Style — defend your shift)
**Q1.** Walk through how you handled one injected incident from alert to closure.
> **Your answer:**

**Q2.** How did you decide severity and scope for each incident, and how did that drive escalation?
> **Your answer:**

**Q3.** What was your MTTD and MTTR for the Sev1, and what would reduce them?
> **Your answer:**

**Q4.** **Scenario:** Mid-shift you have three alerts at once. How do you prioritize?
> **Your answer:**

**Q5.** What did your shift handover include, and why leave one incident deliberately open?
> **Your answer:**

*(Request the "Professional Answer" comparison under each — graded before Lesson 36.)*

---

## Reflection
*(After completion)* — What was hardest under time pressure? · Where did your process break down? ·
What would you standardize?

---

## Search Keywords For Further Understanding
- `noc shift operations workflow`
- `incident triage severity scope`
- `mttd mttr noc metrics`
- `escalation handoff packet`
- 🔴 `security alert in noc nosc` · 🔵 `noc security triage attack mitre`

---

## Lesson Status
- [ ] Simulated shift run; all injected incidents resolved/escalated
- [ ] Ticket trail + per-incident runbooks + shift metrics committed
- [ ] Escalation packet + shift handover written (§9)
- [ ] `PORTFOLIO.md` written (§10)
- [ ] Quiz (shift defense) answered + professional-answer comparisons + reflection

When complete, run the Update Protocol, then move to **Lesson 36 — Network-Security Capstone**.

---

*Lesson 35 written by Navi · 2026-06-20 · full-depth. Detailed plan:
[`capstones/35-noc-capstone.md`](../../capstones/35-noc-capstone.md). Sources: `docs/learning/noc/`
modules, Google SRE (incident/SLO).*
