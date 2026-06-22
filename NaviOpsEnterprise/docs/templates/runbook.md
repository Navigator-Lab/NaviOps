# Runbook Template

> Copy into `docs/runbooks/`. **Audience: the technician.** A runbook is "when X happens, do
> exactly this." Repeatable, ordered, with verification at each gate. Sanitize.

```
# Runbook — <task / trigger, e.g. "New User Onboarding" or "Printer Offline">

**Trigger:** <the ticket/condition that starts this>
**Role/access needed:** <T1 / T2 / AD write / M365 admin>
**Time estimate:** <mm>   **Owner:** <team>   **Last reviewed:** <YYYY-MM-DD>

## Pre-checks (don't skip)
- [ ] Identity verified (if account-related)
- [ ] Scope confirmed (one user vs many)
- [ ] <other pre-condition>

## Procedure
1. **<Step name>** — <exact action, GUI and/or command>
   - *Verify:* <what tells you this step worked>
2. **<Step name>** — <action>
   - *Verify:* <check>
3. ...

## PowerShell / automation (where applicable)
```powershell
# <the command/snippet that does this at scale; use -WhatIf first>
```

## Rollback / if it goes wrong
- <how to undo / safe state>

## Escalate if
- <condition> → to <team>, attach <package>

## Document
- Ticket note (template: ticket-note.md); update the KB if user-facing.
```
```
