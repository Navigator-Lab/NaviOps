# ENT-02 / INC-0015 — Laptop powers on, black screen

```
TICKET:   INC-0015            TYPE: Incident
PRIORITY: P3  (Impact Low × Urgency Med)
USER:     carol@corp.example   ASSET: LT-0428   VERIFIED: portal session (logged-in user)
OPENED:   2026-06-21 09:20     SLA: 4h respond / 1bd resolve   CHANNEL: portal
ASSIGNED: Desktop Support      STATUS: New → In Progress → Resolved → Closed
```

**SUMMARY** — LT-0428 no internal display (powers on, keyboard lit). External monitor showed image →
isolated to internal panel/backlight. Issued loaner; sent to depot for panel replacement.

**SYMPTOM** — black screen, system running (fans, keyboard backlight on).

**SCOPE** — single device/user; spare available → not critical.

**DIAGNOSIS**
1. **External monitor test** → image present on external → GPU/board OK; fault is the display path.
2. **Flashlight test** on the panel → no faint image → **backlight out** (not just low brightness).
**CAUSE:** failed internal display panel/backlight (hardware).

**RESOLUTION**
- Verified user data already in **OneDrive** (no data at risk).
- Issued loaner **LT-0455**; updated asset record to reflect loaner assignment.
- Opened **RMA** with vendor (unit in warranty) for panel replacement.

**ESCALATION** — to **depot/vendor (T3)** for panel replacement (in-warranty; don't self-repair).
Package: symptom, external-monitor + flashlight test results, asset tag, warranty status.

**FOLLOW-UP** — return loaner on repaired-unit receipt; close on user confirmation.

**TIME SPENT:** 25 min · **RESOLUTION CATEGORY:** Hardware

---
*Teaching note (Lesson 02 §6):* the **external-monitor test** is the decisive diagnostic — it splits
"display panel" from "GPU/board" in one step. Data-first + loaner keeps the user productive while
the slow vendor repair runs in the background.
