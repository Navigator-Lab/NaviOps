# Lesson 21 — Advanced Networking: VLANs, VPNs & Load Balancing

**Status:** ready for self-study · **Date written:** 2026-06-11
**Gate Rule:** Concept → Real-World Use → Alternatives → Hands-On → Verification → Quiz → Reflection → Search Keywords

> **How to use this lesson:** same as Lessons 03–20. **Month 3 opener** — this
> lesson extends Lesson 08-09's subnetting/firewall foundations and Lesson
> 16's VPC security groups into three new areas: **segmentation** (VLANs),
> **secure remote access** (VPN), and **traffic distribution** (load
> balancing).

---

## Step 1 — Concept

### What it is

**VLANs (Virtual LANs)** split one physical network into multiple isolated
logical networks (e.g., "servers" VLAN, "guest" VLAN) without separate
cables/switches. **VPNs (Virtual Private Networks)** create an encrypted
tunnel between two points over an untrusted network (the internet),
making remote machines behave as if on the same private network.
**Load balancers** (HAProxy, Nginx) distribute incoming traffic across
multiple backend servers.

### Why it exists

Lesson 08 taught you subnets on **paper** (CIDR math); Lesson 09 taught you
firewalls on **one host**. Real networks have many hosts that need
**isolation without physical rewiring** (VLANs), administrators who need
**secure access from outside the network** (VPN — instead of exposing SSH/
RDP directly to the internet, the Lesson 16 mistake of `0.0.0.0/0`), and
applications that need to **scale beyond one server** (load balancing — the
prerequisite for Lesson 24's multi-service setups and any "highly available"
design).

### What problem it solves

- **"I want my IoT devices isolated from my servers, on the same physical switch"** — VLANs (802.1Q tagging)
- **"I need to SSH into my home lab from a coffee shop without exposing port 22 to the internet"** — WireGuard VPN
- **"One server can't handle all the traffic / I need zero-downtime deploys"** — Load balancer (HAProxy/Nginx) across multiple backends
- **"How do I inspect raw application-layer traffic vs just routing it?"** — Layer 4 (TCP/UDP) vs Layer 7 (HTTP-aware) load balancing
- **"VPN access is too broad — anyone connected can reach everything"** — Zero Trust / per-service access rules layered on top of the VPN

### Three-Level Depth (Lens A)

- **Level 1 — Beginner:** A VLAN is identified by a **VLAN ID** (1-4094);
  switch ports are either **access ports** (untagged, belong to one VLAN) or
  **trunk ports** (carry multiple VLANs, tagged with 802.1Q headers). A VPN
  client connects to a VPN server/gateway; once connected, traffic to the
  remote network is routed through the encrypted tunnel. A load balancer sits
  in front of multiple backend servers and forwards each incoming connection
  to one of them based on an algorithm (round-robin, least-connections).
- **Level 2 — SysAdmin:** Per [LeMaker's 2026 VLAN segmentation
  walkthrough](https://blog.lemaker.org/network-segmentation-home-vlans-guest-iot-vpn-openwrt-2026/):
  VLANs are the practical implementation of "defense in depth" (Lesson 10) at
  the network layer — a compromised IoT device on its own VLAN can't directly
  reach your server VLAN without passing through a firewall rule
  (inter-VLAN routing). Per [WireGuard's own docs](https://www.wireguard.com/)
  and [nucamp's 2026 network security
  fundamentals](https://www.nucamp.co/blog/network-security-fundamentals-in-2026-protocols-firewalls-segmentation-and-vpns):
  **WireGuard** is the modern VPN choice — small codebase (easier to audit),
  modern cryptography (Curve25519, ChaCha20), and ~20%+ throughput over
  OpenVPN. Per [LogicMonitor's HAProxy
  guide](https://www.logicmonitor.com/blog/what-is-haproxy-and-what-is-it-used-for)
  and [dev.to's load balancing deep
  dive](https://dev.to/crit3cal/load-balancing-explained-nginx-haproxy-and-layer-4-vs-7-deep-dive-3oaa):
  **Layer 4** load balancing (HAProxy `tcp` mode) forwards raw TCP/UDP
  connections — fast, protocol-agnostic. **Layer 7** (HAProxy/Nginx `http`
  mode) inspects HTTP headers/paths — enables routing by URL path/hostname,
  but adds overhead. **Health checks** (the load balancer periodically probes
  backends, e.g., `GET /health`) determine which backends receive traffic —
  directly extends Lesson 12's Compose `healthcheck` concept to a
  multi-server context.
- **Level 3 — Systems/Kernel (Lens D):** VLAN tagging happens at **Layer 2**
  — the kernel's network stack (or the NIC, with hardware offload) inserts/
  strips an 802.1Q tag (4 extra bytes in the Ethernet frame containing the
  VLAN ID) — `ip link add link eth0 name eth0.10 type vlan id 10` creates a
  VLAN sub-interface on Linux. **WireGuard** is implemented as a Linux kernel
  module (`wg` device type) — it appears as a network interface
  (`wg0`) just like `eth0`, with its own routing table entries (Lesson 09's
  `ip route`), but all traffic through it is transparently encrypted/
  decrypted by the kernel. **HAProxy/Nginx** as load balancers operate in
  userspace, using the same `accept()`/`connect()` socket syscalls (Lesson
  04's process model) you'd use in any TCP server/client — but proxy
  bytes between two sockets (one to the client, one to a chosen backend),
  often using `splice()` for zero-copy forwarding (kernel-level
  optimization avoiding userspace buffer copies).

### Analogy (Lens B)

- **VLANs** = an office building with one set of physical hallways
  (cables/switches), but **colored ID badges** that determine which doors
  (ports) you can walk through — "blue badge" employees and "red badge"
  guests share the same hallways but can't enter each other's areas without
  going through a security checkpoint (router/firewall doing inter-VLAN
  routing).
- **VPN (WireGuard)** = a private, armored tunnel connecting your home office
  directly to the company building — once inside the tunnel, your laptop
  behaves as if it's plugged into the building's internal network, even
  though it physically traveled over public roads (the internet).
- **Load balancer** = a restaurant host who seats incoming customers (
  connections) at whichever table (backend server) is least busy
  (least-connections) or simply takes the next table in rotation
  (round-robin) — and periodically checks each table is actually staffed
  (health check) before seating anyone there.
- **Layer 4 vs Layer 7 LB** = the host either (L4) just glances at "how many
  people in this party" and assigns a table, without caring what they'll
  order — or (L7) actually reads their order ("this party wants the sushi
  bar specifically") and routes them to the right specialized section.

The "office badge" analogy holds well for VLANs but breaks down for **trunk
ports** — a single hallway (cable) carrying *multiple* badge-colors'
worth of tagged traffic simultaneously doesn't have a clean physical-building
equivalent (closer to a multiplexed pipe than a hallway).

---

## Step 2 — Real-World Use

### How SysAdmins use this daily

```bash
# VLANs (Linux)
ip link add link eth0 name eth0.10 type vlan id 10
ip addr add 10.0.10.1/24 dev eth0.10
ip link set eth0.10 up

# WireGuard
wg genkey | tee privatekey | wg pubkey > publickey
wg-quick up wg0
wg show                       # connected peers, handshake times, transfer stats

# HAProxy
sudo systemctl status haproxy
haproxy -c -f /etc/haproxy/haproxy.cfg   # validate config (like nginx -t)
echo "show stat" | sudo socat stdio /run/haproxy/admin.sock   # live backend status
```

**Real production scenarios:**
1. **Network segmentation audit** — "why can the dev VLAN reach the database
   VLAN?" — trace VLAN tagging on switch ports + inter-VLAN firewall rules,
   the same bottom-up debugging approach from Lesson 08/16.
2. **Remote access without exposed SSH** — instead of Lesson 16's "SSH from
   `<YOUR_IP>/32`" (which breaks when your IP changes), connect via WireGuard
   VPN first, then SSH to the **private** IP — the security group only needs
   to allow SSH from the VPN's subnet.
3. **Zero-downtime deploy** — HAProxy health checks mark a backend "down"
   before you take it out for an update, traffic drains to other backends,
   you update it, health check passes, traffic resumes — no user-visible
   downtime.

### Common mistakes

- **VLANs configured on switch but no inter-VLAN firewall rules** — "Isolated" VLANs can actually reach each other freely — false sense of security
  **Fix:** Explicit firewall rules (default-deny) between VLANs, allow only what's needed
- **VPN configured with overly broad access (entire network reachable once connected)** — A compromised VPN client/laptop = access to everything
  **Fix:** Scope VPN routes/firewall rules to only what each user/device needs (Zero Trust principle)
- **Load balancer with no health checks** — Traffic sent to a dead backend → user-facing errors
  **Fix:** Configure health checks (extends Lesson 12's Compose healthcheck pattern)
- **Single load balancer, no redundancy** — The load balancer itself becomes a single point of failure (Lesson 17 Q3's "single point of failure" theme, again)
  **Fix:** Multiple LB instances + DNS/floating IP, or managed LB (AWS ALB)
- **Choosing L7 LB when L4 would suffice (or vice versa)** — Unnecessary overhead (L7 for raw TCP), or missing routing features (L4 for HTTP path-based routing)
  **Fix:** Match LB layer to actual requirement

### When NOT to over-engineer

- For a single learning lab/VM, full VLAN segmentation is likely overkill
  (one flat network is fine) — but **WireGuard for remote access** is
  valuable even for a single server (replaces "SSH exposed to the internet"
  from Lesson 16). Load balancing matters once you have **2+ instances of the
  same service** (Lesson 24).

### Interview Angle

**Scenario:** "We set up WireGuard so admins can SSH to `10.10.0.1` over the
tunnel. Should we remove the old security group rule allowing SSH from our
office's public IP, keep both, or something else?"

A junior answer says "keep both, just in case" — leaving the broader,
internet-facing rule active defeats the purpose of adding the VPN. A senior
answer applies Lesson 16's least-privilege principle directly: restrict the
security group's SSH rule to `10.10.0.0/24` (the WireGuard subnet) only, and
remove the public-IP rule entirely — SSH now requires both `wg-quick up wg0`
and a valid WireGuard key, collapsing "my IP changed, edit the security group
again" into a non-issue. They'd also note the tradeoff: if WireGuard goes
down, there's no SSH fallback — which is the *correct* tradeoff, since a
fallback path defeats the segmentation, and WireGuard's own reliability
(systemd unit, `wg show` monitoring) becomes the thing to harden instead.

---

## Step 3 — Alternatives

| Topic | Alternative | Note |
|---|---|---|
| WireGuard (this lesson) | OpenVPN, IPsec, AWS Client VPN | OpenVPN is older/more configurable but slower; AWS Client VPN is managed but AWS-only and costs more |
| HAProxy | Nginx (as LB), AWS ALB/NLB | Per [LogicMonitor's guide](https://www.logicmonitor.com/blog/what-is-haproxy-and-what-is-it-used-for), HAProxy is purpose-built for advanced LB/health-checking; Nginx is simpler if you're already using it as a reverse proxy/web server; AWS ALB (L7)/NLB (L4) are managed equivalents |
| Manual VLAN config | Managed switch web UI / cloud VPC subnets (Lesson 16) | Cloud VPCs achieve similar isolation goals via subnets + security groups rather than 802.1Q VLANs |

---

## Step 4 — Hands-On Task (build this yourself)

**Goal:** Set up a WireGuard VPN to your lab VM (replacing direct SSH
exposure), and configure HAProxy as a load balancer in front of two simple
backend instances of a service.

### Lens C — Manual → Automated → Why

**Manual/exposed (Lessons 07/16):** SSH directly reachable on port 22 from
your current IP — works until your IP changes (home ISP, mobile hotspot,
travel), requiring a security-group edit each time.

**Automated (WireGuard):**
```ini
# /etc/wireguard/wg0.conf (server)
[Interface]
Address = 10.10.0.1/24
PrivateKey = <SERVER_PRIVATE_KEY>
ListenPort = 51820

[Peer]
PublicKey = <CLIENT_PUBLIC_KEY>
AllowedIPs = 10.10.0.2/32
```
```ini
# wg0.conf (client/laptop)
[Interface]
Address = 10.10.0.2/24
PrivateKey = <CLIENT_PRIVATE_KEY>

[Peer]
PublicKey = <SERVER_PUBLIC_KEY>
Endpoint = <SERVER_PUBLIC_IP>:51820
AllowedIPs = 10.10.0.0/24
PersistentKeepalive = 25
```

**Why this matters:** once `wg0` is up, `ssh user@10.10.0.1` works over the
encrypted tunnel — the security group can now restrict SSH to **only the
WireGuard subnet** (`10.10.0.0/24`, an internal address) instead of your
ever-changing public IP, closing the Lesson 16 Q5 risk permanently.

**HAProxy config (`/etc/haproxy/haproxy.cfg`):**
```
frontend http_front
    bind *:80
    default_backend http_back

backend http_back
    balance roundrobin
    option httpchk GET /health
    server web1 10.0.1.10:8080 check
    server web2 10.0.1.11:8080 check
```

### What to build, step by step

1. Install WireGuard on your lab VM (server) and your laptop/workstation
   (client). Generate key pairs (`wg genkey`/`wg pubkey`) for each.
2. Configure `wg0` on both ends per the sketch above (use a private subnet
   like `10.10.0.0/24`, distinct from your existing lab network).
3. `wg-quick up wg0` on both; verify with `wg show` (look for a recent
   "latest handshake").
4. Update your lab VM's firewall (Lesson 09 `ufw`/Lesson 16 security group):
   remove the broad SSH rule, allow SSH only from `10.10.0.0/24`.
5. Confirm SSH still works **only** via the WireGuard tunnel
   (`ssh user@10.10.0.1`), and fails if you bring `wg0` down.
6. **Load balancing**: run two instances of a simple HTTP service (e.g., two
   containers from Lesson 11/12, each returning a different identifying
   string + a `/health` endpoint, on different ports/IPs).
7. Install HAProxy, configure `haproxy.cfg` per the sketch, pointing at your
   two backend instances with health checks.
8. `haproxy -c -f /etc/haproxy/haproxy.cfg` to validate, then start it.
9. `curl` the load balancer's address repeatedly — confirm responses
   alternate between backends (round-robin). Stop one backend — confirm
   HAProxy stops sending it traffic (check `show stat`).
10. Document both setups in `docs/networking/vpn-lb-design.md` (redacted
    keys/IPs — **WireGuard private keys are secrets**, never commit them).
11. Commit configs (with placeholders for keys/IPs) and the design doc on
    `lesson/21-advanced-networking-vlans-vpn-loadbalancing`.

---

## Step 5 — Verification

```bash
# WireGuard
wg show                                  # confirm handshake + transfer stats
ssh user@10.10.0.1 "uptime"              # SSH over the tunnel works
wg-quick down wg0 && ssh user@10.10.0.1  # should now fail/timeout (or fall to public IP only if SG allows)

# HAProxy
haproxy -c -f /etc/haproxy/haproxy.cfg   # config validation
for i in $(seq 1 6); do curl -s http://<LB_IP>/; echo; done   # alternating backends
echo "show stat" | sudo socat stdio /run/haproxy/admin.sock | cut -d, -f1,2,18  # backend status (UP/DOWN)
```

### Troubleshooting

- **`wg show` shows no "latest handshake"** — Firewall blocking UDP port 51820, or wrong public key/endpoint
  **Fix:** Check security group/firewall allows UDP 51820; verify keys match (server's peer = client's public key, and vice versa)
- **SSH over WireGuard times out but `wg show` shows a handshake** — SSH daemon listening only on public interface, or firewall on lab VM blocks `10.10.0.0/24`
  **Fix:** Confirm `sshd` listens on all interfaces (or specifically `wg0`'s IP); check local firewall rules
- **HAProxy `-c` validation fails** — Config syntax error (often indentation/missing `backend` reference)
  **Fix:** Read the specific line number in the error; compare against HAProxy docs example syntax
- **All traffic goes to one backend only** — `balance` algorithm not set (defaults can vary), or one backend marked DOWN
  **Fix:** Explicitly set `balance roundrobin`; check `show stat` for backend health
- **Health check always fails (`backend marked DOWN`)** — `/health` endpoint doesn't exist, or wrong port in `server` line
  **Fix:** Verify `curl http://<backend_ip>:<port>/health` works directly first

### Redaction check ✅

**Never commit WireGuard private keys** (server or client) — use
`<SERVER_PRIVATE_KEY>`/`<CLIENT_PRIVATE_KEY>` placeholders in committed
configs; keep real keys only in `/etc/wireguard/` (mode 600, never in git).
Redact public IPs in `docs/networking/vpn-lb-design.md`.

---

## Step 6 — Quiz (Interview-Style, Graded)

**Q1.** What problem do VLANs solve that subnetting alone (Lesson 08) does
not? Why might two hosts be on different subnets but the same VLAN, or vice
versa?

> **Your answer:**

**Q2.** **Scenario:** You set up WireGuard and can now SSH to your lab VM via
its `10.10.0.x` address. Should you remove the SSH rule from `0.0.0.0/0`/your
public IP entirely, keep both, or something else? Justify your answer using
Lesson 16's least-privilege principle.

> **Your answer:**

**Q3.** Explain the difference between Layer 4 and Layer 7 load balancing.
Give one scenario where you'd need Layer 7 specifically.

> **Your answer:**

**Q4.** Why are health checks essential for a load balancer? What happens
without them, concretely, if one backend crashes?

> **Your answer:**

**Q5.** A load balancer with two backends is itself a single point of
failure. How does this connect to Lesson 17 Q3's discussion of single points
of failure for backups? What's a mitigation?

> **Your answer:**

**Q6.** Why is WireGuard often preferred over OpenVPN in 2026 deployments?
Name at least two reasons from this lesson's research.

> **Your answer:**

---

## Step 7 — Reflection

*(Fill in after the quiz)*

- What did you learn?
- What confused you?
- What would you do differently?

---

## Lens E — Attacker & Defender (Red / Blue)

> Red/Blue framing (Gate Rule **Lens E**, D14). Build *both* mindsets: know how the
> tools in this lesson are abused, and how a defender detects and stops them.
> Frameworks: [GTFOBins](https://gtfobins.github.io/) · [MITRE ATT&CK](https://attack.mitre.org/) · [LOLBAS](https://lolbas-project.github.io/).

**🔴 Attacker (how it's abused — Step 2):** Advanced network features bring advanced attacks: **VLAN hopping** (DTP/double-tagging), abused VPN credentials as remote access, and load-balancer/proxy bypass to reach backends directly. ATT&CK **T1599**, **T1133** (External Remote Services).

**🔵 Defender (detect & harden — Step 5):** Disable DTP/auto-trunking and prune VLANs, require **MFA on VPN**, segment and monitor east-west traffic, and front services with a WAF so the LB isn't a soft bypass.

## Step 8 — Search Keywords For Further Understanding

**Core**
- `vlan 802.1q tagging trunk access port explained`
- `wireguard vs openvpn 2026`
- `haproxy vs nginx load balancing layer 4 layer 7`
- `load balancer health checks round robin least connections`

**Tools**
- `ip link add type vlan linux`
- `wg-quick wireguard setup guide`
- `haproxy.cfg backend frontend examples`

**Going further (future lessons)**
- `prometheus haproxy exporter metrics`
- `docker compose multi backend load balancer`
- `aws application load balancer vs network load balancer`

---

**Red / Blue (Lens E — study attacker & defender in parallel):**
- 🔴 **Red (attacker):** `vlan hopping attack double tagging`, `MITRE ATT&CK T1599 network boundary bridging`, `vpn credential abuse remote access`, `load balancer proxy bypass`
- 🔵 **Blue (defender):** `disable dtp auto trunking`, `vpn multi-factor authentication`, `east-west traffic monitoring`, `web application firewall waf`

## Lesson Status

- [ ] Hands-on task completed (Step 4)
- [ ] Verification passed (Step 5)
- [ ] Quiz answered + professional-answer comparisons requested (Step 6)
- [ ] Reflection completed (Step 7)
- [ ] Search Keywords reviewed (Step 8)

When complete, run the Update Protocol, then move to **Lesson 22 —
Observability Stack (Prometheus & Grafana)**.

---

*Lesson 21 written by Navi v28 · 2026-06-11 · WebSearch sources:
[nucamp Network Security Fundamentals in 2026](https://www.nucamp.co/blog/network-security-fundamentals-in-2026-protocols-firewalls-segmentation-and-vpns),
[LogicMonitor What Is HAProxy?](https://www.logicmonitor.com/blog/what-is-haproxy-and-what-is-it-used-for),
[WireGuard Official Site](https://www.wireguard.com/),
[LeMaker Network Segmentation at Home: VLANs + VPN on OpenWrt 2026](https://blog.lemaker.org/network-segmentation-home-vlans-guest-iot-vpn-openwrt-2026/),
[dev.to Load Balancing Explained: Nginx, HAProxy, Layer 4 vs 7](https://dev.to/crit3cal/load-balancing-explained-nginx-haproxy-and-layer-4-vs-7-deep-dive-3oaa)*
