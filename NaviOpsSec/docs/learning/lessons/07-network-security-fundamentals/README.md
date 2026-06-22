# Lesson 07 — Network Security Fundamentals (for Defenders)

**Status:** ✅ ready for self-study (full depth) · **Date written:** 2026-06-20
**Schema:** 12-section SOC (`docs/learning/CLAUDE_TEACHING_RULES.md`)
**Focus:** ports/protocols/TLS through a defender's eyes — normal vs suspicious connections,
listening services, egress/beaconing, and reading network evidence with `ss`/`tcpdump`/`tshark`.
**Primary artifact:** `scripts/net_connections.sh` (connection-state triage).

> **Prereq bridge:** this reuses NaviOpsNetwork's networking foundations; here the lens is
> *detection*. Read §1–§7, do §8 (baseline connections + catch a lab reverse shell), produce §9,
> quiz, reflect. Then Lesson 08.

---

## §1 — Concept (Scientific Theory)

### What it is
For a SOC analyst, "network security" means **reading connections as evidence**: which services
**listen** (attack surface), which connections are **established** (who's talking to whom), what's
**normal egress** vs **suspicious outbound** (beaconing/exfil), and what TLS/SNI/ports reveal.
You don't need to *design* the network (that's NaviOpsNetwork) — you need to *interrogate* it on a
host and spot the abnormal.

### Why it exists
Almost every intrusion crosses the network: initial access comes in, C2 and exfil go out. The host
endpoint shows both ends via its sockets and captures. An analyst who can read `ss`/`tcpdump`
catches the reverse shell, the beacon, and the data leaving — often before the SIEM correlates it.

### Three-Level Depth (Lens A)
- **Level 1 — Beginner:** services listen on ports (22 SSH, 80/443 web); connections are between an
  IP:port and another IP:port. Unexpected listeners or outbound connections are suspicious.
- **Level 2 — Analyst/SOC:** `ss -tunap` shows every socket with its owning process — the fastest
  way to find a foothold (a shell listening on :4444) or C2 (a process connecting out to a strange
  IP). You **baseline** normal (what *should* listen/connect) so abnormal stands out.
- **Level 3 — Adversary/Kernel:** sockets live in the kernel (`/proc/net/tcp`, conntrack); `ss`
  reads them. C2 often hides in TLS on 443 (looks normal) with tell-tale **beaconing** (regular
  interval, small constant size). `tcpdump`/`tshark` expose timing, SNI, JA3, and volumes that
  reveal what the port number hides.

### Two Teaching Approaches (Lens B) — beaconing
**Approach 1 (technical):** C2 beaconing is periodic check-in traffic — a connection at a fixed
interval (± jitter) with a small, consistent payload, often outbound to a single host over 443. You
detect it by *behavior* (periodicity, volume, destination rarity), not by port.

**Approach 2 (analogy):** a spy phoning home every night at 9pm for 30 seconds. The *content* is
encrypted (you can't hear it), but the **pattern** — same time, same length, same number — gives
them away. **Where it breaks down:** sophisticated C2 randomizes timing/size (domain fronting,
jitter) to look like normal browsing — which is why behavioral baselines + threat intel matter.

### Visual (ASCII) — normal vs suspicious
```
 NORMAL:  web01:443  ◄──many short bursts──  internet (users browsing)   ✓
          web01:22   ◄──admin from 10.0.0.5 (known)                       ✓
 SUSPICIOUS: web01:4444  ◄── LISTEN (no service should be here)  ──► reverse shell ✗
          web01 ──every 60s, 200 bytes──► 203.0.113.50:443  (beaconing C2)        ✗
          web01 ──5 GB outbound at 03:00──► unknown host (exfil)                  ✗
```

---

## §2 — Linux Investigation Commands

```bash
ss -tulnp                       # all LISTENING sockets + owning process (attack surface)
ss -tunap                       # all sockets incl. ESTABLISHED + process (who's talking)
ss -tunap state established     # just active conversations
lsof -i -nP                     # files/sockets per process (cross-check ss)
ss -tunap | awk '{print $6}' | grep -oE '([0-9]+\.){3}[0-9]+' | sort | uniq -c | sort -rn  # top peers
tcpdump -ni eth0 'tcp[tcpflags] & tcp-syn != 0 and not src net 10.0.0.0/8'  # outbound SYNs
tcpdump -ni eth0 host 203.0.113.50 -w /tmp/beacon.pcap   # capture suspect peer (lab; sanitize!)
tshark -r /tmp/beacon.pcap -q -z io,stat,60   # 60s buckets → see periodic beaconing
```
| Linux | SIEM equivalent |
|---|---|
| `ss -tulnp` listeners | Wazuh open-ports inventory / port-change alerts |
| outbound to rare IP | SIEM threat-intel match / netflow anomaly |
| `tshark` io,stat periodicity | a beaconing-detection analytic |

---

## §3 — Real-World Threat Context & Use Cases

- **Find the foothold:** `ss -tulnp` instantly shows an unexpected listener (reverse/bind shell,
  webshell helper) — Lesson 21's core move.
- **Find the C2:** an established outbound to a rare/known-bad IP, especially periodic → beaconing
  (Lesson 35 stage).
- **Find the exfil:** large/odd-hour outbound volume to an unusual destination.
- **Egress matters more than ingress:** firewalls watch inbound; attackers rely on permissive
  *outbound*. Defenders baseline and restrict egress.
- **Exam framing:** ports/protocols, the role of TLS, and indicators of C2/exfil appear on
  Security+/CySA+/BTL1.

---

## §4 — Detection

- **Listener change detection:** baseline listening ports; alert on a new one (Wazuh ports
  inventory). A new `:4444` is a near-certain TP.
- **Threat-intel match:** outbound to a known-bad IP/domain (Lesson 09 IOCs) → alert.
- **Beaconing detection:** periodicity + rare-destination analytic (behavioral; introduced here,
  hunted in Lesson 33).
- **Egress anomalies:** volume/destination outliers. Tie to network IDS (Suricata, from
  NaviOpsNetwork) feeding Wazuh.

---

## §5 — Investigation & Triage

A network alert: confirm the **socket + owning process** (`ss -tunap`, `lsof`), identify the
**peer** (reputation/threat-intel), classify (listener = foothold? outbound = C2/exfil?), and scope
(other hosts talking to the same peer? `ioc_sweep.sh`). Capture the suspect flow (lab, sanitized)
before containment so you can prove what it was.

---

## §6 — SOC Perspective

Network evidence corroborates host alerts: a suspicious process is far more conclusive when it
*also* has a socket to a known-bad IP. The SOC tracks "new listening port" and "outbound to bad
reputation" as high-value detections. Network containment (block the peer, isolate the host) is a
common T2 action (`soc/escalation-matrix.md`).

---

## §7 — Incident-Response Perspective

Network state is **volatile evidence** — capture `ss -tunap`/`lsof` and a targeted pcap in IR Phase
2 *before* you isolate the host (isolation kills the connections you're trying to document).
Containment (Phase 3) often *is* a network action: `nft` drop the C2 peer, then proceed. Maps to
`soc/soc-scenarios.md` #3 (reverse shell) and #8 (lateral movement).

---

## §8 — Practical Lab (build this yourself)

**Goal:** baseline your host's connections and catch a (lab) reverse shell + a beacon.

### Lens C — Manual → Automated → Why
- **Manual:** read `ss -tunap` and judge each socket.
- **Automated:** `scripts/net_connections.sh` lists listeners + established peers and flags ones
  not in a baseline allowlist.
- **Why:** a script gives you a repeatable "what's talking" snapshot for any host under
  investigation; production does it continuously (EDR/agent inventory).

### Steps
1. Baseline: `ss -tulnp` — write down what *should* listen on your VM (22, maybe 80/443).
2. **Reverse-shell drill (drill 4, lab):** on the VM run `nc -lvnp 4444 &`; from another box
   `nc <vm> 4444`. Re-run `ss -tunap` and find the rogue `:4444` listener + its PID. Kill it.
3. Write `scripts/net_connections.sh`: print listeners + established, and flag any listener not in
   `{22,80,443}`. `bash -n` + `shellcheck` clean.
4. **Beacon drill (lab):** loop `curl` to a lab host every 60s for a few minutes; capture with
   `tcpdump -w` and view periodicity with `tshark -z io,stat,60`. Note the regular pattern.
5. Document how each would alert in the SIEM.

### Lens D — the raw artifact
```
$ ss -tunap | grep 4444
tcp  LISTEN 0 1  0.0.0.0:4444  0.0.0.0:*  users:(("nc",pid=9001,fd=3))
#                ^rogue listener            ^the owning process = your foothold
```

---

## §9 — GitHub Artifact (the 6-artifact evidence package)

1. **Script:** `scripts/net_connections.sh` (committed, `shellcheck`-clean).
2. **Detection rule/config:** a baseline allowlist of expected ports (rule precursor) + a Wazuh
   ports-inventory note.
3. **Runbook:** `docs/runbooks/runbook-rogue-listener.md` — "when a new listening port appears, do X."
4. **Playbook:** `docs/playbooks/network-evidence-play.md` (ss→lsof→peer rep→capture→contain).
5. **Incident report + notes:** the reverse-shell drill (caught the `:4444` + PID) + notes.
6. **SOC ticket:** `SOC-07` (Task: "connection baseline + catch reverse shell") → Closed.

---

## §10 — Portfolio Artifact

- **Resume bullet:** "Built host network-connection triage (`net_connections.sh`); detected a
  reverse shell by its rogue listener and identified C2 beaconing via packet timing analysis."
- **Interview talking point:** "first commands to find a reverse shell?" → `ss -tunap`/`lsof`, then
  explain beaconing detection by behavior not port.
- **Serves:** SOC T1 → T2 (Stages 2–3). Bridges NaviOpsNetwork.

---

## §11 — Certification Crossover Notes

- **Security+:** networking + attacks (2.x/3.x/4.x). **CySA+:** network analysis. **SC-200:**
  network signals. **BTL1:** network forensics. Builds on NaviOpsNetwork (tcpdump/firewalls).
  Detail: `alignment/CERTIFICATION-MAPPING.md`.

---

## §12 — Security Notes (Lens E — Attacker & Defender)

**🔴 Attacker:** reverse/bind shells (T1059 + a listener), C2 over 443 to blend in (T1071.001,
T1573 encrypted channel), beaconing with jitter, exfil over HTTPS/DNS (T1041/T1048), and using
common ports to evade port-based rules.

**🔵 Defender:** baseline listeners + egress; alert on new listening ports and outbound to
rare/known-bad destinations; detect beaconing by **behavior** (periodicity/volume); restrict and
log egress; feed threat-intel IOCs (Lesson 09). Port number lies — behavior and destination don't.

---

## Quiz (Interview-Style, Graded)

**Q1.** What's the fastest way to find a reverse shell on a Linux host, and what does each command
show?
> **Your answer:**

**Q2.** Why can't you rely on the port number to identify C2, and what behavioral signals reveal
beaconing?
> **Your answer:**

**Q3.** Why do defenders care more about egress than ingress for catching an active intrusion?
> **Your answer:**

**Q4.** **Scenario:** a host has an established connection to 203.0.113.50:443 every 60 seconds,
~200 bytes each. What do you suspect, and how do you investigate + confirm?
> **Your answer:**

**Q5.** Why must you capture network state before isolating a compromised host?
> **Your answer:**

*(Request the "Professional Answer" comparison under each before moving on.)*

---

## Reflection
*(After the quiz)* — What did you learn? · What confused you? · What would you do differently?

---

## Search Keywords For Further Understanding

**Core**
- `ss command find listening ports process`
- `detect reverse shell linux ss lsof`
- `c2 beaconing detection behavior`
- `egress filtering exfiltration detection`
- `tshark io stat periodicity`

**Tools**
- `tcpdump capture filter outbound`
- `wazuh open ports inventory`

**Going further**
- `threat intelligence iocs` (L09) · `mitre att&ck` (L10) · `port scan detection` (L20) · `threat hunting` (L25)

**Red / Blue (Lens E):**
- 🔴 `reverse shell T1059`, `c2 app layer T1071`, `encrypted channel T1573`, `exfil T1041 T1048`
- 🔵 `listening port baseline alert`, `beaconing detection`, `egress filtering`, `threat intel match`

---

## Lesson Status
- [ ] §8 lab completed (baseline; reverse shell caught; beacon observed)
- [ ] 6-artifact evidence package committed (§9)
- [ ] Quiz answered + professional-answer comparisons (graded)
- [ ] Reflection + Search Keywords reviewed

When complete, run the Update Protocol, then move to **Lesson 08 — Threat Modeling Basics**.

---

*Lesson 07 written by Navi · 2026-06-20 · full-depth. Sources to cite at study time: man7 `ss(8)`/
`tcpdump(1)`, MITRE ATT&CK Command-and-Control + Exfiltration tactics, Wireshark docs.*
