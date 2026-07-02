# Lesson 09 — Networking II: DNS, DHCP, NAT, Routing & Firewalls

**Status:** ready for self-study · **Date written:** 2026-06-11
**Gate Rule:** Concept → Real-World Use → Alternatives → Hands-On → Verification → Quiz → Reflection → Search Keywords

> **How to use this lesson:** same as Lessons 03–08.

---

## Step 1 — Concept

### What it is

- **DNS (Domain Name System)** — translates human-readable names (`github.com`) into
  IP addresses, via a hierarchical, distributed lookup.
- **DHCP (Dynamic Host Configuration Protocol)** — automatically assigns IP
  addresses (and gateway/DNS settings) to devices joining a network.
- **NAT (Network Address Translation)** — rewrites IP addresses in packets, most
  commonly to let many private IPs share one public IP.
- **Firewalls (`ufw`/`iptables`)** — filter traffic by rules (allow/deny based on
  port, source IP, protocol).

### Why it exists

- **DNS**: IP addresses are hard to remember and can change; names are stable
  references humans (and configs) can use.
- **DHCP**: manually configuring IP/gateway/DNS on every device that joins a network
  doesn't scale and causes IP conflicts.
- **NAT**: IPv4 address exhaustion — there aren't enough public IPv4 addresses for
  every device, so private networks (RFC 1918: `10.0.0.0/8`, `172.16.0.0/12`,
  `192.168.0.0/16`) share a smaller number of public IPs.
- **Firewalls**: by default, open ports = open doors. Firewalls enforce "deny by
  default, allow only what's needed" — the principle of least privilege applied to
  network traffic.

### What problem it solves

- **"I typed `github.com` — how does my computer find its IP?"** — DNS resolution chain
- **"New laptop joins the office Wi-Fi and just works"** — DHCP
- **"100 internal servers share 1 public IP for outbound internet"** — NAT (specifically PAT/masquerade)
- **"Only allow SSH from my IP, block everything else"** — Firewall rules
- **"Website is down — is it DNS, the server, or a firewall blocking it?"** — Layered diagnosis using all of the above

### Three-Level Depth (Lens A)

- **Level 1 — Beginner:** `dig github.com` or `nslookup github.com` returns an IP.
  `ip route` shows your default gateway (often assigned via DHCP). `ufw allow 22/tcp`
  opens SSH; `ufw enable` turns the firewall on (deny-by-default).
- **Level 2 — SysAdmin:** Per [tecmint's dig/nslookup guide](https://www.tecmint.com/install-dig-and-nslookup-in-linux/)
  and [DNS Spy's troubleshooting guide](https://dnsspy.io/learning/dns-troubleshooting/dns-nslookup-guide):
  `dig` is preferred over `nslookup` for troubleshooting — `dig +short github.com` for
  just the IP, `dig github.com MX` for mail records, `dig +trace github.com` to walk
  the **full resolution chain** (root → TLD → authoritative). DNS resolution order:
  `/etc/hosts` (local overrides) → `/etc/resolv.conf` (configured resolvers, often
  set by DHCP) → recursive resolver → root/TLD/authoritative servers.
  For NAT, per the [NAT/ufw gist](https://gist.github.com/kimus/9315140) and
  [Ubuntu's router/firewall wiki](https://help.ubuntu.com/community/Router/Firewall):
  enabling routing requires `net.ipv4.ip_forward=1` (a kernel sysctl), and
  **MASQUERADE** is the NAT rule type for "rewrite source IP to this host's outbound
  IP" (used when the outbound IP isn't static — typical for a home/office gateway).
  For firewalls, per [WeHaveServers' ufw vs iptables comparison](https://wehaveservers.com/blog/linux-sysadmin/ufw-vs-iptables-simple-firewall-rules-that-actually-work/):
  `ufw` is a friendlier frontend over the same kernel `netfilter` engine as
  `iptables`/`nftables` — `ufw` for simple allow/deny rules, raw `iptables`/`nftables`
  for NAT/port-forwarding/complex rules. Many production systems use both.
- **Level 3 — Systems/Kernel (Lens D):** DNS resolution at the OS level goes through
  `getaddrinfo()` (a libc function) — this is why `/etc/nsswitch.conf`'s `hosts:`
  line matters (it controls the order: `files dns` = check `/etc/hosts` before DNS).
  Firewalls (`iptables`/`nftables`/`ufw`) configure **netfilter**, a series of
  hook points in the kernel's network stack where packets are inspected as they
  arrive (`PREROUTING`), get routed locally (`INPUT`/`FORWARD`), or leave
  (`OUTPUT`/`POSTROUTING`). NAT/MASQUERADE is implemented at the `POSTROUTING` hook —
  the kernel rewrites the source IP/port in the packet header and maintains a
  **connection tracking table** (`conntrack`) so return traffic gets translated back
  correctly. `ip_forward=1` is what allows the kernel to route packets *between*
  interfaces at all (rather than only to/from itself) — this single sysctl is the
  difference between "this Linux box is an endpoint" and "this Linux box is a router."

### Analogy (Lens B)

- **DNS** = a phone book / contacts app: you look up "Mom" (a name) and get a phone
  number (an IP) — and like a contacts app, there's a **local cache** (`/etc/hosts`,
  resolver caches) checked before calling "directory assistance" (DNS servers).
- **DHCP** = a hotel check-in desk: when you arrive (connect to the network), the desk
  (DHCP server) hands you a room number (IP address), tells you where the elevators
  are (gateway), and the front desk's phone number for questions (DNS servers) — all
  automatically, for a limited stay (lease time).
- **NAT** = a company's main switchboard number: externally, everyone sees one phone
  number (public IP); internally, the switchboard (NAT/conntrack table) routes each
  call to the correct extension (private IP:port) and remembers which extension is on
  which call so replies go back correctly.
- **Firewall** = a building's security desk with a visitor list: deny-by-default means
  "no one gets past the lobby unless they're on the list (allow rule)" — `ufw allow
  22/tcp` = "add SSH visitors to the approved list."

The NAT/switchboard analogy breaks down for **NAT traversal problems** (e.g., two
devices both behind NAT trying to connect directly to each other — "two switchboards
trying to call each other's internal extensions directly" doesn't quite map) — a
known advanced topic, not needed for junior roles.

---

## Step 2 — Real-World Use

### How SysAdmins use this daily

```bash
dig +short github.com              # quick: just the IP
dig github.com                     # full response: answer, authority, additional
dig +trace github.com              # full resolution chain (root -> TLD -> authoritative)
cat /etc/resolv.conf                # which DNS resolvers is this host using?
cat /etc/hosts                      # local name->IP overrides

sudo ufw status verbose             # current firewall rules
sudo ufw allow 22/tcp                # allow SSH
sudo ufw allow from 203.0.113.0/24 to any port 22   # allow SSH only from a specific subnet
sudo ufw enable

sysctl net.ipv4.ip_forward          # is this host allowed to route/forward packets?
```

**Real production scenarios:**
1. **"The site works by IP but not by domain name"** — DNS issue. `dig +short
   <domain>` to check resolution; compare to the known-good IP.
2. **"New VM can't reach the internet"** — check `ip route` (default gateway set?
   often via DHCP), `cat /etc/resolv.conf` (DNS configured?), `ping 8.8.8.8` (raw IP
   reachability — rules out DNS) vs `ping github.com` (DNS + reachability).
3. **"We need to expose only port 443, block everything else inbound"** —
   `ufw default deny incoming`, `ufw allow 443/tcp`, `ufw allow 22/tcp` (don't lock
   yourself out!), `ufw enable`.

### Common mistakes

- **`ufw enable` without first allowing SSH (if remote)** — **Lockout** — same risk class as Lesson 07's SSH hardening
  **Fix:** Always `ufw allow 22/tcp` (or your actual SSH port) **before** `ufw enable` on a remote host
- **Diagnosing "ping works but website doesn't" as a network issue** — `ping` is ICMP (L3); HTTP is TCP (L4) + application (L7) — a firewall can block port 443 while allowing ICMP
  **Fix:** Test the actual protocol/port: `curl -v https://...`, `nc -zv host 443`
- **Assuming DNS changes are instant** — DNS records are cached per their **TTL** — propagation can take minutes to hours
  **Fix:** Check TTL with `dig`; use low TTLs before planned changes
- **Confusing `ufw`'s "default deny" direction** — `ufw default deny incoming` ≠ blocking outbound — outbound is usually allowed by default
  **Fix:** Be explicit: `ufw default allow outgoing` / `deny incoming` as a pair, understand which direction each rule applies to

### When NOT to

- Don't run a local DHCP server on a lab VM unless you're specifically practicing
  DHCP — it can conflict with the host network's real DHCP server and cause outages
  for *other* devices on that network. Practice DHCP concepts via reading/`dig`/
  `/etc/resolv.conf` inspection unless in an isolated lab network.

### Interview Angle

**Question:** "A user says `https://internal-app.company.com` times out, but
`ping internal-app.company.com` works fine. What's your diagnosis path?"

A junior answer treats "ping works" as "network is fine" and starts looking at the
app code first. A senior answer recognizes the layer mismatch immediately: ICMP
(ping, Layer 3) and HTTPS (TCP/443, Layer 4+) are different protocols, and a
firewall can allow one while blocking the other. They'd run `dig +short
internal-app.company.com` to confirm DNS resolves to the expected IP, then
`nc -zv <ip> 443` or `curl -v https://internal-app.company.com` to test the actual
port. If `nc` hangs, the next step is `sudo ufw status verbose` (or `iptables -L -n`)
on the target host to check for a `deny` rule on 443 — possibly one added during a
recent hardening pass that forgot to allow the app's port before enabling.

---

## Step 3 — Alternatives

| Topic | Alternative | Note |
|---|---|---|
| `ufw` (this lesson) | raw `iptables`/`nftables` | `ufw` for simple host firewalls; `nftables` (the modern replacement for `iptables`) for complex/NAT/port-forwarding rules |
| Local DNS resolution | **systemd-resolved** | Many modern distros run a local caching resolver — `resolvectl status` shows what's actually configured, which can differ from a plain `/etc/resolv.conf` read |
| Self-hosted DNS | **Cloud DNS** (Route 53, etc.) | For NaviOps' future AWS work (Lesson 15+), DNS becomes a managed service — concepts here transfer directly |
| `dig`/`nslookup` | Online tools (Google's dig toolbox, digwebinterface) | Useful for checking resolution from *outside* your network, but local CLI tools are what you'll use day-to-day |

---

## Step 4 — Hands-On Task (build this yourself)

> ▶ **Do this on the lab**: start the environment first — `./infra/bootstrap.sh up` (once: `pull`), then
> `docker exec -it naviops-web bash`. **Node:** naviops-web. **Artifact:** firewalld/iptables here; build `scripts/firewall_audit.sh`.
> Reference solution (after you try): `docs/learning/reference-solutions/` (gitignored answer key).

**Goal:** Build `scripts/firewall_audit.sh` and a DNS-resolution diagnostic walkthrough.

### Lens C — Manual → Automated → Why

**Manual:**
```bash
sudo ufw status verbose
dig +short github.com
dig +trace github.com | tail -20
cat /etc/resolv.conf
```

**Automated (`scripts/firewall_audit.sh`) — build this yourself** (reuse the Lesson 03
header + `log()` pattern). Spec:

- **`check_firewall_status()`** — if `ufw` exists (`command -v`), `ufw status verbose`;
  else fall back to `iptables -L -n -v`. This portability check is a real-world habit
  (you won't always know which firewall a host runs).
- **`check_listening_ports()`** — `ss -tulnp` (the Lesson 08 command for "what's
  listening").
- **`check_ip_forwarding()`** — `sysctl net.ipv4.ip_forward`.
- **`check_dns_resolution()`** — take a domain as `$1` (default `github.com`),
  `dig +short "$domain"`; print a clear FAILED message if it returns nothing.
- **`main()`** — banner → the four checks → completion banner; end with `main "$@"`.

Combining "what's listening" with "what the firewall allows" is the deliverable — the
actual exposed attack surface. Write the wiring yourself.

**Why this matters:** combining "what's listening" (Lesson 08's `ss`) with "what does
the firewall allow" gives you the **actual exposed attack surface** of a host — a
real security-audit deliverable (foreshadows Lesson 23).

### What to build, step by step

1. On your lab VM, inspect current firewall state (`ufw status` — likely `inactive`
   by default).
2. **Carefully** (per the lockout warning): `ufw allow 22/tcp` first, then
   `ufw enable`, then verify you can still SSH in (separate session).
3. Run the `dig`/`dig +trace`/`/etc/resolv.conf` walkthrough; document what each
   step of `+trace` shows (root servers → `.com` TLD → GitHub's authoritative
   servers).
4. Write `scripts/firewall_audit.sh` per the structure above.
5. Commit on `lesson/09-networking-dns-dhcp-nat-firewalls`.

### Optional: failure drills

When you're ready for timed challenges, try [`troubleshooting-drills.md` §7 (Firewall blocking a service)](../../troubleshooting-drills.md#7-firewall-blocking-a-service) in your sandbox VM.

---

## Step 5 — Verification

```bash
bash -n scripts/firewall_audit.sh
./scripts/firewall_audit.sh

# Confirm firewall didn't lock you out
ssh youruser@vm-alma   # from a separate session, BEFORE relying on this for real

# Confirm DNS chain understanding
dig +trace github.com | grep -E '^(\.|\;)' | head -10
```

### Troubleshooting

- **Locked out after `ufw enable`** — SSH port not allowed before enabling
  **Fix:** Use VM console: `ufw allow 22/tcp`, `ufw reload`
- **`dig` not found** — Not installed (`dnsutils`/`bind-utils`)
  **Fix:** `apt install dnsutils` / `dnf install bind-utils`
- **`dig +short github.com` returns nothing** — `/etc/resolv.conf` empty/misconfigured, or no internet route
  **Fix:** Check `ip route`, `cat /etc/resolv.conf`, try `dig @8.8.8.8 github.com` to bypass local resolver
- **`ufw status` shows rules but traffic still blocked** — Rule order, or a `deny` rule earlier matches first
  **Fix:** `ufw status numbered`; rules are evaluated in order, first match wins

### Redaction check ✅

Replace any real public IPs in `dig`/`ufw` output with placeholders before
committing.

---

## Step 6 — Quiz (Interview-Style, Graded)

**Q1.** Walk through, step by step, what happens when you type `https://github.com`
into a browser, from DNS resolution through to the TCP connection — name the
protocols/tools involved at each step.

> **Your answer:**

**Q2.** **Scenario:** You run `ufw enable` on a remote server over SSH and
immediately lose your connection. What did you forget, and how do you recover (you
have console/VM access but no network access)?

> **Your answer:**

**Q3.** What is NAT/MASQUERADE, and why is `net.ipv4.ip_forward=1` a prerequisite for
a Linux box to act as a NAT gateway?

> **Your answer:**

**Q4.** A user says "the website is down." `ping <ip>` works. `curl https://site.com`
times out. What does this tell you, and what would you check next?

> **Your answer:**

**Q5.** What's the difference between `dig` and `dig +trace`? When would you use
`+trace`?

> **Your answer:**

**Q6.** Explain DHCP's role when a laptop joins a new network — what 3 pieces of
configuration does it typically receive, and where would a misconfigured DHCP server
cause problems?

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

DNS/DHCP failures and firewall/NAT misroutes are **bread-and-butter NOC tickets**. The NOC skill isn't just fixing them — it's **triage + escalation**: classify severity, attempt first-line diagnosis (`dig`, lease check, rule review), and know **when to escalate** to network engineering with a clear, documented hand-off.

## Lens E — Attacker & Defender (Red / Blue)

> Red/Blue framing (Gate Rule **Lens E**, D14). Build *both* mindsets: know how the
> tools in this lesson are abused, and how a defender detects and stops them.
> Frameworks: [GTFOBins](https://gtfobins.github.io/) · [MITRE ATT&CK](https://attack.mitre.org/) · [LOLBAS](https://lolbas-project.github.io/).

**🔴 Attacker (how it's abused — Step 2):** DNS and the network edge are prime exfil/C2 channels: **DNS tunneling** and spoofing, rogue DHCP for MITM, and firewall-evasion / boundary bridging. ATT&CK **T1071.004** (DNS C2), **T1572** (Protocol Tunneling), **T1599** (Network Boundary Bridging).

**🔵 Defender (detect & harden — Step 5):** Log & baseline DNS queries (alert on high-entropy / high-volume domains = tunneling), enable **DHCP snooping**, run a **default-deny firewall with egress filtering**, and review `ufw`/`iptables`/nftables rules for accidental allow-alls.

## Step 8 — Search Keywords For Further Understanding

**Core**
- `dns resolution process step by step explained`
- `ufw vs iptables vs nftables`
- `nat masquerade explained linux`
- `dhcp lease process explained`

**Tools**
- `dig +trace explained`
- `ufw before.rules nat port forwarding`
- `resolvectl status systemd-resolved`

**Going further (future lessons)**
- `aws route 53 dns basics`
- `aws security groups vs nacls vs linux firewall`
- `vpn site to site vs remote access basics`

---

**Red / Blue (Lens E — study attacker & defender in parallel):**
- 🔴 **Red (attacker):** `dns tunneling data exfiltration`, `MITRE ATT&CK T1071.004 dns c2`, `dns spoofing attack`, `rogue dhcp server attack`
- 🔵 **Blue (defender):** `dns query logging anomaly detection`, `dhcp snooping`, `egress filtering firewall`, `detect dns tunneling`

## Lesson Status

- [ ] Hands-on task completed (Step 4)
- [ ] Verification passed (Step 5)
- [ ] Quiz answered + professional-answer comparisons requested (Step 6)
- [ ] Reflection completed (Step 7)
- [ ] Search Keywords reviewed (Step 8)

When complete, run the Update Protocol, then move to **Lesson 10 — Linux Hardening &
Security Basics**.

---

*Lesson 09 written by Navi v28 · 2026-06-11 · WebSearch sources:
[tecmint dig/nslookup guide](https://www.tecmint.com/install-dig-and-nslookup-in-linux/),
[DNS Spy troubleshooting guide](https://dnsspy.io/learning/dns-troubleshooting/dns-nslookup-guide),
[WeHaveServers ufw vs iptables](https://wehaveservers.com/blog/linux-sysadmin/ufw-vs-iptables-simple-firewall-rules-that-actually-work/),
[Ubuntu Router/Firewall wiki](https://help.ubuntu.com/community/Router/Firewall)*
