# Lesson 03 — TCP/IP

**Status:** ✅ ready for self-study (full depth) · **Date written:** 2026-06-22
**Schema:** 12-section (`docs/learning/CLAUDE_TEACHING_RULES.md`)
**Focus:** the 4-layer TCP/IP model, the TCP 3-way handshake & teardown, TCP vs UDP, ports/sockets,
sequence/ACK numbers, and the TCP flags.
**Primary artifact:** `docs/networking/tcp-handshake.md` + a saved capture.

> **How to use this lesson:** OSI (Lesson 02) was the *map*; TCP/IP is the *stack the Internet
> actually runs*. Read §1, then capture a real handshake in §8 and annotate it — this single capture
> teaches more than any diagram.

---

## §1 — Concept (Scientific Theory)

### What it is
**TCP/IP** is the protocol suite the Internet runs on, described as a **4-layer model** (RFC 1122)
that maps onto OSI:

| TCP/IP layer | OSI equivalent | Protocols |
|---|---|---|
| **Application** | L5–L7 | HTTP, DNS, SSH, TLS, SMTP |
| **Transport** | L4 | **TCP**, **UDP** |
| **Internet** | L3 | IP, ICMP, ARP |
| **Link (Network Access)** | L1–L2 | Ethernet, Wi-Fi |

### TCP vs UDP (the core transport choice)
| | TCP | UDP |
|---|---|---|
| Connection | connection-oriented (handshake) | connectionless ("fire and forget") |
| Reliability | guaranteed, ordered, retransmits | none — app handles loss if needed |
| Overhead | higher (state, ACKs) | minimal, fast |
| Header | 20+ bytes (seq/ack/flags/window) | 8 bytes |
| Use cases | web, SSH, email, file transfer | DNS, DHCP, VoIP, video, NTP |

Mental model: **TCP is a phone call** (establish, confirm each word, hang up); **UDP is a postcard**
(send it, no confirmation).

### Ports & sockets
A **port** (0–65535) identifies a service on a host. A **socket** is the full tuple
`protocol:src-IP:src-port ↔ dst-IP:dst-port` — what uniquely identifies one connection. Well-known
ports: 22 SSH, 53 DNS, 80 HTTP, 443 HTTPS, 67/68 DHCP, 123 NTP.

### The TCP 3-way handshake (connection setup)
```
 Client                         Server
   │ ── SYN  (seq=x) ─────────────► │   "let's talk, my seq starts at x"
   │ ◄── SYN-ACK (seq=y, ack=x+1) ─ │   "ok, my seq=y, I got your x"
   │ ── ACK  (ack=y+1) ───────────► │   "got your y — established"
   │  ====== connection ESTABLISHED ======
```

### Teardown (graceful close — the 4-way FIN)
```
   │ ── FIN ──► │   client done sending
   │ ◄── ACK ── │
   │ ◄── FIN ── │   server done sending
   │ ── ACK ──► │   → TIME_WAIT (then CLOSED)
```
(A **RST** is the abrupt slam-the-phone-down close — refused/aborted.)

### Sequence & ACK numbers + flags
- **SEQ**: byte-offset of this segment's first data byte; **ACK**: next byte expected — together they
  guarantee ordering + detect loss (missing ACK → retransmit).
- **Flags:** `SYN` (open), `ACK` (acknowledge), `FIN` (graceful close), `RST` (reset/refuse),
  `PSH` (push to app now), `URG` (urgent).

### Three-Level Depth (Lens A)
- **Level 1 — Beginner:** TCP makes sure data arrives complete and in order; UDP is faster but
  doesn't guarantee delivery. Ports route data to the right program.
- **Level 2 — NetOps/NOC:** you read connection **states** with `ss -tan` (LISTEN, SYN-SENT,
  ESTABLISHED, TIME_WAIT, CLOSE_WAIT). A pile of `SYN-RECV` = possible SYN flood; many `CLOSE_WAIT` =
  an app not closing sockets. A refused connection returns `RST`; a filtered one just times out.
- **Level 3 — Wire/Kernel (Lens D):** TCP is a **state machine** in the Linux kernel. The handshake
  sets up sequence spaces; the **sliding window** + **congestion control** (cwnd, slow-start) govern
  throughput; `TIME_WAIT` (2×MSL) prevents stray old segments from corrupting a new connection. You
  can watch it all in `ss -ti` and a capture.

### Two Teaching Approaches (Lens B) — handshake
**Technical:** the 3-way handshake synchronizes initial sequence numbers in *both* directions and
confirms both sides can send and receive before any data flows.

**Analogy:** a **phone call** — "Hi, can you hear me?" (SYN) / "Yes, can you hear me?" (SYN-ACK) /
"Yes, go ahead" (ACK), then talk, then "bye" / "bye" (FIN/FIN). *Where it breaks down:* phones don't
carry sequence numbers, and a RST has no polite phone equivalent (just hanging up mid-word).

### Visual (ASCII) — a socket is the 4-tuple
```
   curl http://10.0.0.10:80
   socket:  TCP 10.0.0.5:51514  ──►  10.0.0.10:80
            └ src ip:port ┘          └ dst ip:port ┘   (proto+4 fields = unique connection)
```

---

## §2 — Linux Networking Commands

```bash
ss -tan                          # all TCP sockets + states (LISTEN/ESTAB/TIME-WAIT...)
ss -tuln                         # listening TCP+UDP ports, numeric
ss -tip                          # per-socket internals: rtt, cwnd, retrans (add to a conn)
ss -s                            # socket summary (totals by state)
nc -vz 10.0.0.10 443             # test if a TCP port is open/refused/filtered
nc -u -vz 10.0.0.10 53           # UDP probe (best-effort)
tcpdump -ni eth0 'tcp port 80'   # capture the handshake + data on the wire
tcpdump -ni eth0 'tcp[tcpflags] & tcp-syn != 0'   # only SYNs (handshake/scan detection)
curl -v http://10.0.0.10/        # app-layer round trip with timing
```

**Cisco/CCNA mapping:** ACLs match by protocol+port (`permit tcp any host ... eq 443`); `show ip
sockets`/control-plane shows device-originated connections. The TCP/UDP port concepts are identical.

---

## §3 — Real-World Use Cases

**Production scenarios:**
1. **"Connection refused vs timeout":** `RST` = service down/port closed (fix the service); timeout
   = firewall dropping (fix the rule). The distinction routes the ticket.
2. **Socket leak:** many `CLOSE_WAIT` sockets means the application isn't `close()`ing — an app bug,
   not a network one (`ss -tan state close-wait`).
3. **Choosing transport:** real-time (VoIP/video/DNS) → UDP; correctness-critical (web/SSH/files) →
   TCP. Wrong choice = latency or corruption.
4. **Latency analysis:** `ss -ti` exposes per-connection RTT and retransmits — the evidence behind a
   "slow app" that isn't a bandwidth problem.

**How NOC engineers use it:** reading `ss` states is daily Tier-1/2 work; "is the port listening and
reachable?" (`ss -tuln` + `nc -vz`) resolves a huge share of service tickets.

**When NOT to:** don't use TCP for high-rate telemetry where occasional loss is fine — the handshake
+ retransmit overhead hurts; UDP (or QUIC) fits.

**Exam framing (Net+/CCNA):** the handshake, TCP-vs-UDP table, well-known ports, and flags are
guaranteed.

---

## §4 — Troubleshooting Section

| Symptom | Likely cause | Diagnose | Fix |
|---|---|---|---|
| `Connection refused` | nothing listening / port closed | `ss -tuln` on server; `nc -vz` | start service / correct port |
| Connection **times out** | firewall dropping (filtered) | `nc -vz` (hangs); `tcpdump` (SYN, no SYN-ACK) | open firewall / route |
| Many `TIME_WAIT` | normal after high churn | `ss -s` | usually benign; tune if extreme |
| Many `CLOSE_WAIT` | app not closing sockets | `ss -tanp state close-wait` | fix/restart the app |
| Slow transfer, link fine | retransmits / small window | `ss -ti` (retrans, rtt, cwnd) | fix loss (L1/2), MTU, tuning |

**Diagnostic sequence:** `ss -tuln` (listening?) → `nc -vz host port` (reachable?) → `tcpdump`
(handshake completing?) → `ss -ti` (retransmits/RTT?). **Redaction check:** RFC 5737 ranges; never
commit a real `.pcap` from a production network.

---

## §5 — Common Mistakes

| Mistake | Impact | Fix |
|---|---|---|
| Treating refused == timeout | wrong team/fix | RST=service, timeout=firewall |
| Using UDP and expecting reliability | silent data loss | TCP, or add app-level acks |
| Forgetting the ephemeral source port | misread captures/ACLs | client uses a high random src port |
| Ignoring `CLOSE_WAIT` buildup | socket exhaustion, outage | it's an app bug — fix the close path |
| Blocking ICMP everywhere | breaks PMTUD → black-hole | allow needed ICMP types |

---

## §6 — NOC Perspective

> NOC Technician focus (Stage 1, `ROADMAP.md`).

TCP state is a core NOC signal. Dashboards track listeners, connection counts, and retransmit rates.
A spike in half-open `SYN-RECV` triggers a possible-SYN-flood alert (§12); a climbing `CLOSE_WAIT`
count on an app server is a "restart/patch the app" ticket. The fast NOC verdict on a service
incident is `ss -tuln` + `nc -vz`: listening *and* reachable, or not.

---

## §7 — Incident-Response Perspective

- **Detect:** users report "can't connect"; monitoring shows port-check failures or retransmit
  spikes.
- **Triage:** refused (service) vs timeout (network/firewall) vs slow (loss) — different severities
  and owners.
- **Diagnose (RCA):** confirm with `ss`/`nc`/`tcpdump` whether the handshake completes and where it
  stalls (no SYN-ACK = firewall/route; RST = service).
- **Fix → Recover → Document:** restore the service/rule, verify a clean handshake in a capture, and
  write the runbook (symptom → which packet was missing → fix).

---

## §8 — Practical Lab (build this yourself)

**Goal:** capture and annotate a real TCP 3-way handshake, and document TCP states — producing
`docs/networking/tcp-handshake.md` + a saved capture.

### Lens C — Manual → Automated → Why
- **Manual:** open a capture, run a `curl`, read the SYN/SYN-ACK/ACK by hand.
- **Automated:** add a `scripts/port_check.sh` that loops a host:port list with `nc -vz` and reports
  open/refused/timeout — the repeatable service-reachability check.
- **Why:** a scripted port sweep gives consistent evidence on every service ticket instead of ad-hoc
  `telnet` guessing.

### Steps
1. In one terminal: `sudo tcpdump -ni lo -w /tmp/handshake.pcap 'tcp port 80'` (or `eth0` to a lab
   server).
2. In another: start a listener `python3 -m http.server 80` (lab), then `curl http://127.0.0.1/`.
3. Stop the capture; read it: `tcpdump -nr /tmp/handshake.pcap -v` — identify the **SYN → SYN-ACK →
   ACK**, the data + `PSH/ACK`, and the **FIN** teardown. Annotate seq/ack progression in the doc.
4. Inspect live states: `ss -tan | head` during a `sleep`-held connection; observe `ESTABLISHED`
   then `TIME_WAIT`.
5. Build `scripts/port_check.sh` (skeleton):

```bash
#!/usr/bin/env bash
# port_check.sh — TCP reachability sweep. Lesson 03.
set -euo pipefail
while read -r host port; do
  if nc -z -w2 "$host" "$port" 2>/dev/null; then echo "OPEN    $host:$port"
  else echo "CLOSED/FILTERED  $host:$port"; fi
done < "${1:-targets.txt}"
```

6. **Break-it drill:** stop the listener and re-run — see `RST`/refused in the capture and `CLOSED`
   from the script.

### Lens D — read the state machine live
`ss -tio state established` on an active download shows `rtt`, `cwnd`, and `retrans` — the kernel's
TCP control variables changing in real time.

---

## §9 — GitHub Artifact (evidence 5-tuple)

1. **Script:** `scripts/port_check.sh` (committed, shellcheck-clean).
2. **Config/doc:** `docs/networking/tcp-handshake.md` — annotated handshake + states + saved
   (lab-only) capture.
3. **Drill:** refused-vs-timeout drill captured in `troubleshooting-drills.md`.
4. **NAVI ticket:** `NAVI-03` (Task: "capture+annotate TCP handshake, port_check.sh") To Do→Done.
5. **Incident report:** `docs/runbooks/incident-connection-refused.md` — symptom→RCA(missing packet)→fix→verify.

---

## §10 — Portfolio Artifact

- **Resume bullet:** "Diagnosed connectivity incidents by distinguishing TCP refused vs filtered via
  packet capture and `ss` state analysis; built a port-reachability sweep (`port_check.sh`)."
- **Interview talking point:** explain the 3-way handshake, TCP vs UDP trade-offs, and how you tell
  "refused" from "timeout" — a classic SOC/NOC interview question.
- **Serves:** NOC Technician → NetOps (Stages 1–2).

---

## §11 — RHCSA Crossover Notes

Direct overlap: verifying that a service **listens** (`ss -tuln`) and that **firewalld** allows the
port is a core RHCSA task chain (e.g. "make httpd reachable"). `nc`/`ss` and the listening-vs-firewall
distinction transfer straight to RHCSA service-troubleshooting.

---

## §12 — Security Notes (Lens E — Attacker & Defender)

> Frameworks: [MITRE ATT&CK](https://attack.mitre.org/).

**🔴 Attacker:** **TCP/port scanning** to enumerate services — SYN/connect scans (`T1046` Network
Service Discovery); a **SYN flood** (half-open floods, DoS) abuses the handshake; and the handshake
banner often leaks service versions for targeting.

**🔵 Defender:** **SYN cookies** (Linux `net.ipv4.tcp_syncookies`) blunt SYN floods; rate-limit and
alert on bursts of SYNs from one source (IDS/`tcpdump` filter above); expose only required ports and
detect scans via connection-attempt spikes in flow logs. Verify by running a lab `nmap -sS` and
confirming it's logged/alerted.

---

## Quiz (Interview-Style, Graded)

**Q1.** Walk through the TCP 3-way handshake, including what SEQ/ACK numbers accomplish.
> **Your answer:**

**Q2.** Give three differences between TCP and UDP and one real protocol that uses each.
> **Your answer:**

**Q3.** What uniquely identifies a single TCP connection on a host?
> **Your answer:**

**Q4.** **Scenario:** a client gets "connection timed out" to port 443; another gets "connection
refused" to port 22 on the same server. What does each tell you and how do you confirm?
> **Your answer:**

**Q5.** You see hundreds of `CLOSE_WAIT` sockets on an app server. What does that indicate and whose
problem is it?
> **Your answer:**

**Q6.** What is a `RST` and when is it sent?
> **Your answer:**

*(After you answer, request the "Professional Answer" comparison under each — graded before Lesson 04.)*

---

## Reflection
*(Fill in after the quiz)* — What did you learn? · What confused you? · What would you do differently?

---

## Search Keywords For Further Understanding

**Core**
- `tcp three way handshake syn synack ack`
- `tcp vs udp differences`
- `tcp connection states time_wait close_wait`
- `ports sockets ephemeral port`
- `tcp flags syn fin rst psh urg`

**Tools**
- `ss tcp states linux`
- `tcpdump capture handshake filter`
- `nc port test refused vs timeout`

**Going further (future lessons)**
- `ipv4 addressing arp` (L05) · `dhcp dora` (L12) · `dns resolution` (L13) · `nat pat` (L14)

**Red / Blue (Lens E):**
- 🔴 `syn flood attack`, `port scanning nmap T1046`
- 🔵 `tcp syncookies linux`, `detect port scan ids`

---

## Lesson Status
- [ ] §8 lab completed (handshake captured+annotated; port_check.sh built)
- [ ] §4 drill done
- [ ] Evidence committed (§9)
- [ ] Quiz answered + professional-answer comparisons (graded)
- [ ] Reflection + Search Keywords reviewed

When complete, run the Update Protocol, then move to **Lesson 04 — Subnetting Masterclass**.

---

*Lesson 03 written by Navi · 2026-06-22 · full-depth. Sources to cite when worked: RFC 793/9293,
RFC 768, RFC 1122, man7.org `ss`/`tcpdump`, CompTIA Network+ N10-009, MITRE ATT&CK T1046.*
