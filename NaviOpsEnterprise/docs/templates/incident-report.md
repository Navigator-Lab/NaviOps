# Incident Report Template

> For incidents worth a writeup (outages, security events, anything that hurt). Copy into the
> lesson folder or `docs/runbooks/`. Sanitize. For root-cause depth, pair with `rca.md`.

```
# Incident Report — <short title>

**Incident ID:** <INC-xxxx>   **Severity/Priority:** <P1/P2>   **Status:** Resolved | Monitoring
**Declared:** <YYYY-MM-DD HH:MM>   **Resolved:** <HH:MM>   **Duration:** <hh:mm>
**Reporter / IC (incident commander):** <role/placeholder>

## Summary
<2–3 sentences: what happened, who was affected, how it was resolved.>

## Impact
- **Users/services affected:** <scope>
- **Business impact:** <what couldn't people do>

## Timeline (facts, timestamped)
| Time | Event |
|---|---|
| HH:MM | <detected / reported> |
| HH:MM | <triage / what was found> |
| HH:MM | <action taken> |
| HH:MM | <service restored> |

## Root cause
<what actually caused it — link the RCA if separate>

## Resolution
<what fixed it>

## Follow-up actions
| Action | Owner | Due |
|---|---|---|
| <prevent recurrence> | <role> | <date> |

## Lessons learned
- **What went well:** <…>
- **What to improve:** <…>
```
```
