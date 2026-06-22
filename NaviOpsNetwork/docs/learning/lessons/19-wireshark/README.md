# Lesson 19 — Wireshark

**Status:** ✅ ready for self-study (full depth) · **Date written:** 2026-06-20
**Schema:** 12-section (`docs/learning/CLAUDE_TEACHING_RULES.md`)
**Focus:** GUI + `tshark`, display vs capture filters, follow stream, reading TCP/DNS/TLS/HTTP, expert info, IO graphs.
**Primary artifact:** `docs/networking/wireshark-filters.md`.

> **How to use this lesson:** Wireshark turns the abstract (OSI layers, handshakes) into something
> you can *see*. Read §1–§7, capture and dissect real exchanges in §8, build the filter cookbook.
> Capture only on networks/hosts you own; redact — never commit raw `.pcap` from a real network.

---

## §1 — Concept (Scientific Theory)

### What it is
**Wireshark** is the standard GUI **packet analyzer**: it captures frames off an interface and
**dissects** them — decoding every layer (Ethernet → IP → TCP → TLS → HTTP) into a readable tree.
**`tshark`** is its command-line sibling (for headless servers and scripting). Wireshark is how you
*see* everything Lessons 02–16 described actually happening on the wire.

### Why it exists
Sometimes counters and logs aren't enough — you need ground truth: *what exactly is on the wire?*
Is the TCP handshake completing? Is the TLS cert being rejected? Is the DNS response NXDOMAIN? Is
the app sending malformed data? Wireshark answers definitively, which is why it's the tool of last
resort (and first resort for the experienced) in hard network and security cases.

### The two filter types (the #1 thing to get right)
| Filter | When applied | Syntax | Example |
|---|---|---|---|
| **Capture filter** | *during* capture (BPF, limits what's recorded) | `tcp port 443` | `host 10.0.0.5 and port 53` |
| **Display filter** | *after* capture (Wireshark syntax, filters the view) | `http.response.code == 502` | `tcp.flags.syn==1 && tcp.flags.ack==0` |

Capture filters reduce volume (use on busy links); display filters drill into an existing capture.
**They have different syntax** — a constant beginner trip-up.

### Key features
- **Follow Stream:** reassemble a whole TCP/HTTP/TLS conversation into readable form.
- **Expert Info:** Wireshark flags retransmissions, dup ACKs, resets, malformed packets.
- **IO Graphs:** visualize throughput/retransmits over time.
- **Statistics → Conversations / Protocol Hierarchy:** who's talking, and what protocols dominate.
- **Color rules:** instantly spot resets (black), retransmits, etc.

### Three-Level Depth (Lens A)
- **Level 1 — Beginner:** Wireshark records the actual messages computers send and shows them to
  you in plain language, layer by layer — like a transcript of a network conversation.
- **Level 2 — NetOps/NOC:** you capture targeted traffic (a capture filter to limit volume),
  apply display filters to find the relevant packets, **Follow Stream** to read a conversation,
  and read **Expert Info** for retransmits/resets. You can confirm a handshake (Lesson 03),
  diagnose a TLS failure (cert/alert), see a DNS SERVFAIL (Lesson 13), or prove a firewall is
  dropping (Lesson 15 — SYN with no SYN-ACK).
- **Level 3 — Wire/Kernel (Lens D):** Wireshark uses **libpcap** to put the NIC in promiscuous
  mode and copy frames via the kernel's packet socket (`AF_PACKET`). It dissects each protocol
  using its dissector tree — the same nested-header structure as the OSI stack (Lesson 02). On
  switched networks you only see your own + broadcast/multicast traffic unless you use a **SPAN/
  mirror port** or a tap (you can't passively sniff others on a switch — Lesson 08).

### Two Teaching Approaches (Lens B) — reading a capture

**Approach 1 (technical):** a capture is an ordered list of frames with timestamps; each frame's
dissection tree exposes every layer's fields. You filter to the flow of interest (by IP/port/
protocol), follow its stream to reassemble application data, and inspect anomalies (Expert Info:
retransmissions = loss; RST = reset; TLS alerts = handshake failure). Timing deltas between packets
reveal latency at each step.

**Approach 2 (analogy):** Wireshark is a **court stenographer + transcript** of a conversation.
- Every word said (packet) is recorded with a timestamp and who said it.
- A **display filter** is the "find" function — show me only what *these two parties* said about
  *this topic*.
- **Follow Stream** is reading the whole back-and-forth as a coherent dialogue instead of
  scattered lines.
- **Expert Info** is the stenographer's margin notes: "speaker repeated themselves" (retransmit),
  "speaker hung up abruptly" (RST), "they couldn't agree on a language" (TLS handshake failure).
- **Where it breaks down:** a stenographer hears everyone in the room; on a *switched* network you
  only "hear" your own conversations + announcements — you need a mirror port to hear others (the
  L2 reality from Lesson 08).

### Visual (ASCII) — a capture, filtered and followed

```
  Capture (interface eth0, capture filter: tcp port 443)
   No. Time     Source        Dest          Proto  Info
   1  0.000     10.0.0.5      203.0.113.20  TCP    [SYN]            ┐ handshake
   2  0.012     203.0.113.20  10.0.0.5      TCP    [SYN,ACK]        │ (Lesson 03)
   3  0.012     10.0.0.5      203.0.113.20  TCP    [ACK]            ┘
   4  0.013     10.0.0.5      203.0.113.20  TLSv1.3 Client Hello    ┐ TLS handshake
   5  0.030     203.0.113.20  10.0.0.5      TLSv1.3 Server Hello,Cert┘ (Lesson 16)
   …  Expert Info: "TCP Retransmission" (frame 18) → loss on this path
   Display filter: tls.alert  → would isolate a failed handshake
   Right-click frame 4 → Follow → TLS/TCP Stream → read the whole exchange
```

---

## §2 — Linux Networking Commands

```bash
# tshark (CLI Wireshark — works on headless servers)
tshark -D                                   # list interfaces
tshark -i eth0 -f "tcp port 443" -c 50      # CAPTURE filter (BPF), 50 packets
tshark -i eth0 -Y "http.response.code==502" # DISPLAY filter
tshark -i eth0 -f "port 53" -Y "dns" -T fields -e dns.qry.name -e dns.flags.rcode
tshark -r capture.pcap -q -z conv,tcp       # conversation stats from a saved capture
tshark -r capture.pcap -z follow,tcp,ascii,0  # follow a TCP stream

# Capture on a server, analyze in the Wireshark GUI elsewhere:
sudo tcpdump -ni eth0 -w /tmp/cap.pcap 'port 443'   # (Lesson 20) → open cap.pcap in Wireshark

# In the GUI: capture filter (before), display filter (after), Follow Stream, Expert Info, IO Graph
```

**Cisco/CCNA mapping:** CCNA references "protocol analyzer" as a troubleshooting tool; on Cisco
you'd configure a **SPAN/mirror port** to feed Wireshark. The display/capture-filter skill is
pure analyzer knowledge.

---

## §3 — Real-World Use Cases

**Production scenarios:**
1. **Prove where a connection fails:** capture both ends — SYN leaves the client, never arrives at
   the server = it's dropped in the path/firewall (Lesson 15).
2. **TLS failures:** `tls.alert` display filter shows handshake failures (bad cert, protocol
   mismatch) — definitive when `curl` is ambiguous.
3. **Application bugs blamed on "the network":** Follow Stream shows the app sent a malformed
   request / got a 500 — exonerating the network.
4. **Performance:** Expert Info + IO Graph reveal retransmissions/dup-ACKs (loss) vs a slow server
   (clean TCP, slow app response).
5. **Security analysis (Lessons 28/36):** reading suspicious flows, beaconing, plaintext creds.

**How NOC/Network engineers use it:** the escalation tool — when counters/logs don't resolve it,
a targeted capture gives ground truth. Often Tier-2/3, but Tier-1 captures *for* escalation.

**When NOT to:** don't capture on a busy link with no filter (you'll drown); don't sniff networks
you don't own (legal/ethical — and on switches you can't, without a mirror port).

**Exam framing (Net+/CCNA):** protocol analyzer as a tool, capture vs display filters, and
SPAN/mirror ports for capturing on switches.

---

## §4 — Troubleshooting Section

| Symptom | What to look for in the capture | Display filter |
|---|---|---|
| Connection won't establish | SYN with no SYN-ACK (dropped in path/firewall) | `tcp.flags.syn==1 && tcp.flags.ack==0` |
| TLS fails | TLS alert / cert problem | `tls.alert` |
| Slow/lossy | retransmissions, dup ACKs (Expert Info) | `tcp.analysis.retransmission` |
| DNS issue | SERVFAIL/NXDOMAIN responses | `dns.flags.rcode != 0` |
| App error blamed on network | the actual HTTP status/body | `http.response.code >= 400` |
| Reset connections | who sent RST and when | `tcp.flags.reset==1` |

**Redaction check (critical):** captures can contain credentials/PII — **never commit raw
`.pcap`**; share only sanitized field extracts or annotated screenshots with IPs masked.

---

## §5 — Common Mistakes

| Mistake | Impact | Fix |
|---|---|---|
| Mixing capture vs display filter syntax | filter doesn't work | BPF for capture, Wireshark syntax for display |
| Capturing everything on a busy link | dropped packets, huge files | use a capture filter |
| Sniffing a switch expecting all traffic | only see your own | use a SPAN/mirror port (L08) |
| Committing raw `.pcap` | credential/PII leak | sanitize; never commit raw captures |
| Ignoring Expert Info | miss retransmits/resets | check Expert Info first |
| Capturing the wrong interface | empty/irrelevant capture | confirm with `tshark -D` |

---

## §6 — NOC Perspective

> NOC Technician focus (Stage 1, `ROADMAP.md`).

A Tier-1 NOC may not deep-dive captures, but **capturing correctly for escalation** is a real
NOC skill: a targeted `tcpdump`/`tshark` capture (right interface, right filter, both ends)
attached to the ticket lets Tier-2/3 resolve it fast (`noc/escalation-matrix.md`). Knowing the
"SYN with no SYN-ACK = dropped in path" signature lets even Tier-1 say "the firewall/path is
dropping it" with evidence. Captures are also the **preserve-evidence** step in major incidents
(`noc/outage-management.md`) — grab them before they roll off.

---

## §7 — Incident-Response Perspective

- **Detect/Triage:** counters/logs inconclusive → capture for ground truth.
- **Preserve evidence:** capture *before* changing anything (and before buffers roll).
- **Diagnose (RCA):** the capture shows the exact failure (dropped SYN, TLS alert, retransmits,
  app 500) — definitive root cause.
- **Document:** attach sanitized extracts/screenshots to the runbook. In security IR (Lesson 28/
  36), the capture is the primary forensic artifact.

---

## §8 — Practical Lab (build this yourself)

**Goal:** capture and dissect real exchanges, then build `docs/networking/wireshark-filters.md`
(the display/capture-filter cookbook).

### Lens C — Manual → Automated → Why
- **Manual:** GUI capture + Follow Stream + Expert Info.
- **Automated:** `tshark` field extraction (e.g. dump all DNS query names + rcodes, or all TCP
  resets) — repeatable, scriptable capture analysis for monitoring/triage.
- **Why:** GUI is great for one-off deep dives; `tshark` extraction is what you bake into
  detection/triage automation (Lesson 28) and run on headless servers where there's no GUI.

### Steps
1. Capture a TCP+TLS+HTTP exchange (`curl https://example.com` while capturing `tcp port 443`).
   In Wireshark: identify the 3-way handshake (Lesson 03), the TLS Client/Server Hello + cert
   (Lesson 16), and the HTTP request/response. **Follow TLS/TCP Stream.**
2. Capture a DNS exchange (`dig example.com` while capturing `port 53`); read the query + response,
   note the rcode (Lesson 13).
3. Reproduce a failure (firewall-drop, drill 8) and capture the **SYN with no SYN-ACK** signature.
4. Build `docs/networking/wireshark-filters.md`: a cookbook of display filters (handshake, resets,
   retransmissions, TLS alerts, DNS errors, HTTP 4xx/5xx) + capture-filter examples + the
   capture-vs-display distinction + the redaction rule.

### Lens D — promiscuous mode + dissection
Note in your cookbook how libpcap/`AF_PACKET` captures frames and how the dissection tree mirrors
the OSI layers (Lesson 02) — the capture *is* the encapsulation made visible.

---

## §9 — GitHub Artifact (evidence 5-tuple)

1. **Script:** a `tshark` extraction one-liner/script (e.g. DNS-error or TCP-reset extractor).
2. **Config/doc:** `docs/networking/wireshark-filters.md` (the cookbook).
3. **Drill:** capture the firewall-drop SYN signature (drill 8) — **sanitized** extract only.
4. **NAVI ticket:** `NAVI-19` (Task: "Wireshark filter cookbook + capture analysis").
5. **Incident report:** *(optional)* — a capture-backed mini runbook (sanitized).

---

## §10 — Portfolio Artifact

- **Resume bullet:** "Analyzed packet captures with Wireshark/`tshark` to root-cause TCP/TLS/DNS
  failures (handshake drops, TLS alerts, retransmissions); authored a filter cookbook for the team."
- **Interview talking point:** capture vs display filters, the SYN-no-SYNACK signature, and using
  Follow Stream to exonerate the network when an app is at fault.
- **Serves:** Network Operations / Jr Network Engineer + the SOC track (Stages 2, 4, 5).

---

## §11 — RHCSA Crossover Notes

Mostly **N/A for RHCSA** (Wireshark isn't an RHCSA objective), but `tcpdump`/`tshark` on a RHEL
server to diagnose service connectivity is practical admin skill, and understanding captures
complements RHCSA firewall/service troubleshooting.

---

## §12 — Security Notes (Lens E — Attacker & Defender)

> Frameworks: [MITRE ATT&CK](https://attack.mitre.org/).

**🔴 Attacker:** packet capture *is* **network sniffing** (`T1040`) — on a shared/compromised
segment or via a mirror, an attacker reads plaintext creds, tokens, and data. Captures are also a
key step in MITM attacks (combined with ARP/DNS spoofing, Lessons 05/13).

**🔵 Defender:** **encrypt everything** (TLS/SSH/VPN) so a capture yields nothing useful;
**segment** so a sniffer sees little (Lessons 04/09); restrict who can capture on servers
(promiscuous mode needs privilege); and *use* capture defensively — IDS (Suricata, Lesson 28) is
automated capture-analysis for detection. Verify that sniffing a TLS-only service yields no
plaintext (lab).

---

## Quiz (Interview-Style, Graded)

**Q1.** Capture filter vs display filter — what's the difference, when is each applied, and why do
they have different syntax?
> **Your answer:**

**Q2.** You capture a failed connection and see a SYN from the client but no SYN-ACK back. What
does that tell you?
> **Your answer:**

**Q3.** How would you use Wireshark to prove an "app problem" is really a TLS certificate failure?
> **Your answer:**

**Q4.** **Scenario:** Users report slowness to one server. In the capture you see many "TCP
Retransmission" entries in Expert Info. What does that indicate, and what's your next step?
> **Your answer:**

**Q5.** Why can't you sniff other hosts' traffic on a switch, and what do you configure to do it
legitimately?
> **Your answer:**

**Q6.** Why must you never commit raw `.pcap` files to a public repo?
> **Your answer:**

*(After you answer, request the "Professional Answer" comparison under each — graded before Lesson 20.)*

---

## Reflection
*(Fill in after the quiz)* — What did you learn? · What confused you? · What would you do differently?

---

## Search Keywords For Further Understanding

**Core**
- `wireshark capture vs display filters`
- `wireshark follow tcp stream`
- `wireshark expert info retransmission`
- `wireshark tls handshake analysis`

**Tools**
- `tshark command line examples`
- `wireshark display filter cheat sheet`
- `span mirror port capture`

**Going further (future lessons)**
- `tcpdump bpf filters` (L20) · `suricata ids` (L28) · `network forensics pcap`

**Red / Blue (Lens E):**
- 🔴 `network sniffing T1040 wireshark`, `plaintext credential capture`, `mitm packet capture`
- 🔵 `encrypt traffic prevent sniffing`, `ids suricata pcap analysis`, `restrict promiscuous mode`

---

## Lesson Status
- [ ] §8 lab completed (capture + dissect + filter cookbook)
- [ ] §4 drill done (SYN-no-SYNACK capture, sanitized)
- [ ] Evidence committed (§9)
- [ ] Quiz answered + professional-answer comparisons (graded)
- [ ] Reflection + Search Keywords reviewed

When complete, run the Update Protocol, then move to **Lesson 20 — tcpdump**.

---

*Lesson 19 written by Navi · 2026-06-20 · full-depth. Sources to cite when worked: Wireshark User's
Guide, tshark man page, CompTIA Network+ N10-009, MITRE ATT&CK T1040.*
