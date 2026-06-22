# Lesson 20 — Port Scan Detection

**Status:** ✅ ready for self-study (full depth) · **Date written:** 2026-06-20
**Schema:** 12-section SOC (`docs/learning/CLAUDE_TEACHING_RULES.md`)
**Focus:** scan types (SYN/connect/FIN/UDP), detecting scans from firewall logs / `tcpdump` /
IDS, the Wazuh + Suricata signal, internal-vs-external scans, and T1046 — catching recon early.
**Primary artifact:** `scripts/port_scan_detect.sh`.

> **Danger zone:** scanning is done only against self-owned lab targets (`navi.project.md` #2).
> Read §1–§7, do §8 (scan a lab host you own + detect it), produce §9, quiz, reflect. Then Lesson 21.

---

## §1 — Concept (Scientific Theory)

### What it is
A **port scan** is reconnaissance: probing many ports (and/or hosts) to map what's open and what's
running. Types:
- **TCP connect / SYN (half-open)** — the common ones (`nmap -sT`/`-sS`).
- **Stealth (FIN/NULL/Xmas)** — odd flag combos to evade naïve detection.
- **UDP** — slower, for UDP services.
- **Horizontal** (one port across many hosts) vs **vertical** (many ports on one host).

Detection is **behavioral**: many connection attempts (often to closed ports → RST/ICMP unreachable,
or firewall denies) from one source in a short window.

### Why it exists
Scanning is kill-chain **stage 1 (recon)** — the earliest, cheapest place to detect an attacker
(Lesson 11). Catching a scan (especially an *internal* one) is an early warning of an intrusion in
progress: an attacker who's inside scans to find their next target (lateral movement prep).

### Three-Level Depth (Lens A)
- **Level 1 — Beginner:** someone "knocks on" lots of doors (ports) quickly to see which open. Lots
  of knocks from one place = a scan.
- **Level 2 — Analyst/SOC:** detect via firewall **deny** logs, connection-rate anomalies, or an
  IDS (Suricata) scan signature feeding Wazuh. Key questions: **internal or external** source?
  (internal = far more alarming — likely a foothold), and **what was the target** (the crown jewels?).
- **Level 3 — Adversary/Kernel:** a SYN scan sends SYN, gets SYN/ACK (open) or RST (closed), never
  completing the handshake (half-open) — visible in `tcpdump` as many SYNs to many ports with RSTs
  back. Detection counts distinct-dest-ports per source over time; Suricata/Wazuh have purpose-built
  scan detectors. Stealth scans manipulate flags to dodge simple rules.

### Two Teaching Approaches (Lens B) — scan detection
**Approach 1 (technical):** a scan is a fan-out connection pattern — high distinct-destination-port
(or distinct-host) count per source per unit time, with a high ratio of failed/reset connections.
Detect by counting fan-out + failure ratio.

**Approach 2 (analogy):** a burglar **walking down the street trying every door handle**. One person
touching 1,000 handles in a minute is unmistakable — it's the *fan-out*, not any single handle.
**Where it breaks down:** slow scans (one handle every few minutes) look like normal passersby —
needing longer windows + behavioral baselines, like brute-force low-and-slow.

### Visual (ASCII) — the fan-out signature
```
 NORMAL:  10.0.0.5 → web01:443 (one service, established)                        ✓
 SCAN:    10.0.0.99 → web01:{22,23,25,80,443,3306,8080,...}  many SYNs, RSTs back  → vertical scan
          10.0.0.99 → {10.0.0.1..254}:22  one port, many hosts                     → horizontal scan
   detect: distinct dest-ports (or dest-hosts) per source over 60s > threshold
```

---

## §2 — Linux Investigation Commands

```bash
# firewall deny logs (best source if you log drops — Lesson from NaviOpsNetwork nftables)
journalctl -k | grep -i "nft.*drop\|REJECT"     # kernel firewall denies
# tcpdump: see the scan on the wire (lab)
tcpdump -ni eth0 'tcp[tcpflags] & tcp-syn != 0 and tcp[tcpflags] & tcp-ack == 0'  # bare SYNs
# count fan-out per source (from conn logs / tcpdump output)
tcpdump -nnr scan.pcap 'tcp[tcpflags]&tcp-syn!=0' | awk '{print $3}' | sort | uniq | wc -l  # distinct dests
# Suricata (network IDS, feeds Wazuh) scan alerts
tail -f /var/log/suricata/fast.log | grep -i scan
bash scripts/port_scan_detect.sh eth0
```
| Source | Signal | Wazuh/IDS |
|---|---|---|
| firewall denies | many denies one source | Wazuh firewall rules |
| tcpdump | SYN fan-out | manual / scripted |
| Suricata | scan signature | Suricata→Wazuh integration |

---

## §3 — Real-World Threat Context & Use Cases

- **Internal scan = alarm:** an external scan is constant background; an **internal** host scanning
  is a likely foothold doing discovery (T1046) → escalate.
- **Recon precedes attack:** a scan of your DB ports is a heads-up to watch that asset.
- **Vuln scanner FP:** your own authorized scanner (Nessus/OpenVAS) looks identical — allowlist it
  (classic FP).
- **Exam framing:** scan types, recon detection, and T1046 on Security+/CySA+/BTL1.

---

## §4 — Detection

- **Fan-out threshold:** distinct dest-ports (vertical) or dest-hosts (horizontal) per source per
  window > threshold. `port_scan_detect.sh` implements it; Suricata/Wazuh have built-ins.
- **Firewall-deny correlation:** many denies from one source = scan (cheap, high-signal if you log
  drops).
- **Internal-source weighting:** raise severity sharply for internal sources.
- **FP tuning:** allowlist authorized scanners + monitoring probes; tune thresholds to your
  environment.

---

## §5 — Investigation & Triage

Confirm the fan-out (distinct ports/hosts), determine **source location** (internal vs external) and
**target** (criticality), check whether the scan was *followed by* a connection to an open port
(scan → exploit, kill-chain progression). Internal source or follow-on activity → escalate; external-
only background → likely monitor/tune.

---

## §6 — SOC Perspective

External scans are firehose-noise (mostly tuned down/aggregated); **internal** scans are high-value
alerts. The SOC pairs scan detection with the kill chain — a scan is "stage 1," prompting watch for
stages 2+. Suricata (from NaviOpsNetwork) is the typical network-IDS source feeding the Wazuh alert.

---

## §7 — Incident-Response Perspective

An internal scan often *is* the first sign of an active intrusion (discovery before lateral
movement). IR: identify the scanning host (it may be compromised → investigate it, Lesson 21),
scope what it reached, contain if confirmed. Capstone stage 1/6. Maps to `soc/soc-scenarios.md` #5.

---

## §8 — Practical Lab (build this yourself)

**Goal:** scan a lab host you own, then detect it three ways.

### Lens C — Manual → Automated → Why
- **Manual:** eyeball `tcpdump` SYNs.
- **Automated:** `port_scan_detect.sh` counts fan-out per source and flags scans; Suricata/Wazuh do
  it continuously.
- **Why:** scans are fast — you need automated counting + alerting, not manual packet reading.

### Steps
1. **Generate (drill 3, lab, self-owned):** from your box, `nmap -sS <lab-vm>` (vertical) and
   `nmap -p22 10.0.0.0/24` (horizontal) — against *your own* lab only.
2. Capture with `tcpdump -w scan.pcap` during the scan.
3. Build `scripts/port_scan_detect.sh`: from a capture/iface, count distinct dest-ports (and dest-
   hosts) per source over a window; flag > threshold. `bash -n` + `shellcheck` clean.
4. Detect via firewall denies (enable drop logging on the lab host) and/or Suricata `fast.log`;
   confirm the scan shows up. Map to T1046.
5. **Tune:** run a smaller "authorized scanner" pattern and allowlist its source; confirm no FP.

### Lens D — the raw artifact
```
$ tcpdump -nnr scan.pcap 'tcp[tcpflags]&tcp-syn!=0' | head
10.0.0.99.51000 > 10.0.0.20.22:  S      10.0.0.99.51001 > 10.0.0.20.23:  S
10.0.0.99.51002 > 10.0.0.20.25:  S      10.0.0.99.51003 > 10.0.0.20.80:  S
# one source, sequential ports, bare SYNs = the textbook vertical-scan signature.
```

---

## §9 — GitHub Artifact (the 6-artifact evidence package)

1. **Script:** `scripts/port_scan_detect.sh` (committed, `shellcheck`-clean).
2. **Detection rule/config:** the firewall drop-logging + Suricata/Wazuh scan rule note
   (`infra/detection-rules/`).
3. **Runbook:** `docs/runbooks/runbook-port-scan.md` — internal vs external → action.
4. **Playbook:** `docs/playbooks/recon-play.md`.
5. **Incident report + notes:** the scan drill (vertical+horizontal detected; internal-weighting
   reasoning) + notes.
6. **SOC ticket:** `SOC-20` (Task: "port-scan detection") → Closed.

---

## §10 — Portfolio Artifact

- **Resume bullet:** "Built port-scan detection (`port_scan_detect.sh` + firewall/Suricata signals)
  catching vertical + horizontal scans (T1046), weighting internal sources and tuning out authorized
  scanners."
- **Interview talking point:** why an internal scan is far more alarming than an external one, and
  how scan detection fits kill-chain stage 1 (detect early).
- **Serves:** SOC T1 (Stage 2). Bridges NaviOpsNetwork (Suricata/nftables).

---

## §11 — Certification Crossover Notes

- **Security+:** recon/attacks (2.x). **CySA+:** network detection. **SC-200:** network signals.
  **BTL1:** network forensics. Detail: `alignment/CERTIFICATION-MAPPING.md`.

---

## §12 — Security Notes (Lens E — Attacker & Defender)

**🔴 Attacker:** scan for discovery (T1046) — stealth/slow scans + decoys to evade detection, scan
internally after a foothold to plan lateral movement; time scans to blend with normal traffic.

**🔵 Defender:** detect fan-out (ports/hosts per source), heavily weight internal sources, log
firewall drops, deploy a network IDS (Suricata→Wazuh), and watch for scan→connect progression.
Reduce attack surface (close ports) so there's less to find. Catching the scan = catching the
attacker at the cheapest stage.

---

## Quiz (Interview-Style, Graded)

**Q1.** What's the network signature of a port scan, and how does a SYN (half-open) scan differ from
a full connect scan?
> **Your answer:**

**Q2.** Why is an *internal* scan far more concerning than an external one?
> **Your answer:**

**Q3.** Horizontal vs vertical scan — define each and the detection key for each.
> **Your answer:**

**Q4.** **Scenario:** an internal host 10.0.0.7 is connecting to port 22 across the whole /24. What
is it, what do you suspect about 10.0.0.7, and what do you do?
> **Your answer:**

**Q5.** How do you keep your authorized vulnerability scanner from generating endless false
positives?
> **Your answer:**

*(Request the "Professional Answer" comparison under each before moving on.)*

---

## Reflection
*(After the quiz)* — What did you learn? · What confused you? · What would you do differently?

---

## Search Keywords For Further Understanding

**Core**
- `port scan detection syn connect stealth`
- `horizontal vs vertical scan`
- `detect nmap scan linux tcpdump`
- `suricata port scan rule`
- `mitre t1046 network service discovery`

**Tools**
- `nmap scan types`
- `nftables log drops`

**Going further**
- `suspicious process investigation` (L21) · `lateral movement` (L35) · `threat hunting` (L25)

**Red / Blue (Lens E):**
- 🔴 `network service discovery T1046`, `stealth scan evasion`, `internal recon for lateral movement`
- 🔵 `fan-out scan detection`, `internal-source weighting`, `suricata ids to wazuh`, `attack surface reduction`

---

## Lesson Status
- [ ] §8 lab completed (scanned own lab host; detected 3 ways; tuned scanner FP)
- [ ] 6-artifact evidence package committed (§9)
- [ ] Quiz answered + professional-answer comparisons (graded)
- [ ] Reflection + Search Keywords reviewed

When complete, run the Update Protocol, then move to **Lesson 21 — Suspicious Process
Investigation**.

---

*Lesson 20 written by Navi · 2026-06-20 · full-depth. Sources to cite at study time: MITRE T1046,
Suricata scan-detection docs, nmap scan-types reference, Wazuh firewall rules.*
