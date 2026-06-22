# Lesson 06 — IPv6

**Status:** ✅ ready for self-study (full depth) · **Date written:** 2026-06-20
**Schema:** 12-section (`docs/learning/CLAUDE_TEACHING_RULES.md`)
**Focus:** address types (GUA/LLA/ULA), SLAAC, NDP, dual-stack, EUI-64, `ip -6`.
**Primary artifact:** `docs/networking/ipv6-notes.md`.
**Difficulty:** **Difficult concept** — §1 uses two teaching approaches + an ASCII diagram (Lens B).

> **How to use this lesson:** IPv6 is increasingly on Net+/CCNA and in real networks (mobile,
> cloud, ISPs). You already have IPv6 on your machine — read §1–§7, explore it with `ip -6` in
> §8, build the notes. RFC 5737-style doc prefixes only (`2001:db8::/32`).

---

## §1 — Concept (Scientific Theory)

### What it is
**IPv6** (RFC 8200) is the successor to IPv4: a **128-bit** address (vs 32-bit), giving ~3.4×10³⁸
addresses — enough to end scarcity permanently. Written as eight 16-bit hex groups
(`2001:0db8:0000:0000:0000:0000:0000:0001`), compressed by omitting leading zeros and collapsing
one run of all-zero groups with `::` → `2001:db8::1`.

### Why it exists
IPv4 ran out of space; the stopgaps (NAT, private addressing) added complexity and broke
end-to-end connectivity. IPv6 restores a globally unique address per device, simplifies the
header, and bakes in **autoconfiguration** (SLAAC) and **neighbor discovery** (NDP, replacing
ARP + ICMP redirects + router discovery).

### Address types (the core mental model)
| Type | Prefix | Scope | Analogy |
|---|---|---|---|
| **GUA** (Global Unicast) | `2000::/3` | Internet-routable | a public IPv4 |
| **LLA** (Link-Local) | `fe80::/10` | one link only (auto on every IPv6 iface) | APIPA, but always present |
| **ULA** (Unique Local) | `fc00::/7` (usually `fd00::/8`) | private/internal | RFC 1918 private |
| **Multicast** | `ff00::/8` | groups | IPv4 multicast (no broadcast in v6!) |
| **Loopback** | `::1` | host | `127.0.0.1` |
| **Documentation** | `2001:db8::/32` | docs/examples | RFC 5737 v4 docs ranges |

**Key differences from IPv4:** no broadcast (multicast does its jobs), every interface has a
**link-local** address automatically, hosts often hold **multiple** addresses (LLA + GUA +
maybe ULA), and a `/64` is the standard subnet size (the host portion is 64 bits).

### Three-Level Depth (Lens A)
- **Level 1 — Beginner:** IPv6 addresses are long hex strings. Your device gets a "local" one
  (link-local, starts `fe80:`) for talking on the same link, and usually a "global" one (starts
  `2001:` etc.) for the Internet — often configured automatically with no DHCP needed.
- **Level 2 — NetOps/NOC:** **SLAAC** (Stateless Address Autoconfiguration) lets a host build its
  own GUA from the **prefix** advertised by the router (in an **RA** — Router Advertisement) plus
  an interface identifier. **NDP** (Neighbor Discovery Protocol, ICMPv6) replaces ARP — `ip -6
  neigh` is the v6 neighbour table; Neighbor Solicitation/Advertisement (NS/NA) do address
  resolution; Router Solicitation/Advertisement (RS/RA) do router/prefix discovery. **Dual-stack**
  (run v4 + v6 together) is the normal migration state — and means you must troubleshoot *both*
  (a name with an AAAA record may try v6 first and fail while v4 works — the "happy eyeballs"
  fallback isn't always graceful).
- **Level 3 — Wire/Kernel (Lens D):** SLAAC's interface ID is built either via **EUI-64** (derived
  from the MAC: split it, insert `fffe` in the middle, flip the 7th bit) or via **privacy
  extensions** (random, RFC 4941, to avoid MAC-tracking). NDP runs over **ICMPv6** (not a
  separate L2 protocol like ARP) using multicast (solicited-node multicast `ff02::1:ffXX:XXXX`),
  which is why blocking ICMPv6 wholesale *breaks* IPv6 (a classic firewall mistake). The Linux
  kernel processes RAs (`net.ipv6.conf.<if>.accept_ra`) to install the address + default route.

### Two Teaching Approaches (Lens B) — SLAAC & "why so many addresses"

**Approach 1 (technical):** an IPv6 host listens for Router Advertisements. The RA carries a
`/64` prefix and flags. With SLAAC, the host appends a 64-bit interface ID (EUI-64 or random) to
the prefix to form its GUA, sets the advertised router as its default gateway, and uses its
auto-generated link-local for all on-link NDP. No DHCP server is required (though DHCPv6 exists
for stateful/option needs).

**Approach 2 (analogy):** moving into a planned neighborhood that *posts its own street name*.
- The **link-local** address is like your name within the building — always works for talking to
  neighbors on the same floor, no paperwork.
- The **router's RA** is the city posting "this street's prefix is Maple-Lane-2001:db8:0:1".
- **SLAAC** is you painting your own house number using the posted street name + a number you
  derive yourself — instant valid address, no clerk (DHCP) needed.
- **Where it breaks down:** the analogy understates that a host keeps the building-name address
  (LLA) *and* the street address (GUA) *simultaneously and permanently* — IPv6 multi-addressing
  has no clean IPv4 or postal parallel.

### Visual (ASCII) — SLAAC + NDP

```
  HOST (new on link)                         ROUTER
   │ auto-creates LLA: fe80::.../64 (no help needed)
   │ ── RS (Router Solicitation, ICMPv6) ──────►│  "any routers here?"
   │ ◄──── RA (Router Advertisement) ───────────│  "prefix 2001:db8:0:1::/64, I'm your gw"
   │ builds GUA: 2001:db8:0:1: + [EUI-64/random]
   │ ── NS (Neighbor Solicitation) ────────────►│  "is this address already taken?" (DAD)
   │   (no answer = address is unique → use it)
   │ default route → the RA's router
```

---

## §2 — Linux Networking Commands

```bash
ip -6 addr show               # IPv6 addresses (note: usually LLA fe80:: + a GUA)
ip -br -6 addr                # brief
ip -6 route show              # IPv6 routing table (note the default via fe80:: gateway)
ip -6 neigh show              # NDP neighbour table (the IPv6 'ARP')
ping6 2001:db8::1   # or: ping -6 <addr>     # ICMPv6 reachability
ping6 -I eth0 ff02::1         # all-nodes link-local multicast (who's on this link?)
traceroute6 <host>            # IPv6 path
ss -6 -tuln                   # IPv6 listening sockets
sysctl net.ipv6.conf.eth0.accept_ra   # is the host accepting RAs? (SLAAC on/off)
dig AAAA example.com          # the IPv6 (AAAA) record
```

**Cisco/CCNA mapping:** `ipv6 unicast-routing`, `ipv6 address autoconfig` / `ipv6 address
2001:db8:0:1::1/64`, `show ipv6 interface brief`, `show ipv6 neighbors`, `show ipv6 route`. CCNA
tests SLAAC, EUI-64, and address-type identification.

---

## §3 — Real-World Use Cases

**Production scenarios:**
1. **Dual-stack services:** a service with both A and AAAA records — clients may prefer IPv6; if
   v6 is misconfigured, users see slowness/failures while v4 "works for me." You must test both
   (`curl -4` vs `curl -6`).
2. **Cloud/mobile:** AWS, mobile carriers, and modern ISPs deploy IPv6 widely; a NOC must read
   `ip -6` and AAAA records as routinely as v4.
3. **No-NAT internal design:** ULA (`fd00::/8`) gives globally-unique private addressing without
   the NAT complexity of IPv4.

**How NOC engineers use it:** recognizing address types at a glance (`fe80:` = link-local,
`2001:`/`2600:` = global, `fd` = ULA) and using `curl -4/-6` to isolate which stack is broken.

**When NOT to:** don't disable IPv6 reflexively "to simplify" — it can break services and is
increasingly required; troubleshoot it instead.

**Exam framing (Net+/CCNA):** address types, SLAAC, EUI-64 derivation, `::` compression rules,
and "no broadcast in IPv6" are guaranteed.

---

## §4 — Troubleshooting Section

| Symptom | Likely cause | Diagnose | Fix |
|---|---|---|---|
| Site slow then loads (dual-stack) | broken IPv6 path, v4 fallback | `curl -6 url` (fails?) vs `curl -4 url` | fix v6 routing/RA or AAAA |
| No GUA, only `fe80::` | no RA received (SLAAC) | `ip -6 addr`; `sysctl ...accept_ra` | enable RA / check router |
| IPv6 neighbors unreachable | ICMPv6 blocked by firewall | check firewall for ICMPv6 NS/NA/RA/RS | allow required ICMPv6 (don't block all) |
| Wrong default gateway (v6) | rogue RA | `ip -6 route`; inspect RAs (`radvdump`/tcpdump) | RA Guard on switches |
| AAAA resolves but unreachable | v6 routing gap | `traceroute6` | fix the v6 route |

**Redaction check:** use `2001:db8::/32` in committed examples.

---

## §5 — Common Mistakes

| Mistake | Impact | Fix |
|---|---|---|
| Blocking all ICMPv6 | breaks NDP → IPv6 stops working | allow NS/NA/RS/RA + PMTUD types |
| Disabling IPv6 to "fix" issues | hides problems, breaks services | troubleshoot, don't disable |
| Wrong `::` compression (two `::`) | invalid/ambiguous address | only one `::` per address |
| Ignoring the v6 stack in monitoring | half-blind on dual-stack | monitor v4 + v6 |
| Assuming DHCP is required | misses SLAAC | SLAAC self-configures from RAs |

---

## §6 — NOC Perspective

> NOC Technician focus (Stage 1, `ROADMAP.md`).

On dual-stack networks, "works for some users, not others" is often an IPv6-path issue — the NOC
move is `curl -4` vs `curl -6` (or `dig A` vs `dig AAAA`) to isolate the stack, which determines
whether it's a v6 routing/RA problem vs a v4 one. A **rogue RA** (a misconfigured or malicious
host advertising itself as the router) is a real incident that hands clients a bad gateway —
recognizing it and applying **RA Guard** is a NetOps escalation. Monitoring must cover both
stacks or you're half-blind.

---

## §7 — Incident-Response Perspective

- **Detect:** intermittent/partial reachability; AAAA-having services slow.
- **Triage:** isolate the stack (`curl -4/-6`) — scope to v6.
- **Diagnose (RCA):** no RA (SLAAC broken) / ICMPv6 blocked (NDP down) / rogue RA (bad gateway) /
  v6 routing gap.
- **Fix → Recover → Document:** fix RA/route/firewall, verify `ping6` + `curl -6`, document. Rogue
  RA is a strong security-flavored runbook (§12).

---

## §8 — Practical Lab (build this yourself)

**Goal:** explore your machine's live IPv6 and write `docs/networking/ipv6-notes.md`.

### Lens C — Manual → Automated → Why
- **Manual:** read `ip -6 addr`, identify each address's type by prefix, `ping6` your link-local
  router.
- **Automated:** extend `scripts/net_diag.sh` to also dump `ip -6 addr/route/neigh` and label
  address types — a dual-stack snapshot.
- **Why:** dual-stack incidents need both stacks captured at once; production diagnostics never
  assume v4-only anymore.

### Steps
1. `ip -6 addr show` — for each address, classify it (LLA `fe80:`, GUA `2000::/3`, ULA `fd`).
   Find your interface's EUI-64 or privacy-random ID.
2. `ip -6 route show` (note the `fe80::` link-local default gateway), `ip -6 neigh show`.
3. `ping6 -c2 ff02::1%eth0` (replace `eth0`) — see which nodes on your link answer (all-nodes
   multicast — the IPv6 way to "ping the broadcast").
4. `dig AAAA example.com`, then `curl -6 -sI https://example.com` vs `curl -4 -sI ...` — confirm
   both stacks.
5. Write `docs/networking/ipv6-notes.md`: address-type table, `::` compression rules with
   examples, the SLAAC/NDP flow diagram (§1), and the `curl -4/-6` isolation trick.

### Lens D — derive EUI-64 by hand
Take your interface MAC, split it, insert `fffe`, flip the 7th bit, and confirm it matches the
interface ID in your SLAAC address (when not using privacy extensions). This is exactly what the
kernel did.

---

## §9 — GitHub Artifact (evidence 5-tuple)

1. **Script:** `scripts/net_diag.sh` extended for IPv6 (dual-stack snapshot).
2. **Config/doc:** `docs/networking/ipv6-notes.md`.
3. **Drill:** disable `accept_ra` on a VM, observe loss of GUA, re-enable — or simulate a rogue
   RA in a lab and detect it.
4. **NAVI ticket:** `NAVI-06` (Task: "IPv6 notes + dual-stack snapshot") To Do→In Progress→Done.
5. **Incident report:** *(optional)* — rogue-RA or SLAAC-failure mini runbook.

---

## §10 — Portfolio Artifact

- **Resume bullet:** "Documented IPv6 addressing (GUA/LLA/ULA), SLAAC/NDP, and EUI-64; built
  dual-stack diagnostics isolating v4-vs-v6 reachability with `curl -4/-6`."
- **Interview talking point:** explain SLAAC and why blocking all ICMPv6 breaks IPv6 — a
  distinguishing, modern answer most juniors miss.
- **Serves:** Network Operations / Jr Network Engineer (Stages 2–4); increasingly expected.

---

## §11 — RHCSA Crossover Notes

RHCSA-relevant: configuring IPv6 with `nmcli` (`ipv6.method auto/manual`, `ipv6.addresses`),
understanding link-local vs global, and verifying with `ip -6 addr`/`ping6`. RHEL is dual-stack
by default; knowing not to blanket-block ICMPv6 in `firewalld` is practical exam-adjacent
knowledge.

---

## §12 — Security Notes (Lens E — Attacker & Defender)

> Frameworks: [MITRE ATT&CK](https://attack.mitre.org/).

**🔴 Attacker:** **rogue RA** (`T1557` Adversary-in-the-Middle) — a malicious host advertises
itself as the router, hijacking IPv6 traffic; **NDP spoofing** (the v6 analog of ARP spoofing);
**IPv6 used as a covert/overlooked path** on networks that monitor only v4 (shadow attack
surface).

**🔵 Defender:** **RA Guard** + **DHCPv6 Guard** + **ND Inspection** on switches; **monitor v6 as
well as v4** (don't leave it unobserved); allow only the required **ICMPv6** types rather than
blocking all; alert on unexpected RAs. Verify by injecting a lab RA and confirming RA Guard drops
it.

---

## Quiz (Interview-Style, Graded)

**Q1.** Compress `2001:0db8:0000:0000:0000:0000:0000:0001` and state the rule(s) you applied.
> **Your answer:**

**Q2.** Name the three main unicast address types (with prefixes) and the IPv4 concept each is
analogous to.
> **Your answer:**

**Q3.** Explain SLAAC: what does the host need from the router, and what does it generate itself?
> **Your answer:**

**Q4.** Why does blocking *all* ICMPv6 break IPv6 connectivity? Which mechanism depends on it?
> **Your answer:**

**Q5.** **Scenario:** Some users report a dual-stack site is slow/intermittent; others are fine.
How do you isolate whether IPv6 is the culprit?
> **Your answer:**

**Q6.** What is a rogue RA, what's the impact, and what's the switch-level defense?
> **Your answer:**

*(After you answer, request the "Professional Answer" comparison under each — graded before Lesson 07.)*

---

## Reflection
*(Fill in after the quiz)* — What did you learn? · What confused you? · What would you do differently?

---

## Search Keywords For Further Understanding

**Core**
- `ipv6 address types gua lla ula`
- `slaac stateless address autoconfiguration`
- `ndp neighbor discovery protocol icmpv6`
- `eui-64 interface identifier`
- `ipv6 address compression rules`

**Tools**
- `ip -6 commands linux`
- `ping6 traceroute6 examples`
- `curl -4 -6 test dual stack`

**Going further (future lessons)**
- `dhcpv6 vs slaac` · `dual stack migration` · `dns aaaa records` (L13)

**Red / Blue (Lens E):**
- 🔴 `rogue ra attack ipv6 T1557`, `ndp spoofing`, `ipv6 shadow attack surface`
- 🔵 `ra guard dhcpv6 guard`, `nd inspection`, `monitor ipv6 security`

---

## Lesson Status
- [ ] §8 lab completed (ipv6-notes + dual-stack snapshot)
- [ ] §4 drill done
- [ ] Evidence committed (§9)
- [ ] Quiz answered + professional-answer comparisons (graded)
- [ ] Reflection + Search Keywords reviewed

When complete, run the Update Protocol, then move to **Lesson 07 — Routing Fundamentals**.

---

*Lesson 06 written by Navi · 2026-06-20 · full-depth. Sources to cite when worked: RFC 8200/4862
(SLAAC)/4861 (NDP)/4291 (addressing), CompTIA Network+ N10-009, MITRE ATT&CK T1557.*
