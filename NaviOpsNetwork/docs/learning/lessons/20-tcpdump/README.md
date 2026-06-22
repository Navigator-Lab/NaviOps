# Lesson 20 — tcpdump

**Status:** ✅ ready for self-study (full depth) · **Date written:** 2026-06-20
**Schema:** 12-section (`docs/learning/CLAUDE_TEACHING_RULES.md`)
**Focus:** BPF capture filters, ring buffers, headless capture then analyze, `-nn`/`-X`/`-w`, server capture triage.
**Primary artifact:** `scripts/capture_triage.sh`.

> **How to use this lesson:** tcpdump is Wireshark's headless cousin — the tool you actually use
> *on the server* during an incident (no GUI). Read §1–§7, build `capture_triage.sh` in §8. Own
> hosts only; never commit raw captures.

---

## §1 — Concept (Scientific Theory)

### What it is
**tcpdump** is the command-line packet capture tool present on virtually every Unix/Linux server.
It captures frames matching a **BPF (Berkeley Packet Filter)** expression, prints a one-line
summary per packet (or full hex with `-X`), and can write to a `.pcap` file (`-w`) for later
analysis in Wireshark (Lesson 19). It's the practical reality of packet capture in operations:
you SSH to the affected server and run tcpdump.

### Why it exists
You can't install a GUI on every server, and during an incident you need to capture *right where
the problem is*. tcpdump is always available, scriptable, low-overhead, and uses the same BPF
filter engine as Wireshark's capture filters — so it's the field tool, with Wireshark as the
deep-analysis back-end.

### The essential flags
| Flag | Meaning |
|---|---|
| `-i <if>` / `-i any` | interface to capture on |
| `-n` / `-nn` | don't resolve names / nor ports (faster, clearer) |
| `-c N` | stop after N packets |
| `-w file.pcap` | write raw capture (for Wireshark) |
| `-r file.pcap` | read a saved capture |
| `-X` / `-A` | show hex+ASCII / ASCII payload |
| `-e` | show the Ethernet (L2) header |
| `-s 0` | full packet (snaplen; modern default is already full) |
| `-G <sec> -W <n>` | rotate files every G seconds, keep n (**ring buffer**) |

### BPF capture-filter language (learn the common forms)
```
host 10.0.0.5            net 10.0.0.0/24          port 443         portrange 1-1024
tcp / udp / icmp / arp   src host X / dst host Y   tcp port 80 and host X
'tcp[tcpflags] & tcp-syn != 0'    # SYN packets (for handshake/scan analysis)
'port 67 or port 68'     # DHCP        'port 53'   # DNS
```

### Three-Level Depth (Lens A)
- **Level 1 — Beginner:** tcpdump prints the network traffic going through a server's interface,
  one line per packet, so you can see what's actually happening without a GUI.
- **Level 2 — NetOps/NOC:** you craft a tight BPF filter (so you only capture what matters on a
  busy server), use `-nn` for speed/clarity, capture to a file with `-w` for Wireshark, and use a
  **ring buffer** (`-G`/`-W`) for "capture until the intermittent problem happens" without filling
  the disk. You read the one-line output to confirm handshakes, see resets, watch DHCP/DNS, and
  prove a firewall drop (SYN out, no SYN-ACK back).
- **Level 3 — Wire/Kernel (Lens D):** tcpdump compiles the BPF expression into bytecode that runs
  **in the kernel** (the BPF VM), so only matching packets are copied to userspace — that's why
  it's efficient even on busy links. It uses the `AF_PACKET` socket and (with `-i any` or
  promiscuous mode) sees more traffic. `-w` writes the standard **pcap** format Wireshark reads.

### Two Teaching Approaches (Lens B) — filter-first capture & capture-then-analyze

**Approach 1 (technical):** specify a BPF filter to constrain capture to the flow of interest
(reducing volume and kernel→userspace copies), choose output (one-line summary for live reading,
`-X` for payload, `-w` for a pcap), and either read inline or move the pcap to Wireshark for deep
dissection. For intermittent issues, use a time/size ring buffer so you can leave it running.

**Approach 2 (analogy):** tcpdump is a **wiretap with a keyword filter**, Wireshark is the
**forensics lab**.
- On the server (the scene), you place a tap and tell it "only record calls involving *this
  number* about *this topic*" (the BPF filter) so you're not drowning in everyone's calls.
- For a quick listen, you read the live transcript lines on the spot (`tcpdump` output).
- For a thorough investigation, you bag the recording (`-w file.pcap`) and send it to the lab
  (Wireshark) where analysts reassemble and dissect it (Lesson 19).
- **Where it breaks down:** a wiretap implies you can hear everyone; on a switch tcpdump (like
  Wireshark) only sees the server's own traffic + broadcast/multicast unless mirrored — it's a
  *host* tap, which is usually exactly what you want (capture *at the affected server*).

### Visual (ASCII) — capture-on-server, analyze-in-Wireshark workflow

```
   AFFECTED SERVER (ssh in)                          YOUR WORKSTATION
   sudo tcpdump -nni eth0 -w /tmp/cap.pcap \         scp cap.pcap here
        'host 10.0.0.50 and port 443'   ──────────►  open in Wireshark (L19)
   (tight BPF filter = small file)                   Follow Stream / Expert Info
   intermittent? add: -G 60 -W 10  (ring: 60s files, keep 10)
   live read instead: sudo tcpdump -nni eth0 'tcp port 443'  → watch [S]/[S.]/[.] flags
```

---

## §2 — Linux Networking Commands

```bash
sudo tcpdump -nni eth0 'tcp port 443' -c 20             # live, 20 packets, no name resolution
sudo tcpdump -nni any 'port 53' -c 10                   # DNS exchange (Lesson 13)
sudo tcpdump -nni any 'port 67 or port 68'              # DHCP DORA (Lesson 12)
sudo tcpdump -nni eth0 'tcp[tcpflags] & tcp-syn != 0'   # SYN packets (handshakes/scans)
sudo tcpdump -nni eth0 'host 10.0.0.50' -w /tmp/cap.pcap   # write for Wireshark
sudo tcpdump -nni eth0 -G 60 -W 10 -w /tmp/cap-%H%M%S.pcap 'port 443'   # ring buffer
sudo tcpdump -nnXr /tmp/cap.pcap 'port 80'              # read back + hex/ASCII payload
sudo tcpdump -enni eth0 arp                              # ARP with L2 (Ethernet) headers
```

**Cisco/CCNA mapping:** IOS has `monitor capture` (EPC) for on-device capture; the BPF concept
maps to the analyzer skill. tcpdump is the Linux/server-side reality CCNA-adjacent NetOps lives in.

---

## §3 — Real-World Use Cases

**Production scenarios:**
1. **Prove a firewall drop:** capture on both client and server — SYN leaves the client, never
   arrives at the server = dropped in the path/firewall (Lesson 15). The definitive evidence.
2. **Intermittent issue:** leave a ring-buffer capture running; when it recurs, you have the pcap.
3. **Headless server triage:** no GUI — `tcpdump` confirms whether traffic reaches the server, the
   handshake completes, DNS/DHCP work, or resets are flying.
4. **Capture for escalation:** `-w` a tight pcap, hand it to Tier-2/3 / Wireshark.
5. **Security:** spot beaconing, plaintext creds, or scan patterns (Lessons 28/36).

**How NOC/admins use it:** the *server-side* capture tool. When you SSH into the box that's having
trouble, tcpdump is how you see the traffic. Pair with Wireshark for analysis.

**When NOT to:** don't run an unfiltered capture on a busy production server (load + huge files +
privacy); always filter, bound with `-c` or a ring buffer, and clean up.

**Exam framing (Net+/CCNA):** tcpdump is the named CLI protocol-analyzer/packet-capture tool;
BPF filtering and capture-to-file are the expected skills.

---

## §4 — Troubleshooting Section

| Symptom | tcpdump approach | Look for |
|---|---|---|
| Connection won't establish | capture both ends, `tcp port N` | SYN out, no SYN-ACK = path/firewall drop |
| Service unreachable | `host X and port N` on the server | does traffic even arrive? |
| DNS issue | `-nni any port 53` | query out, response rcode |
| DHCP failure | `-nni any port 67 or 68` | DISCOVER with no OFFER (drill 2) |
| Resets/instability | `tcp[tcpflags] & tcp-rst != 0` | who sends RST, when |
| Intermittent | ring buffer `-G -W` | capture spanning the event |

**Redaction check (critical):** captures contain real data — **never commit raw `.pcap`**; only
sanitized one-line extracts or masked screenshots. Delete pcaps from servers after use.

---

## §5 — Common Mistakes

| Mistake | Impact | Fix |
|---|---|---|
| Unfiltered capture on a busy host | load, huge files, dropped packets | always use a BPF filter |
| Forgetting `-nn` | slow (DNS lookups), confusing | `-nn` for speed/clarity |
| No bound (`-c`/ring) | fills the disk | `-c N` or `-G/-W` ring |
| Capturing the wrong interface | empty capture | check with `ip -br link`; use `-i any` to start |
| Committing raw pcap | data/credential leak | sanitize; never commit |
| Leaving captures on the server | disk + privacy | clean up after |

---

## §6 — NOC Perspective

> NOC Technician focus (Stage 1, `ROADMAP.md`).

tcpdump is the NOC's *field* capture tool — you SSH to the affected server and capture *there*,
which is often the only place that proves whether traffic arrives. The high-value Tier-1 move is a
**both-ends capture** to localize a drop (client side: SYN sent; server side: SYN absent → it's
the path/firewall) and a **tight pcap for escalation** (`noc/escalation-matrix.md`). Ring buffers
turn "it happens randomly at night" into a capturable event — a great handover watch-item setup
(`noc/shift-handover.md`).

---

## §7 — Incident-Response Perspective

- **Detect/Triage:** logs/counters inconclusive → capture on the affected host.
- **Preserve evidence:** `-w` a pcap *before* changing anything (and before it recurs/rolls).
- **Diagnose (RCA):** the capture shows the exact failure point (dropped SYN, RST, no DHCP OFFER).
- **Document:** attach sanitized extracts to the runbook; in security IR (Lesson 36) the pcap is
  the forensic centerpiece. Used across drills 1, 2, 8.

---

## §8 — Practical Lab (build this yourself)

**Goal:** build `scripts/capture_triage.sh` — a guided, safe, filtered server capture + quick
summary — and use it to capture a drill.

### Lens C — Manual → Automated → Why
- **Manual:** craft a BPF filter, capture with bounds, read the output.
- **Automated:** `capture_triage.sh <iface> <bpf>` — runs a **bounded** capture (`-c`/timeout),
  writes a timestamped pcap, prints a quick summary (packet count, top talkers, SYN-without-ACK
  count), and reminds you to redact/clean up.
- **Why:** safe, consistent captures under pressure (correct flags, bounded, never unfiltered),
  with a quick verdict before you even open Wireshark — exactly how on-call engineers capture
  without footguns.

### Steps
1. Practice the §2 filters live: handshake (`tcp port 443`), DNS (`port 53`), DHCP (`67 or 68`),
   SYN-only (`tcp[tcpflags] & tcp-syn != 0`).
2. Build `scripts/capture_triage.sh`:

```bash
#!/usr/bin/env bash
# capture_triage.sh — safe, bounded server capture + quick summary. Lesson 20.
# Usage: sudo ./capture_triage.sh <iface> "<bpf filter>" [seconds]
set -euo pipefail
iface="${1:?usage: capture_triage.sh <iface> \"<bpf>\" [seconds]}"
bpf="${2:?need a BPF filter — never capture unfiltered}"
secs="${3:-30}"
out="/tmp/triage-$(date +%H%M%S).pcap"
echo "Capturing on $iface filter='$bpf' for ${secs}s -> $out"
timeout "$secs" tcpdump -nni "$iface" -w "$out" "$bpf" || true
echo "== summary =="
tcpdump -nnr "$out" 2>/dev/null | wc -l | xargs echo "packets:"
echo "SYN-without-ACK (possible drops/scan):"
tcpdump -nnr "$out" 'tcp[tcpflags] & (tcp-syn|tcp-ack) = tcp-syn' 2>/dev/null | wc -l
echo "REMINDER: redact before sharing; delete $out when done (raw pcap = sensitive)."
```

3. `bash -n` → `shellcheck` → run it for a known flow.
4. **Drill:** run drill 8 (firewall block) capturing on both sides and show the SYN-no-SYN-ACK
   signature with the script; or drill 2 (DHCP) capturing DORA.

### Lens D — BPF in the kernel
Note in your notes that the BPF filter compiles to bytecode executed by the **kernel BPF VM**, so
only matching packets reach userspace — verify with a tight filter on a busy interface and see low
CPU/file size vs unfiltered.

---

## §9 — GitHub Artifact (evidence 5-tuple)

1. **Script:** `scripts/capture_triage.sh` (bounded, filtered, summarizing).
2. **Config/doc:** a BPF-filter quick-reference appended to `docs/networking/wireshark-filters.md`
   (or a `tcpdump-filters.md`).
3. **Drill:** drill 8 or 2 captured (sanitized extract).
4. **NAVI ticket:** `NAVI-20` (Task: "capture_triage.sh + BPF cookbook").
5. **Incident report:** a capture-backed runbook (e.g. `incident-firewall-block.md` enriched with
   the sanitized capture evidence).

---

## §10 — Portfolio Artifact

- **Resume bullet:** "Built a safe, filtered server-side packet-capture triage tool
  (`capture_triage.sh`) with ring-buffer support; localized a firewall-drop incident via dual-side
  capture evidence."
- **Interview talking point:** the both-ends capture to localize a drop, BPF vs display filters,
  and why you never run an unfiltered capture on a busy server.
- **Serves:** NOC + Network Operations + SOC track (Stages 1–2, 5).

---

## §11 — RHCSA Crossover Notes

RHCSA-relevant in practice: `tcpdump` on a RHEL host to confirm whether traffic reaches a service
(complements firewalld/service troubleshooting). Not a named RHCSA objective, but a standard admin
diagnostic skill on Red Hat systems.

---

## §12 — Security Notes (Lens E — Attacker & Defender)

> Frameworks: [MITRE ATT&CK](https://attack.mitre.org/) · [GTFOBins](https://gtfobins.github.io/).

**🔴 Attacker:** tcpdump = **network sniffing** (`T1040`) for credential/data harvesting on a
compromised host; it's a dual-use binary (on GTFOBins for some privilege contexts). Ring-buffer
captures can be used to quietly collect traffic over time.

**🔵 Defender:** **encrypt traffic** (TLS/SSH/VPN) so a capture is worthless; **restrict who can
run tcpdump** (needs `CAP_NET_RAW`/root) and **alert on its execution** on servers (Lesson 28 —
unexpected tcpdump on a prod host is a red flag); segment so a sniffer sees little. Use tcpdump
*defensively* too — it feeds IDS/forensics. Verify a TLS-only capture yields no plaintext (lab).

---

## Quiz (Interview-Style, Graded)

**Q1.** Why use a BPF capture filter, and where does that filter actually run (and why does that
matter for performance)?
> **Your answer:**

**Q2.** You suspect a firewall is dropping traffic to a server. Describe the tcpdump approach that
proves it.
> **Your answer:**

**Q3.** What do `-nn`, `-w`, and `-G/-W` do, and when would you use each?
> **Your answer:**

**Q4.** **Scenario:** A problem happens randomly a few times a night on a production server. How do
you capture it without filling the disk or running unfiltered all night?
> **Your answer:**

**Q5.** Write a BPF filter to capture only DNS traffic to/from `10.0.0.53`.
> **Your answer:**

**Q6.** Why must captures be handled carefully (redaction) and tcpdump access be restricted?
> **Your answer:**

*(After you answer, request the "Professional Answer" comparison under each — graded before Lesson 21.)*

---

## Reflection
*(Fill in after the quiz)* — What did you learn? · What confused you? · What would you do differently?

---

## Search Keywords For Further Understanding

**Core**
- `tcpdump bpf filter examples`
- `tcpdump capture to file wireshark`
- `tcpdump ring buffer -G -W`
- `tcpdump tcp flags syn filter`

**Tools**
- `tcpdump cheat sheet`
- `tcpdump read pcap -r`
- `bpf berkeley packet filter`

**Going further (future lessons)**
- `wireshark analysis` (L19) · `suricata ids rules` (L28) · `network forensics`

**Red / Blue (Lens E):**
- 🔴 `tcpdump sniffing T1040`, `tcpdump gtfobins`, `credential harvesting capture`
- 🔵 `restrict cap_net_raw tcpdump`, `alert tcpdump execution server`, `encrypt traffic`

---

## Lesson Status
- [ ] §8 lab completed (capture_triage.sh + BPF practice)
- [ ] §4 drill done (drill 8 or 2, captured)
- [ ] Evidence committed (§9)
- [ ] Quiz answered + professional-answer comparisons (graded)
- [ ] Reflection + Search Keywords reviewed

When complete, run the Update Protocol, then move to **Lesson 21 — Network Monitoring**.

---

*Lesson 20 written by Navi · 2026-06-20 · full-depth. Sources to cite when worked: tcpdump/pcap man
pages, BPF docs, CompTIA Network+ N10-009, MITRE ATT&CK T1040, GTFOBins.*
