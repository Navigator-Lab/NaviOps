# ENT-03 / INC-0032 — BSOD on dock connect after update

```
TICKET:   INC-0032            TYPE: Incident (→ Problem raised)
PRIORITY: P2  (Impact Med × Urgency High)
USER:     erin@corp.example    ASSET: LT-0431   VERIFIED: portal session
OPENED:   2026-06-21 08:05     SLA: 1h respond / 8h resolve   CHANNEL: portal
ASSIGNED: T2                   STATUS: New → In Progress → Resolved → Closed
```

**SUMMARY** — BSOD on dock connect after overnight update on LT-0431. Rolled back display driver +
uninstalled the problem update; pinned for patch-ring review. Stable after fix.

**SYMPTOM** — BSOD (BugCheck **VIDEO_TDR_FAILURE**) every time the docking station is connected;
began the morning after the overnight update. Reproducible.

**SCOPE** — single user confirmed; pattern ("after update" + specific dock) suggests **fleet risk** →
problem ticket.

**DIAGNOSIS**
1. Stop code = **display-driver** fault.
2. Update history (`Get-Hotfix` / Settings) → display driver + cumulative update installed overnight.
3. Rolled back driver → reconnected dock → **no BSOD** (confirmed cause).
**CAUSE:** display-driver regression delivered with the update; interacts with the docking station.

**RESOLUTION**
- Device Manager → **rolled back** the display driver.
- **Paused** that driver update; confirmed dock works dual-monitor.

**ESCALATION** — raised a **Problem ticket** (Lesson 32) for the same model + dock fleet-wide;
notified the **patch owner** to hold the driver in the deployment ring (Lesson 26).

**FOLLOW-UP** — monitor for the same stop code across the model; KB drafted; close Erin's incident on
confirmation (problem stays open until fleet remediation lands).

**TIME SPENT:** 40 min · **RESOLUTION CATEGORY:** OS/Endpoint (post-patch regression)

---
*Teaching note (Lesson 03 §6):* one user's BSOD + "after the update" + a shared model/dock = an
early signal of a **fleet problem**, not just a ticket. Capturing the **stop code** and **update
history** in the note is what lets problem management find the cluster fast.
