# SOC Scenarios — the 8 canonical incidents

The recurring incident types a SOC analyst works. Every lesson's §7 (Incident-Response
Perspective) maps to one of these, and the IR workflow (`../workflows/`) is applied to each.
These are the "what you'll actually see" set — rehearse the first-30-seconds move for each.

> **Universal first-30-seconds checklist** (run for any alert): **scope** (one host/user vs
> many?) · **when** (correlate with a change/maintenance?) · **evidence** (collect *before* you
> act) · **severity** (set it, start the SLA clock) · **ATT&CK** (which technique?).

## 1. Failed-login storm
- **Signal:** many `Failed password` in `auth.log` / Wazuh 5710-family alerts.
- **Suspect:** brute force (T1110) or a misconfigured app.
- **First move:** group by source IP + target user; did any attempt **succeed**? (That flips
  Sev3 → Sev2 and triggers escalation.)
- **Lessons:** 18, 19.

## 2. Successful unauthorized login
- **Signal:** `Accepted password/publickey` from an unusual IP/time, often after #1.
- **Suspect:** valid-account compromise (T1078).
- **First move:** what did the session do? `last`, process tree, new files, outbound conns.
  Preserve evidence, escalate.
- **Lessons:** 18, 21, 22, 35.

## 3. Suspicious process / reverse shell
- **Signal:** odd parent-child (`bash` ← `nginx`), process with a network socket, exec from
  `/tmp`.
- **Suspect:** code execution / C2 (T1059, T1071).
- **First move:** `ps auxf`, `/proc/<pid>`, `ss -tunap`, hash the binary; contain the host if
  confirmed.
- **Lessons:** 21, 07.

## 4. New / modified privileged account
- **Signal:** `useradd`/`usermod` in logs, new entry in `/etc/passwd`, sudoers change.
- **Suspect:** persistence / account creation (T1136, T1098).
- **First move:** who created it and from what session? correlate, check for keys/cron, scope.
- **Lessons:** 22, 24.

## 5. Port scan / recon
- **Signal:** many connection attempts across ports/hosts, firewall denies, Suricata/Wazuh scan
  alert.
- **Suspect:** discovery (T1046).
- **First move:** internal or external source? one target or sweeping? often a precursor — watch
  for follow-on.
- **Lessons:** 20, 07.

## 6. Web attack
- **Signal:** access log with `UNION SELECT`, `../`, `<script>`, abnormal 4xx/5xx bursts.
- **Suspect:** SQLi/XSS/LFI/path traversal (T1190 exploit public-facing app).
- **First move:** enumeration vs successful exploitation? response codes + sizes tell you;
  check for a follow-on shell/file write.
- **Lessons:** 23.

## 7. File integrity / tamper event
- **Signal:** Wazuh FIM/`syscheck` alert on a critical file; AIDE diff; changed binary or config.
- **Suspect:** persistence / defense evasion / log tampering (T1565, T1070, T1543).
- **First move:** what changed, when, by whom? compare to baseline; is a log being truncated?
- **Lessons:** 24, plus the log-tampering thread.

## 8. Lateral movement
- **Signal:** the same credential/IOC across multiple hosts, internal SSH/SMB from an unusual
  host, new sessions fanning out.
- **Suspect:** lateral movement (T1021).
- **First move:** map the spread (which hosts, which account), this is now a multi-host incident —
  escalate to IR.
- **Lessons:** 21, 22, 35.

---

Each scenario has a runbook skeleton in `../workflows/` and is exercised by the matching lesson's
§8 drill and the capstone (Lesson 35, which chains several of them).
