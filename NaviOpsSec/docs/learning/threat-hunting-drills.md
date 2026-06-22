# Threat-Hunting & Detection Drills

The **generate-then-detect** drills used in lesson §8 labs. Each: stage benign telemetry on a
self-owned lab host, then detect + investigate it. The point is to *see the signal you'll hunt*.

> **Authorization (`navi.project.md` Hard Rule #2):** every drill runs only against your own lab
> VMs, with benign payloads. Never a third party. Sanitize all evidence before commit.

| # | Drill | Generate (lab, benign) | Detect / investigate | ATT&CK | Lesson |
|---|---|---|---|---|---|
| 1 | Failed SSH logins | `ssh baduser@lab-host` ×N (wrong pw) | `grep "Failed password" /var/log/auth.log`; Wazuh 5710 | T1110 | 18 |
| 2 | SSH brute force → success | scripted wrong-pw burst then a correct login to a weak lab cred | failed-then-accepted from one IP; frequency rule | T1110→T1078 | 19 |
| 3 | Port scan | `nmap -sS lab-host` from your own box | firewall denies / Suricata-Wazuh scan alert; `tcpdump` | T1046 | 20 |
| 4 | Suspicious process | run a benign "reverse shell" (`nc -lvnp 4444` + a `bash` child) | `ps auxf`, `ss -tunap`, `/proc/<pid>` | T1059 | 21 |
| 5 | Rogue user creation | `useradd svc_tmp` + add to sudo (lab) | log `useradd`; `/etc/passwd` diff; `user_audit.sh` | T1136/T1098 | 22 |
| 6 | Cron persistence | add a benign crontab entry | cron log; `auditd` watch; FIM on crontab | T1053 | 22/24 |
| 7 | authorized_keys persistence | append a test key to `~/.ssh/authorized_keys` | FIM/`syscheck` alert; file diff | T1098.004 | 24 |
| 8 | Web attack | `curl 'lab/app?id=1 UNION SELECT'` + a `../../etc/passwd` request | access-log analysis; Wazuh web rules; `weblog_analyze.sh` | T1190 | 23 |
| 9 | Log tampering | truncate part of a lab log (`: > /var/log/test.log`) | FIM on log dir; gap detection; auditd | T1070 | 06/24 |
| 10 | File integrity change | modify a "critical" lab file/binary | Wazuh FIM / AIDE diff; `fim_check.sh` | T1565 | 24 |

## How a drill becomes the lesson's evidence
Each drill produces the 6-artifact package: the detection **script**, the **rule** (Wazuh/Sigma/
auditd), a **runbook** ("when this fires…"), a **playbook** (the response play), an **incident
report + investigation notes**, and a **`SOC-NN` ticket**. Drill 11+ (chained) is the capstone
(Lesson 35) — several of these run as one staged compromise.
