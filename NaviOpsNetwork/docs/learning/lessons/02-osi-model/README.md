# Lesson 02 — The OSI Model

**Status:** ✅ ready for self-study (full depth) · **Date written:** 2026-06-22
**Schema:** 12-section (`docs/learning/CLAUDE_TEACHING_RULES.md`)
**Focus:** the 7 layers, encapsulation/decapsulation, PDUs, and using the model as a **layer-by-layer
troubleshooting map**.
**Primary artifact:** `docs/networking/osi-troubleshooting-map.md`.

> **How to use this lesson:** the OSI model is the single most useful *thinking tool* in networking —
> it turns "the network is broken" into "which layer is broken." Read §1, then build the
> troubleshooting map in §8 and use it on every later incident.

---

## §1 — Concept (Scientific Theory)

### What it is
The **OSI (Open Systems Interconnection) model** (ISO/IEC 7498-1) is a **7-layer reference model**
that splits networking into independent functions, each serving the layer above and using the layer
below. It's a *conceptual* model — real stacks (TCP/IP, Lesson 03) collapse some layers — but it's
the universal vocabulary and the best troubleshooting framework.

### The 7 layers (top to bottom) — and their PDU
| # | Layer | Job | PDU | Examples / where it lives |
|---|---|---|---|---|
| 7 | **Application** | user-facing protocols | Data | HTTP, DNS, SSH, SMTP |
| 6 | **Presentation** | format/encrypt/compress | Data | TLS, JPEG, ASCII/Unicode |
| 5 | **Session** | start/manage/end sessions | Data | RPC, sockets, NetBIOS |
| 4 | **Transport** | end-to-end delivery, ports | **Segment** (TCP)/Datagram (UDP) | TCP, UDP |
| 3 | **Network** | logical addressing + routing | **Packet** | IP, ICMP, routers |
| 2 | **Data Link** | local delivery on a link | **Frame** | Ethernet, MAC, switches, ARP |
| 1 | **Physical** | bits on the medium | **Bits** | cables, NICs, fiber, RF |

**Mnemonics:** top→bottom "**A**ll **P**eople **S**eem **T**o **N**eed **D**ata **P**rocessing";
bottom→top "**P**lease **D**o **N**ot **T**hrow **S**ausage **P**izza **A**way."

### Encapsulation & decapsulation
As data goes **down** the stack on the sender, each layer **adds its own header** (L4 port → L3 IP →
L2 MAC + trailer/FCS) — this is **encapsulation**. On the receiver it goes **up** the stack, each
layer **stripping its header** — **decapsulation**. The same payload is wrapped, sent, and unwrapped.

### Three-Level Depth (Lens A)
- **Level 1 — Beginner:** networking is layered; each layer has one job; a problem usually lives at
  one specific layer.
- **Level 2 — NetOps/NOC:** you triage **bottom-up** — is the cable up (L1)? does the switch see the
  MAC (L2)? is the IP/route right (L3)? is the port open (L4)? does the app respond (L7)? The model
  turns chaos into a checklist.
- **Level 3 — Wire/Kernel (Lens D):** on the wire a single Ethernet frame literally contains the
  nested headers — `[Eth | IP | TCP | HTTP...]`. In Linux the layers map to subsystems: NIC/driver
  (L1/2), the IP/route stack + netfilter (L3), the socket/TCP state machine (L4), userspace apps
  (L5–7). `tcpdump`/Wireshark *show you the layers* by decoding each header.

### Two Teaching Approaches (Lens B) — encapsulation
**Technical:** each layer prepends a header describing how its peer layer on the other host should
process the payload; lower layers neither know nor care what's inside.

**Analogy:** **shipping a gift in nested boxes.** The gift (data) goes in a box with a note (L7),
that box into a labeled box (L4 port), into a box with the destination city address (L3 IP), into a
truck-routing box with the next depot (L2 MAC). Each depot opens only *its* box, reads its label,
re-boxes, and forwards. *Where it breaks down:* real packets don't physically nest infinitely — and
some "layers" (5/6) are fuzzy in practice.

### Visual (ASCII) — encapsulation down, decapsulation up
```
 SENDER (down)                                RECEIVER (up)
 L7 Data ............ "GET /"                 L7 Data ........... "GET /"
 L4 +TCP hdr ........ [TCP|Data]              L4 strip TCP ...... [Data]
 L3 +IP  hdr ........ [IP|TCP|Data]           L3 strip IP ....... [TCP|Data]
 L2 +Eth hdr/FCS .... [Eth|IP|TCP|Data|FCS]   L2 strip Eth ...... [IP|TCP|Data]
 L1 bits on wire .... 010101...  ───────────► L1 bits off wire .. 010101...
```

---

## §2 — Linux Networking Commands (mapped to layers)

```bash
# L1 Physical
ethtool eth0                      # link, speed, duplex (is the wire even up?)
ip -br link                       # interface state UP/DOWN
# L2 Data Link
ip neigh show                     # ARP/neighbour table (IP<->MAC on the link)
bridge fdb show                   # switch-style MAC forwarding entries (Linux bridge)
# L3 Network
ip route ; ping -c1 10.0.0.1      # routing table + reachability
traceroute 1.1.1.1                # per-hop L3 path
# L4 Transport
ss -tuln                          # listening TCP/UDP ports
nc -vz 10.0.0.10 443              # is a specific port open?
# L7 Application
dig example.com ; curl -v http://10.0.0.10/   # name resolution + app response
tcpdump -ni eth0 port 80          # SEE every layer decoded on the wire
```

**Cisco/CCNA mapping:** `show interfaces` (L1/2), `show mac address-table` (L2),
`show ip route`/`ping`/`traceroute` (L3), ACL/port logic (L4). Wireshark/`tcpdump` make the layers
visible — the single best OSI learning tool.

---

## §3 — Real-World Use Cases

**Production scenarios:**
1. **Structured incident triage:** the OSI model *is* the runbook order — bottom-up isolates the
   broken layer fast instead of random guessing.
2. **Cross-team handoffs:** "it's an L1 issue" (facilities/cabling) vs "L3 routing" (network) vs
   "L7 app" (dev) routes the ticket to the right team immediately.
3. **Reading captures:** Wireshark groups every packet by layer — knowing the model lets you read a
   capture (Lessons 19–20).
4. **Exam framing:** Net+/CCNA test layer order, PDUs, which device/protocol lives at each layer, and
   encapsulation order.

**How NOC engineers use it:** the universal triage language. "Where in the stack is this failing?"
is the first question on almost every connectivity incident.

**When NOT to over-apply:** don't force the fuzzy L5/L6 distinction — in practice TLS/session live
inside the app+transport conversation; use the model as a guide, not gospel.

---

## §4 — Troubleshooting Section (the bottom-up map)

| Layer | Symptom | Diagnose | Typical fix |
|---|---|---|---|
| L1 Physical | no link, `state DOWN` | `ethtool`, `ip -br link` | cable/port/optic |
| L2 Data Link | no ARP, wrong VLAN | `ip neigh`, `bridge fdb` | VLAN/switchport, duplicate IP |
| L3 Network | no route / wrong gateway | `ip route`, `ping`, `traceroute` | gateway/route fix |
| L4 Transport | port refused/filtered | `ss -tuln`, `nc -vz` | start service, open firewall |
| L7 Application | name fails / app error | `dig`, `curl -v`, logs | DNS, app/service config |

**Diagnostic sequence (bottom-up):** L1 link → L2 ARP/VLAN → L3 ping gateway then `1.1.1.1` → L4
`nc -vz host port` → L7 `dig`+`curl`. **Redaction check:** RFC 5737 ranges only in committed output.

---

## §5 — Common Mistakes

| Mistake | Impact | Fix |
|---|---|---|
| Troubleshooting top-down by guess | slow, misdiagnosed | go bottom-up, isolate the layer |
| Confusing PDUs (frame vs packet vs segment) | imprecise comms, exam loss | frame=L2, packet=L3, segment=L4 |
| Thinking a switch is L3 / router is L2 | wrong device for the fix | switch=L2, router=L3 |
| Forgetting encapsulation order | misread captures | L7→L4→L3→L2 down, reverse up |
| Treating L5/L6 as hard boundaries | overthinking | they're conceptual; TLS≈L6, sockets≈L5 |

---

## §6 — NOC Perspective

> NOC Technician focus (Stage 1, `ROADMAP.md`).

The OSI model is the NOC's shared mental model on every bridge call. Alerts map to layers: "interface
down" (L1/2), "BGP/route flap" (L3), "service port not listening" (L4), "HTTP 5xx / DNS NXDOMAIN"
(L7). Stating the suspected layer in the incident channel routes it to the right team and sets the
escalation path. Dashboards are themselves layered (link health → reachability → service checks).

---

## §7 — Incident-Response Perspective

- **Detect:** users/monitoring report a failure ("can't reach the app").
- **Triage:** establish blast radius and the *layer* — one app (likely L7) vs whole segment (L1–3).
- **Diagnose (RCA):** walk the stack bottom-up until a layer fails its check — that's the RCA layer.
- **Fix → Recover → Document:** fix at the identified layer, verify the full stack passes, and record
  the layer + evidence in the runbook so the next analyst starts there.

---

## §8 — Practical Lab (build this yourself)

**Goal:** build `docs/networking/osi-troubleshooting-map.md` — a one-page, command-by-layer triage
sheet you'll use on every future incident.

### Lens C — Manual → Automated → Why
- **Manual:** walk the bottom-up command sequence by hand.
- **Automated:** extend `scripts/net_diag.sh` (Lesson 01) with a `--osi` mode that runs one check per
  layer (L1 link → L2 ARP → L3 route/ping → L4 port → L7 dig/curl) and prints the first failing
  layer.
- **Why:** encoding the model as a script means consistent, fast layer-isolation under pressure.

### Steps
1. Fill in the map for each layer: *symptom → command → expected vs broken output → fix*.
2. Add the `--osi` block to `net_diag.sh` (skeleton):

```bash
osi_check() {
  echo "L1:"; ip -br link | grep -q 'UP' && echo "  up" || { echo "  DOWN"; return 1; }
  echo "L2:"; ip neigh show | grep -q . && echo "  neighbours present" || echo "  (no ARP yet)"
  echo "L3:"; ping -c1 -W1 "$(ip route show default | awk '/default/{print $3;exit}')" >/dev/null \
        && echo "  gateway reachable" || { echo "  gateway UNREACHABLE"; return 1; }
  echo "L4:"; ss -tuln | grep -q ':22' && echo "  sshd listening" || echo "  (ssh not listening)"
  echo "L7:"; dig +short example.com >/dev/null && echo "  DNS resolves" || { echo "  DNS FAIL"; return 1; }
}
```

3. **Break-it drill:** disable the gateway route, run `--osi`, confirm it stops at L3; restore and
   re-verify. Repeat by stopping `sshd` (L4) and breaking DNS (L7).

### Lens D — watch the layers on the wire
`sudo tcpdump -ni eth0 -vv port 80` while running `curl http://10.0.0.10/` — Wireshark/`tcpdump`
decode the nested **Eth → IP → TCP → HTTP** headers; that *is* encapsulation, visible.

---

## §9 — GitHub Artifact (evidence 5-tuple)

1. **Script:** `scripts/net_diag.sh --osi` mode (committed, shellcheck-clean).
2. **Config/doc:** `docs/networking/osi-troubleshooting-map.md` — the layered triage sheet.
3. **Drill:** a layer-isolation drill (break L3, confirm the map points to L3) in `troubleshooting-drills.md`.
4. **NAVI ticket:** `NAVI-02` (Task: "OSI troubleshooting map + --osi mode") To Do→In Progress→Done.
5. **Incident report:** a runbook using the map to RCA a multi-layer outage (`docs/runbooks/`).

---

## §10 — Portfolio Artifact

- **Resume bullet:** "Authored a bottom-up OSI troubleshooting map and a layered diagnostic mode in
  `net_diag.sh`, standardizing incident triage from physical link to application."
- **Interview talking point:** name the 7 layers + PDUs and walk an interviewer through diagnosing a
  "can't reach the app" ticket bottom-up.
- **Serves:** NOC Technician (Stage 1) — the universal triage framework.

---

## §11 — RHCSA Crossover Notes

Indirect but useful: RHCSA troubleshooting (link with `ip`, routing, `firewalld` ports, name
resolution) maps cleanly onto L1–L4 + L7. Framing RHEL network problems by layer speeds exam tasks.
The model itself is "N/A for RHCSA" as an exam objective but invaluable as method.

---

## §12 — Security Notes (Lens E — Attacker & Defender)

> Frameworks: [MITRE ATT&CK](https://attack.mitre.org/).

**🔴 Attacker (1–2 line, Day-1 scale):** attacks map to layers too — L2 ARP/MAC spoofing
(`T1557`), L3/L4 scanning + spoofing (`T1046`), L7 app exploits — and tunneling hides higher-layer
payloads inside allowed lower-layer traffic (`T1572`).

**🔵 Defender:** **defense-in-depth** is literally per-layer (port security L2, ACLs/firewall L3/4,
WAF/TLS L7). Detection and logging should exist at multiple layers so an evasion at one is caught at
another. Verify by mapping each control to its OSI layer and checking for gaps.

---

## Quiz (Interview-Style, Graded)

**Q1.** List the 7 OSI layers in order with each layer's PDU. Which mnemonic do you use?
> **Your answer:**

**Q2.** Explain encapsulation and decapsulation. What header is added at L3 vs L2?
> **Your answer:**

**Q3.** At which layer does each operate: switch, router, TCP, HTTP, cable, ARP?
> **Your answer:**

**Q4.** **Scenario:** "I can't reach the web app." Walk through your bottom-up OSI triage, naming the
command at each layer.
> **Your answer:**

**Q5.** A `ping` to the gateway works but `curl` to a server's port 443 is refused. Which layer is
the problem and how do you confirm?
> **Your answer:**

**Q6.** Why is bottom-up troubleshooting usually faster than top-down?
> **Your answer:**

*(After you answer, request the "Professional Answer" comparison under each — graded before Lesson 03.)*

---

## Reflection
*(Fill in after the quiz)* — What did you learn? · What confused you? · What would you do differently?

---

## Search Keywords For Further Understanding

**Core**
- `osi model 7 layers explained`
- `encapsulation decapsulation networking`
- `pdu frame packet segment`
- `osi vs tcp ip model`
- `osi troubleshooting bottom up`

**Tools**
- `wireshark layers decode packet`
- `tcpdump read headers`
- `ss nc port check`

**Going further (future lessons)**
- `tcp ip 4 layer model` (L03) · `subnetting` (L04) · `routing fundamentals` (L07)

**Red / Blue (Lens E):**
- 🔴 `layer 2 arp spoofing T1557`, `protocol tunneling T1572`
- 🔵 `defense in depth per layer`, `multi-layer detection`

---

## Lesson Status
- [ ] §8 lab completed (osi map + `--osi` mode + layer drills)
- [ ] §4 drill done
- [ ] Evidence committed (§9)
- [ ] Quiz answered + professional-answer comparisons (graded)
- [ ] Reflection + Search Keywords reviewed

When complete, run the Update Protocol, then move to **Lesson 03 — TCP/IP**.

---

*Lesson 02 written by Navi · 2026-06-22 · full-depth. Sources to cite when worked: ISO/IEC 7498-1,
RFC 1122, man7.org `tcpdump`, CompTIA Network+ N10-009, MITRE ATT&CK T1557/T1572.*
