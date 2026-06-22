# Capstone 36 — Network-Security Capstone (Detect + Respond to an Attack)

**Proves:** you can analyze traffic, run detection (IDS + SIEM), triage alerts, map activity to
MITRE ATT&CK, and run the IR lifecycle — the SOC / Security-Analyst (networking track) skill set.
**Prereqs:** Lessons 15, 19, 20, 28 (+ Lens E thread across the curriculum).
**Tooling:** the lab from earlier capstones + **Suricata** (IDS) + **Wazuh** (SIEM) +
`tcpdump`/`tshark`. **All activity is against lab hosts the operator owns** — never a third
party (`navi.project.md` danger zone). Authorization context: self-owned lab, educational.

## The scenario (attacker → defender)

You play **both sides** (the platform's Lens E made real):

### Red (attacker — from a lab box you own, against a lab target you own)
A staged intrusion chain:
1. **Recon** — `nmap -sS -sV` host/port discovery against the lab subnet → `T1046` Network
   Service Discovery.
2. **Brute force** — `hydra`/`ncrack` against a lab SSH on a deliberately weak cred →
   `T1110` Brute Force.
3. **Foothold + C2-ish beacon** — a benign script making periodic outbound HTTPS to a lab
   "C2" → `T1071.001` Application Layer Protocol / `T1571` Non-Standard Port (vary it).
4. **Exfil simulation** — push a marked dummy file out → `T1041` Exfiltration Over C2 Channel.

> Keep it lab-only and benign (dummy data, no real malware). The point is *generating the
> telemetry a defender must catch.*

### Blue (defender — the deliverable)
Detect and respond to each stage:
1. **Sensor up:** Suricata watching the lab span/interface; Wazuh collecting host + Suricata logs.
2. **Detect:** show the alert/log for each stage (scan signature, repeated SSH auth failures,
   beacon periodicity in flow, exfil volume anomaly).
3. **Triage:** severity + true/false-positive call + ATT&CK mapping per alert.
4. **Respond (IR lifecycle):** detect → contain (block the source with nftables) → eradicate →
   recover → **document**.

## Deliverables (the artifacts)

1. **Attack runbook** — `docs/runbooks/sec-capstone-attack.md`: the staged chain + the exact
   (lab-only) commands, with ATT&CK IDs.
2. **Detection evidence** — per stage: the Suricata alert / Wazuh rule / log line / capture
   snippet that caught it (redacted), in `docs/runbooks/sec-capstone-detection.md`.
3. **Detection scripts** — `scripts/port_scan_detect.sh` + a failed-login/brute-force detector
   (parse auth logs with `grep`/`awk`), committed and `shellcheck`-clean.
4. **Triage table** — alert → severity → TP/FP → ATT&CK ID → action.
5. **IR report** — full lifecycle write-up with RCA + containment proof (`nft` counters on the
   block) + recovery verification.
6. **PORTFOLIO.md** — "built attacker telemetry + detected it with Suricata/Wazuh, mapped to
   MITRE ATT&CK, ran IR end-to-end" + interview talking points.

## Coverage (interview-ready)

| Skill | Evidence |
|---|---|
| Traffic analysis | tcpdump/tshark snippets of each stage |
| IDS | Suricata signatures firing on scan/brute-force/beacon |
| SIEM | Wazuh correlating host auth logs + IDS alerts |
| Detection engineering basics | the two detection scripts + a tuned threshold |
| MITRE ATT&CK | every stage mapped to a technique ID |
| Alert triage | the TP/FP severity table |
| Incident response | the full-lifecycle IR report |

## Done when
Every attack stage has a corresponding detection + triage + response documented, containment is
proven, and `PORTFOLIO.md` is written. Open `NAVI-36` (Incident). **Redaction check:** no real
IPs/captures — lab ranges + sanitized snippets only.
