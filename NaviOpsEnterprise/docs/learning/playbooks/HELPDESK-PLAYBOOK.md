# Help Desk Playbook — NaviOpsEnterprise

The operating manual for working a Tier-1/Tier-2 service-desk queue. This is the behavior the
lessons train and the capstones grade. Pair with [`IT-SUPPORT-PLAYBOOK.md`](IT-SUPPORT-PLAYBOOK.md)
and the ITIL lesson (17).

## The prime directives
1. **Acknowledge fast, set expectations always.** A user who knows what's happening and when is a
   calm user. Never go silent on an open ticket.
2. **Verify identity before you change anything.** Especially for password resets, access grants,
   and anything touching another person's account. (See Lesson 29.)
3. **Fix the user, then fix the cause.** Restore service first; capture the root cause for the
   ticket/problem record.
4. **Document so the next tech doesn't start over.** The ticket note is the deliverable.
5. **Escalate with a package, not a shrug.** When it leaves you, it leaves *complete*.

## The ticket lifecycle (every ticket)

```
 New ─▶ Acknowledged ─▶ Triaged ─▶ In Progress ─▶ (Escalated?) ─▶ Resolved ─▶ Closed
   │         │             │            │              │              │           │
 logged   greet +       priority    diagnose +     handoff w/      confirm     user
          set ETA       (I×U)       resolve        package         w/ user     confirms
```

### 1 · Intake
Capture in the user's words + the facts: who (and verified how), what they see (exact error),
when it started, what changed, scope (just them? whole floor?), and business impact.

### 2 · Triage & priority — impact × urgency
| | **Urgency High** | **Urgency Med** | **Urgency Low** |
|---|---|---|---|
| **Impact High** (many users / critical service) | **P1** | P2 | P3 |
| **Impact Med** (a team / degraded) | P2 | P3 | P4 |
| **Impact Low** (one user / cosmetic) | P3 | P4 | P4 |

P1 = drop everything + declare incident (Lesson 31). P4 = scheduled/standard request.

### 3 · Diagnose & resolve — the spine
Always: **Symptoms → Possible Causes → Diagnostic Steps → Resolution Steps → Escalation Criteria
→ Post-Incident Documentation.** Start with the cheapest, most-likely check. Confirm the fix
*with the user* before resolving.

### 4 · Escalate (when)
Escalate to T2/T3/vendor when: it exceeds your access/skill, it's past the SLA risk threshold,
it's a known problem owned elsewhere, or it's a P1/major incident. **The handoff package:**
- Ticket #, verified user, asset
- Symptom + exact error + screenshots
- What you've already tried (and the result)
- Your suspected cause + why
- Business impact + SLA clock

### 5 · Close
Resolution confirmed by the user → write the closing note → set resolution category → ask for
CSAT if your tool prompts it. If it'll recur, spin a **KB article** (Lesson 28).

## The professional ticket note (template)
```
SUMMARY:  <one line — what was wrong and what fixed it>
VERIFIED: <how you confirmed the user's identity>
SYMPTOM:  <what the user reported / you observed; exact error>
CAUSE:    <root cause, or "suspected" if escalated>
ACTIONS:  1) <step> → <result>
          2) <step> → <result>
RESOLUTION: <the fix; user confirmed at HH:MM>
FOLLOW-UP:  <KB created/updated? problem ticket? none>
```

## First-Contact Resolution (FCR) targets — the common 80%
These should be resolved at T1 without escalation:
- Password reset / account unlock (Lesson 21)
- Printer offline / spooler (Lesson 10)
- Basic connectivity / Wi-Fi (Lesson 08)
- Outlook profile / send-receive (Lesson 13)
- Browser / SSO login (Lesson 14)
- Software install request (standard catalog) (Lesson 25)
- M365 / OneDrive / Teams how-to (Lesson 11)

## Metrics you're measured on
| Metric | What it means | How you move it |
|---|---|---|
| **FCR** | % resolved on first contact | Master the common 80%; good KBs |
| **MTTR** | mean time to resolve | Tight triage, don't sit on tickets |
| **Response time / SLA** | time to first acknowledge | Acknowledge immediately |
| **CSAT** | customer satisfaction | Communicate + set expectations |
| **Backlog / aging** | open tickets getting old | Work oldest-at-risk first |

## Communication scripts
- **Greeting:** "Thanks for reaching out — I can help with that. To confirm I'm working with the
  right account, can you verify <identity check>?"
- **Setting an ETA:** "I'll have an update for you by <time>. If I need more from you I'll reach
  out here."
- **Escalating:** "This needs our <team> to resolve. I've passed them everything so you won't have
  to repeat yourself; expect contact by <SLA>."
- **Closing:** "That should be resolved — can you confirm it's working on your end before I close
  this out?"
