# Root Cause Analysis (RCA) Template

> For major or recurring incidents (Lesson 32). Blameless — focus on the system, not the person.
> Sanitize.

```
# RCA — <short title>

**Related incident:** <INC-xxxx>   **Date of incident:** <YYYY-MM-DD>   **Author:** <role>
**Severity:** <P1/P2>   **Status:** Draft | Final

## 1 · Problem statement
<one precise sentence: what failed, measurable impact.>

## 2 · Timeline
<key timestamped events — detection to resolution>

## 3 · Investigation (the 5 Whys)
- **Why did <symptom> happen?** → <answer>
- **Why did <that> happen?** → <answer>
- **Why…?** → <answer>
- **Why…?** → <answer>
- **Why…?** → <root cause>

*(Or a fishbone/Ishikawa across People / Process / Technology / Environment.)*

## 4 · Root cause
<the single underlying cause — not the symptom, not "human error" as a stopping point>

## 5 · Contributing factors
- <thing that made it worse / let it happen / delayed detection>

## 6 · Corrective & preventive actions
| Action | Type (corrective/preventive) | Owner | Due | Status |
|---|---|---|---|---|
| <fix the cause> | corrective | <role> | <date> | open |
| <stop recurrence> | preventive | <role> | <date> | open |

## 7 · How we'll know it worked
<the metric/monitor/test that proves the fix held>
```
```
