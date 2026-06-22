# Lesson 13 — DNS (Domain Name System)

**Status:** ✅ ready for self-study (full depth — quality bar) · **Date written:** 2026-06-20
**Schema:** 12-section (`docs/learning/CLAUDE_TEACHING_RULES.md`)
**Focus:** recursion vs iteration, record types, zones, `dig`/`dig +trace`, caching/TTL,
forward/reverse, DoH/DoT.
**Primary artifact:** `scripts/dns_check.sh`.
**Difficulty:** **Difficult concept** — §1 uses two teaching approaches + an ASCII diagram (Lens B).

> **How to use this lesson:** DNS is the #1 NOC ticket source ("it's always DNS"). Read §1–§7,
> do §8 hands-on with `dig`, build `dns_check.sh`, run the **DNS-outage drill** (drill 1), then
> answer the quiz. Lab/RFC-1918 + `example.com` only; redact real internal zones.

---

## §1 — Concept (Scientific Theory)

### What it is
**DNS** is the distributed, hierarchical database that maps human-friendly **names**
(`www.example.com`) to machine **addresses** (`93.184.216.34`) — and much more (mail routing,
service discovery, text records). It's defined originally in **RFC 1034/1035** and runs mostly
over **UDP/53** (falling back to **TCP/53** for large responses and zone transfers).

### Why it exists
Humans don't remember IPs, and IPs change. A layer of indirection (name → address) lets
services move, scale, and load-balance without anyone re-learning an address. Centralizing it
in one file didn't scale (the original `HOSTS.TXT`), so DNS distributes authority hierarchically
— each level delegates the next.

### What problem it solves
| Problem | DNS answer |
|---|---|
| "I can't memorize `93.184.216.34`" | name → A/AAAA record |
| "The server moved to a new IP" | change one record, TTL expires, everyone follows |
| "Send mail for this domain where?" | MX records |
| "Spread load across many servers" | multiple A records / weighted responses |
| "Is this a name problem or a connectivity problem?" | `dig` vs `ping` isolates the layer |

### Three-Level Depth (Lens A)
- **Level 1 — Beginner:** When you type a name, your computer asks a **resolver** "what's the
  IP for this name?" The resolver finds out and answers; your computer caches it for a while
  (the **TTL**) so it doesn't ask again every time.
- **Level 2 — NetOps/NOC:** Resolution is **recursive** from the client's view (the resolver
  does all the work and returns a final answer) but **iterative** behind the scenes (the
  resolver walks the hierarchy: **root** → **TLD** (`.com`) → **authoritative** for the domain).
  You read the chain with `dig +trace`. Operationally you care about: which resolver the host
  uses (`/etc/resolv.conf`, `resolvectl status`), **caching/TTL** (stale records cause "it
  works for me but not them"), **forward** (name→IP) vs **reverse** (IP→name, PTR), and the
  record types (A/AAAA/CNAME/MX/NS/TXT/SOA/PTR/SRV). SERVFAIL vs NXDOMAIN is a key distinction
  (server failure vs "name doesn't exist").
- **Level 3 — Wire/Kernel (Lens D):** A DNS query is a single UDP datagram to port 53 with a
  header (ID, flags incl. **RD** recursion-desired / **RA** recursion-available, counts) and a
  question section (`QNAME`, `QTYPE`, `QCLASS`); the response echoes the ID and adds answer/
  authority/additional sections. Names are encoded as length-prefixed labels. On Linux the
  C call path is `getaddrinfo()` → NSS (`/etc/nsswitch.conf`) → the `dns` module → the
  resolver. You can see the raw exchange with `tcpdump -ni any port 53` and decode it in
  Wireshark (Lesson 19).

### Two Teaching Approaches (Lens B)

**Approach 1 (technical):** DNS is a delegated hierarchy. The namespace is a tree rooted at `.`
(the root). Authority is delegated downward via **NS** records: the root servers delegate
`.com` to the TLD servers, which delegate `example.com` to its authoritative servers, which
hold the actual A/MX/etc. records. A **recursive resolver** caches answers and walks this tree
on the client's behalf; **authoritative** servers answer only for zones they own.

**Approach 2 (analogy):** A phone directory system with a chain of operators.
- You ask your local **operator** (recursive resolver): "number for Acme Corp?"
- The operator doesn't know, so it asks the **national directory** (root): "who handles
  `.com`?" → "ask the `.com` directory."
- It asks the **`.com` directory** (TLD): "who handles `example.com`?" → "ask Acme's own
  directory."
- It asks **Acme's directory** (authoritative): "number for `www`?" → the actual answer.
- Your operator writes it on a sticky note (**cache**) with an expiry (**TTL**) so the next
  caller gets it instantly.
- **Where it breaks down:** real DNS caches at *every* level and can return *multiple* numbers
  (load balancing); a single human operator analogy understates the caching and parallelism —
  which is exactly why stale-cache incidents (Approach-1's TTL) are so common.

### Visual (ASCII) — recursive resolution of `www.example.com`

```
                                       ┌──────────────┐  "ask .com servers"
  stub        recursive resolver       │ ROOT (.)     │◄── (1) who serves .com?
  (your PC)   (e.g. 10.0.0.53)          └──────────────┘
     │  (RD=1)        │  ───────────────────► (1)
     │  "www.example  │  ◄───────────────────  referral to .com
     │   .com A?"     │     ┌──────────────┐
     ├───────────────►     │ .com TLD      │◄── (2) who serves example.com?
     │                │  ──►└──────────────┘
     │                │  ◄── referral to example.com NS
     │                │     ┌────────────────────┐
     │                │  ──►│ example.com (auth)  │◄── (3) www A?
     │                │  ◄──└────────────────────┘   "93.184.216.34" (+TTL)
     │  final answer  │
     │◄───────────────┤  caches it for TTL seconds
   uses 93.184.216.34
```

`dig +trace www.example.com` performs exactly this walk and prints each referral.

### Record types you must know

| Type | Maps | Example |
|---|---|---|
| **A** | name → IPv4 | `www → 93.184.216.34` |
| **AAAA** | name → IPv6 | `www → 2606:2800:...` |
| **CNAME** | name → another name (alias) | `shop → www.example.com.` |
| **MX** | domain → mail server (+ priority) | `example.com → 10 mail.example.com.` |
| **NS** | zone → authoritative name server (delegation) | `example.com → ns1.example.com.` |
| **PTR** | IP → name (reverse) | `34.216.184.93.in-addr.arpa → www.example.com.` |
| **TXT** | arbitrary text (SPF/DKIM/verification) | `"v=spf1 ..."` |
| **SOA** | zone authority + serial + timers | start-of-authority |
| **SRV** | service location (host+port) | `_sip._tcp → ...` |

---

## §2 — Linux Networking Commands

```bash
dig example.com                      # default A-record lookup (full DNS detail)
dig example.com +short               # just the answer (scriptable)
dig AAAA example.com                  # IPv6
dig MX example.com                    # mail servers
dig NS example.com                    # authoritative name servers
dig TXT example.com                   # SPF/DKIM/verification
dig +trace example.com                # walk root -> TLD -> authoritative (see delegation)
dig @9.9.9.9 example.com              # query a SPECIFIC resolver (isolates "your resolver" issues)
dig -x 93.184.216.34                  # reverse lookup (PTR)
dig example.com +norecurse           # ask without recursion (test authoritative directly)
host example.com                      # quick human-friendly lookup
nslookup example.com                  # interactive/legacy (Windows parity)
resolvectl status                     # systemd-resolved: which resolver(s) this host uses
getent hosts example.com              # resolution via NSS (what the OS apps actually use)
sudo tcpdump -ni any port 53          # watch the raw DNS queries/responses on the wire
```

**Cisco/CCNA mapping:** `ip name-server <ip>` (set resolver) · `ip domain-lookup` (enable) ·
`show hosts` (cache). The *concepts* are identical; Linux gives you far deeper visibility
(`+trace`, `tcpdump`).

> **`dig` reading tip:** check the **status** in the header — `NOERROR` (ok), **`NXDOMAIN`**
> (name doesn't exist), **`SERVFAIL`** (resolver/upstream failure). And the **flags**: `ra` =
> recursion available, `aa` = authoritative answer. These three fields resolve most DNS tickets.

---

## §3 — Real-World Use Cases

**Production scenarios:**
1. **"The website is down" → it's DNS:** `dig +short app.example.com` returns nothing/SERVFAIL
   while `ping 1.1.1.1` works → name resolution, not connectivity. Single fastest isolation.
2. **A deploy "didn't take":** old IP still served → **TTL/caching**. `dig` the authoritative
   server directly (`dig @ns1.example.com app.example.com`) vs your resolver to prove cache lag.
3. **Mail bouncing:** `dig MX` + `dig TXT` (SPF/DKIM) to verify routing + auth records.
4. **Split-horizon:** internal vs external resolvers return different answers — `dig
   @<internal>` vs `dig @<external>` confirms.

**How NOC engineers use it:** DNS is in the first three checks of nearly every reachability
ticket. The skill is *isolating* DNS from connectivity in one command, then localizing it
(your resolver vs forwarder vs authoritative) with `@server` and `+trace`.

**When NOT to:** don't lower TTLs to 0 "to be safe" — it crushes resolver caches and your
authoritative load; pick TTLs deliberately (low before a planned migration, normal otherwise).

**Exam framing (Net+/CCNA):** record types, recursive vs iterative, forward vs reverse,
UDP/TCP 53, and the resolution order are guaranteed questions.

---

## §4 — Troubleshooting Section

| Symptom | Likely cause | Diagnose | Fix |
|---|---|---|---|
| `ping name` fails, `ping 1.1.1.1` works | DNS, not connectivity | `dig +short name` | fix resolver/forwarder (below) |
| `dig name` = SERVFAIL | resolver or upstream forwarder broken | `dig @9.9.9.9 name` (works? → *your* resolver) | restart/repoint resolver; check forwarder reachability |
| `dig name` = NXDOMAIN | name genuinely doesn't exist / typo / wrong zone | `dig +trace name` | fix the record / query the right zone |
| Resolves to the *old* IP after a change | TTL/cache | compare `dig @resolver` vs `dig @authoritative` | wait out TTL / flush cache (`resolvectl flush-caches`) |
| Works on one host, not another | different `/etc/resolv.conf` | `resolvectl status` on both | align resolver config |
| Slow resolution | unreachable primary resolver, timeout-then-fallback | `dig name` (note Query time) | fix/remove the dead resolver |

Decision flow:
```
dig +short name  ──answer?──► DNS is fine; problem is elsewhere (connectivity/app)
       │ no/err
       ▼
dig @9.9.9.9 name ──works?──► YOUR resolver/forwarder is the fault (repoint/restart)
       │ still fails
       ▼
dig +trace name  ──► find which level breaks (root/TLD/authoritative) → escalate to that owner
```

**Redaction check:** scrub real internal zone names / private resolver IPs before committing;
use `example.com` + `10.0.0.53`.

---

## §5 — Common Mistakes

| Mistake | Impact | Fix |
|---|---|---|
| Treating every reachability issue as connectivity | wastes time pinging when it's DNS | `dig` first to isolate |
| Confusing SERVFAIL with NXDOMAIN | wrong escalation (server vs record) | SERVFAIL=server broken, NXDOMAIN=no such name |
| CNAME at the zone apex | breaks per RFC (apex needs A/SOA/NS) | use A/ALIAS at apex, CNAME only on sub-names |
| Forgetting reverse (PTR) zones | mail/logging tools flag the host | maintain `in-addr.arpa` PTRs |
| Open recursion to the internet | DNS amplification DDoS (security) | restrict recursion to internal clients |
| TTL set to 0 / very low everywhere | resolver cache thrash, high auth load | deliberate TTLs; lower only pre-migration |

---

## §6 — NOC Perspective

> NOC Technician focus (Stage 1, `ROADMAP.md`).

DNS is the single most common NOC incident category — "it's always DNS." On the dashboard,
DNS failures show up *indirectly*: a cluster of web/app reachability alerts firing at once with
intact ICMP/connectivity is the DNS signature. The first NOC move is `dig @<resolver> name` vs
`dig @9.9.9.9 name` to decide **your resolver vs upstream** — which determines the escalation
target (internal DNS team vs ISP/forwarder, `noc/escalation-matrix.md`). Monitor resolvers
directly (synthetic `dig` checks in Lesson 21) so DNS fails *as a DNS alert*, not as a confusing
swarm of app alerts. SLA angle: DNS is a shared dependency — a resolver outage breaches many
services' SLOs at once, so it's almost always Sev1 (`noc/sla-concepts.md`).

---

## §7 — Incident-Response Perspective

Maps to NOC scenario **#1 DNS outage** (`noc/noc-scenarios.md`) and **drill 1**:
- **Detect:** synthetic `dig` check fails / app-reachability alert cluster.
- **Triage:** scope (one zone vs all resolution) → severity (usually Sev1 — shared dependency).
- **Contain:** point clients at a known-good secondary resolver while you fix the primary (fast
  restore, `noc/outage-management.md`).
- **Diagnose (RCA):** resolver up? forwarder reachable (firewall blocking UDP/53?)? zone expired
  (SOA serial/timers)? recursion broken? `dig +trace` to localize the level.
- **Fix → Recover → Document:** restore, verify `dig` answers, write the runbook
  (`docs/runbooks/incident-dns-outage.md`) with the RCA + a prevention item (e.g. "add DNS
  resolution to the change-rollout checklist" — the classic 5-Whys root cause in `noc/rca.md`).

---

## §8 — Practical Lab (build this yourself)

**Goal:** become fluent reading `dig`, then build `scripts/dns_check.sh` and run the DNS-outage
drill.

### Lens C — Manual → Automated → Why
- **Manual:** `dig`, read status/flags/answer, compare resolvers with `@`.
- **Automated:** `scripts/dns_check.sh` — given a name, query the local resolver *and* a public
  one, compare, and flag SERVFAIL/NXDOMAIN/mismatch. This is the synthetic check a NOC runs
  every minute.
- **Why:** turns "it's always DNS" guesswork into a one-command verdict that drops straight
  into a ticket. Production teams run exactly this (blackbox-exporter DNS probes, Lesson 22).

### Steps
1. Explore: `dig example.com`, `dig +short`, `dig MX`, `dig NS`, `dig +trace example.com`,
   `dig -x <some-public-ip>`. For each, identify the **status** and **flags** in the header.
2. Prove the resolver-isolation trick: `dig @9.9.9.9 example.com` vs `dig @1.1.1.1 example.com`.
3. Build `scripts/dns_check.sh` (skeleton — operator finishes the TODOs):

```bash
#!/usr/bin/env bash
# dns_check.sh — compare local vs public resolver for a name. NaviOpsNetwork Lesson 13.
# Usage: dns_check.sh <name> [public_resolver]
set -euo pipefail
name="${1:?usage: dns_check.sh <name> [public_resolver]}"
pub="${2:-9.9.9.9}"
local_ans=$(dig +short "$name" @"$(awk '/^nameserver/{print $2; exit}' /etc/resolv.conf)" 2>/dev/null || true)
pub_ans=$(dig +short "$name" @"$pub" 2>/dev/null || true)
status=$(dig "$name" +noall +comments | awk -F'status: ' '/status:/{print $2}' | awk -F',' '{print $1}')
echo "name=$name  status=$status"
echo "local_resolver: ${local_ans:-<none>}"
echo "public($pub):    ${pub_ans:-<none>}"
# TODO (operator): exit non-zero on SERVFAIL, and warn on local/public mismatch (possible cache/split-horizon).
```

4. `bash -n` → `shellcheck` → run it against a known-good name and a typo'd name.
5. Run **drill 1 (DNS outage)** from `troubleshooting-drills.md`: break resolution (block UDP/53
   with nftables or point `resolv.conf` at a dead resolver), confirm `dns_check.sh` flags it,
   diagnose with the §4 decision flow, fix, verify.

### Lens D — see DNS on the wire (optional)
```bash
sudo tcpdump -ni any port 53 &     # then run a dig in another shell and watch the query/response
dig example.com
```
Note the single UDP query out, the response back, the QNAME/QTYPE. Decode it fully in Wireshark
in Lesson 19.

---

## §9 — GitHub Artifact (evidence 5-tuple)

1. **Script:** `scripts/dns_check.sh` (committed, `shellcheck`-clean).
2. **Config:** a minimal `dnsmasq`/`unbound` resolver config **or** `/etc/resolv.conf` +
   `resolvectl status` notes → `infra/configs/` (redacted).
3. **Drill:** drill 1 (DNS outage) executed; capture broken vs fixed `dig` output.
4. **NAVI ticket:** `NAVI-13` (Incident: "DNS resolution failing — RCA") To Do→In Progress→Done,
   linked to the closing commit.
5. **Incident report:** `docs/runbooks/incident-dns-outage.md` (symptom → diagnose via decision
   flow → fix → verify → RCA + prevention).

---

## §10 — Portfolio Artifact

- **Resume bullet:** "Built a DNS synthetic-check tool (`dns_check.sh`) that isolates resolver
  vs upstream failures; resolved a simulated DNS outage with a documented RCA."
- **Interview talking point:** "It's always DNS — here's how I isolate it in one command
  (`dig @resolver` vs `dig @public`), localize it with `+trace`, and the SERVFAIL-vs-NXDOMAIN
  distinction that tells me who to escalate to."
- **Serves:** NOC Technician + NetOps (Stages 1–2); the DNS-outage runbook is prime interview
  demo material.

---

## §11 — RHCSA Crossover Notes

RHCSA-relevant: configuring name resolution (`/etc/resolv.conf`, `nmcli con mod … ipv4.dns`),
`/etc/hosts` precedence via `/etc/nsswitch.conf`, hostname management (`hostnamectl`), and
verifying resolution with `getent hosts` / `dig`. RHCSA doesn't require running BIND, but
*configuring a host's resolver and `/etc/hosts`* is squarely in scope — this lesson covers it.

---

## §12 — Security Notes (Lens E — Attacker & Defender)

> Frameworks: [MITRE ATT&CK](https://attack.mitre.org/) · [GTFOBins](https://gtfobins.github.io/).
> DNS is security-relevant → fuller red/blue treatment.

**🔴 Attacker:**
- **DNS tunneling / exfiltration** — smuggling data inside DNS queries to bypass egress filters
  (`T1071.004` Application Layer Protocol: DNS; `T1048` Exfiltration Over Alternative Protocol).
  Telltale: abnormally long/high-entropy subdomains and high query volume to one domain.
- **Cache poisoning / spoofing** (`T1557` Adversary-in-the-Middle) — forging responses to
  redirect a name to an attacker IP.
- **DNS amplification DDoS** — abusing open recursive resolvers as reflectors.
- **Recon** — zone transfer attempts (`dig AXFR`) and subdomain enumeration.

**🔵 Defender:**
- **Restrict recursion** to internal clients; **disable zone transfers** to untrusted hosts
  (allow only secondaries).
- **Log + analyze DNS** (Lesson 25 syslog, Lesson 28 SIEM): alert on long/high-entropy QNAMEs
  (tunneling), NXDOMAIN spikes, and queries to known-bad domains.
- **DNSSEC** to authenticate responses; **DoT/DoH** to encrypt resolver traffic (and to know
  that encrypted DNS can *hide* exfil from inspection — a trade-off to monitor).
- **Verify hardening:** `dig +norecurse @<your-resolver> example.com` should refuse recursion
  for external clients; `dig AXFR @<your-ns> example.com` should be denied.

---

## Quiz (Interview-Style, Graded)

**Q1.** Explain recursive vs iterative resolution, and say which one your stub resolver requests
and which the recursive resolver performs.
> **Your answer:**

**Q2.** A user reports "the site won't load." `ping 1.1.1.1` works but `ping app.example.com`
fails. What's your first `dig` command and what would each possible result (NOERROR with an
answer / NXDOMAIN / SERVFAIL) tell you?
> **Your answer:**

**Q3.** After a migration, some users still hit the old server IP for an hour. What's the cause,
and how do you *prove* it with `dig`?
> **Your answer:**

**Q4.** Difference between SERVFAIL and NXDOMAIN — and for each, who do you escalate to?
> **Your answer:**

**Q5.** **Scenario:** `dig @<your-resolver> example.com` returns SERVFAIL but `dig @9.9.9.9
example.com` works. What does that tell you, and what are the two most likely root causes?
> **Your answer:**

**Q6.** Name the record types you'd check to diagnose: (a) a website not loading, (b) email
bouncing, (c) a reverse-lookup tool flagging your host.
> **Your answer:**

**Q7.** Your SIEM flags a host making thousands of queries to subdomains like
`a8f3...d9.evil.example`. What attack technique is this, and what's the defensive control?
> **Your answer:**

*(After you answer, request the "Professional Answer" comparison under each — graded before
Lesson 14.)*

---

## Reflection
*(Fill in after the quiz)* — What did you learn? · What confused you? · What would you do differently?

---

## Search Keywords For Further Understanding

**Core**
- `dns recursive vs iterative resolution`
- `dns record types a aaaa cname mx ns ptr soa txt srv`
- `dig +trace explained delegation`
- `dns ttl caching stale records`
- `servfail vs nxdomain difference`

**Tools**
- `dig command examples cheat sheet`
- `dig @server query specific resolver`
- `resolvectl systemd-resolved status flush-caches`
- `tcpdump dns port 53 capture`

**Going further (future lessons)**
- `dnssec how it works` · `doh dot encrypted dns` · `blackbox exporter dns probe` (L22) · `wireshark dns analysis` (L19)

**Red / Blue (Lens E):**
- 🔴 `dns tunneling exfiltration MITRE ATT&CK T1071.004`, `dns cache poisoning T1557`, `dns amplification ddos`, `dig axfr zone transfer attack`
- 🔵 `restrict dns recursion`, `disable zone transfer bind`, `detect dns tunneling high entropy subdomain`, `dnssec validation`

---

## Lesson Status
- [ ] §8 lab completed (dns_check.sh built + dig fluency)
- [ ] §4 troubleshooting drill done (drill 1 — DNS outage)
- [ ] Evidence 5-tuple committed (§9)
- [ ] Quiz answered + professional-answer comparisons (graded)
- [ ] Reflection + Search Keywords reviewed

When complete, run the Update Protocol (`CLAUDE_TEACHING_RULES.md`), then move to **Lesson 14 —
NAT / PAT**.

---

*Lesson 13 written by Navi · 2026-06-20 · full-depth exemplar. Sources to cite at authoring time
per the §2 WebSearch rule: RFC 1034/1035, BIND/`dig` docs (ISC), Cloudflare DNS learning center,
MITRE ATT&CK T1071.004 / T1557 / T1048.*
