# Troubleshooting Guide Template

> Copy into `docs/troubleshooting/`. This is the **diagnostic spine** in document form
> (`navi.project.md` Hard Rule #4). Audience: the technician. Sanitize.

```
# Troubleshooting — <problem class, e.g. "No Internet Connectivity">

**Applies to:** <devices/users/app>   **Owner:** <team>   **Last reviewed:** <YYYY-MM-DD>

## 1 · Symptoms
- <what the user reports>
- <what you observe / exact errors / Event IDs>

## 2 · Possible Causes (most-likely first)
1. <cause> — <how common / when>
2. <cause>
3. ...

## 3 · Diagnostic Steps (ordered, cheap-first)
| # | Check (GUI / command) | If this… | …then |
|---|---|---|---|
| 1 | <e.g. `ipconfig /all`> | <observation> | <branch / next> |
| 2 | <check> | <observation> | <branch> |

## 4 · Resolution Steps (per cause)
- **Cause A:** <fix>
- **Cause B:** <fix>

## 5 · Escalation Criteria
- Escalate to <T2/T3/vendor> when: <condition>. Attach: symptom, exact error, steps tried +
  results, suspected cause, scope, SLA clock.

## 6 · Post-Incident Documentation
- Ticket note (resolution category, root cause).
- KB update if user-facing; problem ticket if recurring; RCA if it was a major incident.
```
```
