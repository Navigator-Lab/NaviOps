# ENT-01 / INC-0002 — Account locked before client call

```
TICKET:   INC-0002            TYPE: Incident
PRIORITY: P2  (Impact Low-Med × Urgency High)
USER:     asmith@corp.example   ASSET: LT-0427   VERIFIED: phone identity check per policy
OPENED:   2026-06-21 13:38     SLA: 1h respond / 4h resolve   CHANNEL: phone
ASSIGNED: T1                   STATUS: New → In Progress → Resolved → Closed
```

**SUMMARY** — AD account locked from repeated bad attempts; unlocked, user signed in before client call.

**SYMPTOM** — *"None of my passwords work and now it says my account is locked. I have a client call
in 20 minutes!!"* Account state: **locked out** (not disabled, not expired).

**SCOPE** — single user; time-pressured (client call).

**DIAGNOSIS**
1. Verified caller identity (security questions per policy) → confirmed.
2. Checked account state → **lockout threshold reached** (bad-password count exceeded).
3. Account not disabled, password not expired.
**CAUSE:** account lockout from repeated bad attempts — **suspected stale cached credential** on a
mobile device or mapped drive (common re-lockout source).

**RESOLUTION**
- Unlocked the account (Lesson 21 procedure).
- **Confirmed with user at 13:41:** signed in successfully ✅. P2 SLA met.

**ESCALATION** — none required.

**FOLLOW-UP** — scheduled a check of mobile/mapped-drive cached credentials to prevent re-lockout
(root-cause prevention, not just symptom); linked KB "Account locked out — what to do."

**TIME SPENT:** 6 min · **RESOLUTION CATEGORY:** Account/Access

---
*Teaching note (Lesson 01 §6):* the value here is the **suspected root cause** + the prevention
step in FOLLOW-UP. A bare "unlocked account" note would leave the next tech blind when Alex
re-locks at 2pm from the same phone.
