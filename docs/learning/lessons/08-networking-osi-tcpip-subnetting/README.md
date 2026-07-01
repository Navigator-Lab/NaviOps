# Lesson 08 — Networking I: OSI/TCP-IP Models & Subnetting

**Status:** ready for self-study · **Date written:** 2026-06-11
**Gate Rule:** Concept → Real-World Use → Alternatives → Hands-On → Verification → Quiz → Reflection → Search Keywords

> **How to use this lesson:** same as Lessons 03–07. This lesson is more conceptual
> (no servers needed yet) — Step 4 uses your own machine and pencil-and-paper subnet
> math.

---

## Step 1 — Concept

### What it is

The **OSI model** is a 7-layer conceptual framework describing how data moves from one
device to another. The **TCP/IP model** is the 4-layer model the real Internet
actually runs on (OSI is teaching/reference; TCP/IP is what's implemented).
**Subnetting/CIDR** is how IP address space is divided into smaller networks.

### Why it exists

Networking has many concerns at different "altitudes" — physical signals, addressing,
routing, reliable delivery, application protocols. Layering means each layer only
needs to know about the layer directly below/above it — Ethernet doesn't need to know
about HTTP, and HTTP doesn't need to know about Ethernet. This is the same
"separation of concerns" principle as good software architecture. Subnetting exists
because IPv4 address space (≈4.3 billion addresses) is finite and must be allocated
efficiently — and because splitting a network into subnets contains broadcast traffic
and groups devices logically (e.g., "servers" vs "workstations" vs "guest Wi-Fi").

### What problem it solves

| Problem | Solution |
|---|---|
| "Is this a cabling issue, a routing issue, or an application bug?" | OSI layers give you a systematic place to start (Layer 1 → Layer 7) |
| "I have 192.168.1.0/24 — how do I split it for 4 departments?" | Subnetting math (Step 4) |
| "What's my server's IP, and is it listening on port 443?" | `ip addr`, `ss -tlnp` |
| "Two hosts on the same subnet can talk; different subnets can't, without a router" | Understanding network/host portions of an address |

### Three-Level Depth (Lens A)

- **Level 1 — Beginner:** OSI layers (top to bottom): **Application** (HTTP, SSH,
  DNS), **Presentation** (encryption/encoding — often merged into Application in
  practice), **Session** (connection management), **Transport** (TCP/UDP — ports),
  **Network** (IP — routing, addresses), **Data Link** (Ethernet, MAC addresses,
  switches), **Physical** (cables, signals). TCP/IP's 4 layers map roughly:
  Application (OSI 5-7), Transport (OSI 4), Internet (OSI 3), Link (OSI 1-2). An IPv4
  address (`192.168.1.10`) plus a **subnet mask** (`255.255.255.0`, written `/24`)
  splits into a **network portion** (identifies the subnet) and a **host portion**
  (identifies the device within it).
- **Level 2 — SysAdmin:** Per [DigitalOcean's CIDR guide](https://www.digitalocean.com/community/tutorials/understanding-ip-addresses-subnets-and-cidr-notation-for-networking):
  `/24` = 24 network bits, 8 host bits → 2^8 = 256 addresses, minus network address
  (`.0`) and broadcast (`.255`) = **254 usable hosts**. General formula:
  usable hosts = 2^(32 − prefix) − 2. Common prefixes: `/24` (254 hosts), `/25` (126),
  `/26` (62), `/30` (2 — point-to-point links). Diagnostic commands by layer:
  `ip link` (Layer 2 — interface up/down, MAC), `ip addr` (Layer 3 — IP addresses),
  `ip route` (Layer 3 — routing table), `ss -tlnp` (Layer 4 — listening TCP ports +
  owning process), `curl`/`dig` (Layer 7). A SysAdmin troubleshooting "can't reach the
  web server" works **bottom-up**: is the cable/interface up (L1/2)? Does it have an
  IP (L3)? Can it ping the gateway (L3)? Is the service listening on the port (L4)? Does
  `curl localhost` work (L7)?
- **Level 3 — Systems/Kernel (Lens D):** A **socket** is the kernel abstraction for a
  network endpoint — created with the `socket()` syscall, bound to an address/port
  with `bind()`, and for TCP, `listen()`+`accept()` (server) or `connect()` (client).
  `ss -tlnp` literally reads the kernel's socket table and cross-references it with
  `/proc/<pid>/fd/` (Lesson 04) to show which **process** owns each listening socket.
  TCP's reliability (the "T" in TCP/IP — Transmission Control Protocol) is implemented
  via the **three-way handshake** (SYN → SYN-ACK → ACK) at connection setup, sequence
  numbers for ordering, and retransmission timers for lost packets — all maintained
  by the kernel's TCP stack, not by the application.

### Analogy (Lens B)

- **OSI layers** = a postal system: the **address on the envelope** (Network layer/IP)
  is independent of **how the truck gets there** (Data Link/physical — could be
  highway, rail, air), which is independent of **what's inside the envelope**
  (Application — a letter, a contract, a photo). Each layer adds its own "envelope"
  around the one above (encapsulation).
- **Subnetting** = a building's address + apartment numbers: `192.168.1.0/24` is "123
  Main Street" (the building/network); `.10` through `.254` are apartment numbers
  (hosts). `.0` is reserved (the building's own address, not an apartment) and `.255`
  is the building-wide announcement address (broadcast — "everyone in this building").
  Two buildings on different streets need a router (like a mail-forwarding service)
  to exchange mail; two apartments in the *same* building can pass things directly.

This analogy holds for addressing/routing but breaks down for the **handshake**
(Level 3) — postal mail has no equivalent of "before sending the letter, exchange 3
acknowledgment notes confirming both sides are ready."

---

## Step 2 — Real-World Use

### How SysAdmins use this daily

```bash
ip addr show              # interfaces and their IPs (replaces old `ifconfig`)
ip route show              # routing table — what's the default gateway?
ip link show               # interface state (UP/DOWN), MAC addresses
ss -tlnp                    # listening TCP sockets + owning process (replaces `netstat`)
ss -tnp                     # established TCP connections
ping <ip>                   # Layer 3 reachability test
traceroute <ip>             # which hops/routers does traffic pass through?
```

**Real production scenarios:**
1. **"The app server can't reach the database"** — check `ip route` (is there a route
   to the DB's subnet?), `ping <db-ip>` (L3 reachable?), `ss -tnp | grep 5432`
   (is the DB port reachable/established from the app server?).
2. **Subnet planning for a new VPC** — given `10.0.0.0/16`, how many `/24` subnets fit
   for public/private/database tiers? (`/16` = 65536 addresses → 256 `/24` subnets)
3. **"Why can't these two VMs see each other?"** — often they're on different subnets
   with no route between them, or a firewall (Lesson 09) is blocking.

### Common mistakes

| Mistake | Impact | Fix |
|---|---|---|
| Confusing IP address with subnet mask role | Misconfigured static IPs that can't reach the gateway | Remember: mask defines network/host **split**, not a separate address |
| Forgetting network (`.0`) and broadcast (`.255`) addresses aren't usable hosts | Off-by-one errors when planning host counts | Usable hosts = 2^(32-prefix) − 2 |
| Troubleshooting "top-down" (jumping straight to "is the website broken?") | Wastes time — the issue might be L1/L2/L3 | Troubleshoot **bottom-up** (Level 2) |
| Using `ifconfig`/`netstat` (deprecated) | Often not installed by default on modern distros | Use `ip` and `ss` (the `iproute2` suite) |

### When NOT to over-engineer subnetting

- For a single small lab VM, you don't need to carve up address space — `/24` for
  everything is fine. Subnetting design matters when you have **multiple network
  segments** (production VPC design, Lesson 16).

### Interview Angle

**Question:** "You're handed `10.0.0.0/22` and asked to carve it into 4 equal
subnets for a new environment. What size do you give each, and how do you verify a
host's IP actually belongs to one of them?"

A junior answer might guess "/24 each" without checking the math, or stop at "here's
the subnet, done." A senior answer starts from `/22` = 1024 addresses (2^(32-22)),
splits into 4 equal blocks by borrowing 2 more bits → four `/24`s (256 addresses
each, 254 usable after subtracting network/broadcast), and states each block's
range explicitly (`10.0.0.0/24`, `10.0.1.0/24`, etc.). For verification, they don't
eyeball it — they reach for `ip addr show` to confirm the assigned CIDR and
`ip route show` to confirm the host's default gateway sits inside the same subnet,
catching the classic misconfiguration where an IP and gateway are on different
networks and the host silently can't route.

---

## Step 3 — Alternatives

| Topic | Alternative | Note |
|---|---|---|
| `ip`/`ss` (this lesson, `iproute2`) | `ifconfig`/`netstat` (`net-tools`, legacy) | Still seen in older docs/scripts; `iproute2` is the modern standard on every current distro |
| IPv4 + subnetting | **IPv6** | Vastly larger address space, no NAT needed — but IPv4 + NAT (Lesson 09) remains dominant in most enterprise/cloud setups for now; IPv6 awareness is a "good to know," not yet core for junior roles |
| OSI 7-layer model | TCP/IP 4-layer model | OSI is the *teaching* reference; real protocol stacks and most documentation use TCP/IP's 4 layers — know both because interviewers ask about OSI specifically |

---

## Step 4 — Hands-On Task (build this yourself)

> ▶ **Do this on the lab**: start the environment first — `./infra/bootstrap.sh up` (once: `pull`), then
> `docker exec -it naviops-web bash`. **Node:** naviops-web + naviops-db (172.28.0.0/24). **Artifact:** `ip`/`ss` across the subnet; build `scripts/net_diag.sh`.
> Reference solution (after you try): `docs/learning/reference-solutions/` (gitignored answer key).

**Goal:** Produce `docs/networking/subnet-cheatsheet.md` — your own reference for
CIDR/subnet math — and run a full bottom-up diagnostic on your own machine.

### Lens C — Manual → Automated → Why

This lesson is mostly **conceptual diagnosis**, but the "automation" angle is: a
SysAdmin who has internalized the bottom-up checklist can write a
`scripts/network_diag.sh` (a natural Lesson 09 extension) that runs `ip addr`,
`ip route`, `ss -tlnp`, and `ping <gateway>` in sequence — turning a mental checklist
into a repeatable command.

### Subnet math practice (do these by hand, then verify)

For each, compute: network address, broadcast address, usable host range, and number
of usable hosts.

1. `192.168.1.0/24`
2. `10.0.0.0/16` — if you split this into `/24` subnets, how many do you get?
3. `172.16.5.0/26`
4. `192.168.1.128/25`
5. A point-to-point link needs only 2 usable IPs — what's the smallest CIDR prefix
   that provides exactly 2 usable hosts, and why?

Per [GeeksforGeeks' CIDR explainer](https://www.geeksforgeeks.org/computer-networks/classless-inter-domain-routing-cidr/),
the formula is: total addresses = 2^(32-prefix); usable hosts = total − 2 (minus
network + broadcast). Write your worked answers (including the formula applied) into
`docs/networking/subnet-cheatsheet.md`.

### Diagnostic walkthrough on your own machine

```bash
ip link show        # 1. Is your interface UP?
ip addr show        # 2. What IP/CIDR do you have?
ip route show       # 3. What's your default gateway? Is there a route to it?
ping -c 3 <gateway> # 4. Can you reach the gateway (L3)?
ss -tlnp            # 5. What's listening locally, and on which ports/processes?
```

Document the output (redacted — replace your real IP with `10.0.x.x` per the
redaction convention) in `docs/networking/subnet-cheatsheet.md` along with a short
explanation of what each command told you and which OSI layer it corresponds to.

### What to build, step by step

1. Work through the 5 subnet-math problems by hand.
2. Run the diagnostic walkthrough, capture (redacted) output.
3. Write `docs/networking/subnet-cheatsheet.md`: subnet math reference table (common
   prefixes `/24` through `/30` with usable-host counts), the OSI/TCP-IP layer
   mapping table, and the bottom-up diagnostic checklist with your own machine's
   (redacted) output as a worked example.
4. Commit on `lesson/08-networking-osi-tcpip-subnetting`.

---

## Step 5 — Verification

```bash
# Verify your subnet math with a calculator/tool (cross-check, don't replace the by-hand work)
python3 -c "
import ipaddress
net = ipaddress.ip_network('192.168.1.128/25')
print('Network:', net.network_address)
print('Broadcast:', net.broadcast_address)
print('Usable hosts:', net.num_addresses - 2)
"

# Confirm the diagnostic commands all run without error
ip link show && ip addr show && ip route show && ss -tlnp
```

### Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| `ip`/`ss` not found | Minimal container/image without `iproute2` | `apt install iproute2` / `dnf install iproute` |
| `ping` to gateway fails but internet works | Asymmetric routing or `ping` blocked by firewall on the gateway itself | Try `ip route get <internet-ip>` to see which route is actually used |
| Subnet math doesn't match the Python check | Arithmetic error in manual calc — common spot: forgetting to subtract 2 for usable hosts, or miscounting host bits | Recompute: host bits = 32 − prefix; total = 2^host bits |
| `ss -tlnp` requires `sudo` to show process names | Permission — only your own processes' names show without root | `sudo ss -tlnp` for full visibility |

### Redaction check ✅

Replace your real IP/gateway with `10.0.x.x` / `<GATEWAY_IP>` per
`LEARNING_STATE.md`'s redaction convention before committing.

---

## Step 6 — Quiz (Interview-Style, Graded)

**Q1.** List the 7 OSI layers in order, and give one real protocol/technology example
for each.

> **Your answer:**

**Q2.** For `10.0.0.0/22`, calculate: the network address, broadcast address, number
of usable hosts, and the range of usable host addresses.

> **Your answer:**

**Q3.** **Scenario:** A user reports "I can't open the company website." Walk through
your bottom-up troubleshooting approach, naming the OSI layer and command for each
step.

> **Your answer:**

**Q4.** What's the difference between `ip route` and `ip addr`? If a host has a valid
IP/subnet but no default route, what can and can't it do?

> **Your answer:**

**Q5.** Explain what `ss -tlnp` shows you, and how it relates to `/proc/<pid>/` from
Lesson 04.

> **Your answer:**

**Q6.** Why can two hosts on the same `/24` subnet communicate directly, while hosts
on different subnets need a router — what's actually different about the
communication path?

> **Your answer:**

---

## Step 7 — Reflection

*(Fill in after the quiz)*

- What did you learn?
- What confused you?
- What would you do differently?

---

## NOC Angle

> NOC Technician focus (Stage 1, `ROADMAP.md`).

Subnetting and OSI/TCP-IP are **core NOC knowledge** — on shift you read `ip`/`ss`/`ping`/`traceroute` and a network-monitoring dashboard (**SolarWinds, PRTG, Zabbix, Nagios**) showing interface/link health. Knowing the address plan tells you instantly whether an alerting host is in-scope and where it sits. Practice reading a dashboard alert and tracing it to the right segment.

## Lens E — Attacker & Defender (Red / Blue)

> Red/Blue framing (Gate Rule **Lens E**, D14). Build *both* mindsets: know how the
> tools in this lesson are abused, and how a defender detects and stops them.
> Frameworks: [GTFOBins](https://gtfobins.github.io/) · [MITRE ATT&CK](https://attack.mitre.org/) · [LOLBAS](https://lolbas-project.github.io/).

**🔴 Attacker (how it's abused — Step 2):** This is the recon layer: attackers map the network with `nmap`/`ss`, sniff traffic on a shared subnet, and ARP-spoof to MITM. Knowing OSI/TCP-IP is exactly what lets them find the soft targets. ATT&CK **T1046** (Network Service Discovery), **T1040** (Network Sniffing).

**🔵 Defender (detect & harden — Step 5):** Segment with VLANs/subnets, default-deny between zones, run an IDS and **port-scan detection** (e.g. fail2ban recidive, Suricata), encrypt traffic so sniffing yields nothing, and alert on unexpected east-west connections.

## Step 8 — Search Keywords For Further Understanding

**Core**
- `osi model 7 layers explained with examples`
- `subnet mask cidr notation calculator explained`
- `tcp three way handshake explained`
- `ip command vs ifconfig iproute2`

**Tools**
- `ss command examples linux`
- `traceroute mtr network troubleshooting`
- `python ipaddress module subnet calculation`

**Going further (future lessons)**
- `dns resolution process step by step`
- `nat types explained pat vs static`
- `vpc subnet design aws best practices`

---

**Red / Blue (Lens E — study attacker & defender in parallel):**
- 🔴 **Red (attacker):** `nmap network scanning techniques`, `MITRE ATT&CK T1046 network service discovery`, `arp spoofing man in the middle`, `network sniffing T1040`
- 🔵 **Blue (defender):** `network segmentation vlan`, `port scan detection IDS`, `suricata snort intrusion detection`, `detect arp spoofing`

## Lesson Status

- [ ] Hands-on task completed (Step 4)
- [ ] Verification passed (Step 5)
- [ ] Quiz answered + professional-answer comparisons requested (Step 6)
- [ ] Reflection completed (Step 7)
- [ ] Search Keywords reviewed (Step 8)

When complete, run the Update Protocol, then move to **Lesson 09 — Networking II
(DNS, DHCP, NAT, Routing, Firewalls)**.

---

*Lesson 08 written by Navi v28 · 2026-06-11 · WebSearch sources:
[DigitalOcean IP/CIDR guide](https://www.digitalocean.com/community/tutorials/understanding-ip-addresses-subnets-and-cidr-notation-for-networking),
[GeeksforGeeks CIDR](https://www.geeksforgeeks.org/computer-networks/classless-inter-domain-routing-cidr/),
[Wikipedia CIDR](https://en.wikipedia.org/wiki/Classless_Inter-Domain_Routing)*
