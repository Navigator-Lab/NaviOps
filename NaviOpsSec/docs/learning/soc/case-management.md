# Case Management — SOC Module (the `SOC-NN` ticket)

A SOC runs on tickets. The case is the **system of record** for an incident: every action,
finding, and decision is logged so the investigation is reproducible, hand-offable, and
defensible. This is the security analog of NaviOps' `NAVI-NN` scheme.

## The `SOC-NN` lifecycle

```
 To Do ──► Investigating ──► Contained ──► Eradicated ──► Closed
   │             │               │              │            │
 alert        TP confirmed,   attacker      threat        recovered,
 created      timeline +      blocked/      removed,      report written,
 (or hunt)    IOCs building   isolated      persistence   lessons learned,
                                            cleared       rule tuned
                                  │
                                  └──► (or) Closed-FP / Closed-Benign  (with note + tuning)
```

One ticket per incident (not per alert — dedup related alerts into one case). In this platform,
each **lesson** produces one `SOC-NN` ticket so the operator practices the lifecycle every time.

## What every case must contain

| Field | Why |
|---|---|
| **ID / title / severity** | identify + prioritize |
| **Affected asset(s) + owner** | scope + who to notify |
| **Detection source** | which rule/alert/hunt found it (provenance) |
| **Timeline** | timestamped actions + findings (the spine of the report) |
| **IOCs** | host/network/file indicators extracted |
| **ATT&CK mapping** | technique IDs per stage |
| **Actions taken** | every containment/eradication/recovery step (+ who, when) |
| **Evidence links** | logs, captures, hashes (sanitized, in `docs/runbooks/` or evidence pkg) |
| **Resolution + lessons learned** | outcome + the detection/control to add |

## Case hygiene (the habits that make you trusted)

- **Timestamp everything in UTC.** "02:14Z" beats "around 2-ish."
- **Write as you go**, not after — memory rewrites the timeline.
- **Facts vs assessment** — separate "auth.log shows X" (fact) from "this looks like brute force"
  (assessment). Reports and courts care about the difference.
- **Preserve before you act** — note that you collected evidence *before* containment.
- **Close with a reason** — TP-resolved / FP-tuned / benign-authorized. A case closed without a
  reason teaches nobody.

## Lesson tie-in
Lesson 17 (triage) opens cases; Lessons 28–30 (IR + reporting) close them with full reports;
Lesson 34 (SOC ops) runs many cases through the board at once.
