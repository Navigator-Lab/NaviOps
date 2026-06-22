# Lesson 27 — Network Documentation

**Status:** ✅ ready for self-study (full depth) · **Date written:** 2026-06-20
**Schema:** 12-section (`docs/learning/CLAUDE_TEACHING_RULES.md`)
**Focus:** topology diagrams, IPAM, runbooks, change records, as-built docs, diagram-as-code.
**Primary artifact:** `docs/networking/ipam.md` + `docs/diagrams/`.

> **How to use this lesson:** documentation is a graded NOC/network competency (Network+ weights
> it). Read §1–§7, build the IPAM + a topology diagram in §8. "Documentation First" is a NaviOps
> design principle — this lesson makes it concrete for networking.

---

## §1 — Concept (Scientific Theory)

### What it is
**Network documentation** is the maintained record of *what the network is and why*: **topology
diagrams** (how devices connect), **IPAM** (IP Address Management — what addresses/subnets/VLANs
are assigned), **runbooks** (how to do/fix things, Lesson 26), **change records** (what changed,
when, by whom, with rollback), **as-built docs** (the real, current state vs the original design),
and **standard operating procedures**. It's the difference between a network only one person
understands and one a team can operate.

### Why it exists
Undocumented networks are operationally fragile: troubleshooting is slow (no map), onboarding is
painful, changes are risky (no record of why things are the way they are), and the "bus factor" is
1. Documentation reduces MTTR (you know the topology + address plan instantly), de-risks change
(records + rollback), and is itself a deliverable that distinguishes professional operations.

### The core documents
| Doc | What it answers | Form |
|---|---|---|
| **Topology diagram** | how is it wired/segmented? | ASCII / Mermaid / diagram-as-code / Visio |
| **IPAM** | what subnets/VLANs/IPs are assigned? | table / IPAM tool (NetBox) |
| **Runbook** | how do I do/fix X? | Markdown (Lesson 26) |
| **Change record** | what changed, when, why, rollback? | ticket (Lesson 23 ticketing) |
| **As-built** | what is the *actual current* state? | updated diagrams + configs |
| **SOP** | the standard way to do recurring tasks | Markdown |

### Diagram-as-code (the modern, version-controlled way)
Instead of binary Visio files, define diagrams in **text** (Mermaid, Graphviz/DOT, ASCII) so they
live in Git, diff in PRs, and never drift into a forgotten drive. This platform uses ASCII +
Mermaid in `docs/diagrams/` — version-controlled, reviewable, always current.

### Three-Level Depth (Lens A)
- **Level 1 — Beginner:** documentation is the map and address book of the network — drawings of
  how things connect and a list of what IP/VLAN each thing uses — kept up to date.
- **Level 2 — NetOps/NOC:** you maintain an **IPAM** (subnet/VLAN/IP assignments with owners), keep
  **topology diagrams** current (as-built, not just as-designed), record **changes** with rollback,
  and write **runbooks/SOPs**. Good docs cut MTTR (you localize an alerting IP instantly) and make
  changes safe (the record + rollback). Diagram-as-code keeps it in Git, reviewed and current.
- **Level 3 — Systems (Lens D):** documentation can be **generated** from the network itself —
  LLDP/CDP neighbor data (Lesson 08) builds topology; SNMP (Lesson 24) inventories devices; config
  backups are the as-built source of truth. The discipline is keeping generated + authored docs in
  sync and version-controlled (NetBox as a source of truth in mature shops).

### Two Teaching Approaches (Lens B) — why docs reduce MTTR, and diagram-as-code

**Approach 1 (technical):** documentation is an index into the network's state. During an incident,
the IPAM maps an alerting IP → device → owner → segment in seconds; the topology shows the blast
radius and dependencies; the change record reveals "what changed before this broke." This directly
shortens the diagnose phase (Lesson 26) — less time spent rediscovering the network. Diagram-as-code
makes the index trustworthy by keeping it version-controlled and reviewed alongside changes.

**Approach 2 (analogy):** network docs are the **building's blueprints + directory + maintenance
log**.
- The **blueprint** (topology) shows how everything connects — when a pipe bursts (outage), you
  see which rooms are affected (blast radius) and where the shutoff is (containment point).
- The **directory** (IPAM) tells you who's in each room (which device has which IP/VLAN/owner).
- The **maintenance log** (change records) shows "the plumbing was modified last Tuesday" — often
  the cause of today's leak.
- **Diagram-as-code** = keeping the blueprints in a shared, versioned system instead of a dusty
  tube in a closet that no longer matches the building (the dreaded *as-designed ≠ as-built* gap).
- **Where it breaks down:** buildings change slowly; networks change constantly, so docs must be
  *updated as part of every change* (the as-built discipline) — the part static blueprints
  understate, and exactly why diagram-as-code-in-Git matters.

### Visual (ASCII) — a documented topology (as-built) + IPAM linkage

```
   ┌────────── CORE (10.0.0.0/16, VLANs) ──────────┐
   │  [router R1] 10.0.255.1  ── trunk ──  [sw-dist]│
   │       │ SVI v10 .10.1   SVI v20 .20.1          │
   │  v10 servers 10.0.10.0/24   v20 staff 10.0.20.0/24  v30 guest 10.0.30.0/24
   └───────────────────────────────────────────────┘
   IPAM (docs/networking/ipam.md):
     10.0.10.0/24  VLAN10  Servers   gw .10.1   owner: infra
     10.0.20.0/24  VLAN20  Staff     gw .20.1   owner: it
     10.0.30.0/24  VLAN30  Guest     gw .30.1   owner: it (isolated)
   alert from 10.0.20.57 → IPAM → "Staff VLAN, owner IT" in one lookup → faster triage
```

---

## §2 — Linux Networking Commands (generate docs from the network)

```bash
# Topology / neighbors (Lesson 08): discover how things connect
lldpctl                          # LLDP neighbors (what's plugged into what)
ip -br link ; ip -br addr ; ip route ; bridge vlan show   # the as-built host/segment state
# Inventory (Lesson 24): SNMP for device facts
snmpget -v2c -c <COMMUNITY_STRING> 10.0.0.1 SNMPv2-MIB::sysName.0
# Diagram-as-code (render text → image, optional)
# mermaid in Markdown (renders on GitHub); graphviz: dot -Tpng topo.dot -o topo.png
# Config backup = as-built source of truth (devices), version-controlled
```

**Cisco/CCNA mapping:** `show cdp neighbors`/`show lldp neighbors` (build topology), `show
running-config` (as-built), `show ip interface brief` (addressing → IPAM). CCNA explicitly covers
documentation, diagrams, IPAM, and the importance of keeping them current.

---

## §3 — Real-World Use Cases

**Production scenarios:**
1. **Faster incident triage:** an alert from an IP → IPAM lookup → device/owner/segment instantly
   (lower MTTR, Lesson 26).
2. **Safe changes:** a change record with rollback + an as-built diagram prevents "we didn't know
   that link existed" mistakes.
3. **Onboarding/handover:** new engineers (or the next shift, `noc/shift-handover.md`) get up to
   speed from the docs instead of tribal knowledge.
4. **Audit/compliance:** documented topology, IPAM, and change history satisfy audits.

**How NOC engineers use it:** the IPAM + topology are reference material consulted on nearly every
ticket; documentation discipline (recording changes, updating as-builts) is a graded professional
behavior, not optional.

**When NOT to:** don't over-document trivia that goes stale (document what reduces MTTR/risk); don't
keep diagrams in un-versioned binary files that drift.

**Exam framing (Net+):** Domain 3.0 Network Operations explicitly covers documentation —
diagrams, IPAM, SOPs, change management, and as-built vs as-designed.

---

## §4 — Troubleshooting Section (doc-related failure modes)

| Symptom | Cause | Fix |
|---|---|---|
| Slow triage, "where is this IP?" | no/stale IPAM | maintain IPAM as part of change |
| "We didn't know that link existed" | as-built ≠ as-designed | update diagrams every change |
| Change caused an outage, no rollback | no change record | record changes + rollback steps |
| Onboarding takes weeks | tribal knowledge | runbooks/SOPs |
| Diagrams out of date | binary/un-versioned | diagram-as-code in Git |

**Redaction check:** the **biggest** one here — IPAM/diagrams are full of addressing; use
RFC-1918/5737 + placeholders, never real public IPs/hostnames/circuit IDs.

---

## §5 — Common Mistakes

| Mistake | Impact | Fix |
|---|---|---|
| No documentation / tribal knowledge | bus factor 1, slow MTTR | document the essentials |
| As-designed never updated to as-built | dangerous changes | update on every change |
| Binary diagrams in a forgotten drive | drift, can't review | diagram-as-code in Git |
| Over-documenting trivia | stale noise | document what reduces MTTR/risk |
| No change records | repeat mistakes, no rollback | record every change |
| Committing real addressing | leak | redact (RFC ranges + placeholders) |

---

## §6 — NOC Perspective

> NOC Technician focus (Stage 1, `ROADMAP.md`).

Documentation is a *measured* NOC competency. The IPAM + topology are what you consult on every
ticket to set scope and find owners; the change log answers "what changed before this broke" (the
fastest RCA shortcut, Lesson 26); the runbooks/SOPs are how the NOC operates consistently across
shifts. "Documentation First" (a NaviOps principle) means writing/updating the runbook *as part of*
handling the incident, not after — which is exactly what makes a NOC's knowledge compound instead
of evaporate.

---

## §7 — Incident-Response Perspective

Documentation is both an **input** and an **output** of IR (Lesson 26):
- **Input:** IPAM + topology + change records accelerate triage and RCA (scope, owners, "what
  changed").
- **Output:** every incident produces/updates a **runbook** and may update the **as-built** docs
  (a discovered undocumented link) and the **change record**. The post-incident review's prevention
  item is often "document this." Good IR continuously improves the docs, and good docs continuously
  improve IR — a virtuous loop.

---

## §8 — Practical Lab (build this yourself)

**Goal:** produce `docs/networking/ipam.md` (the address/VLAN plan) and `docs/diagrams/` (an
as-built topology, diagram-as-code), plus a change-record template.

### Lens C — Manual → Automated → Why
- **Manual:** hand-draw the topology + tabulate IPAM.
- **Automated:** generate the as-built from the network — `lldpctl`/`ip`/`bridge`/SNMP into a
  topology + IPAM, and keep diagrams as Mermaid/ASCII in Git.
- **Why:** generated + version-controlled docs don't drift; production teams treat docs-as-code
  (and tools like NetBox) as the source of truth so the map always matches reality.

### Steps
1. Document your lab (from Lessons 07/09/17): write `docs/networking/ipam.md` — a table of every
   subnet/VLAN with gateway, purpose, and owner (RFC-1918, redacted).
2. Draw the as-built topology in `docs/diagrams/lab-topology.md` (ASCII + a Mermaid `graph`),
   reflecting the *actual* wiring you built (router/VLANs/services).
3. Create a **change-record template** (what/when/who/why/rollback/verification) and log one real
   change you made (e.g. "added VLAN 30") with rollback steps.
4. **Drill:** simulate an alert from a documented IP and show the IPAM lookup → device/owner/segment
   in seconds; then make a change *without* a record and feel the difference (then record it).

### Lens D — generate topology from LLDP/SNMP
Show how `lldpctl` (Lesson 08 neighbors) + SNMP `sysName` (Lesson 24) could auto-build a topology —
the principle behind NetBox/auto-discovery as the as-built source of truth.

---

## §9 — GitHub Artifact (evidence 5-tuple)

1. **Script:** an as-built/IPAM generator (`lldpctl`/`ip`/`bridge` → a table/diagram).
2. **Config/doc:** `docs/networking/ipam.md` + `docs/diagrams/lab-topology.md` (diagram-as-code).
3. **Drill:** a change recorded with rollback; an IPAM-accelerated triage demonstrated.
4. **NAVI ticket:** `NAVI-27` (Change: "establish IPAM + as-built topology docs").
5. **Incident report:** *(optional)* — a runbook showing docs accelerating triage.

---

## §10 — Portfolio Artifact

- **Resume bullet:** "Established IPAM and as-built network topology documentation (diagram-as-code,
  version-controlled) plus a change-record standard; reduced incident triage time via IP→owner
  lookups."
- **Interview talking point:** why documentation reduces MTTR and de-risks change, and the
  as-designed-vs-as-built gap + diagram-as-code — a maturity signal junior candidates rarely show.
- **Serves:** NOC + Network Operations + Linux Net Admin (Stages 1–3); supports every other lesson.

---

## §11 — RHCSA Crossover Notes

Mostly **N/A for RHCSA** as a topic, but documentation discipline (and version-controlling configs
with Git — the sibling NaviOps covers this) is a professional admin skill. Keeping `/etc/hosts`,
network configs, and runbooks in version control overlaps with RHEL operational hygiene.

---

## §12 — Security Notes (Lens E — Attacker & Defender)

> Frameworks: [MITRE ATT&CK](https://attack.mitre.org/).

**🔴 Attacker:** network documentation is a **prime recon target** — a leaked diagram/IPAM hands an
attacker the whole map (topology, addressing, key assets) for free (`T1590` Gather Victim Network
Information; `T1602` Data from Configuration Repository). Public repos leaking real IPs/diagrams is a
genuine breach vector (exactly why this platform's redaction rule exists).

**🔵 Defender:** **classify and protect** documentation (it's sensitive), **redact** anything public
(this repo's rule), restrict access to the real IPAM/diagrams, and **don't leak** addressing/topology
in tickets, screenshots, or commits. Documentation also *aids defense* — an accurate asset inventory
is foundational to detecting the *unexpected* (a device not in IPAM = investigate). Verify your
public artifacts contain no real addressing (grep before commit).

---

## Quiz (Interview-Style, Graded)

**Q1.** Name four core network documents and what question each answers.
> **Your answer:**

**Q2.** What's the difference between "as-designed" and "as-built," and why does the gap matter?
> **Your answer:**

**Q3.** How does good documentation reduce MTTR during an incident? Give a concrete example.
> **Your answer:**

**Q4.** **Scenario:** A change caused an outage and there's no record of what was changed or how to
undo it. What documentation practices would have prevented this?
> **Your answer:**

**Q5.** What is diagram-as-code and why prefer it over binary diagram files?
> **Your answer:**

**Q6.** Why is network documentation sensitive from a security standpoint, and how do you handle it
in a public repo?
> **Your answer:**

*(After you answer, request the "Professional Answer" comparison under each — graded before Lesson 28.)*

---

## Reflection
*(Fill in after the quiz)* — What did you learn? · What confused you? · What would you do differently?

---

## Search Keywords For Further Understanding

**Core**
- `network documentation best practices`
- `ipam ip address management`
- `as-built vs as-designed network`
- `diagram as code mermaid graphviz`
- `network change management records`

**Tools**
- `netbox source of truth`
- `mermaid network diagram`
- `lldp cdp topology discovery`

**Going further (future lessons)**
- `network security fundamentals` (L28) · `runbook automation` · `config backup version control`

**Red / Blue (Lens E):**
- 🔴 `network diagram recon T1590`, `config repository data T1602`, `leaked topology breach`
- 🔵 `protect network documentation`, `asset inventory detection`, `redact public repo addressing`

---

## Lesson Status
- [ ] §8 lab completed (IPAM + as-built diagram + change record)
- [ ] §4 drill done (IPAM-accelerated triage; change with/without record)
- [ ] Evidence committed (§9)
- [ ] Quiz answered + professional-answer comparisons (graded)
- [ ] Reflection + Search Keywords reviewed

When complete, run the Update Protocol, then move to **Lesson 28 — Network Security Fundamentals**.

---

*Lesson 27 written by Navi · 2026-06-20 · full-depth. Sources to cite when worked: CompTIA Network+
N10-009 (Domain 3.0), NetBox docs, Mermaid/Graphviz docs, MITRE ATT&CK T1590/T1602.*
