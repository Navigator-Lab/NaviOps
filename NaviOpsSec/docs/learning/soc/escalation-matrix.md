# Escalation Matrix — SOC Module

Who handles what, and when an analyst hands an incident up. Escalating too early wastes T2/IR
time; escalating too late lets an intrusion spread. The matrix removes the guesswork.

## SOC tiers

| Tier | Owns | Typical work |
|---|---|---|
| **Tier 1 (Analyst)** | the alert queue | monitor, triage, TP/FP, basic investigation, close FPs, escalate confirmed/complex |
| **Tier 2 (Investigator)** | escalated incidents | deep investigation, scoping, containment decisions, host/network forensics |
| **Tier 3 / IR / Detection Eng** | major incidents + detection content | full IR, threat hunting, malware analysis, new detections, tuning |
| **SOC Lead / Manager** | comms + coordination | stakeholder comms, bridge calls, major-incident command |

## When T1 escalates to T2 (escalation triggers)

Escalate immediately when **any** of these is true:
- A login/brute-force attempt **succeeded** (not just attempted).
- Evidence of **code execution**, a **new/modified account**, **persistence**, or **lateral
  movement**.
- **Multiple hosts** show the same indicator (it's spreading).
- A **critical asset** (DC, database, jump host) is involved.
- The activity matches a **known threat-intel IOC** with a confirmed hit.
- You **can't determine TP/FP** with the T1 toolset within the SLA window.

When you escalate, **hand over the work, not just the alert**: ticket number, what you've
confirmed, the timeline so far, the IOCs, and what you've already tried.

## When T2 escalates to IR / T3

- Confirmed intrusion with active attacker or data exfiltration.
- Ransomware / destructive activity.
- Scope beyond what containment-in-shift can handle.
- Legal/compliance/PII exposure (triggers notification clocks).

## The escalation note (what to include)

```
Ticket: SOC-NN          Severity: Sev2          Asset: web01.lab.example (10.0.0.20)
Summary: Successful SSH login from 203.0.113.50 after 240 failed attempts (T1110 → T1078).
Confirmed: brute force in auth.log; successful "Accepted password for svc_app" at 02:14Z.
Timeline so far: [link]    IOCs: 203.0.113.50, user svc_app
Done: blocked nothing yet (preserving evidence); collected auth.log + last output.
Asking T2: confirm containment plan + check for persistence/lateral movement.
```

## Lesson tie-in
Every detection lesson's §6 names the escalation trigger for that signal. Lesson 34 exercises the
full matrix on a simulated queue.
