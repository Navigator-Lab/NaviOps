# Lesson 15 — Firewalls & Packet Filtering

**Status:** ✅ ready for self-study (full depth) · **Date written:** 2026-06-20
**Schema:** 12-section (`docs/learning/CLAUDE_TEACHING_RULES.md`)
**Focus:** stateful vs stateless, security zones, nftables/firewalld/ufw, ACL logic, default-deny, logging.
**Primary artifact:** `scripts/firewall_audit.sh`.
**Difficulty:** security-heavy → fuller red/blue treatment in §12.

> **How to use this lesson:** firewalls are NOC scenario #8 (firewall blocking traffic) and a
> core security control. Read §1–§7, build an nftables policy + `firewall_audit.sh` in §8, run
> drill 8. Lab/RFC-1918 only.

---

## §1 — Concept (Scientific Theory)

### What it is
A **firewall** filters traffic by policy — permitting or denying packets based on attributes
(source/destination IP, port, protocol, and for stateful firewalls, **connection state**). It
enforces a boundary between **security zones** (e.g. untrusted Internet ↔ DMZ ↔ trusted LAN). The
guiding principle is **default-deny**: block everything, then explicitly allow only what's needed.

### Why it exists
Networks are reachable by default; that's dangerous. A firewall is the policy enforcement point
that limits what can talk to what — shrinking the attack surface, enforcing segmentation (Lesson
09), and giving you a logged, auditable control over traffic.

### Stateless vs stateful (the core distinction)
| | Stateless (ACL) | Stateful |
|---|---|---|
| Decides on | each packet in isolation (IP/port/proto) | the **connection** (tracks state) |
| Return traffic | must be explicitly allowed (both directions) | **automatically** allowed for established flows |
| Example | router ACL, basic packet filter | nftables `ct state`, firewalld, modern firewalls |
| Trade-off | simple, fast, but verbose + error-prone | smarter, the modern default |

A stateful firewall uses **conntrack** (Lesson 14): allow `new` inbound on permitted ports, allow
`established,related` automatically (so replies and related flows work), drop `invalid`.

### Default-deny + the rule-order rule
Rules are evaluated **top to bottom, first match wins**, ending in a **default-deny**. Order
matters: a broad allow above a specific deny defeats the deny. The canonical structure:
1. allow `established,related` (let ongoing flows continue)
2. allow specific `new` flows you intend (e.g. `tcp dport {22,80,443}`)
3. (optional) log + drop the rest → **default deny**.

### Three-Level Depth (Lens A)
- **Level 1 — Beginner:** a firewall is a bouncer with a guest list — only traffic on the list
  gets in; everything else is turned away.
- **Level 2 — NetOps/NOC:** you write and audit rulesets, reason about zones (Internet/DMZ/LAN),
  and troubleshoot "it was working, now it's blocked" by reading rule **hit counters** and
  capturing on **both sides** to see where the packet dies. You distinguish **drop** (silent — no
  reply, scanner gets nothing) from **reject** (sends ICMP/RST — faster failure for legit users).
  Stateful rules + `ct state` are the modern idiom (nftables/firewalld).
- **Level 3 — Wire/Kernel (Lens D):** on Linux, firewalling is **netfilter** hooks
  (`prerouting/input/forward/output/postrouting`) driven by **nftables** (the successor to
  iptables). `firewalld`/`ufw` are friendlier front-ends that compile to nftables. Rules with
  `ct state` consult the same **conntrack** table as NAT. Counters on each rule (`nft -a list
  ruleset` / `nft list ruleset` with `counter`) show exactly what's matching — the single best
  firewall-debugging tool.

### Two Teaching Approaches (Lens B) — stateful filtering & rule order

**Approach 1 (technical):** packets traverse netfilter chains; the firewall evaluates rules in
order until one matches (accept/drop/reject), defaulting to deny. A stateful policy first accepts
packets belonging to `established,related` connections (so replies need no explicit reverse rule),
then accepts the specific `new` connections it intends, then drops the rest. Conntrack provides
the state.

**Approach 2 (analogy):** a nightclub with a bouncer and a guest list.
- **Default-deny** = "if you're not on the list, you don't get in."
- **Stateful** = once you're inside (an established connection), you can come back from the
  smoking area without re-checking the list (the return path is remembered) — versus a
  **stateless** bouncer who re-checks you *every* time you move (you'd have to be on the list for
  both directions).
- **Rule order** = the bouncer reads the list top-down and acts on the *first* matching line — so
  a "VIPs welcome" line above a "ban list" line lets a banned VIP in. Put specific denies before
  broad allows.
- **Where it breaks down:** a bouncer judges people; a firewall matches packet *attributes*, not
  identity (that's the limit — it can't know intent, only IP/port/state, which is why L7/WAF and
  IDS exist).

### Visual (ASCII) — zones + a default-deny stateful policy

```
  INTERNET (untrusted)        FIREWALL (default-deny)        LAN (trusted)
        │                  ┌────────────────────────┐            │
        │── new :443 ─────►│ 1. ct established,related ACCEPT │──►│ web/DMZ
        │── new :22  ──X──►│ 2. ct new tcp dport 443  ACCEPT │    │
        │   (not allowed)  │ 3. ct new tcp dport 22 from mgmt│    │
        │                  │ 4. log + DROP everything else   │    │
        └──────────────────└────────────────────────┘────────────┘
   replies to allowed flows pass via rule 1 (no reverse rule needed)
```

---

## §2 — Linux Networking Commands

```bash
# nftables — a minimal stateful default-deny input policy
nft add table inet filter
nft 'add chain inet filter input { type filter hook input priority 0 ; policy drop ; }'
nft add rule inet filter input ct state established,related accept
nft add rule inet filter input iif lo accept
nft add rule inet filter input tcp dport {22,80,443} ct state new accept
nft add rule inet filter input counter log prefix "DROP " drop      # log the denies

nft list ruleset                 # full ruleset
nft -a list ruleset              # with handles + counters (which rule is hitting)
conntrack -L                     # stateful connection table

# firewalld (RHCSA) / ufw (Debian/Ubuntu) front-ends
firewall-cmd --list-all
firewall-cmd --add-service=https --permanent ; firewall-cmd --reload
ufw status verbose ; ufw allow 443/tcp
journalctl -k | grep "DROP"      # kernel firewall log lines
```

**Cisco/CCNA mapping:** ACLs (`access-list 101 permit tcp any host 10.0.0.20 eq 443`), applied to
interfaces, are the stateless equivalent; ASA/zone-based firewalls are stateful. CCNA tests ACL
logic, order, and implicit deny.

---

## §3 — Real-World Use Cases

**Production scenarios:**
1. **Edge policy:** default-deny inbound, allow only published services (443/DMZ); allow LAN
   outbound (or restrict it — egress filtering, §12).
2. **Segmentation enforcement:** firewall between VLANs/zones (servers↔staff↔guest) so a
   compromised guest can't reach servers (Lessons 09/04).
3. **Post-change outage:** a new rule (or wrong order) blocks a working service — read counters,
   capture both sides, fix order/rule.
4. **Host firewalls:** firewalld/ufw on individual servers as defense-in-depth.

**How NOC engineers use it:** "service worked, now refused/timing out, often after a change" →
read which rule's counter is incrementing, capture both sides to confirm where the packet dies,
escalate or fix.

**When NOT to:** don't open broad any-any allows "to make it work"; don't rely on the firewall
alone (combine with IDS/WAF, Lesson 28).

**Exam framing (Net+/CCNA):** stateful vs stateless, implicit deny, rule order, zones/DMZ, and
ACL construction are guaranteed.

---

## §4 — Troubleshooting Section

| Symptom | Likely cause | Diagnose | Fix |
|---|---|---|---|
| Service worked, now blocked | new rule / wrong order / default-deny | `nft -a list ruleset` counters | fix/reorder the rule |
| Connection times out (no reply) | firewall **drop** (silent) | `tcpdump` both sides (arrives? dropped?) | add an allow |
| Connection refused immediately | **reject** or no service | distinguish RST vs timeout | allow / start service |
| Replies fail though request allowed | stateless missing reverse rule | check `ct state established` rule | add stateful established rule |
| Port-forward still blocked | DNAT done but not allowed | NAT (L14) + firewall both needed | allow the forwarded port |

**Redaction check:** lab IPs in any committed ruleset/log.

---

## §5 — Common Mistakes

| Mistake | Impact | Fix |
|---|---|---|
| No default-deny | everything is allowed by omission | end with `policy drop` |
| Broad allow above a specific deny | deny never matches | order specific rules first |
| Forgetting `established,related` | replies dropped, "half-working" | add the stateful accept first |
| Locking yourself out (SSH) on a remote box | no console access | allow mgmt first; use a timed rollback |
| Reject vs drop confusion | scanners get info (reject) | drop for untrusted, reject for internal UX |
| No logging on denies | blind during incidents | log + drop |

> ⚠️ **Danger zone (`navi.project.md`):** editing firewall rules on a live remote host can cut
> you off. Allow your management access first, and keep a console/rollback path.

---

## §6 — NOC Perspective

> NOC Technician focus (Stage 1, `ROADMAP.md`).

Firewall-blocking (NOC scenario #8) is the classic "it worked yesterday" ticket — almost always
**correlated with a change** (`noc/ticketing.md`), so "what changed in the firewall?" is the first
question. The NOC's strongest evidence is **rule hit counters** (which rule is dropping) plus a
**both-sides capture** (`tcpdump` on sender and receiver: does it leave A? arrive at B?) — that
pinpoints the firewall as the culprit vs the app/network. Severity scales with scope (one service
vs a whole zone).

---

## §7 — Incident-Response Perspective

Firewalls are *both* a thing that *causes* incidents (misconfig) and a *tool* for IR (block an
attacker):
- **As cause:** detect (service unreachable post-change) → diagnose (counters + both-sides
  capture) → fix order/rule → verify → document. Maps to **drill 8 (firewall blocking traffic)**.
- **As response (containment):** during an attack (Lesson 28), the firewall is how you **contain**
  — block the attacker's source IP (`nft add rule ... ip saddr <attacker> drop`), confirm the
  drop counter rises, document the block in the IR report.

---

## §8 — Practical Lab (build this yourself)

**Goal:** build a default-deny stateful nftables policy, audit it with `scripts/firewall_audit.sh`,
and run drill 8.

### Lens C — Manual → Automated → Why
- **Manual:** write the ruleset, read counters, test allowed + denied flows.
- **Automated:** `firewall_audit.sh` — summarize the ruleset, flag risky patterns (no
  default-deny, any-any allows, missing `established` rule), and report top hit counters.
- **Why:** firewall rulesets rot (stale allows pile up); an audit script that flags overly-broad
  rules and confirms default-deny is exactly what security/NetOps teams run regularly. It's also
  great portfolio evidence.

### Steps
1. Build the §2 default-deny stateful `input` policy (in a VM/namespace — **not** your only access
   path). Save it as a loadable ruleset under `infra/configs/`.
2. Test: allowed port (`nc -vz` succeeds), denied port (times out — drop), confirm
   `established,related` lets replies through.
3. Build `scripts/firewall_audit.sh`: parse `nft list ruleset`, flag (a) no `policy drop`, (b)
   `accept` with no match (any-any), (c) missing `ct state established` rule; print rule counters.
4. **Drill 8:** add a rule blocking a known-good service (`nft add rule ... tcp dport 8080 drop`)
   → observe the outage → diagnose via counters + both-sides `tcpdump` → remove the rule.

### Lens D — counters + capture
`nft -a list ruleset` shows per-rule counters; pair with `tcpdump` on both endpoints to *prove*
the firewall (not the network/app) is dropping — the definitive firewall diagnosis.

---

## §9 — GitHub Artifact (evidence 5-tuple)

1. **Script:** `scripts/firewall_audit.sh` (ruleset auditor + counter report).
2. **Config:** a loadable default-deny stateful ruleset in `infra/configs/`.
3. **Drill:** drill 8 (firewall blocking traffic) executed.
4. **NAVI ticket:** `NAVI-15` (Incident: "service blocked after firewall change — RCA").
5. **Incident report:** `docs/runbooks/incident-firewall-block.md` (symptom→counters+capture→fix→verify).

---

## §10 — Portfolio Artifact

- **Resume bullet:** "Implemented a default-deny stateful firewall (nftables) with zone
  segmentation and logging; built a ruleset auditor flagging overly-broad rules; resolved a
  firewall-block incident via hit-counters and dual-side capture."
- **Interview talking point:** stateful vs stateless, default-deny + rule order, and how you prove
  a firewall is the culprit (counters + both-sides capture).
- **Serves:** NOC, Network Operations, and the SOC/Security-Analyst track (Stages 1–2, 5).

---

## §11 — RHCSA Crossover Notes

Strong RHCSA overlap: **firewalld** (zones, services, ports, masquerade, rich rules) is a core
RHCSA objective. The default-deny + allow-services model and `firewall-cmd --list-all` map
directly. Knowing firewalld compiles to nftables ties the two views together.

---

## §12 — Security Notes (Lens E — Attacker & Defender) — full treatment

> Frameworks: [MITRE ATT&CK](https://attack.mitre.org/). Security-heavy lesson.

**🔴 Attacker:** **firewall evasion/recon** — scanning to map allowed ports (`T1046`), exploiting
**overly-permissive rules** (any-any, stale allows) to reach internal services, and using
**allowed outbound** for C2/exfil when egress is unfiltered (`T1071`/`T1048`). Misconfigured
port-forwards (Lesson 14) expose internal services (`T1133`).

**🔵 Defender:** **default-deny both directions**, least-privilege allows, **egress filtering**
(don't let everything out — a top under-used control), **log denies** and feed them to the SIEM
(Lesson 28), **segment** with zone firewalls (Lesson 09), and **audit rulesets** regularly
(`firewall_audit.sh`) to kill stale/broad rules. **Drop > reject** for untrusted zones (less recon
info). Verify with `nmap` from outside (lab-only) that only intended ports are open.

---

## Quiz (Interview-Style, Graded)

**Q1.** Stateful vs stateless firewall — what does each track, and why does stateless need rules
for return traffic?
> **Your answer:**

**Q2.** Explain default-deny and why rule order matters. Give an example where bad order defeats a deny.
> **Your answer:**

**Q3.** Difference between **drop** and **reject**, and when you'd choose each.
> **Your answer:**

**Q4.** **Scenario:** A web service that worked yesterday now times out from clients. You suspect
the firewall. What two pieces of evidence prove it's the firewall, and how do you gather them?
> **Your answer:**

**Q5.** Why must a stateful policy accept `established,related` before the specific allows?
> **Your answer:**

**Q6.** What is egress filtering and why is it an important (and often missing) control?
> **Your answer:**

*(After you answer, request the "Professional Answer" comparison under each — graded before Lesson 16.)*

---

## Reflection
*(Fill in after the quiz)* — What did you learn? · What confused you? · What would you do differently?

---

## Search Keywords For Further Understanding

**Core**
- `stateful vs stateless firewall`
- `default deny firewall policy`
- `firewall rule order first match`
- `drop vs reject firewall`
- `security zones dmz`

**Tools**
- `nftables tutorial stateful`
- `firewalld zones services rich rules`
- `nft list ruleset counters`

**Going further (future lessons)**
- `ids ips suricata` (L28) · `egress filtering c2` · `waf layer 7 firewall`

**Red / Blue (Lens E):**
- 🔴 `firewall evasion recon T1046`, `overly permissive rule exploit`, `c2 over allowed port T1071`
- 🔵 `egress filtering best practices`, `firewall ruleset audit`, `drop vs reject security`

---

## Lesson Status
- [ ] §8 lab completed (default-deny stateful policy + firewall_audit.sh)
- [ ] §4 drill done (drill 8 — firewall blocking traffic)
- [ ] Evidence committed (§9)
- [ ] Quiz answered + professional-answer comparisons (graded)
- [ ] Reflection + Search Keywords reviewed

When complete, run the Update Protocol, then move to **Lesson 16 — Network Services**.

---

*Lesson 15 written by Navi · 2026-06-20 · full-depth. Sources to cite when worked: nftables wiki,
firewalld docs, CompTIA Network+ N10-009 (security), MITRE ATT&CK T1046/T1071/T1133.*
