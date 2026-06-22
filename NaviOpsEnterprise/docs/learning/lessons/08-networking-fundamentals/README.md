# Lesson 08 — Networking Fundamentals

**Status:** ✅ ready for self-study (full depth) · **Date written:** 2026-06-21
**Schema:** 12-section IT-Support (`docs/learning/CLAUDE_TEACHING_RULES.md`)
**Focus:** the network knowledge a support tech needs to answer "is it the network?" — IP
addresses/subnets/gateway/DNS, the layered mental model, the core CLI tools (`ipconfig`, `ping`,
`tracert`, `nslookup`, `Test-NetConnection`), and the universal **"no internet" / "can't reach X"**
troubleshooting ladder.
**Primary artifact:** the "no internet" troubleshooting guide + `scripts/net_triage.ps1`.

> **How to use this lesson:** read §1–§7, do §8 (run the tools + work the ladder), produce §9, take
> the quiz, reflect. Then Lesson 09 (DNS/DHCP depth).

---

## §1 — Concept (Theory)

### What it is
A network lets devices talk. Each device has an **IP address** (its number on the network), a
**subnet mask** (which addresses are "local"), a **default gateway** (the door to other networks/the
internet), and **DNS servers** (which turn names like `intranet.corp.example` into IP addresses —
Lesson 09). Data moves in **packets**; reaching a far host means hopping through the gateway and
routers in between. The job: given "I can't reach X," find *which* of those pieces is broken.

### Why it matters for support
"No internet," "can't reach the share," "the app is down," "Wi-Fi keeps dropping," "VPN won't
connect" — a large slice of tickets are network-shaped. A tech who can run four commands and read
them resolves these at T1; one who can't escalates everything (and looks lost). It's also the second
great triage axis after "is it this machine or the whole network?"

### Three-Level Depth (Lens A)
- **Level 1 — User:** "the internet doesn't work" / "I can't get to the website."
- **Level 2 — Technician:** check the machine's IP config (`ipconfig /all`), test reachability in
  layers (gateway → internet IP → name), and **localize**: just this user (their PC/cable/Wi-Fi) vs
  everyone (the network/DHCP/DNS/uplink).
- **Level 3 — Engineer:** the **layered model** (the OSI/TCP-IP stack) — link (MAC/switch/Wi-Fi),
  network (IP/routing), transport (TCP/UDP ports), application (HTTP/DNS) — lets you isolate the
  failing layer; a `169.254.x.x` (APIPA) address means **DHCP failed** (no IP was leased — L09); a
  failed `ping` to the gateway is a *local/link* problem, a failed `ping` to `8.8.8.8` with a good
  gateway is *upstream*, and "IP works but name doesn't" is **DNS** (L09).

### Two Teaching Approaches (Lens B) — the layered model & addressing
**Approach 1 (technical):** networking is layered; each layer depends on the one below. To reach a
website you need: a valid **IP** (link+DHCP), a route to the **gateway** (network), an open **port**
to the server (transport), and **name resolution** (application/DNS). Test bottom-up; the lowest
broken layer is your cause.

**Approach 2 (analogy):** sending data is like **mailing a letter**. Your **IP address** is your
street address; the **subnet mask** tells you who's on your street (deliver directly) vs another town
(send via the post office); the **default gateway** is your local **post office** (everything leaving
the neighborhood goes through it); **DNS** is the **phone book** that converts a name to an address.
*No internet* usually means you have no return address (DHCP failed → 169.254), the post office is
unreachable (gateway down), or the phone book is broken (DNS). **Where it breaks down:** unlike mail,
it's instant and bidirectional, and a single misconfigured "phone book" entry can break one site while
everything else works.

### Visual (ASCII) — the reachability ladder
```
   YOUR PC ──(link: cable/Wi-Fi/switch)── GATEWAY ──(ISP/uplink)── INTERNET ── DNS ── web server
      │                                      │                        │          │
   ipconfig /all                       ping <gateway>           ping 8.8.8.8   nslookup name
   (got a real IP? not 169.254?)       (local network OK?)      (internet OK?) (DNS OK? → L09)

   Diagnose BOTTOM-UP:  no IP/169.254 → DHCP/link   |  gateway fails → local net  |
                        8.8.8.8 fails → upstream/ISP |  IP works, name fails → DNS (L09)
```

---

## §2 — Tools & Commands

| Tool | What it tells you |
|---|---|
| `ipconfig /all` | your IP, subnet, gateway, DNS, DHCP server, MAC — the whole identity |
| `ping <host/IP>` | can I reach it + round-trip time + packet loss |
| `tracert <host>` | the hops to a destination — *where* it breaks |
| `nslookup <name>` | does the name resolve, and to what (DNS — L09) |
| `Test-NetConnection <host> -Port <n>` | is a specific **port** open (app reachability) |
| `ipconfig /release` + `/renew` | get a fresh DHCP lease (L09) |
| `ipconfig /flushdns` | clear cached (possibly stale) DNS answers (L09) |
| `Get-NetIPConfiguration` / `Get-NetAdapter` | the PowerShell view; adapter up/down |

```powershell
ipconfig /all                                   # the first thing you run on any "no internet" ticket
ping 10.10.0.1                                   # the default gateway — local network reachable?
ping 8.8.8.8                                     # a known internet IP — internet reachable (bypasses DNS)?
Test-NetConnection intranet.corp.example -Port 443   # is the web app's port actually open?
tracert 8.8.8.8                                  # where does the path die?
```

---

## §3 — Real-World Support Context & Use Cases

- **"No internet" / "can't reach X"** is a top ticket family; the laddered method resolves most at T1.
- **Localize first:** one user (their port/cable/Wi-Fi/PC) vs a floor/site (switch/DHCP/DNS/uplink) →
  a single user is a P3, a whole floor is a **P1 major incident** (L31). Same symptom, very different
  response.
- **`ping IP works but name fails` = DNS** (Lesson 09) — the single most common "it's weird" network
  ticket.
- **`169.254.x.x` = DHCP failure** (Lesson 09) — no address was leased.
- **Wi-Fi specifics:** signal, wrong/changed SSID password, band/driver, captive portals.
- **Exam framing:** Network+ (addressing, tools, troubleshooting) and A+ Core 1 (networking + the
  troubleshooting methodology) lean heavily on exactly this.

---

## §4 — Demonstration (worked walkthrough)

> **Ticket INC-0201 (P3):** *"My computer has no internet — nothing loads. — Lena, DESK-1190."*
> (single user; the floor is fine → it's local.)

1. **Localize:** colleagues nearby are fine → it's **Lena's machine/connection**, not the network →
   P3.
2. **`ipconfig /all`:** does she have a **real IP**?
   - `169.254.x.x` → **DHCP failed** (no lease) → `ipconfig /release && /renew`; check cable/Wi-Fi
     link (L09 for DHCP depth).
   - A valid `10.10.x.x` with gateway/DNS → continue.
3. **`ping <gateway>` (e.g. 10.10.0.1):** fails → **local link** issue (cable unplugged, switch port,
   Wi-Fi disconnected, adapter disabled — check `Get-NetAdapter`). Succeeds → local net is fine.
4. **`ping 8.8.8.8`:** fails (gateway OK) → **upstream/ISP** issue (likely wider — re-check scope!).
   Succeeds → internet works by IP.
5. **`nslookup google.com`:** fails while 8.8.8.8 pings → **DNS** (L09): `ipconfig /flushdns`, verify
   DNS servers.
6. **Resolve the identified layer**, confirm pages load, document.

The discipline: **test in order, stop at the first failure** — that layer *is* the cause. Don't skip
to "reinstall the network driver" before you've localized.

---

## §5 — Troubleshooting Workflow (the diagnostic spine)

**Problem class: "no internet" / "can't reach a host or app."**

### 1 · Symptoms
Nothing loads · some sites work, others don't · "can't reach the share/app" · Wi-Fi drops · slow only
on the network · works wired not wireless (or vice-versa).

### 2 · Possible Causes (most-likely first)
1. **Physical/link**: cable/Wi-Fi disconnected, adapter disabled, switch port (just this user).
2. **DHCP failure**: `169.254.x.x`, no/incorrect IP (L09).
3. **DNS**: IP works, names don't (L09).
4. **Gateway/local network** down (often wider scope → incident).
5. **Upstream/ISP/uplink** down (whole site).
6. **App/port/firewall**: network's fine but one app's port is blocked/down.

### 3 · Diagnostic Steps (ordered — bottom-up)
| # | Check | If… | …then |
|---|---|---|---|
| 1 | Scope: others affected? | many | **major incident** (L31), escalate to network team |
| 2 | `ipconfig /all` — real IP? | 169.254 / none | DHCP (L09): release/renew, check link |
| 3 | Link: `Get-NetAdapter` / cable / Wi-Fi | down/disabled | reconnect/enable; reseat cable |
| 4 | `ping <gateway>` | fails | local link/switch issue |
| 5 | `ping 8.8.8.8` | fails (gw ok) | upstream/ISP |
| 6 | `nslookup <name>` | fails (8.8.8.8 ok) | DNS (L09): flushdns, check servers |
| 7 | `Test-NetConnection <app> -Port n` | port closed | app/firewall, not "the internet" |

### 4 · Resolution Steps
Reconnect/enable adapter, reseat cable, fix Wi-Fi (re-enter key/forget-reconnect); `ipconfig
/release` + `/renew` for DHCP; `ipconfig /flushdns` + correct DNS for name issues; escalate gateway/
upstream/switch problems to the network team; for an app-port block, route to the app/firewall owner.

### 5 · Escalation Criteria
Escalate to the **network team / NOC** for: multi-user outages (floor/site), gateway/switch/uplink
failures, ISP issues, or anything beyond the endpoint (this is the **NaviOpsNetwork** sibling's
domain). Attach: scope, `ipconfig /all`, the ping/tracert results showing *which layer* fails. A
multi-user outage is a **P1 major incident** (L31) — declare it.

### 6 · Post-Incident Documentation
Ticket note (which layer failed + fix), KB (self-service Wi-Fi/connectivity checks), major-incident
report + RCA for outages (L31/L32).

---

## §6 — Ticket Simulation

> **Ticket ENT-08 / INC-0202 (P1):** *"The entire 3rd floor has no internet — about 40 people, all at
> once, started ~9:05am."* Channel: multiple reports flooding in.

**Triage:** **many users, one location, simultaneous** → this is **not** an endpoint ticket — it's a
**major incident** (L31). Priority **P1**. Your job at the desk: confirm scope, declare/escalate fast,
and communicate — *not* to troubleshoot 40 laptops.

**Worked response:**
1. **Confirm scope quickly:** is it the whole 3rd floor? other floors fine? (Yes → localized to floor
   infrastructure — a switch/uplink/DHCP scope, not 40 separate PC problems.)
2. **One representative check:** on one affected PC, `ipconfig /all` — do they have an IP?
   - No IP / 169.254 across the floor → floor **DHCP scope** exhausted or the floor **switch/uplink**
     is down.
   - Valid IP but no gateway reachability → floor **switch/router** or uplink.
3. **Declare a major incident (L31):** open the P1, notify the **network team/NOC**, post a status
   update so 40 people stop opening 40 tickets (link them to the master incident).
4. **Coordinate, don't solo:** the network team fixes the switch/uplink; you own **communication** and
   the **timeline**.
5. **Resolve + verify + RCA:** on restoration, confirm with reps on the floor; capture the timeline
   for the **RCA** (L32) — *why* did the switch/uplink/DHCP fail, and how is recurrence prevented?

**The professional ticket note (major incident):**
```
SUMMARY: 3rd-floor network outage (~40 users) from 09:05. Localized to floor switch uplink. Declared
P1 major incident; network team restored uplink 09:38. RCA to follow.
SCOPE: entire 3rd floor; other floors unaffected → floor infrastructure, not endpoints.
DIAGNOSIS: rep PC had no gateway reachability with a valid IP → switch/uplink, not DHCP/DNS/PC.
ACTIONS: 09:08 confirmed scope · 09:10 declared P1, paged network team, posted status · 09:38 uplink
restored by network team · 09:42 confirmed with floor reps.
CAUSE (per network team): failed uplink on the 3rd-floor switch (RCA L32 in progress).
RESOLUTION: network team restored the uplink; service confirmed.
FOLLOW-UP: RCA + preventive (redundant uplink?); merged the duplicate floor tickets into this master.
```

---

## §7 — Service Desk / ITIL Perspective

- **Category:** Network/Connectivity. Single user = **Incident** (P3); multi-user = **Major Incident**
  (L31, P1) with a dedicated process.
- **Scope drives everything:** the *same words* ("no internet") are a 10-minute T1 fix or a
  business-wide P1 depending on **how many** are affected — confirming scope is your first move.
- **The hand-off line:** endpoints/Wi-Fi/this-PC = you; switches/routers/uplinks/ISP/DHCP-server/
  DNS-server = the **network team/NOC** (the NaviOpsNetwork domain). Escalate with the layered evidence.
- **Metric angle:** network MTTR and major-incident comms are highly visible to the business;
  proactive monitoring (NOC) catches outages before users do.

---

## §8 — Practical Lab (build this yourself)

**Goal:** master the reachability ladder and build a one-shot network-triage script.

### Lens C — Manual → Automation → Why
- **Manual:** type `ipconfig /all`, then `ping` gateway, then `ping 8.8.8.8`, then `nslookup`.
- **Automated:** `net_triage.ps1` runs the whole ladder and prints a verdict (IP ok? gateway ok?
  internet ok? DNS ok?) — the same diagnosis every time, attachable to a ticket.
- **Why:** in an outage you want one consistent capture, not four typed-from-memory commands; at NOC
  scale this becomes continuous monitoring (NaviOpsNetwork).

### Steps
1. **Read your config:** `ipconfig /all` — identify your IP, subnet, gateway, DNS, DHCP server.
2. **Walk the ladder:** `ping` your gateway → `ping 8.8.8.8` → `nslookup google.com`. Note what each
   proves.
3. **Port test:** `Test-NetConnection <a real internal host> -Port 443` — see app-layer reachability.
4. **Break-then-fix (lab):** disable your network adapter (`Disable-NetAdapter`) → observe the ladder
   fail at link → re-enable → recovers. (Safe, reversible.)
5. **Write `scripts/net_triage.ps1`** (ipconfig summary + gateway/internet/DNS ping + a port test with
   a pass/fail verdict) and the "no internet" troubleshooting guide.

### Lens D — the raw artifact (ipconfig telling you the cause)
```
> ipconfig /all
   IPv4 Address. . . . : 169.254.213.7   ← APIPA: DHCP FAILED — no address leased (L09); not "internet down"
   Subnet Mask . . . . : 255.255.0.0
   Default Gateway . . :                 ← blank gateway → can't leave the local link at all
   DNS Servers . . . . :
#   A 169.254 address + blank gateway is the fingerprint of "DHCP didn't give me an address."
#   The fix is release/renew + check the link/DHCP (L09) — pinging websites first would waste time.
```

---

## §9 — GitHub Artifact (the 6-artifact evidence package)

1. **Runbook:** `docs/runbooks/no-internet-triage.md` — the bottom-up reachability ladder.
2. **Troubleshooting Guide:** `docs/troubleshooting/no-internet.md` — the full spine (link/DHCP/DNS/
   gateway/upstream/app).
3. **Ticket Notes:** `docs/tickets/ENT-08-floor-outage.md` — the worked ENT-08 major incident.
4. **KB Article:** `docs/kb/` — "Wi-Fi/internet not working — checks before you call IT" (KB-0004).
5. **Incident Report:** the floor outage as a **major incident report** (template — feeds L31).
6. **Portfolio Artifact:** §10 bullet + the localize-then-ladder talking point.
7. **Script:** `scripts/net_triage.ps1` (`Invoke-ScriptAnalyzer`-clean).

---

## §10 — Portfolio Artifact

- **Resume bullet:** *"Built a PowerShell network-triage script and a 'no internet' troubleshooting
  guide implementing a bottom-up reachability ladder (IP → gateway → internet → DNS), and ran the
  service-desk side of a 40-user floor outage as a P1 major incident."*
- **Interview talking point:** **localize first (scope), then ladder bottom-up**; reading `ipconfig`
  to spot `169.254` (DHCP) vs "IP works, name fails" (DNS); when "no internet" is a P1 not a P3.
- **Serves:** Help Desk T1/T2, IT Support, Infrastructure Support (on-ramp to NaviOpsNetwork).

---

## §11 — Certification Crossover Notes

- **CompTIA Network+ (N10-009):** networking fundamentals (IP/subnet/gateway/DNS), tools, and network
  troubleshooting — core.
- **CompTIA A+ (Core 1):** networking concepts + the troubleshooting methodology. Detail in
  `alignment/CERTIFICATION-MAPPING.md`.

---

## §12 — Support Notes (Lens E — Service & Security)

**🤝 Service:** in a multi-user outage, **communication is the deliverable** — a single clear status
update stops a flood of duplicate tickets and panicked users; promise the next update time and keep it.

**🔒 Security:** beware **rogue Wi-Fi / evil-twin** access points (a network named like the corporate
SSID); teach users not to enter credentials on captive portals they don't recognize; an unexpected DNS
change or a new gateway can be malicious (DNS hijacking — L09/L29). On public Wi-Fi, the VPN (KB-0003)
protects traffic. Don't read out internal IP/topology details to unverified callers (recon).

---

## Quiz (Interview-Style, Graded)

**Q1.** A user says "no internet." What's the very first thing you determine, before touching their
PC, and why?
> **Your answer:**

**Q2.** What does an IP address of `169.254.x.x` tell you, and what do you do about it?
> **Your answer:**

**Q3.** `ping 8.8.8.8` works but `nslookup google.com` fails. What's broken, and how do you fix it?
> **Your answer:**

**Q4.** **Scenario:** 40 people on one floor lose internet at the same time. Is this a P3 or a P1, what
do you do first, and what do you NOT do?
> **Your answer:**

**Q5.** Explain default gateway, subnet mask, and DNS using the postal-mail analogy.
> **Your answer:**

*(Request the "Professional Answer" comparison under each before moving on.)*

---

## Reflection
*(After the quiz)* — What did you learn? · What confused you? · What would you do differently?

---

## Search Keywords For Further Understanding

**Core**
- `ip address subnet mask default gateway explained`
- `ipconfig ping tracert nslookup troubleshooting`
- `169.254 APIPA address meaning`
- `ping IP works but not hostname DNS`
- `OSI model layers for troubleshooting`

**Tools**
- `Test-NetConnection port check PowerShell`
- `tracert read the hops`

**Going further**
- `DNS DHCP and connectivity` (L09) · `email troubleshooting` (L13) · `incident management` (L31) ·
  **NaviOpsNetwork** (the full networking/NOC platform)

**Service / Security (Lens E):**
- 🤝 `major incident communication status updates`
- 🔒 `rogue access point evil twin`, `dns hijacking`, `public wifi vpn`

---

## Lesson Status
- [ ] §8 lab completed (ladder + port test + break/fix + net_triage.ps1 + guide)
- [ ] 6-artifact evidence package committed (§9)
- [ ] Quiz answered + professional-answer comparisons (graded)
- [ ] Reflection + Search Keywords reviewed

When complete, run the Update Protocol, then move to **Lesson 09 — DNS, DHCP & Connectivity**.

---

*Lesson 08 written by Navi · 2026-06-21 · full-depth. Sources to cite at study time: CompTIA
Network+ N10-009 (fundamentals + troubleshooting), A+ 220-1101 networking; deep dive → NaviOpsNetwork.*
