# Lesson 29 — VPN Technologies

**Status:** ✅ ready for self-study (full depth) · **Date written:** 2026-06-20
**Schema:** 12-section (`docs/learning/CLAUDE_TEACHING_RULES.md`)
**Focus:** IPsec (IKE/ESP), WireGuard, OpenVPN, site-to-site vs remote-access, split tunneling.
**Primary artifact:** `infra/configs/wireguard-lab.conf`.
**Difficulty:** **Difficult concept** — §1 uses two teaching approaches + an ASCII diagram (Lens B).

> **How to use this lesson:** VPNs are core to remote access + site connectivity + Net+/CCNA
> security. Read §1–§7, build a **WireGuard** tunnel between two lab hosts in §8. Lab/RFC-1918 +
> `<PSK>`/`<WG_KEY>` placeholders only — never commit real keys.

---

## §1 — Concept (Scientific Theory)

### What it is
A **VPN** (Virtual Private Network) creates an **encrypted tunnel** across an untrusted network
(the Internet) so two endpoints communicate as if on a private network. It provides
**confidentiality** (encryption), **integrity** (tamper detection), and **authentication** (only
authorized peers). Two deployment shapes: **site-to-site** (connect two networks, e.g. branch ↔
HQ) and **remote-access** (a user's device ↔ the corporate network). The major technologies:
**IPsec** (the standard, IKE + ESP), **WireGuard** (modern, simple, fast), and **OpenVPN** (TLS-based).

### Why it exists
The Internet is untrusted — sending private traffic across it in the clear exposes it to sniffing
and tampering (Lessons 19/05). A VPN tunnels that traffic inside an encrypted, authenticated
channel, so a branch office can securely reach HQ, or a remote worker can securely reach internal
systems, over the public Internet — without a private leased line.

### The technologies
| Tech | Layer/model | Notes |
|---|---|---|
| **IPsec** | L3, IKE (key exchange) + ESP (encrypt/auth) | the enterprise/site-to-site standard; complex; transport vs tunnel mode |
| **WireGuard** | L3, modern crypto, in-kernel | tiny, fast, simple config (key pairs); the modern default |
| **OpenVPN** | over TLS (TCP/UDP) | flexible, firewall-friendly, widely used for remote access |
| **SSL/TLS VPN** | L7/portal | browser-based remote access |

### Key concepts
- **Tunnel vs transport mode (IPsec):** tunnel mode encrypts the *whole* packet (site-to-site);
  transport mode encrypts the payload only (host-to-host).
- **Split tunneling:** only corporate-bound traffic goes through the VPN; the rest goes direct
  (vs full tunnel = everything through the VPN). A security + performance trade-off.
- **MTU:** VPN encapsulation adds overhead, shrinking the usable MTU — a classic cause of "small
  pings work, large transfers hang" (Lesson 18 MTU black-hole).

### Three-Level Depth (Lens A)
- **Level 1 — Beginner:** a VPN is a secret, locked tunnel through the public Internet so your data
  travels privately between two points, as if they were directly connected.
- **Level 2 — NetOps/NOC:** you configure tunnels (WireGuard key pairs / IPsec peers), choose
  site-to-site vs remote-access and split vs full tunnel, and troubleshoot the common failures:
  the tunnel won't establish (key/peer/firewall — UDP port), it's up but no traffic passes
  (routing/allowed-IPs/firewall), or large transfers hang (MTU). You verify with `wg show` /
  `ip xfrm state` and `ping`/`mtr` through the tunnel.
- **Level 3 — Wire/Kernel (Lens D):** WireGuard is **in the Linux kernel** — it adds a `wg`
  interface; packets routed to it are encrypted (ChaCha20-Poly1305) and sent as UDP to the peer;
  **AllowedIPs** double as the crypto-routing table (which peer owns which subnet). IPsec uses
  **IKE** (ISAKMP, UDP 500/4500) to negotiate keys and **ESP** (protocol 50) to carry encrypted
  payloads, managed via the kernel **XFRM** framework (`ip xfrm`). Encapsulation overhead reduces
  the path MTU (PMTUD interactions, Lesson 18).

### Two Teaching Approaches (Lens B) — the encrypted tunnel

**Approach 1 (technical):** a VPN peer authenticates the other end (pre-shared key, certificate, or
public-key pair), negotiates session keys, then encapsulates IP packets inside an encrypted,
integrity-protected payload sent to the peer's public endpoint over UDP (WireGuard/IKE) or TLS
(OpenVPN). The receiving peer authenticates, decrypts, and forwards the inner packet onto its local
network. Routing/AllowedIPs decide which traffic enters the tunnel.

**Approach 2 (analogy):** a VPN is an **armored courier through hostile territory**.
- Two offices (sites) need to exchange sensitive documents across a city full of pickpockets (the
  Internet). They hire an **armored van** (the encrypted tunnel): documents are sealed in a locked
  safe (encryption), the van only opens for the right key (authentication), and any tampering en
  route is obvious (integrity).
- **Site-to-site** = a regular armored route between two buildings; **remote-access** = a courier
  who picks up one employee working from home and brings them securely to the office network.
- **Split tunneling** = the van only carries *company* documents; the employee's personal mail goes
  by normal post (direct) — faster, but the company doesn't see/secure it.
- **MTU overhead** = the armor + safe take up space, so each van carries slightly less than a
  normal truck (smaller usable packet) — overfill it and it jams (MTU black-hole).
- **Where it breaks down:** an armored van is one physical vehicle; a VPN multiplexes many flows
  through one tunnel simultaneously, and the "armor" is math (crypto), not metal — but the
  trust/confidentiality intuition holds.

### Visual (ASCII) — site-to-site tunnel over the Internet

```
   SITE A 10.0.10.0/24                INTERNET (untrusted)         SITE B 10.0.20.0/24
   host ─► [VPN-GW A] ══════ encrypted tunnel (UDP) ══════ [VPN-GW B] ◄─ host
            pub: 203.0.113.5      ESP/WireGuard payload     pub: 203.0.113.9
   AllowedIPs/route: 10.0.20.0/24 → tunnel        10.0.10.0/24 → tunnel
   inner packet 10.0.10.x→10.0.20.x is encrypted inside an outer UDP packet between the public IPs
```

---

## §2 — Linux Networking Commands

```bash
# WireGuard (modern, in-kernel) — the lab tool
wg genkey | tee privatekey | wg pubkey > publickey      # generate a key pair (keep private secret!)
ip link add wg0 type wireguard
ip addr add 10.99.0.1/24 dev wg0
wg set wg0 private-key ./privatekey listen-port 51820 \
   peer <PEER_PUBKEY> allowed-ips 10.99.0.2/32 endpoint 203.0.113.9:51820
ip link set wg0 up
wg show                                  # tunnel status: peers, handshakes, transfer
ping 10.99.0.2                            # test through the tunnel
ip route                                  # confirm the tunneled subnet routes to wg0

# IPsec (enterprise) inspection
ip xfrm state ; ip xfrm policy           # IPsec SAs/policies (strongSwan/libreswan)
# MTU diagnosis through a tunnel (Lesson 18)
ping -M do -s 1372 10.99.0.2             # find the reduced path MTU inside the tunnel
```

**Cisco/CCNA mapping:** `crypto isakmp policy` / `crypto ipsec transform-set` / `crypto map`
(IPsec site-to-site), AnyConnect (remote access). CCNA Security covers IPsec site-to-site and
remote-access VPN concepts; WireGuard is the modern Linux-first equivalent.

---

## §3 — Real-World Use Cases

**Production scenarios:**
1. **Branch ↔ HQ (site-to-site):** securely connect office networks over the Internet instead of
   a leased line.
2. **Remote workers (remote-access):** WireGuard/OpenVPN/AnyConnect so staff reach internal systems
   securely from anywhere.
3. **Cloud connectivity:** VPN from on-prem to a cloud VPC (Lesson 33) for hybrid networking.
4. **Split-tunnel decision:** route only corporate traffic through the VPN (performance) vs full
   tunnel (security/visibility) — a real policy trade-off.

**How NOC/NetOps engineers use it:** monitoring tunnel health (a down site-to-site tunnel = a
branch offline = Sev1/2), and troubleshooting the three classic VPN failures (won't establish / up
but no traffic / MTU).

**When NOT to:** don't roll your own crypto; don't expose VPN endpoints without strong auth + MFA
(they're brute-force targets, §12); don't ignore MTU (a top "VPN is flaky" cause).

**Exam framing (Net+/CCNA):** VPN types (site-to-site vs remote-access), IPsec (IKE/ESP, tunnel vs
transport), split tunneling, and the role of encryption/auth are tested.

---

## §4 — Troubleshooting Section

| Symptom | Likely cause | Diagnose | Fix |
|---|---|---|---|
| Tunnel won't establish | key/peer mismatch, firewall (UDP 500/4500/51820) | `wg show` (no handshake); `nc -vzu` the port | fix keys/peer/firewall |
| Tunnel up, no traffic | routing / AllowedIPs / firewall | `ip route`, `wg show` allowed-ips | fix route/allowed-ips |
| Small pings work, transfers hang | **MTU** overhead (black-hole) | `ping -M do -s` through tunnel | lower MTU/MSS-clamp |
| Intermittent drops | endpoint IP changed / NAT keepalive | `wg show` last-handshake | persistent-keepalive; fix endpoint |
| One subnet reachable, another not | missing AllowedIPs/route for it | check allowed-ips/routes | add the subnet |

**Redaction check:** **never commit real keys/PSKs/endpoints** — `<WG_KEY>`, `<PSK>`,
`203.0.113.x` (RFC 5737) only.

---

## §5 — Common Mistakes

| Mistake | Impact | Fix |
|---|---|---|
| Committing private keys/PSKs | total compromise | placeholders only; keys in `.secrets/` |
| Ignoring MTU overhead | flaky/hanging transfers | MSS-clamp / lower MTU |
| Weak/no MFA on remote-access | brute-force/credential attacks | strong auth + MFA |
| Full vs split tunnel chosen blindly | perf or visibility loss | deliberate policy |
| Wrong AllowedIPs | traffic doesn't route into tunnel | match the remote subnets |
| Exposing VPN with weak crypto | interception | modern crypto (WireGuard/strong IPsec) |

---

## §6 — NOC Perspective

> NOC + Network Operations (Stages 1–2, 4, `ROADMAP.md`).

A site-to-site tunnel down means a **branch is isolated** — high severity, fast escalation. The NOC
monitors tunnel health (last-handshake/up-down, via `wg show` or SNMP) and runs the three-failure
triage (establish / traffic / MTU). VPN endpoints are also **attack-exposed** (Internet-facing
auth) — failed-auth spikes on the VPN are a security alert (Lesson 28). The MTU black-hole is a
signature "VPN is slow/flaky" ticket worth recognizing instantly.

---

## §7 — Incident-Response Perspective

- **Detect:** tunnel-down alert (branch offline) or VPN auth-failure spike (attack).
- **Triage:** connectivity incident (Sev by scope) vs security incident (brute force, Lesson 28).
- **Diagnose:** the three classic failures (establish/traffic/MTU) for connectivity; auth-log
  analysis for attacks.
- **Contain/Fix → Recover → Document:** restore the tunnel / block the attacker (Lesson 15) +
  enforce MFA, verify with `wg show` + traffic, document. VPN brute-force is a common security IR
  scenario.

---

## §8 — Practical Lab (build this yourself)

**Goal:** build a **WireGuard** tunnel between two lab hosts/namespaces, route a subnet through it,
diagnose MTU, and document `infra/configs/wireguard-lab.conf` (keys redacted).

### Lens C — Manual → Automated → Why
- **Manual:** generate keys, configure both peers, bring up `wg0`, test.
- **Automated:** a build script + a tunnel-health check (`wg show` last-handshake within N seconds;
  ping through the tunnel) — the NOC monitor for VPN health.
- **Why:** tunnels fail silently (handshake stops, traffic dies); an automated health check catches
  it before the branch calls in. Production teams monitor exactly this.

### Steps (two lab hosts/namespaces)
1. Generate a key pair on each peer (keep private keys out of the repo — `.secrets/`).
2. Configure `wg0` on each (addresses in `10.99.0.0/24`, each peer's pubkey + endpoint +
   AllowedIPs). Bring up; `wg show` should show a recent handshake; `ping` across the tunnel.
3. Route a "behind-peer" subnet through the tunnel via AllowedIPs; verify reachability.
4. **MTU drill (Lesson 18):** `ping -M do -s <large>` through the tunnel, find where it fails =
   the reduced path MTU; apply MSS-clamping / lower the `wg0` MTU; confirm large transfers work.
5. Write `infra/configs/wireguard-lab.conf` with **`<WG_PRIVATE_KEY>`/`<PEER_PUBKEY>`** placeholders,
   the AllowedIPs, and the MTU note. **Drill:** stop a peer → `wg show` shows stale handshake →
   your health check alerts.

### Lens D — see the encapsulation
`tcpdump -nni <wan-if> udp port 51820` shows only the *outer* encrypted UDP packets between the
public IPs — the inner traffic is invisible (that's the point). Contrast with capturing on `wg0`
(decrypted inner traffic) to *see* the tunnel boundary.

---

## §9 — GitHub Artifact (evidence 5-tuple)

1. **Script:** the WireGuard build + tunnel-health check.
2. **Config:** `infra/configs/wireguard-lab.conf` (keys/endpoints redacted).
3. **Drill:** tunnel established + MTU diagnosed + a peer-down detected.
4. **NAVI ticket:** `NAVI-29` (Change: "site-to-site WireGuard tunnel + health monitoring").
5. **Incident report:** a tunnel-down or VPN-brute-force runbook (sanitized).

---

## §10 — Portfolio Artifact

- **Resume bullet:** "Built and monitored a WireGuard site-to-site VPN (Linux, in-kernel),
  diagnosed an MTU black-hole, and added tunnel-health checks; understands IPsec (IKE/ESP) and
  remote-access trade-offs."
- **Interview talking point:** site-to-site vs remote-access, split vs full tunnel, the three VPN
  failure modes (including MTU), and why VPN endpoints need MFA.
- **Serves:** Jr Network Engineer + Network Operations + SOC (Stages 2, 4, 5); CCNA security.

---

## §11 — RHCSA Crossover Notes

Mostly **N/A for RHCSA** as an objective, but WireGuard/IPsec run on RHEL (NetworkManager has
WireGuard support; `nmcli`), and firewalld must allow the VPN UDP port — RHCSA firewall/service
skills apply. Securing remote access overlaps with RHEL hardening (sibling NaviOps).

---

## §12 — Security Notes (Lens E — Attacker & Defender) — security-heavy

> Frameworks: [MITRE ATT&CK](https://attack.mitre.org/).

**🔴 Attacker:** VPN endpoints are Internet-facing auth surfaces — **brute force / credential
stuffing** (`T1110`), exploiting **VPN appliance CVEs** (a top real-world initial-access vector,
`T1133` External Remote Services), and abusing VPNs for **C2/tunneling** to evade egress controls
(`T1572` Protocol Tunneling). Weak/legacy crypto enables interception.

**🔵 Defender:** **MFA** on all remote-access VPN, **patch VPN appliances** promptly, strong modern
crypto (WireGuard / well-configured IPsec), **monitor VPN auth logs** for brute force (Lesson 28),
limit what the VPN can reach (segmentation, least privilege — don't grant full network access), and
prefer **split-tunnel-with-inspection or full-tunnel** per your visibility needs. Verify by
attempting (lab) auth brute force and confirming MFA + detection block it.

---

## Quiz (Interview-Style, Graded)

**Q1.** What three security properties does a VPN provide, and how?
> **Your answer:**

**Q2.** Site-to-site vs remote-access VPN — define each and give a use case.
> **Your answer:**

**Q3.** What is split tunneling, and what's the security-vs-performance trade-off?
> **Your answer:**

**Q4.** **Scenario:** A new VPN tunnel is up (`wg show` shows handshakes) but users report that web
pages load partially or large file transfers hang while small pings work. What's the cause and fix?
> **Your answer:**

**Q5.** Name the three classic VPN failure modes and the first check for each.
> **Your answer:**

**Q6.** Why are VPN endpoints high-value attack targets, and what are the top two defenses?
> **Your answer:**

*(After you answer, request the "Professional Answer" comparison under each — graded before Lesson 30.)*

---

## Reflection
*(Fill in after the quiz)* — What did you learn? · What confused you? · What would you do differently?

---

## Search Keywords For Further Understanding

**Core**
- `vpn site to site vs remote access`
- `ipsec ike esp tunnel transport mode`
- `wireguard how it works`
- `split tunnel vs full tunnel`
- `vpn mtu mss clamping`

**Tools**
- `wireguard setup wg show`
- `strongswan libreswan ipsec`
- `openvpn configuration`

**Going further (future lessons)**
- `load balancing` (L30) · `high availability vpn` (L31) · `cloud vpn aws` (L33)

**Red / Blue (Lens E):**
- 🔴 `vpn brute force T1110`, `vpn appliance cve T1133`, `protocol tunneling c2 T1572`
- 🔵 `vpn mfa`, `patch vpn appliance`, `monitor vpn auth logs`, `least privilege vpn access`

---

## Lesson Status
- [ ] §8 lab completed (WireGuard tunnel + MTU + health check)
- [ ] §4 drill done (MTU / peer-down)
- [ ] Evidence committed (§9 — keys redacted)
- [ ] Quiz answered + professional-answer comparisons (graded)
- [ ] Reflection + Search Keywords reviewed

When complete, run the Update Protocol, then move to **Lesson 30 — Load Balancing**.

---

*Lesson 29 written by Navi · 2026-06-20 · full-depth. Sources to cite when worked: WireGuard
whitepaper, RFC 4301 (IPsec)/7296 (IKEv2), CompTIA Network+ N10-009, MITRE ATT&CK T1133/T1110/T1572.*
