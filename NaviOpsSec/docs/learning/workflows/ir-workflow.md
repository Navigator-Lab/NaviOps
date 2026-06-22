# The IR Workflow — Detection → Investigation → Containment → Eradication → Recovery → Lessons Learned

The 6-phase incident-response process (aligned to **NIST SP 800-61**), the spine of every
detection lesson's §7 and the capstone. Each phase has a **checklist**, the **evidence** to
collect, and how it feeds the **runbook / playbook / report**.

```
 ┌───────────┐  ┌──────────────┐  ┌────────────┐  ┌─────────────┐  ┌──────────┐  ┌──────────────────┐
 │ DETECTION │─►│ INVESTIGATION│─►│ CONTAINMENT│─►│ ERADICATION │─►│ RECOVERY │─►│ LESSONS LEARNED  │
 └───────────┘  └──────────────┘  └────────────┘  └─────────────┘  └──────────┘  └──────────────────┘
   alert/hunt     scope+timeline    stop spread      remove threat    restore +     post-incident
   fires          +IOCs             (evidence         + persistence    validate      review + new
                                     FIRST!)                            clean         detection
```

> **The golden rule:** *preserve evidence before you contain.* Containment (isolating a host,
> killing a process, blocking an IP) destroys volatile evidence — collect it first, or you can't
> write the timeline.

---

## Phase 1 — Detection
**Goal:** confirm something real is happening and open the case.
- [ ] Alert fired (SIEM/Wazuh) or hunt hypothesis confirmed.
- [ ] TP/FP decision made (`soc/alert-triage.md`).
- [ ] Severity set, SLA clock started, `SOC-NN` case opened.
- [ ] Detection source recorded (which rule/log/hunt) — provenance.
**Feeds:** the runbook's "trigger" section.

## Phase 2 — Investigation
**Goal:** understand what happened — scope, timeline, IOCs, root cause.
- [ ] **Scope:** one host/user vs many? (`ioc_sweep.sh` across hosts.)
- [ ] **Collect evidence (FIRST):** copy relevant logs off-box, capture if needed, `stat`/hash
  suspect files, snapshot process/network state (`evidence_collect.sh`).
- [ ] **Timeline:** order events in UTC from the evidence.
- [ ] **IOCs:** extract host/network/file indicators.
- [ ] **ATT&CK mapping:** technique per stage.
- [ ] **Root cause:** the entry point / initial access.
**Feeds:** investigation notes + the report timeline.

## Phase 3 — Containment
**Goal:** stop the spread without destroying evidence (it's already preserved).
- [ ] **Short-term:** isolate the host (network), block the source IP (`nftables`/firewall), kill
  the malicious process, disable the compromised account.
- [ ] **Long-term (if needed):** segment, apply temporary rules, rotate credentials.
- [ ] Record every action with timestamp + who.
**Trade-off:** short-term containment stops the bleeding but may tip off the attacker; weigh
evidence-gathering vs impact (`soc/escalation-matrix.md` — T2/IR decision).
**Feeds:** the containment playbook + report "actions taken."

## Phase 4 — Eradication
**Goal:** remove the threat and everything it left behind.
- [ ] Remove malware/webshell/dropped files.
- [ ] Remove **persistence** (cron, systemd units, `authorized_keys`, rc.local, rogue accounts).
- [ ] Close the entry vector (patch, fix config, rotate the abused credential).
- [ ] Verify nothing re-establishes (watch FIM + process + network).
**Feeds:** eradication checklist in the report.

## Phase 5 — Recovery
**Goal:** restore normal service and confirm it's clean.
- [ ] Restore from known-good (rebuild > clean when in doubt).
- [ ] Re-enable services, validate functionality.
- [ ] **Monitor closely** for reinfection (heightened detection on the asset).
- [ ] Confirm IOCs no longer present.
**Feeds:** recovery section + the "validated clean" sign-off.

## Phase 6 — Lessons Learned
**Goal:** make the next one easier to catch.
- [ ] Post-incident review: what worked, what was slow, what was missed (false negatives).
- [ ] **New/tuned detection** — the rule that would have caught it earlier (commit it).
- [ ] Update runbook/playbook with what you learned.
- [ ] Technical report + executive summary finalized; `SOC-NN` closed.
**Feeds:** lessons-learned doc + a new entry in `docs/detections/`.

---

## How it maps to the artifacts (per lesson §9)
- **Runbook** = Phases 1–2 condensed into "when this fires, do X."
- **Playbook** = the whole 6-phase play for this threat type.
- **Investigation notes** = Phase 2 working notes.
- **Incident report** = the closed-out narrative (all phases) + timeline + RCA.
- **Lessons-learned** = Phase 6.
- **Detection rule** = the Phase-6 new/tuned detection.

Templates for each: [`../../templates/`](../../templates/).
