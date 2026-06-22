# The Compromised-Server Scenario (Capstone — Lesson 35)

The platform's final, realistic, end-to-end incident. You stage a **benign, self-owned**
intrusion chain on a lab Linux server, then play the **defender**: investigate, identify IOCs,
build the timeline, contain, recover, and report. This is the spec's "complete real-world
scenario."

> **Authorization & safety (`navi.project.md` Hard Rule #2 + Danger Zones):** the "attacker" is
> *you*, on your *own* lab VM, with *benign* payloads (no real malware, no third-party target).
> The point is to produce realistic telemetry to defend against. Sanitize everything before
> commit.

## The lab

```
            ┌──────────────────────── lab network 10.0.0.0/24 ────────────────────────┐
            │                                                                          │
  attacker  │   web01.lab.example (10.0.0.20)        wazuh-mgr (10.0.0.10)             │
  (you)  ───┼─►  Linux server (the victim)  ──agent──►  Wazuh manager + dashboard      │
  kali/host │   - SSH, a small web app                  (your SIEM — the defender view) │
            │   - Wazuh agent installed                                                │
            └──────────────────────────────────────────────────────────────────────────┘
```

## The staged chain (attacker side — run once, then switch to defender)

Each stage is benign and maps to a kill-chain stage + ATT&CK technique:

| # | Stage | Action (lab, benign) | Kill chain | ATT&CK |
|---|---|---|---|---|
| 1 | Recon | `nmap` the lab host from your own attacker box | Reconnaissance | T1046 |
| 2 | Initial access | SSH **brute force** a deliberately weak lab cred → success | Delivery/Exploitation | T1110 → T1078 |
| 3 | Execution | run a benign "payload" (a marked script, e.g. writes a flag file, opens a listening socket) | Installation | T1059 |
| 4 | Persistence | add a cron job **and** an `authorized_keys` entry **and** a rogue user | C2/Persistence | T1053, T1098/T1136 |
| 5 | Defense evasion | truncate/clear part of a log to simulate tampering | — | T1070 |
| 6 | Discovery / lateral prep | enumerate users + reach toward a second lab host | Actions on objectives | T1087, T1021 |
| 7 | "Exfil" | copy a marked dummy file out (benign) | Exfiltration | T1041 |

## The defender mission (what you produce — the capstone package)

Switch hats. Using only the **Linux host evidence + the Wazuh SIEM**, reconstruct and respond:

1. **Investigate** — find each stage from the evidence (don't peek at the script; work the logs).
2. **Identify IOCs** — the attacker IP, the abused/created accounts, the cron/key/file artifacts,
   the dummy-exfil file hash.
3. **Determine the attack timeline** — every stage in UTC order, mapped to ATT&CK + the kill
   chain.
4. **Contain** — *after preserving evidence*: block the IP, disable the accounts, isolate the
   host.
5. **Eradicate** — remove the cron job, the key, the rogue user, the payload; close the SSH
   vector (key-only auth, strong creds).
6. **Recover** — restore service, validate the host is clean, confirm IOCs gone.
7. **Technical report** — full detail for the security team (`templates/incident-report.md`).
8. **Executive summary** — impact + actions for leadership (`templates/executive-summary.md`).
9. **Evidence package** — collected logs/captures/hashes, sanitized (`templates/evidence-package.md`).
10. **Lessons learned** — the detection that would have caught stage 2 sooner; commit it as a
    Wazuh/Sigma rule.

## Which lessons each stage exercises

- Stage 1 (recon) → Lessons 07, 20.
- Stage 2 (brute force → login) → Lessons 18, 19.
- Stage 3 (execution) → Lesson 21.
- Stage 4 (persistence) → Lessons 22, 24.
- Stage 5 (log tampering) → Lessons 06, 24.
- Stage 6–7 (discovery/lateral/exfil) → Lessons 21, 22, 07.
- Detection + IR + reporting throughout → Lessons 13–17, 28–30.

## Done when

The 10-item package is committed and sanitized, `SOC-35` is Closed, the capstone quiz is answered
to a professional standard, and `lessons/35-security-analyst-capstone/PORTFOLIO.md` rolls up the
whole platform. Rubric: `../CAPSTONE-GUIDE.md`.
