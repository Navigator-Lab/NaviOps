# Lesson 28 — Network Security Fundamentals

**Status:** ✅ ready for self-study (full depth) · **Date written:** 2026-06-20
**Schema:** 12-section (`docs/learning/CLAUDE_TEACHING_RULES.md`)
**Focus:** recon/scan detection (nmap), traffic analysis, IDS (Suricata), brute-force/failed-login/port-scan detection, Wazuh/SIEM, MITRE ATT&CK.
**Primary artifact:** `scripts/port_scan_detect.sh` + `docs/runbooks/soc-net-triage.md`.
**Difficulty:** the security capstone-feeder — **full red/blue throughout** (this is the §12-heavy lesson).

> **How to use this lesson:** this is the SOC/Security-Analyst (networking) anchor — it ties every
> prior lesson's Lens E together into detection + triage. Read §1–§7, build the detection scripts +
> a SIEM in §8. **Lab-only, self-owned targets** (`navi.project.md` danger zone). Authorization
> context: educational, your own lab.

---

## §1 — Concept (Scientific Theory)

### What it is
**Network security fundamentals** = detecting and responding to malicious network activity. The
core skills: **traffic analysis** (Lessons 19/20 with a security lens), **recon/scan detection**
(spotting `nmap`-style enumeration), **brute-force / failed-login detection**, an **IDS**
(Intrusion Detection System — Suricata) that signature/anomaly-matches traffic, a **SIEM**
(Security Information and Event Management — Wazuh) that correlates logs + IDS alerts, and mapping
observed activity to **MITRE ATT&CK** techniques. This is the running **Lens E** thread of the whole
curriculum, made into its own discipline.

### Why it exists
Networks are constantly probed and attacked; prevention (firewalls, segmentation) is necessary but
insufficient — you must **detect** what gets through and **respond**. This lesson turns the
attacker/defender awareness built in every prior lesson into operational **detection engineering
basics** and **alert triage** — the SOC Tier-1 job.

### The attack lifecycle you detect (maps to ATT&CK)
| Stage | Activity | ATT&CK | Detect via |
|---|---|---|---|
| **Recon** | port/host scanning | `T1046` Network Service Discovery | many SYNs to many ports from one src (IDS/logs) |
| **Initial access** | brute force | `T1110` Brute Force | repeated auth failures (logs, Lesson 25) |
| **C2** | beaconing | `T1071` App-Layer Protocol | periodic outbound to one dest (flow/IDS) |
| **Exfil** | data out | `T1041`/`T1048` Exfiltration | large/odd outbound (flow/DLP) |
| **Lateral** | east-west movement | `T1021` Remote Services | unexpected internal connections |

### The detection stack
- **IDS (Suricata):** inspects traffic against **signatures** (known-bad patterns) and protocol
  anomalies; emits alerts. (IDS = detect; IPS = also block.)
- **SIEM (Wazuh):** collects logs (Lesson 25) + IDS alerts, **correlates** them, applies rules,
  and presents **alerts to triage**. Wazuh also does host-based detection (FIM — File Integrity
  Monitoring).
- **Detection scripts:** lightweight log/flow parsing (the `port_scan_detect.sh` / failed-login
  counter you build) — detection engineering at its simplest.

### Three-Level Depth (Lens A)
- **Level 1 — Beginner:** security monitoring watches network traffic and logs for signs of
  attack (scans, password guessing, weird outbound) and raises alerts a human checks.
- **Level 2 — SOC/NetOps:** you recognize attack signatures (a port scan = many SYNs to many ports
  from one source; brute force = many failed logins; beaconing = regular outbound to one host),
  run an **IDS** (Suricata) + **SIEM** (Wazuh), and **triage alerts** — true vs false positive,
  severity, escalate or close, mapped to **MITRE ATT&CK**. You write basic **detection rules** and
  tune false positives (the core SOC skill).
- **Level 3 — Wire/Kernel (Lens D):** detection sits on the primitives you've learned — IDS reads
  the same packets `tcpdump`/Wireshark do (Lessons 19/20), scan detection keys on TCP flags
  (`T1046` = SYNs without completed handshakes, Lesson 03), brute-force keys on auth-log patterns
  (Lesson 25), and the SIEM correlates by NTP-synced timestamps (Lesson 25). Detection is applied
  networking + log analysis, not magic.

### Two Teaching Approaches (Lens B) — detection & alert triage

**Approach 1 (technical):** detection = pattern-matching observable signals against known-bad or
anomalous behavior. A signature engine (Suricata) matches packet/stream patterns; log analytics
(SIEM/scripts) match event patterns (N failures in M seconds = brute force; X distinct ports from
one source = scan). Triage = for each alert, assess true/false positive, severity, scope, map to
ATT&CK, then escalate/contain or close+tune.

**Approach 2 (analogy):** security monitoring is a **building's security team with cameras + a
guard at the desk**.
- **IDS** = motion sensors + cameras that flag "someone is jiggling every door handle" (a scan) or
  "someone tried the keypad 50 times" (brute force).
- **SIEM** = the guard's desk where *all* sensor feeds + the door-access logs come together, so the
  guard sees "door-jiggling at the back *and* a keypad attack at the front, same person" (correlation).
- **Alert triage** = the guard deciding: real intruder (escalate, call police = contain/IR) vs the
  cleaning crew (false positive, note it and tune the sensor so it stops flagging them).
- **MITRE ATT&CK** = the shared vocabulary of *how* intruders operate, so the guard can name the
  technique ("this is lock-picking, stage: forced entry").
- **Where it breaks down:** a guard watches one building with a few sensors; a SOC drowns in
  thousands of alerts, so **tuning false positives** (alert fatigue, `noc/alert-handling.md`) is the
  make-or-break skill the single-guard analogy understates.

### Visual (ASCII) — the detection pipeline

```
   TRAFFIC ─► IDS (Suricata, signatures/anomaly) ─┐
   HOST/AUTH LOGS (Lesson 25) ────────────────────┤─► SIEM (Wazuh: correlate + rules)
   FLOW/firewall denies (Lessons 15/24) ──────────┘            │
                                                          ALERT QUEUE
                                                               │  triage:
                                              TP/FP? · severity · ATT&CK ID · scope
                                                               │
                                              escalate+contain (IR, L26) ── or ── close+tune
```

---

## §2 — Linux Networking Commands

```bash
# Recon (RED — lab-only, your own targets) — to UNDERSTAND what defenders detect
nmap -sS -p- 10.0.0.0/24            # SYN/stealth port scan (T1046)
nmap -sV 10.0.0.50                  # service/version detection
# Detect (BLUE) — scans/brute-force from logs & captures
grep "Failed password" /var/log/auth.log | awk '{print $(NF-3)}' | sort | uniq -c | sort -rn
# ^ failed logins per source IP (brute-force signal, T1110)
sudo tcpdump -nni any 'tcp[tcpflags] & (tcp-syn) != 0' | awk '{print $3}' | ...   # SYN sources (scan)
# Suricata (IDS)
suricata -i eth0 -c /etc/suricata/suricata.yaml      # run IDS
tail -f /var/log/suricata/fast.log                    # alerts
# Wazuh (SIEM) — agent + manager; alerts in the dashboard / /var/ossec/logs/alerts/
```

**Cisco/CCNA mapping:** CCNA Security Fundamentals covers threat types (DoS, on-path/MITM,
spoofing, scanning), and the concept of IDS/IPS. The Linux-first detection (Suricata/Wazuh/log
analysis) is the operational depth CCNA gestures at.

---

## §3 — Real-World Use Cases

**Production scenarios:**
1. **Port-scan detection:** an IDS/log rule flags one source hitting many ports → recon → alert,
   triage, possibly block (Lesson 15).
2. **Brute-force detection:** repeated SSH/RDP/VPN auth failures from one source → `T1110` → alert
   + (fail2ban) auto-block.
3. **Beaconing/C2:** regular outbound to one external host at a fixed interval → suspicious →
   investigate (Lesson 16/egress filtering).
4. **SOC alert triage:** the daily SOC Tier-1 job — work the alert queue, classify TP/FP, severity,
   ATT&CK, escalate or close+tune.

**How NOC/SOC engineers use it:** this is the bridge from NOC to SOC (the "NOSC" blended role,
`ROADMAP.md`). The detection scripts + IDS + SIEM + triage runbook are exactly the Security-Analyst
(networking) skill set.

**When NOT to:** never scan/recon anything you don't own (legal + `navi.project.md` danger zone);
don't deploy an IPS in blocking mode without tuning (false positives = self-inflicted outage).

**Exam framing:** Network+ Domain 4.0 (Security) + Security+ (the SOC entry cert) — attack types,
IDS/IPS, detection, and hardening.

---

## §4 — Troubleshooting / Triage Section

| Alert | Is it real? (triage) | ATT&CK | Action |
|---|---|---|---|
| Many ports from one src | scan vs a vuln-scanner/monitoring | `T1046` | confirm source; block if unauthorized |
| Burst of failed logins | brute force vs a misconfigured app retrying | `T1110` | block source; check for success after |
| Regular outbound to one host | C2 vs legit polling (update/telemetry) | `T1071` | identify the process/dest; egress policy |
| Large outbound transfer | exfil vs backup/legit | `T1041`/`T1048` | identify data + dest; DLP |
| Unexpected internal connection | lateral vs normal app traffic | `T1021` | verify expected; segment |

**Triage discipline:** every alert → TP/FP + severity + scope + ATT&CK + action. **Redaction
check:** sanitized indicators in committed runbooks; no real internal IPs.

---

## §5 — Common Mistakes

| Mistake | Impact | Fix |
|---|---|---|
| Scanning targets you don't own | illegal/unethical | lab/self-owned only (authorization) |
| IPS blocking without tuning | self-inflicted outages | start in detect, tune, then block |
| Alert fatigue (no FP tuning) | real attacks missed | tune false positives relentlessly |
| No ATT&CK mapping | can't communicate/track | map alerts to techniques |
| Detection without response plan | alerts ignored | tie to IR (Lesson 26) |
| Monitoring only inbound | misses C2/exfil | watch egress too (Lessons 15/16) |

---

## §6 — NOC Perspective

> NOC→SOC bridge (Stages 1→5, `ROADMAP.md`).

Security alerts increasingly land in the NOC (or a blended **NOSC**). The NOC's job is the same
loop — alert → triage (now: TP/FP + ATT&CK) → escalate (to security/Tier-2) or contain (block the
source, Lesson 15) → document. The detection scripts you build here are NOC-runnable; the SIEM is
the security analog of the monitoring stack (Lessons 22–23). Triage discipline (TP/FP, severity,
no alert fatigue) is identical to `noc/alert-handling.md` — which is why a NOC start is a real
on-ramp to SOC.

---

## §7 — Incident-Response Perspective

Security IR is the IR lifecycle (Lesson 26) with security stages:
- **Detect:** IDS/SIEM/script alert.
- **Triage:** TP/FP + severity + ATT&CK + scope.
- **Contain:** block the source (Lesson 15), isolate the host, **preserve evidence** (off-box logs
  Lesson 25, captures Lesson 20) *before* changing anything.
- **Eradicate → Recover → Report:** remove the foothold, restore, document mapped to ATT&CK.
This is exactly the **Network-Security Capstone (36)** — you generate (lab) attack telemetry and
run this lifecycle end-to-end. The triage runbook (`docs/runbooks/soc-net-triage.md`) is the SOP.

---

## §8 — Practical Lab (build this yourself)

**Goal:** build `scripts/port_scan_detect.sh` + a failed-login detector, stand up Suricata (and
optionally Wazuh), and write `docs/runbooks/soc-net-triage.md`. **Lab/self-owned only.**

### Lens C — Manual → Automated → Why
- **Manual:** read auth logs / a capture and *spot* a scan or brute force by hand.
- **Automated:** `port_scan_detect.sh` (flag a source hitting > N ports/hosts) and a failed-login
  counter (flag > N failures/source/window) — detection engineering at its simplest; then Suricata/
  Wazuh generalize it.
- **Why:** detection must be automated to scale; building the simple version teaches *what* the IDS/
  SIEM do and how to tune thresholds (FP control). This is the core Security-Analyst skill.

### Steps (LAB ONLY — own targets, authorization context)
1. **Generate telemetry (red, lab-only):** `nmap -sS` a lab host (recon), a few failed `ssh` logins
   to a lab host (brute force) — to produce the signals a defender catches.
2. **Build detection (blue):**

```bash
#!/usr/bin/env bash
# port_scan_detect.sh — flag sources hitting many distinct ports (scan signal, T1046). Lesson 28.
# Usage: sudo ./port_scan_detect.sh <iface> [seconds] [port_threshold]
set -euo pipefail
iface="${1:?usage: port_scan_detect.sh <iface> [secs] [threshold]}"; secs="${2:-30}"; thr="${3:-15}"
echo "Watching $iface ${secs}s; flag sources hitting >${thr} distinct ports..."
timeout "$secs" tcpdump -nni "$iface" 'tcp[tcpflags] & tcp-syn != 0 and tcp[tcpflags] & tcp-ack = 0' 2>/dev/null \
 | awk '{split($3,a,"."); src=a[1]"."a[2]"."a[3]"."a[4]; split($5,b,"."); dport=b[5]; key=src; ports[key, dport]=1; seen[key]++}
        END{ for (k in seen){ c=0; for (p in ports){ split(p,pp,SUBSEP); if(pp[1]==k) c++ } if(c>thr) printf "ALERT scan: %s hit %d ports (T1046)\n", k, c } }' thr="$thr"
```

   Plus the failed-login counter (from Lesson 25):
   `grep "Failed password" /var/log/auth.log | awk '{print $(NF-3)}' | sort | uniq -c | sort -rn` →
   alert if any source > threshold (T1110).
3. **IDS:** run Suricata on the lab interface; trigger its scan/brute-force rules with your red
   activity; read `fast.log`.
4. **(Optional) SIEM:** deploy Wazuh, ingest auth logs + Suricata alerts, see correlated alerts.
5. **Triage runbook:** write `docs/runbooks/soc-net-triage.md` — the TP/FP + severity + ATT&CK +
   action table (§4) as the SOP, plus how to tune a false positive.
6. **Drill:** run a full **security incident**: detect (your script/Suricata) → triage → contain
   (block the source with nftables, Lesson 15) → document (IR report, Lesson 26).

### Lens D — detection on the primitives
Note how every detection reduces to earlier lessons: scan = TCP flags (L3), brute force = auth log
patterns (L25), C2/exfil = flow/egress (L15/16), correlation = NTP-synced logs (L25). Detection is
applied networking.

---

## §9 — GitHub Artifact (evidence 5-tuple)

1. **Script:** `scripts/port_scan_detect.sh` + a failed-login detector (shellcheck-clean).
2. **Config:** a Suricata rule snippet / Wazuh rule in `infra/configs/` (lab).
3. **Drill:** a full security incident (detect→triage→contain→document), lab-only.
4. **NAVI ticket:** `NAVI-28` (Incident: "port scan + brute force detected — triaged + contained").
5. **Incident report:** `docs/runbooks/soc-net-triage.md` + an IR report mapped to ATT&CK
   (sanitized indicators only).

---

## §10 — Portfolio Artifact

- **Resume bullet:** "Built network-attack detection (port-scan + brute-force scripts), deployed
  Suricata IDS + Wazuh SIEM, and triaged alerts mapped to MITRE ATT&CK; ran a detect→contain→report
  incident end-to-end."
- **Interview talking point:** how you detect a scan vs brute force vs C2, the TP/FP triage
  discipline, and ATT&CK mapping — the core SOC Tier-1 answer (and the NOC→SOC bridge story).
- **Serves:** SOC / Security Analyst (networking track, Stage 5) + NOC (Stage 1); feeds capstone 36.

---

## §11 — RHCSA Crossover Notes

RHCSA-adjacent: **fail2ban**, **firewalld** (containment, Lesson 15), SSH hardening, and **auditd**/
log review on RHEL overlap with the host side of detection. The sibling NaviOps platform covers
Linux hardening + Wazuh in depth; here it's the network-detection lens.

---

## §12 — Security Notes (Lens E — Attacker & Defender) — this lesson IS the §12 deep-dive

> Frameworks: [MITRE ATT&CK](https://attack.mitre.org/) · [GTFOBins](https://gtfobins.github.io/) · [Suricata](https://suricata.io/).

**🔴 Attacker:** the full early kill-chain — recon/scan (`T1046`, `nmap`), brute force (`T1110`),
exploitation, C2 (`T1071`), exfil (`T1041`/`T1048`), lateral movement (`T1021`) — plus
**defense evasion**: slow/low scans to stay under thresholds, encrypted C2 to defeat inspection,
and disabling logging/monitoring (`T1562`, `T1070`).

**🔵 Defender:** **detect** each stage (IDS signatures, log analytics, flow anomalies), **tune**
thresholds to beat both false positives *and* low-and-slow evasion, **correlate** in the SIEM,
**map to ATT&CK** for tracking, and **respond** via IR (Lesson 26): contain (block/isolate,
Lesson 15), preserve evidence (Lessons 20/25), eradicate, recover, report. Defense-in-depth across
every prior lesson's Lens E. **Verify** detections fire against your own (lab) red activity and that
a tuned rule stops a known false positive.

---

## Quiz (Interview-Style, Graded)

**Q1.** How do you detect a port scan from logs/traffic, and what's the ATT&CK technique?
> **Your answer:**

**Q2.** What signal indicates a brute-force attack, and how would you detect *and* respond to it?
> **Your answer:**

**Q3.** IDS vs IPS, and IDS vs SIEM — what does each do?
> **Your answer:**

**Q4.** **Scenario:** Your SIEM flags a host making a connection to the same external IP every 60
seconds. What do you suspect, what's the ATT&CK technique, and how do you triage it?
> **Your answer:**

**Q5.** What is alert triage, and why is tuning false positives the most important SOC skill?
> **Your answer:**

**Q6.** Walk through responding to a confirmed intrusion using the IR lifecycle (detect→...→report).
> **Your answer:**

*(After you answer, request the "Professional Answer" comparison under each — graded before Lesson 29.)*

---

## Reflection
*(Fill in after the quiz)* — What did you learn? · What confused you? · What would you do differently?

---

## Search Keywords For Further Understanding

**Core**
- `network security monitoring fundamentals`
- `port scan detection`
- `brute force detection failed logins`
- `mitre attack network techniques`
- `alert triage true false positive`

**Tools**
- `suricata ids rules tutorial`
- `wazuh siem setup`
- `fail2ban ssh brute force`

**Going further (future lessons)**
- `network security capstone` (L36) · `vpn security` (L29) · `threat hunting`

**Red / Blue (Lens E):**
- 🔴 `nmap scan T1046`, `brute force T1110`, `c2 beaconing T1071`, `exfiltration T1041 T1048`, `low and slow evasion`
- 🔵 `suricata scan brute force rules`, `wazuh correlation`, `mitre attack mapping`, `tune false positives siem`

---

## Lesson Status
- [ ] §8 lab completed (detection scripts + Suricata/Wazuh + triage runbook)
- [ ] §4 drill done (full security incident, lab-only)
- [ ] Evidence committed (§9 — sanitized)
- [ ] Quiz answered + professional-answer comparisons (graded)
- [ ] Reflection + Search Keywords reviewed

When complete, run the Update Protocol, then move to **Lesson 29 — VPN Technologies**.

---

*Lesson 28 written by Navi · 2026-06-20 · full-depth. Sources to cite when worked: MITRE ATT&CK,
Suricata & Wazuh docs, CompTIA Network+ N10-009 (Domain 4.0) + Security+, NIST SP 800-61.*
