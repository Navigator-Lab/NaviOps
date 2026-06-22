# Lesson 12 — DHCP

**Status:** ✅ ready for self-study (full depth) · **Date written:** 2026-06-20
**Schema:** 12-section (`docs/learning/CLAUDE_TEACHING_RULES.md`)
**Focus:** DORA, lease lifecycle, scopes/reservations/options, relay/helper-address, dnsmasq/ISC.
**Primary artifact:** `infra/configs/dhcp-dnsmasq.conf`.
**Difficulty:** **Difficult concept** — §1 uses two teaching approaches + an ASCII diagram (Lens B).

> **How to use this lesson:** DHCP is NOC scenario #2 (DHCP failure) and pairs with Lesson 05
> (APIPA). Read §1–§7, stand up `dnsmasq` DHCP in §8, run drill 2. Lab/RFC-1918 only.

---

## §1 — Concept (Scientific Theory)

### What it is
**DHCP** (Dynamic Host Configuration Protocol, RFC 2131) automatically gives a host its IP
configuration: **address**, **subnet mask**, **default gateway**, **DNS servers**, and other
**options** (NTP, domain, TFTP/boot, etc.). A host boots knowing nothing; DHCP hands it
everything needed to communicate. Runs over **UDP** — client port **68**, server port **67**.

### Why it exists
Manually assigning IPs to every device doesn't scale and causes conflicts/typos. DHCP centralizes
addressing: define a **scope** (range) once, and devices self-configure on boot, returning
addresses to the pool when done (**leases**). It's why a laptop "just works" on any network.

### DORA — the four-step exchange (memorize)
| Step | Message | Direction | Meaning |
|---|---|---|---|
| **D** | DISCOVER | client → broadcast | "any DHCP servers out there?" |
| **O** | OFFER | server → client | "here's an address you can have" |
| **R** | REQUEST | client → broadcast | "I'll take that one" (broadcast so other servers know) |
| **A** | ACK | server → client | "it's yours, here's the lease + options" |

### Key concepts
- **Lease:** an address is *leased* for a duration; the client **renews** at 50% (T1) directly to
  the server, and **rebinds** at 87.5% (T2) by broadcast if the server is unreachable.
- **Scope/pool:** the range of addresses a server hands out for a subnet.
- **Reservation:** a fixed IP tied to a MAC (DHCP's "static" — central, conflict-free).
- **Exclusions:** addresses inside the scope reserved for static devices (gateway, servers).
- **Options:** extra config delivered with the lease (option 3 = gateway, 6 = DNS, 51 = lease
  time, 66/67 = boot server).
- **Relay (helper-address):** DHCP DISCOVER is a **broadcast** and doesn't cross routers — a
  **DHCP relay / `ip helper-address`** on the gateway forwards it (unicast) to a central server,
  so one server can serve many subnets.

### Three-Level Depth (Lens A)
- **Level 1 — Beginner:** when a device joins a network, it shouts "I need an address!" and a DHCP
  server answers with one (plus the gateway and DNS), lending it for a while.
- **Level 2 — NetOps/NOC:** you configure scopes, reservations, exclusions, and options; you read
  lease files and logs; you know that a client on `169.254.x.x` (APIPA) means DORA failed — the
  causes being server down, **scope exhausted**, the relay/`ip helper-address` missing on a
  remote subnet, or a **rogue DHCP server** handing out bad addresses. You troubleshoot with
  `journalctl`/lease files + `tcpdump port 67 or 68`.
- **Level 3 — Wire/Kernel (Lens D):** DISCOVER/REQUEST are L2 broadcasts (`255.255.255.255`,
  dst MAC `ff:ff:ff:ff:ff:ff`) — that's why they need a relay to cross routers. The relay rewrites
  the **giaddr** field so the server knows which subnet's scope to use. On Linux, `dhclient`/
  `systemd-networkd`/NetworkManager are clients; `dnsmasq` or ISC `kea`/`dhcpd` are servers. The
  exchange is visible end-to-end with `tcpdump -ni any port 67 or 68`.

### Two Teaching Approaches (Lens B) — DORA & relays

**Approach 1 (technical):** a booting client with no IP broadcasts a DISCOVER; every server on
the segment may OFFER an address from its scope; the client broadcasts a REQUEST naming its chosen
offer (so non-chosen servers reclaim their offers); the chosen server ACKs with the lease and
options. Across a router, a relay agent intercepts the broadcast and unicasts it to the central
server, stamping giaddr so the right scope is used.

**Approach 2 (analogy):** checking into a hotel.
- You arrive with no room (no IP) and ask the front desk "any rooms?" (**DISCOVER**).
- The desk offers room 305 (**OFFER**).
- You say "I'll take 305" out loud so other desks know it's claimed (**REQUEST**).
- The desk confirms and hands you a key valid until checkout (**ACK** + lease + "breakfast is at
  7, Wi-Fi password is X" = options).
- You renew at the desk before checkout if you're staying longer (**renewal at T1**).
- A **relay** is like a concierge at a satellite building who phones the main front desk on your
  behalf because the desk isn't on your floor.
- **Where it breaks down:** a hotel won't hand the same room to two guests, but a *rogue* DHCP
  server (a second, unauthorized "front desk") absolutely will hand out conflicting/bad rooms —
  the security risk in §12.

### Visual (ASCII) — DORA, with and without a relay

```
  SAME SUBNET:                          ACROSS A ROUTER (relay needed):
   CLIENT            SERVER              CLIENT     ROUTER(relay)     SERVER
   │── DISCOVER ─bcast─►│               │─DISCOVER─►│ giaddr=subnet │
   │◄──── OFFER ────────│               │           │── unicast ───►│
   │── REQUEST ──bcast─►│               │◄────────── OFFER ─────────│
   │◄──── ACK ──────────│               │── REQUEST ►│── unicast ──►│
   (lease: IP, mask, gw, DNS, time)     │◄────────── ACK ───────────│
                                        (ip helper-address forwards the broadcast)
```

---

## §2 — Linux Networking Commands

```bash
# Client side
dhclient -v eth0                 # request a lease verbosely (watch DORA)
nmcli con up eth0                # NetworkManager renew
ip addr show eth0                # confirm the leased address (and 'dynamic' flag)
journalctl -u NetworkManager     # client-side DHCP logs

# Server side (dnsmasq example)
systemctl status dnsmasq
journalctl -u dnsmasq            # OFFER/ACK logs, scope exhaustion warnings
cat /var/lib/misc/dnsmasq.leases # active leases (MAC, IP, hostname, expiry)

# Watch the exchange on the wire
sudo tcpdump -ni any port 67 or port 68
```

**Cisco/CCNA mapping:** `ip helper-address <server>` (relay on the SVI/interface), `ip dhcp pool`
(IOS DHCP server), `show ip dhcp binding`. CCNA tests DORA, relay/helper-address, and DHCP
snooping.

---

## §3 — Real-World Use Cases

**Production scenarios:**
1. **Onboarding any client:** laptops/phones/IoT get addressing automatically via the scope.
2. **Centralized DHCP for many subnets:** one server + `ip helper-address` relays on each
   gateway — far easier than a server per VLAN.
3. **Reservations for infrastructure:** printers/APs/cameras get a fixed IP by MAC (predictable,
   but still centrally managed).
4. **Boot/provisioning:** options 66/67 point PXE clients at a boot server.

**How NOC engineers use it:** APIPA recognition + reading lease logs/exhaustion are core Tier-1.
"New devices can't get on the network" is a DHCP-first ticket.

**When NOT to:** don't DHCP your critical servers/gateways (use static or reservations);
don't run two uncoordinated DHCP servers on one segment (conflicts).

**Exam framing (Net+/CCNA):** DORA, lease/renewal (T1/T2), scope/reservation/exclusion, options,
relay/helper-address, and DHCP snooping are guaranteed.

---

## §4 — Troubleshooting Section

| Symptom | Likely cause | Diagnose | Fix |
|---|---|---|---|
| Client on `169.254.x.x` (APIPA) | DORA failed | `tcpdump port 67/68` (DISCOVER, no OFFER?) | start server / fix relay / expand scope |
| New devices fail, old ones OK | scope exhausted | `dnsmasq.leases` count vs scope size | enlarge scope / shorten lease |
| Only remote subnet fails | missing relay/helper-address | check gateway `ip helper-address` | add the relay |
| Wrong gateway/DNS on clients | bad DHCP options | server config (option 3/6) | fix options |
| Some clients get bad addresses | rogue DHCP server | `tcpdump` shows unexpected OFFER source | find/kill rogue; DHCP snooping |
| Lease not renewing | server unreachable at T1/T2 | client logs | restore server reachability |

**Redaction check:** RFC-1918 scope + lab MACs in committed configs.

---

## §5 — Common Mistakes

| Mistake | Impact | Fix |
|---|---|---|
| Not recognizing APIPA as DHCP failure | misdiagnosis | `169.254` ⇒ DORA failed |
| Forgetting the relay on remote subnets | only local subnet gets leases | `ip helper-address` per subnet |
| Scope too small / lease too long | exhaustion | size scope; tune lease time |
| Overlapping scopes / two servers | conflicts | one authoritative server per scope |
| Not excluding static IPs from the scope | duplicate-IP conflicts | exclude gateway/servers |
| No DHCP snooping | rogue server attacks | enable snooping on access switches |

---

## §6 — NOC Perspective

> NOC Technician focus (Stage 1, `ROADMAP.md`).

DHCP failure (NOC scenario #2) often presents as a **cluster** of clients on APIPA — instantly a
scope/relay/server incident, usually Sev2 (a segment can't onboard) escalating to Sev1 if
site-wide. The fast NOC moves: confirm APIPA, `tcpdump port 67/68` to see whether OFFERs are
coming, check the lease count for exhaustion, and check the relay on the affected subnet. A
**rogue DHCP server** is both an outage and a security event (clients get a malicious gateway) —
worth a security escalation (§12).

---

## §7 — Incident-Response Perspective

- **Detect:** clients can't get addresses / APIPA cluster.
- **Triage:** scope (one subnet vs site) → Sev.
- **Diagnose (RCA):** server down / scope exhausted / relay missing / rogue server. `tcpdump` +
  lease file localize fast.
- **Fix → Recover → Document:** restore/expand/relay/remove-rogue, verify a client gets a valid
  lease (`dhclient -v`), document. Maps to **drill 2 (DHCP failure)**.

---

## §8 — Practical Lab (build this yourself)

**Goal:** stand up a `dnsmasq` DHCP server, lease an address, break it (drill 2), fix it; produce
`infra/configs/dhcp-dnsmasq.conf`.

### Lens C — Manual → Automated → Why
- **Manual:** configure a scope, start dnsmasq, request a lease, read the lease file.
- **Automated:** a check that watches for APIPA clients and scope-exhaustion (free leases below a
  threshold) — a synthetic DHCP-health probe.
- **Why:** DHCP failures cascade (no address → nothing works); proactive scope/health checks
  catch exhaustion before users do. Production teams alert on low free-lease counts.

### Steps (isolated lab network/namespace)
```ini
# infra/configs/dhcp-dnsmasq.conf  (lab; RFC-1918)
interface=lab0
dhcp-range=10.0.50.100,10.0.50.150,255.255.255.0,1h     # scope (51 addresses, 1h lease)
dhcp-option=3,10.0.50.1            # option 3: default gateway
dhcp-option=6,10.0.50.1            # option 6: DNS
dhcp-host=aa:bb:cc:00:00:09,10.0.50.10   # a reservation by MAC
```
1. Run `dnsmasq --conf-file=infra/configs/dhcp-dnsmasq.conf -d` on a lab interface; from a client
   namespace, `dhclient -v` and watch DORA; confirm `ip addr` shows the lease.
2. Read `/var/lib/misc/dnsmasq.leases`.
3. **Drill 2:** stop dnsmasq (or shrink the scope to 0 free) → client falls to APIPA → diagnose
   with `tcpdump port 67/68` (DISCOVER, no OFFER) → fix → re-lease.
4. Capture the DORA exchange with `tcpdump -ni any port 67 or 68` and annotate the four messages.

### Lens D — read DORA on the wire
The `tcpdump` shows `BOOTP/DHCP` Discover/Offer/Request/ACK; note the broadcast addresses and
(if relayed) the giaddr field.

---

## §9 — GitHub Artifact (evidence 5-tuple)

1. **Script:** a DHCP-health check (APIPA / low-free-lease detector).
2. **Config:** `infra/configs/dhcp-dnsmasq.conf` (scope, options, reservation).
3. **Drill:** drill 2 (DHCP failure) executed.
4. **NAVI ticket:** `NAVI-12` (Incident: "clients on APIPA — DHCP scope exhausted — RCA").
5. **Incident report:** `docs/runbooks/incident-dhcp-failure.md` (symptom→tcpdump→RCA→fix→verify).

---

## §10 — Portfolio Artifact

- **Resume bullet:** "Deployed and operated a DHCP service (dnsmasq) with scopes, options, and
  reservations; diagnosed a DHCP-failure incident (APIPA) via packet capture, with a documented RCA."
- **Interview talking point:** explain DORA from memory, why a relay is needed across routers, and
  the APIPA-means-DHCP-failed diagnosis.
- **Serves:** NOC Technician + Network Operations (Stages 1–2).

---

## §11 — RHCSA Crossover Notes

RHCSA is primarily a *DHCP client* context (configuring `ipv4.method auto` with `nmcli`, verifying
leases) rather than running a server. But understanding DORA and the APIPA signal directly helps
RHEL "host can't get on the network" troubleshooting. Running dnsmasq is "useful, not required"
for RHCSA.

---

## §12 — Security Notes (Lens E — Attacker & Defender)

> Frameworks: [MITRE ATT&CK](https://attack.mitre.org/).

**🔴 Attacker:** **rogue DHCP server** (`T1557` Adversary-in-the-Middle) — an unauthorized server
hands clients a malicious **gateway/DNS**, routing their traffic through the attacker.
**DHCP starvation** — flooding DISCOVERs to exhaust the scope (DoS), often paired with a rogue
server to then take over addressing.

**🔵 Defender:** **DHCP snooping** on access switches (trust only the legit server's port, drop
OFFER/ACK from untrusted ports), **port security** + rate-limiting to blunt starvation, and
monitoring for unexpected OFFER sources. Verify by (lab-only) running a second DHCP server and
confirming snooping blocks it.

---

## Quiz (Interview-Style, Graded)

**Q1.** Walk through DORA, naming each message, its direction, and what it accomplishes.
> **Your answer:**

**Q2.** A client shows `169.254.x.x`. What does that mean and what are the top causes?
> **Your answer:**

**Q3.** Why doesn't DHCP work across a router by default, and what fixes it?
> **Your answer:**

**Q4.** **Scenario:** New devices on the sales VLAN can't get addresses; existing devices are fine.
What do you suspect and how do you confirm it?
> **Your answer:**

**Q5.** Difference between a reservation and an exclusion, and when you'd use each.
> **Your answer:**

**Q6.** What is a rogue DHCP server, what's the impact, and what control stops it?
> **Your answer:**

*(After you answer, request the "Professional Answer" comparison under each — graded before Lesson 13.)*

---

## Reflection
*(Fill in after the quiz)* — What did you learn? · What confused you? · What would you do differently?

---

## Search Keywords For Further Understanding

**Core**
- `dhcp dora process explained`
- `dhcp lease t1 t2 renewal`
- `dhcp relay ip helper-address`
- `dhcp options gateway dns`

**Tools**
- `dnsmasq dhcp configuration`
- `tcpdump dhcp port 67 68`
- `dhcp lease file linux`

**Going further (future lessons)**
- `dns resolution` (L13) · `dhcp snooping security` · `pxe boot dhcp options 66 67`

**Red / Blue (Lens E):**
- 🔴 `rogue dhcp server attack T1557`, `dhcp starvation dos`
- 🔵 `dhcp snooping configuration`, `detect rogue dhcp server`

---

## Lesson Status
- [ ] §8 lab completed (dnsmasq DHCP + lease obtained)
- [ ] §4 drill done (drill 2 — DHCP failure)
- [ ] Evidence committed (§9)
- [ ] Quiz answered + professional-answer comparisons (graded)
- [ ] Reflection + Search Keywords reviewed

When complete, run the Update Protocol, then move to **Lesson 13 — DNS** (already written full-depth).

---

*Lesson 12 written by Navi · 2026-06-20 · full-depth. Sources to cite when worked: RFC 2131/2132,
dnsmasq docs, CompTIA Network+ N10-009, Cisco DHCP references, MITRE ATT&CK T1557.*
