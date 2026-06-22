# Lesson 18 — Network Troubleshooting Method

**Status:** ✅ ready for self-study (full depth) · **Date written:** 2026-06-20
**Schema:** 12-section (`docs/learning/CLAUDE_TEACHING_RULES.md`)
**Focus:** the bottom-up method, `ping`/`traceroute`/`tracepath`/`mtr`, latency vs loss vs jitter, MTU/PMTUD black-holes, DNS vs connectivity.
**Primary artifact:** `docs/runbooks/troubleshooting-method.md`.

> **How to use this lesson:** this is the *method* lesson — the structured approach that ties
> Lessons 01–17 together and is the single most-tested NOC interview topic. Read §1–§7, codify
> the method as a runbook, run any drill end-to-end with it.

---

## §1 — Concept (Scientific Theory)

### What it is
A **troubleshooting methodology** is a repeatable, structured process for diagnosing network
problems — so you find the cause by *elimination*, not guessing. The two industry-standard frames:
- **The CompTIA 7-step method:** (1) identify the problem, (2) establish a theory, (3) test the
  theory, (4) plan of action, (5) implement/escalate, (6) verify + preventive measures, (7)
  document.
- **The OSI bottom-up method** (Lesson 02): test L1 → L2 → L3 → L4 → L7 in order; the first
  failing layer is the fault domain.

### Why it exists
Under pressure, people guess and thrash ("restart it," "is it the website?") — wasting time and
sometimes making things worse. A method gives you a deterministic path, captures evidence as you
go (for the ticket + RCA), and tells you *when to escalate*.

### The performance vocabulary (precision matters)
| Term | Definition | Measured by |
|---|---|---|
| **Latency** | round-trip delay (ms) | `ping` RTT, `mtr` |
| **Jitter** | variation in latency | `mtr` (best/worst spread), VoIP tools |
| **Packet loss** | % of packets dropped | `ping` loss %, `mtr` per-hop loss |
| **Throughput** | actual data rate | `iperf3`, transfer tests |
| **MTU / PMTUD** | max packet size; path MTU discovery | `ping -M do -s`, `tracepath` |

"Slow" is not a diagnosis — *latency vs loss vs jitter vs throughput vs DNS* are different
problems with different causes and fixes.

### Three-Level Depth (Lens A)
- **Level 1 — Beginner:** don't guess — check things in order from the cable up, and write down
  what you find. The first thing that's broken is usually the cause.
- **Level 2 — NetOps/NOC:** you run the bottom-up ladder (`ip link` → `ip addr`/`ip route` →
  `ping` gateway → `ping`/`mtr` destination → `nc -vz`/`curl` service → `dig`), you distinguish
  **DNS** failures from **connectivity** failures (`ping IP` works, `ping name` fails = DNS), and
  you localize path problems with `mtr` (which hop shows latency/loss). You always **capture
  evidence into the ticket before changing anything** and you know the escalation triggers.
- **Level 3 — Wire/Kernel (Lens D):** `ping` uses ICMP echo; `traceroute` uses incrementing TTL
  (Lesson 07) to elicit ICMP Time-Exceeded per hop; `mtr` combines both continuously. **MTU
  black-holes** (PMTUD failure) happen when a path can't carry full-size packets and the ICMP
  "fragmentation needed" messages are filtered — large transfers hang while pings (small) work,
  the classic "ping works but file copy stalls." `ping -M do -s <size>` finds the real path MTU.

### Two Teaching Approaches (Lens B) — bottom-up vs divide-and-conquer

**Approach 1 (technical — bottom-up):** start at L1 and ascend; each layer's test is a gate —
don't proceed up until the current layer passes. The first failing gate is the fault domain; this
guarantees you never debug an L7 symptom that's really an L1 cable.

**Approach 2 (analogy — and divide-and-conquer):** diagnosing why a letter never arrived.
- **Bottom-up** = check each link in the chain from your end outward: did it leave your mailbox?
  reach the local depot? the regional hub? the destination depot? the recipient's mailbox? The
  first place it's missing is where it went wrong.
- **Divide-and-conquer** = a faster variant for long paths: test the *middle* first (did it reach
  the regional hub?). If yes, the problem is in the second half; if no, the first half. `mtr` to a
  midpoint, or pinging a router halfway, halves the search each time.
- **Where it breaks down:** the mail analogy has no equivalent of *layered* failure (a letter
  doesn't fail "at the encryption layer"); for that, bottom-up by OSI layer is the precise frame.

### Visual (ASCII) — the bottom-up ladder + DNS-vs-connectivity split

```
  START
   │  L1  ip link / ethtool ........ link up?            ──no─► cable/port/SFP
   │  L2  ip neigh ................. gateway ARP ok?     ──no─► switch/VLAN (L08/09)
   │  L3  ip route / ping gw ....... reach gateway?      ──no─► addressing/route (L05/07)
   │      ping <dest-IP> ........... reach destination?  ──no─► routing/path (mtr)  (L07)
   │  L4  nc -vz <dest> <port> ..... port open?          ──no─► firewall/service (L15/03)
   │  L7  curl -v / dig ............ app + DNS ok?        ──no─► DNS (L13) / app
   ▼
  "Slow"? → mtr (which hop? latency vs loss) · ping -M do (MTU) · iperf3 (throughput)
  "ping IP works, ping NAME fails" → it's DNS (L13), not connectivity.
```

---

## §2 — Linux Networking Commands

```bash
ping -c5 <gateway>                 # L3 reachability + RTT + loss (start local, then remote)
ping -c100 <dest>                  # loss % over many packets
ping -M do -s 1472 <dest>          # MTU probe (1472+28 = 1500); shrink until it succeeds = path MTU
traceroute <dest>                  # hop-by-hop path
tracepath <dest>                   # path + MTU discovery, no root needed
mtr <dest>                          # continuous traceroute: per-hop latency + loss (the best tool)
mtr -rwc 100 <dest>                # report mode, 100 cycles (paste into a ticket)
dig +short <name>                   # DNS vs connectivity isolation (Lesson 13)
ss -tnp                             # is the connection established/stuck?
iperf3 -c <server>                  # throughput test (needs an iperf3 server)
ip -s link                          # interface error/drop counters (L1/L2 faults)
```

**Cisco/CCNA mapping:** `ping`, `traceroute`, `show interfaces` (errors), and the **7-step method**
are explicitly on Network+/CCNA. The Linux tools (`mtr`, `tracepath`, `ss`) give deeper visibility
than IOS for the same job.

---

## §3 — Real-World Use Cases

**Production scenarios:**
1. **"The network is slow":** `mtr -rwc 100 <dest>` localizes the hop and tells you *latency vs
   loss* — congestion (latency at one hop), a bad link (loss at one hop), or fine network + slow
   app (clean mtr).
2. **"File copies hang but ping works":** MTU black-hole — `ping -M do -s` finds the path MTU;
   fix MTU/PMTUD (Lessons 14/29 — VPNs are a common cause).
3. **"Site won't load":** `dig` vs `ping IP` splits DNS from connectivity in one step (Lesson 13).
4. **Intermittent VoIP/video issues:** jitter + loss — `mtr` over time reveals it.

**How NOC engineers use it:** *this is the job.* Every ticket runs through this method; `mtr`
output and the dig-vs-ping split are the evidence pasted into tickets and escalations.

**When NOT to:** don't skip to L7 ("is the app broken?") before confirming L1–L3; don't change
things before capturing evidence.

**Exam framing (Net+/CCNA):** the 7-step method (in order), tool selection per symptom, and
latency/loss/jitter/MTU definitions are heavily tested (Network+ Domain 5.0 = 24%).

---

## §4 — Troubleshooting Section (the method applied to the 8 scenarios)

| Symptom | First move | Localizes to | Lesson/drill |
|---|---|---|---|
| Can't reach anything | `ip link`/`ip addr`/`ip route` bottom-up | L1–L3 | 01/05/07 |
| Slow/high latency | `mtr -rwc 100` | the hop with rising latency | drill 3 |
| Packet loss | `ping -c100`, `mtr` loss column | the lossy hop/link | drill 4 |
| Site won't load | `dig` vs `ping IP` | DNS vs connectivity | 13 / drill 1 |
| File copy hangs, ping ok | `ping -M do -s` | MTU black-hole | 14/29 |
| Port refused/filtered | `nc -vz` | firewall/service | 15/03 / drill 8 |
| One subnet unreachable | `ip route get`, bidirectional traceroute | routing | 07 / drill 6 |
| Whole VLAN down | VLAN checklist | L2/VLAN | 09 / drill 7 |

**Redaction check:** redact real IPs/hosts in any `mtr`/traceroute output committed to a ticket.

---

## §5 — Common Mistakes

| Mistake | Impact | Fix |
|---|---|---|
| Guessing instead of a method | thrash, longer outages | run the ladder |
| Saying "slow" without measuring | wrong fix | latency vs loss vs jitter vs throughput |
| Changing before capturing evidence | no RCA, can't roll back | capture into the ticket first |
| Using `ping` to test a service | misses L4/L7 | `nc -vz`/`curl` |
| Missing the MTU black-hole | days lost | `ping -M do -s` when "ping ok, transfer hangs" |
| Not knowing escalation triggers | sit on a Sev1 too long | time-box + scope/severity rules |

---

## §6 — NOC Perspective

> NOC Technician focus (Stage 1, `ROADMAP.md`).

This lesson *is* the NOC's core competency and the thing interviews probe most ("X is broken —
what do you check first?"). The deliverables — the bottom-up ladder + the dig-vs-ping split + an
`mtr` report — are exactly the evidence that goes into the ticket and the escalation packet
(`noc/escalation-matrix.md`). Knowing the **escalation triggers** (severity, time-box, scope,
access, risk) is part of the method, not separate from it.

---

## §7 — Incident-Response Perspective

The method *is* the IR diagnose phase (`noc/rca.md` fault-domain isolation):
- **Detect → Triage:** scope + severity from the symptom.
- **Diagnose:** run the bottom-up ladder, capturing evidence; the first failing layer/hop is the
  root-cause domain.
- **Fix/Escalate → Recover → Document:** apply or hand off with the evidence packet; verify;
  write the runbook with the **timeline + evidence + RCA + prevention**. Every drill in
  `troubleshooting-drills.md` is an exercise of this method.

---

## §8 — Practical Lab (build this yourself)

**Goal:** codify `docs/runbooks/troubleshooting-method.md` (the canonical method runbook) and run
**any one drill end-to-end** using it, producing a real incident report.

### Lens C — Manual → Automated → Why
- **Manual:** the bottom-up ladder by hand.
- **Automated:** `net_diag.sh` (Lessons 01/17) automates the L1–L4 rungs; here you add a "path
  report" wrapper (`mtr -rwc` + `dig` + `ping -M do`) that produces ticket-ready output.
- **Why:** a method that's also a script is faster and consistent under pressure, and the output
  is the evidence — exactly what NOC teams standardize.

### Steps
1. Write `docs/runbooks/troubleshooting-method.md`: the 7-step method, the bottom-up ladder
   (with the exact command per layer), the dig-vs-ping split, the MTU-black-hole check, the
   latency/loss/jitter definitions, and the escalation-trigger list.
2. Pick a drill (e.g. drill 3 high latency via `tc netem`), induce it, and **walk the method**,
   capturing each step's output.
3. Produce the incident report (`docs/runbooks/incident-<drill>.md`) using the runbook's RCA
   format — this is the portfolio centerpiece of the lesson.

### Lens D — how the tools work
Confirm `traceroute`'s TTL mechanism (`sudo tcpdump -ni any icmp` during a traceroute → see the
Time-Exceeded replies) and find your path MTU with `ping -M do -s` decreasing until it passes.

---

## §9 — GitHub Artifact (evidence 5-tuple)

1. **Script:** a "path report" wrapper (`mtr`+`dig`+MTU) extending `net_diag.sh`.
2. **Config/doc:** `docs/runbooks/troubleshooting-method.md` (the canonical method).
3. **Drill:** any drill walked end-to-end with the method.
4. **NAVI ticket:** `NAVI-18` (Incident: the drill, run through the full method).
5. **Incident report:** `docs/runbooks/incident-<drill>.md` (full timeline + RCA + prevention).

---

## §10 — Portfolio Artifact

- **Resume bullet:** "Authored the team's network troubleshooting runbook (7-step + OSI bottom-up)
  and resolved incidents (latency/loss/MTU/DNS) with `mtr`/`ping`/`dig` evidence and documented RCA."
- **Interview talking point:** answer "X is broken, what do you check first?" with the bottom-up
  ladder + the dig-vs-ping split + the MTU-black-hole gotcha — the highest-value NOC answer.
- **Serves:** NOC Technician (Stage 1) — the core hireable skill; Network+ Domain 5.0.

---

## §11 — RHCSA Crossover Notes

RHCSA-relevant: `ping`/`ip`/`ss`/`getent`/`dig` for diagnosing a RHEL host's connectivity, and the
structured approach to "this server can't reach the network." The method is tool-agnostic and
applies directly to RHCSA troubleshooting tasks.

---

## §12 — Security Notes (Lens E — Attacker & Defender)

> Frameworks: [MITRE ATT&CK](https://attack.mitre.org/).

**🔴 Attacker:** the same tools are recon — `ping` sweeps + `traceroute` map a network
(`T1018` Remote System Discovery, `T1590` Gather Network Information). Loss/latency anomalies can
also be a symptom of an attack (a DoS or a saturated link from exfil).

**🔵 Defender:** rate-limit/監視 ICMP (don't blanket-block — it breaks PMTUD), detect ping sweeps
and traceroute patterns (IDS, Lesson 28), and treat unexplained latency/loss spikes as possible
incidents (correlate with security events). Verify your monitoring flags a sweep (lab-only).

---

## Quiz (Interview-Style, Graded)

**Q1.** Walk through the bottom-up troubleshooting method, naming the command at each layer.
> **Your answer:**

**Q2.** "It's slow." How do you turn that into a precise diagnosis, and which tool localizes the
hop?
> **Your answer:**

**Q3.** Ping to an IP works but ping to its hostname fails. What's broken, and how do you confirm?
> **Your answer:**

**Q4.** **Scenario:** Small pings succeed but large file transfers hang across a VPN. What's the
likely cause and how do you prove it?
> **Your answer:**

**Q5.** List the CompTIA 7-step troubleshooting method in order.
> **Your answer:**

**Q6.** When should you escalate rather than keep troubleshooting? Name three triggers.
> **Your answer:**

*(After you answer, request the "Professional Answer" comparison under each — graded before Lesson 19.)*

---

## Reflection
*(Fill in after the quiz)* — What did you learn? · What confused you? · What would you do differently?

---

## Search Keywords For Further Understanding

**Core**
- `comptia 7 step troubleshooting methodology`
- `bottom up network troubleshooting osi`
- `latency vs jitter vs packet loss`
- `mtu black hole pmtud`
- `dns vs connectivity issue`

**Tools**
- `mtr report mode examples`
- `ping -M do mtu test`
- `tracepath vs traceroute`

**Going further (future lessons)**
- `tcpdump capture analysis` (L20) · `iperf3 throughput` · `network monitoring baselines` (L21)

**Red / Blue (Lens E):**
- 🔴 `ping sweep traceroute recon T1018 T1590`, `dos latency loss symptom`
- 🔵 `icmp rate limiting`, `detect ping sweep ids`, `latency anomaly alerting`

---

## Lesson Status
- [ ] §8 lab completed (method runbook + a drill walked end-to-end)
- [ ] §4 drill done (any scenario)
- [ ] Evidence committed (§9)
- [ ] Quiz answered + professional-answer comparisons (graded)
- [ ] Reflection + Search Keywords reviewed

When complete, run the Update Protocol, then move to **Lesson 19 — Wireshark**.

---

*Lesson 18 written by Navi · 2026-06-20 · full-depth. Sources to cite when worked: CompTIA Network+
N10-009 (Domain 5.0), man7.org ping/traceroute, mtr docs, MITRE ATT&CK T1018/T1590.*
