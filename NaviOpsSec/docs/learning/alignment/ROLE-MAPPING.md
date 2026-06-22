# NaviOpsSec — Role Mapping (the three-platform career bridge)

How the three NaviOps platforms combine into one realistic career path, and exactly which
artifacts to lead with for each role.

## The path

```
 NaviOpsNetwork        NaviOps              NaviOps + NaviOpsSec        NaviOpsSec
 ─────────────         ───────              ────────────────────        ──────────
 NOC Technician  →  Linux Support  →  Junior SysAdmin  →  Security Analyst  →  Security Operations Engineer
                                                              │
                                                              ├─►  SOC Analyst T1 → T2
                                                              ├─►  Incident Responder
                                                              └─►  Junior Detection Engineer
```

Security Operations is not an entry point from zero — it sits **on top of** Linux fluency
(NaviOps) and network literacy (NaviOpsNetwork). You investigate Linux hosts, read network
evidence, and reason about both to catch an attacker. That's why this is the third platform.

## Role → what you need → which platform/lessons prove it

| Target role | Foundation (sibling) | NaviOpsSec lessons | Lead artifacts |
|---|---|---|---|
| **Security Analyst (entry)** | NaviOps Linux basics; NaviOpsNetwork NOC triage | 01–06, 17 | `log_triage.sh`, auditd config, triage playbook, first SOC-NN tickets |
| **SOC Analyst Tier 1** | NaviOpsNetwork (alerts/escalation/SLA); NaviOps (Linux) | 07–20 | Wazuh stack, brute-force/port-scan detections + rules, detection runbooks |
| **SOC Analyst Tier 2** | + NaviOps process/user/service depth | 21–24, 28–30 | process/user/web investigation scripts, IR reports w/ timelines + RCA |
| **Incident Responder (jr)** | NaviOpsNetwork network IR; NaviOps recovery | 28–29, 35 | the CER playbook, the capstone incident package, exec summaries |
| **Junior Detection Engineer** | NaviOps scripting; NaviOpsNetwork detection (Suricata/Wazuh) | 25–27, 32–33 | Sigma rules, Wazuh ruleset, ATT&CK coverage map, hunt reports |
| **Security Operations Engineer** | all three platforms | 31, 34–35 | the full `infra/` stack, the SOC shift report, the capstone |

## What each sibling platform contributes (don't re-teach it here)

- **NaviOps (Linux/SysAdmin):** users/groups/permissions, processes/services (`systemd`), the
  filesystem, package mgmt, SSH hardening, cron, RHCSA. NaviOpsSec *investigates* these; it
  assumes you can operate them. Lesson §11 (cert crossover) and §2 note where prior Linux skill
  is the prerequisite.
- **NaviOpsNetwork (Networking/NOC):** OSI/TCP-IP, packet capture (`tcpdump`/Wireshark),
  firewalls (`nftables`), monitoring (Prometheus/Grafana/SNMP/syslog), NOC alert-handling/
  escalation/SLA, and an intro network-security/Suricata/Wazuh thread. NaviOpsSec reuses the
  network evidence skills (Lesson 07, 20) and the NOC alert-ops discipline (the `soc/` modules
  are the security analog of NaviOpsNetwork's `noc/` modules).
- **NaviOpsSec (this platform):** detection engineering, SIEM/Wazuh in depth, alert triage &
  investigation, threat hunting, incident response, and report writing — the Blue-Team layer.

## The one-line bridge (use on every application)

> "Linux SysAdmin + Network Operations + Security Operations, each a public, artifact-backed
> build log: I investigate Linux hosts and network evidence and engineer the detections that
> catch attackers."
