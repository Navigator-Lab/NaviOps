# NaviOpsSec — LinkedIn Guide

How to present the Blue-Team build log on LinkedIn so it reads as a working analyst, not a
student. Same rule: **claim = committed evidence**.

## Headline (pick the role you're applying to)

- Entry: `Security Analyst | Blue Team | Wazuh · MITRE ATT&CK · Linux IR | building a public SOC lab`
- T1: `SOC Analyst (Tier 1) | SIEM (Wazuh) · Detection · Alert Triage | Security+ / BTL1`
- Detection: `Detection Engineer (Junior) | Sigma · Wazuh · ATT&CK coverage | detection-as-code`

## About section (template)

> Blue-Team-focused. I build and operate a real Security-Operations lab in public — a Wazuh
> SIEM, custom detections (Sigma + Wazuh rules) mapped to MITRE ATT&CK, alert-triage and
> investigation workflows, and full incident-response with technical reports + executive
> summaries.
>
> Background: Linux SysAdmin + Network Operations (NOC), now Security Operations. I investigate
> Linux hosts and network evidence directly (`journalctl`/`auditd`/`tcpdump`) and in the SIEM,
> and I engineer the detections that catch attackers.
>
> Everything is public and artifact-backed: [link to NaviOpsSec] · [NaviOps] · [NaviOpsNetwork].

## Posts that work (the "build in public" cadence)

Post a short write-up when you finish a meaningful lesson/milestone. The pattern that gets
engagement from security folks:

1. **The detection story** — "I wanted to catch SSH brute force. Here's the auth-log signal, the
   Wazuh rule, the FP I had to tune, and the ATT&CK mapping (T1110)." + a sanitized screenshot.
2. **The investigation walkthrough** — "Suspicious process on a lab host: how I went from the
   alert to the parent-child tree to the reverse shell to containment." + the timeline.
3. **The lesson-learned** — "What surprised me building FIM with Wazuh syscheck."
4. **The milestone** — "Finished the SOC-operations project: triaged a simulated shift of N
   alerts, here's what I escalated and why."

**Rules:** always sanitize (a real IP/cred in a security post is disqualifying). Always link the
artifact. Teach one concrete thing per post. Map to ATT&CK — security hiring managers read for it.

## Skills to list (only what you can demo)

Wazuh · SIEM · MITRE ATT&CK · Sigma · Incident Response · Threat Hunting · Detection Engineering ·
Linux (log analysis / auditd) · Alert Triage · `tcpdump`/`tshark` · Bash · Cyber Kill Chain · IOCs.

Endorsements/claims must trace to a committed artifact. If you can't open the repo and show it,
it doesn't go on the profile.
