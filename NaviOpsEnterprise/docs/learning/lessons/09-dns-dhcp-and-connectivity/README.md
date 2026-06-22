# Lesson 09 — DNS, DHCP & Connectivity

**Status:** ✅ ready for self-study (full depth) · **Date written:** 2026-06-21
**Schema:** 12-section IT-Support (`docs/learning/CLAUDE_TEACHING_RULES.md`)
**Focus:** the two services that quietly make networking work — **DHCP** (hands out IP addresses) and
**DNS** (turns names into addresses) — and the tickets that appear when each fails: `169.254`/no-IP
(DHCP) and "IP works but the name doesn't" / "wrong site loads" (DNS). Builds directly on Lesson 08.
**Primary artifact:** `scripts/check_dns.ps1` + a DNS/DHCP troubleshooting guide.

> **How to use this lesson:** read §1–§7, do §8 (watch a lease + resolve names + break/fix), produce
> §9, take the quiz, reflect. Then Lesson 10.

---

## §1 — Concept (Theory)

### What it is
**DHCP** (Dynamic Host Configuration Protocol) automatically gives a device its **IP address, subnet
mask, default gateway, and DNS servers** when it joins a network — a temporary **lease** with an
expiry. **DNS** (Domain Name System) translates human names (`intranet.corp.example`) into the IP
addresses computers actually use, via a hierarchy of name servers and **records** (A/AAAA, CNAME, MX,
etc.). Together they are why you can plug in a laptop and reach `outlook.office.com` without typing a
single number.

### Why it matters for support
These two cause a hugely disproportionate share of "weird" connectivity tickets. **DHCP failure** =
`169.254` / no address / "no internet" for one or many. **DNS failure** = "the internet's down" but
`ping 8.8.8.8` works; "the website goes to the wrong place"; "email/Teams won't connect." Recognizing
the *fingerprint* of each turns a baffling ticket into a two-command fix.

### Three-Level Depth (Lens A)
- **Level 1 — User:** "I plugged in and got nothing" (DHCP) / "the site won't load but my phone
  works" (often DNS).
- **Level 2 — Technician:** for DHCP — `ipconfig /all` (real IP vs 169.254), `release`/`renew`, check
  the link/scope; for DNS — `nslookup`, `ipconfig /flushdns`, verify the DNS servers and that names
  resolve to the right IP.
- **Level 3 — Engineer:** **DHCP's DORA** handshake (Discover→Offer→Request→Ack) leases an address
  from a **scope**; an exhausted scope or an unreachable DHCP server → no lease → APIPA `169.254`.
  **DNS** is a hierarchical, cached lookup (client cache → configured resolver → root/TLD/authoritative);
  **records** map names to data (**A** = name→IPv4, **CNAME** = alias, **MX** = mail server — L13);
  **TTL** controls caching, which is why a changed record can take time to propagate and why
  `flushdns` fixes a stale answer. This is *why* a specific command resolves a specific symptom.

### Two Teaching Approaches (Lens B) — DHCP lease & DNS resolution
**Approach 1 (technical):** DHCP: the client broadcasts, a server offers an address from its scope, the
client requests it, the server acknowledges (a timed lease it must renew). DNS: the client asks its
resolver for a name; the resolver returns the cached or looked-up record; the client connects to that
IP. Both are normally invisible — you only notice when they break.

**Approach 2 (analogy):** **DHCP is the hotel front desk** — you arrive (join the network) and are
handed a **room key (IP) valid for a set time (lease)**; if the hotel is full (scope exhausted) or the
desk is closed (server down), you get no key and can't function (`169.254`). **DNS is the phone book /
directory assistance** — you know the *name* of who you want, DNS gives you the *number (IP)* to dial;
a wrong or outdated entry sends your call to the wrong place (DNS hijack/stale cache). **Where it
breaks down:** the "phone book" is cached at several layers, so a fixed entry can still ring the old
number until caches (TTL) expire — hence `flushdns`.

### Visual (ASCII) — the two handshakes & their failures
```
   DHCP (DORA):  PC ──Discover──▶  ◀──Offer── SERVER ──Request──▶ ◀──Ack── (lease: IP/mask/gw/DNS)
                 FAIL → no Ack (server down / scope full) → PC self-assigns 169.254.x.x (APIPA) → "no internet"

   DNS:  PC ── "intranet.corp.example?" ──▶ RESOLVER ──▶ (cache / hierarchy) ──▶ "10.10.0.50" ──▶ connect
                 FAIL → name doesn't resolve (resolver down/wrong) → ping 8.8.8.8 works but names don't
                 WRONG → resolves to wrong IP (stale cache / hijack) → wrong/blocked site loads → flushdns
```

---

## §2 — Tools & Commands

| Task | Command |
|---|---|
| See IP + DHCP server + DNS servers + lease | `ipconfig /all` |
| Release / renew the DHCP lease | `ipconfig /release` then `ipconfig /renew` |
| Clear the DNS client cache | `ipconfig /flushdns` |
| Show the DNS client cache | `ipconfig /displaydns` / `Get-DnsClientCache` |
| Resolve a name (and to what) | `nslookup <name>` / `Resolve-DnsName <name>` |
| Query a *specific* DNS server | `nslookup <name> <dns-server-ip>` |
| Look up a record type (mail, etc.) | `Resolve-DnsName <domain> -Type MX` (L13) |
| PowerShell DNS client config | `Get-DnsClientServerAddress` |

```powershell
ipconfig /all | findstr /i "IPv4 Gateway DNS DHCP Lease"   # the key network identity lines
ipconfig /release; ipconfig /renew                          # force a fresh DHCP lease
Resolve-DnsName intranet.corp.example                       # does the name resolve, and to what IP?
nslookup intranet.corp.example 10.10.0.10                   # ask the corporate DNS server specifically
ipconfig /flushdns                                          # clear a stale/wrong cached answer
```

---

## §3 — Real-World Support Context & Use Cases

- **`169.254` / no IP** → DHCP: a single PC (link/cable/Wi-Fi or its lease) or many PCs (DHCP server
  down or scope exhausted — a wider incident).
- **"IP works, names don't"** → DNS: the single most common "the internet is broken but it isn't"
  ticket. `flushdns` + verify DNS servers usually nails it.
- **"Wrong/old site loads" or "internal sites fail on VPN"** → stale DNS cache or wrong resolver
  (e.g. using public DNS instead of corporate, so `intranet.corp.example` won't resolve).
- **Email/Teams/M365 "can't connect"** can be a DNS problem (the service name won't resolve) — check
  before assuming the app is broken (L13).
- **Static vs DHCP:** servers/printers often have **static** IPs or **DHCP reservations**; a duplicate
  static IP causes intermittent conflicts.
- **Exam framing:** Network+ (DNS/DHCP services, records, troubleshooting), A+ Core 1 (services + the
  `ipconfig`/`nslookup` tools).

---

## §4 — Demonstration (worked walkthrough)

> **Ticket INC-0204 (P2):** *"Internal sites won't load — the intranet, our ticket system, nothing
> 'company' works — but Google is fine. — Marco (on VPN), LT-0445."*

1. **Read the fingerprint:** *external* sites work, *internal* names fail → strongly **DNS**, and
   specifically *which resolver* Marco is using.
2. **`ipconfig /all`:** what DNS servers? On VPN he should use **corporate DNS** (`10.10.0.10`); if he's
   using a **public** resolver (8.8.8.8), it can't resolve `*.corp.example`.
3. **Prove it:** `Resolve-DnsName intranet.corp.example` → "name not found"; but
   `nslookup intranet.corp.example 10.10.0.10` (ask corporate DNS directly) → resolves fine. That
   confirms it's a **resolver** problem, not a dead intranet.
4. **Resolve:** ensure the VPN pushes corporate DNS (reconnect VPN; `ipconfig /flushdns`); if a stale
   cached "not found" lingers, flush it. Confirm internal names resolve and sites load.
5. **Document:** note it was a DNS-resolver issue on VPN, not an intranet outage (so nobody chases a
   ghost server problem).

The teaching point: **the pattern of *what works vs what doesn't* points to the layer** — internal-only
failures with working external = DNS/resolver, not "the internet."

---

## §5 — Troubleshooting Workflow (the diagnostic spine)

**Problem class: DHCP (no/auto IP) and DNS (name resolution) failures.**

### 1 · Symptoms
`169.254` / "no internet" right after connecting · IP conflict / intermittent drops · "internet down"
but `ping 8.8.8.8` works · internal sites fail, external work · "wrong site loads" · email/Teams can't
connect.

### 2 · Possible Causes (most-likely first)
1. **DHCP**: no lease (server down / scope exhausted / link down) → `169.254`.
2. **DHCP**: duplicate/static IP conflict → intermittent.
3. **DNS**: stale/poisoned client cache → wrong or failed resolution.
4. **DNS**: wrong resolver (public instead of corporate; VPN not pushing DNS) → internal names fail.
5. **DNS**: server down / record missing or wrong (wider; → network team).

### 3 · Diagnostic Steps (ordered)
| # | Check | If… | …then |
|---|---|---|---|
| 1 | `ipconfig /all` — real IP? | 169.254 / none | DHCP path → step 2 |
| 2 | `ipconfig /release` + `/renew` | gets a real IP | DHCP transient — done |
| 3 | scope: many users no IP? | yes | DHCP server/scope → network team (incident) |
| 4 | `ping 8.8.8.8` vs `nslookup <name>` | IP ok, name fails | DNS path → step 5 |
| 5 | `ipconfig /flushdns` then re-resolve | resolves now | stale cache — done |
| 6 | which DNS server? right one? (`/all`) | public/wrong | set/repair corporate DNS; reconnect VPN |
| 7 | `nslookup <name> <corp-dns>` directly | resolves there | resolver/VPN issue, not the record |
| 8 | resolves to wrong IP everywhere | yes | record wrong/poisoned → network team |

### 4 · Resolution Steps
`release`/`renew` for a stuck lease; escalate DHCP-server/scope problems; resolve a static/duplicate IP
conflict; `flushdns` for stale cache; correct the DNS server settings / reconnect VPN so it pushes
corporate DNS; escalate server-side DNS record issues to the network team.

### 5 · Escalation Criteria
Escalate to the **network team / NOC** for: DHCP **server**/scope failures (multi-user), DNS **server**
or **record** problems (resolves wrong/everywhere, missing record), or suspected **DNS hijacking/
poisoning** (security — L29). These are the NaviOpsNetwork/NaviOpsSec domains. Attach: `ipconfig /all`,
`nslookup` against both the default and the corporate DNS, scope.

### 6 · Post-Incident Documentation
Ticket note (DHCP vs DNS, exact fix), KB (Wi-Fi/connectivity self-help — KB-0004), incident+RCA for
server-side outages (L31/L32). Record a DNS record change as a **change** (L17/26).

---

## §6 — Ticket Simulation

> **Ticket ENT-09 / INC-0205 (P2):** *"I just got back from vacation, plugged in my laptop, and it
> says no internet — everyone else around me is fine. — Nadia, DESK-1200."*

**Triage:** **single** user (neighbors fine → not the network), right after rejoining → smells like a
**DHCP/lease or link** issue on her machine. **P2** (blocked, but isolated).

**Worked resolution:**
1. **`ipconfig /all`:** Nadia has **`169.254.88.13`**, blank gateway → **APIPA**: she didn't get a DHCP
   lease.
2. **Link check first:** is the cable seated / Wi-Fi connected / adapter enabled (`Get-NetAdapter`)? A
   `169.254` with a *down* link is just "not connected." (Here: link is up.)
3. **Force a lease:** `ipconfig /release` then `ipconfig /renew`.
   - **Gets a `10.10.x.x`** → fixed (her old expired lease/stale state cleared). Most cases end here.
   - **Still 169.254 with link up** → is the DHCP **scope exhausted** or **server** unreachable? Check
     whether *new* devices on that segment also fail → if yes, **escalate to network team** (scope/
     server), it's no longer just Nadia.
4. **Verify:** valid IP + gateway, `ping` gateway + `nslookup` a name → internet works.
5. **Document:** DHCP renew resolved it; note if a scope concern was ruled out.

**The professional ticket note:**
```
SUMMARY: Nadia had an APIPA 169.254 address (no DHCP lease) after returning from leave; release/renew
obtained a valid lease and restored connectivity. Confirmed DHCP scope healthy (other new devices OK).
SYMPTOM: "no internet", neighbors fine; ipconfig showed 169.254.88.13, blank gateway.
DIAGNOSIS: APIPA = DHCP did not lease an address. Link/adapter up (not a cable issue).
CAUSE: stale/expired DHCP client state after extended offline period (no lease obtained on rejoin).
RESOLUTION: ipconfig /release && /renew → got 10.10.4.61 + gateway + corporate DNS; verified browsing.
FOLLOW-UP: spot-checked that other new devices lease fine (scope not exhausted) — ruled out a wider
DHCP incident. KB-0004 linked.
```

---

## §7 — Service Desk / ITIL Perspective

- **Category:** Network/Connectivity. Single user = **Incident** (P2/P3); a DHCP-server/scope or
  DNS-server failure = **Major Incident** (L31, P1).
- **The scope question again:** one `169.254` is a desk fix; *many* `169.254` is a DHCP server/scope
  incident — confirm before you renew 50 laptops.
- **DNS changes are changes:** modifying a DNS record is a **change** (L17/26) with potential
  org-wide blast radius (mail, web, auth) — never casual.
- **Escalation line:** clients/leases/cache = you; **DHCP & DNS servers, scopes, and records** = the
  network team (NaviOpsNetwork). DNS hijacking = security (NaviOpsSec, L29).
- **Metric angle:** these fixes are high-FCR when you know the fingerprints; misdiagnosing DNS as "the
  internet" wastes time and tanks MTTR.

---

## §8 — Practical Lab (build this yourself)

**Goal:** see a lease, resolve names, recognize the two failure fingerprints, and script the checks.

### Lens C — Manual → Automation → Why
- **Manual:** `ipconfig /all`, `release`/`renew`, `nslookup`, `flushdns` typed by hand.
- **Automated:** `check_dns.ps1` reports the current DNS servers, resolves a set of critical names
  (intranet, M365, a public site) against the configured resolver *and* the corporate DNS, and flags
  mismatches — the DNS half of triage in one shot.
- **Why:** "is it DNS?" recurs constantly; one script that proves resolver-vs-record saves minutes per
  ticket and standardizes the answer; at NOC scale it becomes synthetic monitoring.

### Steps
1. **Inspect a lease:** `ipconfig /all` — find DHCP Server, Lease Obtained/Expires, your DNS servers.
2. **Renew drill:** `ipconfig /release` (watch connectivity drop) then `/renew` (watch it return).
   (Brief, reversible.)
3. **Resolve names:** `Resolve-DnsName` a public name and (in a lab/with corp DNS) an internal name;
   `nslookup name <specific-dns>` to compare resolvers.
4. **Cache drill:** `ipconfig /displaydns` (see cached answers) → `ipconfig /flushdns` → re-resolve.
5. **Write `scripts/check_dns.ps1`** (current resolvers + resolve critical names + compare to corp DNS
   + verdict) and the DNS/DHCP troubleshooting guide.

### Lens D — the raw artifact (resolver vs record)
```
> Resolve-DnsName intranet.corp.example            # using the laptop's CURRENT resolver
   ... : DNS name does not exist                    ← fails (wrong/public resolver in use)
> nslookup intranet.corp.example 10.10.0.10         # ask the CORPORATE DNS server directly
   Name: intranet.corp.example   Address: 10.10.0.50   ← resolves fine!
#   Same name, two resolvers, different result → the RECORD is fine; the laptop is using the WRONG
#   DNS server (public instead of corporate / VPN not pushing DNS). Fix the resolver, not the intranet.
```

---

## §9 — GitHub Artifact (the 6-artifact evidence package)

1. **Runbook:** `docs/runbooks/dhcp-dns-triage.md` — the `169.254`→DHCP and "name fails"→DNS paths.
2. **Troubleshooting Guide:** `docs/troubleshooting/dns-dhcp.md` — the full spine.
3. **Ticket Notes:** `docs/tickets/ENT-09-apipa-no-lease.md` — the worked ENT-09.
4. **KB Article:** `docs/kb/` — contributes to "Wi-Fi/internet not working" (KB-0004): the
   reconnect/renew/flush self-help steps.
5. **Incident Report:** a DHCP-scope-exhaustion or DNS-server outage as a major incident (template).
6. **Portfolio Artifact:** §10 bullet + the resolver-vs-record talking point.
7. **Script:** `scripts/check_dns.ps1` (`Invoke-ScriptAnalyzer`-clean).

---

## §10 — Portfolio Artifact

- **Resume bullet:** *"Built a PowerShell DNS-check script (resolver vs corporate-DNS comparison) and a
  DNS/DHCP troubleshooting guide, diagnosing APIPA/lease failures and resolver-side DNS issues without
  misattributing them to broad outages."*
- **Interview talking point:** the two fingerprints — **`169.254` = DHCP** (release/renew) and **"ping
  by IP works, by name fails" = DNS** (flushdns / wrong resolver) — and *resolver vs record* (same name,
  two DNS servers, different answers).
- **Serves:** Help Desk T2, IT Support, Infrastructure Support (on-ramp to NaviOpsNetwork).

---

## §11 — Certification Crossover Notes

- **CompTIA Network+ (N10-009):** DNS & DHCP services, record types, and troubleshooting — core.
- **CompTIA A+ (Core 1):** network services + the `ipconfig`/`nslookup` toolset. Detail in
  `alignment/CERTIFICATION-MAPPING.md`.

---

## §12 — Support Notes (Lens E — Service & Security)

**🤝 Service:** distinguish "your machine didn't get an address" (a quick personal fix) from "a service
is down" (wait on a team) — telling the user *which* sets honest expectations and prevents the "is it
fixed yet?" loop.

**🔒 Security:** DNS is a security surface — **DNS hijacking/poisoning** redirects a real name to a
malicious IP (the "wrong site loads" symptom can be an attack, not just stale cache — escalate to
security, L29, if records resolve wrong *everywhere*). Rogue **DHCP servers** can hand out a malicious
gateway/DNS (man-in-the-middle). Corporate DNS often enforces **filtering** (blocking malicious
domains) — "this site is blocked" may be a control working, not a bug. Don't disclose internal DNS
records/topology to unverified callers.

---

## Quiz (Interview-Style, Graded)

**Q1.** In one sentence each: what does DHCP do, and what does DNS do?
> **Your answer:**

**Q2.** A laptop shows `169.254.x.x`. What failed, what's your first command, and what's the wider
thing you'd rule out?
> **Your answer:**

**Q3.** A user can reach external sites but no internal ones (on VPN). What's the likely cause and how
do you prove it with two commands?
> **Your answer:**

**Q4.** **Scenario:** a user says a familiar website now loads a different/odd page, and `flushdns`
doesn't fix it — and a colleague sees the same. What do you suspect, and who do you involve?
> **Your answer:**

**Q5.** Why might `ipconfig /flushdns` fix a "site won't load" problem? What is it actually doing?
> **Your answer:**

*(Request the "Professional Answer" comparison under each before moving on.)*

---

## Reflection
*(After the quiz)* — What did you learn? · What confused you? · What would you do differently?

---

## Search Keywords For Further Understanding

**Core**
- `how DHCP works DORA lease`
- `how DNS resolution works records A CNAME MX`
- `169.254 APIPA fix release renew`
- `ipconfig flushdns stale dns cache`
- `nslookup query specific dns server`

**Tools**
- `Resolve-DnsName Get-DnsClientServerAddress`
- `ipconfig displaydns`

**Going further**
- `printers and peripherals` (L10) · `email troubleshooting MX records` (L13) ·
  `security awareness DNS hijacking` (L29) · **NaviOpsNetwork** (DNS/DHCP server depth)

**Service / Security (Lens E):**
- 🤝 `explaining service-down vs your-machine to users`
- 🔒 `dns hijacking poisoning`, `rogue dhcp server`, `dns filtering security`

---

## Lesson Status
- [ ] §8 lab completed (lease + resolve + cache drills + check_dns.ps1 + guide)
- [ ] 6-artifact evidence package committed (§9)
- [ ] Quiz answered + professional-answer comparisons (graded)
- [ ] Reflection + Search Keywords reviewed

When complete, run the Update Protocol, then move to **Lesson 10 — Printers & Peripherals**.

---

*Lesson 09 written by Navi · 2026-06-21 · full-depth. Sources to cite at study time: CompTIA
Network+ N10-009 (DNS/DHCP), A+ 220-1101 services; deep dive → NaviOpsNetwork.*
