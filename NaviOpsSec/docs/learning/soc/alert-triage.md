# Alert Triage — SOC Module

The core T1 skill: turn a stream of alerts into a small set of real, prioritized incidents.

## The alert lifecycle

```
   fire ──► triage ──► acknowledge ──► investigate ──► decide ──► resolve ──► tune
    │          │            │              │             │           │          │
  SIEM      TP or FP?    I own it       scope +       escalate    close +    fix the
  rule      sev/impact   (stop the      timeline +    or          document   rule if it
  fires     dedup        clock)         IOCs          contain                was noise
```

## The triage decision tree

```
 alert fires
    │
    ├─ Is it a TRUE positive?  ── no ──► close as FP  ──► (tune the rule so it won't refire)
    │        │ yes
    │        ▼
    ├─ How severe?  (Sev1 outage/active intrusion … Sev4 informational)
    │        ▼
    ├─ What's the SCOPE?  one host / one user  vs  many hosts / spreading
    │        ▼
    ├─ Enrich:  IOC reputation, asset criticality, recent changes, the user's normal baseline
    │        ▼
    └─ Decide:  ESCALATE (T2/IR) for confirmed/spreading/high-impact  │  HANDLE in shift  │  CLOSE+tune
```

## True positive vs false positive (the judgement call)

- **True positive (TP):** the activity is real *and* malicious/policy-violating. Work it.
- **False positive (FP):** the rule fired but the activity is benign (a vuln scan from your own
  team, a backup job, an admin's expected `sudo`). Close it **and tune** so it won't refire.
- **Benign true positive:** the activity is real but authorized (a pentest, a sanctioned admin
  action) — close with a note, don't tune away the detection.
- **False negative:** the attack happened and *no* alert fired — the most dangerous case;
  surfaced by threat hunting (Lesson 25) and post-incident review.

## Severity rubric (typical SOC)

| Sev | Meaning | Example | Response |
|---|---|---|---|
| **Sev1 / Critical** | active intrusion / data at risk / major service impact | confirmed C2, ransomware, admin account takeover | immediate, escalate to IR, comms |
| **Sev2 / High** | likely-malicious, contained scope | successful brute-force login, web exploit attempt that hit | urgent, escalate to T2 |
| **Sev3 / Medium** | suspicious, needs investigation | repeated failed logins, port scan, anomalous process | handle in shift |
| **Sev4 / Low / Info** | policy/hygiene/informational | expired cert, expected scan, single failed login | track, batch, or tune |

## Alert fatigue — the SOC's real enemy

Too many low-value alerts and the analyst stops reading them — and the Sev1 hides in the Sev4
noise. Counter it the same way every shift:
- **Deduplicate / group** — 500 "failed login" alerts from one brute-force source = one incident.
- **Correlate** — failed logins + a successful login + a new process from the same IP = one
  intrusion, not three alerts.
- **Suppress known-benign** — your own vuln scanner, backup windows, maintenance.
- **Tune at review** — every FP gets a rule fix. An alert nobody trusts is worse than none.

## Lesson tie-in
- Lesson 17 (Alert Triage Fundamentals) builds the triage playbook.
- Every detection lesson (18–24) produces an alert this process consumes.
- Lesson 34 (SOC Operations Project) runs a full simulated queue through it.
