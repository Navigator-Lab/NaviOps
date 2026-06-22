# Lesson 24 — SNMP

**Status:** ✅ ready for self-study (full depth) · **Date written:** 2026-06-20
**Schema:** 12-section (`docs/learning/CLAUDE_TEACHING_RULES.md`)
**Focus:** MIBs/OIDs, v2c vs v3, snmpwalk/snmpget, polling vs traps, interface counters.
**Primary artifact:** `scripts/snmp_poll.sh`.

> **How to use this lesson:** SNMP is *the* protocol behind almost all network-device monitoring
> (it's how Zabbix/SolarWinds/PRTG read switches and routers). Read §1–§7, poll a local snmpd in
> §8, build `snmp_poll.sh`. Lab only; never commit real community strings.

---

## §1 — Concept (Scientific Theory)

### What it is
**SNMP** (Simple Network Management Protocol) is the standard protocol for **monitoring and
managing network devices** (switches, routers, firewalls, printers, servers). A **manager** (NMS
— Zabbix/SolarWinds/Prometheus snmp_exporter) **polls** an **agent** running on the device for
metric values, identified by numeric **OIDs** (Object Identifiers) organized in a **MIB**
(Management Information Base) tree. Devices can also **push** unsolicited **traps** for events.
Runs over **UDP** — polling on **161**, traps on **162**.

### Why it exists
Network devices need a standard, vendor-neutral way to expose "how am I doing?" (interface
counters, CPU, errors, status) so one monitoring system can read thousands of heterogeneous
devices. SNMP is that lingua franca — it's why a single dashboard can show a Cisco switch, a
Juniper router, and a Linux server side by side.

### MIBs and OIDs
- An **OID** is a dotted-number address in a global tree, e.g. `1.3.6.1.2.1.2.2.1.10.2` =
  `IF-MIB::ifInOctets.2` = inbound bytes on interface index 2.
- A **MIB** is a human-readable map of OIDs (so you write `ifInOctets` instead of the numbers).
- The common, must-know objects live in **IF-MIB** (interfaces): `ifDescr`, `ifOperStatus`
  (up/down), `ifInOctets`/`ifOutOctets` (traffic counters), `ifInErrors`/`ifOutDiscards`.

### Versions (security matters here)
| Version | Auth | Encryption | Use |
|---|---|---|---|
| **v1** | community string (plaintext) | none | legacy, avoid |
| **v2c** | community string (plaintext) | none | very common, but the string = a password sent in clear |
| **v3** | username + auth (SHA) | **privacy (AES)** | the secure choice — auth + encryption |

The **community string** (v1/v2c) is a shared secret that acts as a password; `public` (read) and
`private` (write) are the notorious defaults — leaving them is a classic vulnerability (§12).

### Polling vs traps
- **Polling (GET/GETNEXT/WALK):** the manager asks on an interval ("what's ifInOctets now?") —
  predictable, the basis of utilization graphs (you compute rate from successive counter reads).
- **Traps (and informs):** the device pushes an event ("link down on port 5!") immediately —
  faster for state changes than waiting for the next poll. Informs are acknowledged traps.

### Three-Level Depth (Lens A)
- **Level 1 — Beginner:** SNMP is how a monitoring system reads numbers off network gear — like
  every device having a standard set of gauges the monitor can check.
- **Level 2 — NetOps/NOC:** you `snmpwalk`/`snmpget` to read interface counters and status, compute
  **utilization** as the *rate* of `ifInOctets`/`ifOutOctets` (counter delta ÷ time × 8 ÷ link
  speed), watch `ifOperStatus` for up/down, and configure **traps** for instant link-down alerts.
  You use **v3** (or at least non-default communities) and lock SNMP to the management network. The
  snmp_exporter (Lesson 22) and Zabbix (Lesson 23) are SNMP managers under the hood.
- **Level 3 — Wire/Kernel (Lens D):** SNMP messages are UDP datagrams carrying the version,
  community/security params, and a PDU (GET/GETNEXT/GETBULK/SET/TRAP) with OID/value bindings,
  encoded in **ASN.1 BER**. Counters like `ifInOctets` are 32-bit (Counter32) and **wrap** on fast
  links — high-speed interfaces use 64-bit counters (`ifHCInOctets`, IF-MIB high-capacity), a real
  gotcha. On Linux, `net-snmp` (`snmpd`) is the agent; `snmpwalk`/`snmpget`/`snmptrap` are the
  tools.

### Two Teaching Approaches (Lens B) — OIDs/MIBs & polling-for-utilization

**Approach 1 (technical):** a manager sends a GET (or WALK = repeated GETNEXT) for an OID; the
agent returns the value. To graph interface utilization you poll a **counter** (`ifInOctets`)
twice, take the delta over the interval, convert bytes→bits×8, and divide by `ifSpeed` → percent.
`ifOperStatus` gives up/down; errors/discards give health. Traps invert this for instant
event notification.

**Approach 2 (analogy):** SNMP is **reading utility meters on a building**.
- Every device is a building with a standard set of **meters** (OIDs) — electricity, water, gas
  (interface in/out, errors, status). The **MIB** is the labeled meter board so you know which dial
  is which.
- **Polling** = the meter reader visits on a schedule and records each dial; **utilization** is the
  *difference* between two readings over time (your electric bill is `(this reading − last
  reading)`), not the raw number — exactly why you `rate()` a counter.
- **Traps** = a smoke alarm that calls the fire department *immediately* instead of waiting for the
  next meter reading.
- **The community string** = the key to the meter room; leaving it as the factory default
  (`public`) means anyone can read (or with `private`, *change*) your meters.
- **Where it breaks down:** meters don't "wrap around to zero" the way a 32-bit Counter32 does on a
  fast link — the counter-wrap gotcha (use 64-bit `ifHC*`) has no clean meter analogy.

### Visual (ASCII) — manager polling + device trap

```
   MANAGER (NMS: Zabbix/snmp_exporter)        DEVICE (snmpd agent, UDP 161)
        │── GET ifInOctets.2 ──────────────────►│
        │◄──── value: 18,442,113,002 ───────────│   (read again next interval →
        │── GET ifOperStatus.5 ─────────────────►│    delta/time = utilization)
        │◄──── value: 2 (down) ──────────────────│
        │                                        │
        │◄════ TRAP linkDown port 5 (UDP 162) ═══│   device PUSHES the event instantly
   utilization graph + up/down state + instant link-down alert
```

---

## §2 — Linux Networking Commands

```bash
# Install/run an agent locally to practice (net-snmp): snmpd
snmpwalk -v2c -c <COMMUNITY_STRING> 10.0.0.1 system          # walk the system subtree
snmpget  -v2c -c <COMMUNITY_STRING> 10.0.0.1 IF-MIB::ifNumber.0
snmpwalk -v2c -c <COMMUNITY_STRING> 10.0.0.1 IF-MIB::ifDescr      # interface names + indexes
snmpwalk -v2c -c <COMMUNITY_STRING> 10.0.0.1 IF-MIB::ifOperStatus # up(1)/down(2) per interface
snmpwalk -v2c -c <COMMUNITY_STRING> 10.0.0.1 IF-MIB::ifInOctets   # inbound counters
snmpget  -v2c -c <COMMUNITY_STRING> 10.0.0.1 IF-MIB::ifHCInOctets.2   # 64-bit counter (fast links)
# SNMPv3 (secure): auth + privacy
snmpwalk -v3 -l authPriv -u <USER> -a SHA -A <AUTHPASS> -x AES -X <PRIVPASS> 10.0.0.1 system
snmptranslate -On IF-MIB::ifInOctets     # name <-> numeric OID
```

**Cisco/CCNA mapping:** `snmp-server community <string> RO`, `snmp-server host <nms> version 2c
<string>`, `snmp-server enable traps`; `show snmp`. CCNA tests SNMP versions, the manager/agent/MIB
model, and polling vs traps.

---

## §3 — Real-World Use Cases

**Production scenarios:**
1. **Interface utilization graphs:** poll `ifHCInOctets`/`ifHCOutOctets` → utilization % → the
   capacity dashboards every NOC watches.
2. **Up/down + error monitoring:** `ifOperStatus` and `ifInErrors` drive link-down and bad-cable
   alerts.
3. **Instant link-down:** SNMP **traps** give immediate notification instead of waiting for the
   next poll (faster MTTD).
4. **Inventory/discovery:** `sysDescr`/`sysName` identify devices for auto-onboarding (Lesson 23).

**How NOC engineers use it:** SNMP is the invisible engine behind the device side of every NOC
dashboard. You won't always type `snmpwalk`, but understanding it explains *where the dashboard
numbers come from* and how to debug "device shows no data."

**When NOT to:** don't use v1/v2c with default communities on anything reachable; don't poll too
fast (device CPU); don't rely on 32-bit counters for fast links (wrap).

**Exam framing (Net+/CCNA):** SNMP versions + security, manager/agent/MIB/OID, GET vs trap,
and community strings are guaranteed.

---

## §4 — Troubleshooting Section

| Symptom | Likely cause | Diagnose | Fix |
|---|---|---|---|
| Device shows "no data" in NMS | wrong community/version / ACL / UDP161 blocked | `snmpwalk` from the NMS host | fix community/version/ACL/firewall |
| Utilization graph looks insane (spikes/negatives) | 32-bit counter wrap | use `ifHC*` 64-bit counters | switch to high-capacity OIDs |
| Some interfaces missing | ifIndex changed (reindex) | re-walk `ifDescr` | use ifName/persistent index |
| No traps received | trap dest/community/UDP162 | check `snmp-server host`; `nc -u -l 162` | fix trap config/firewall |
| Security finding: default community | `public`/`private` left | `snmpwalk -c public` succeeds | change community / move to v3 |

**Redaction check:** **never commit real community strings** — use `<COMMUNITY_STRING>`; lab IPs only.

---

## §5 — Common Mistakes

| Mistake | Impact | Fix |
|---|---|---|
| Default community `public`/`private` | data leak / device takeover | unique community / SNMPv3 |
| v2c on untrusted networks | community sent in cleartext | SNMPv3 (auth+priv) or mgmt-only |
| 32-bit counters on fast links | wrapping → bad graphs | `ifHCInOctets`/`ifHCOutOctets` |
| Polling too aggressively | device CPU load | sane interval (60s typical) |
| Treating raw counters as rates | wrong utilization | compute delta/time (Lesson 21/22 `rate()`) |
| SNMP open to the world | recon/attack surface | restrict to the NMS + mgmt VLAN |

---

## §6 — NOC Perspective

> NOC Technician focus (Stage 1, `ROADMAP.md`).

Every "interface utilization," "link down," and "device errors" panel on a NOC dashboard is SNMP
underneath. When a device shows **no data**, SNMP is the first thing to check (community/version/
ACL/UDP-161) — a common Tier-1 fix. **Traps** are why link-down alerts are near-instant rather than
delayed by the poll interval (better MTTD). Knowing SNMP lets you explain and debug the device side
of the monitoring you built in Lessons 22–23.

---

## §7 — Incident-Response Perspective

- **Detect:** an SNMP-driven alert (link down via trap, util/errors threshold via polling) →
  dashboard.
- **Triage/Diagnose:** `ifOperStatus`/`ifInErrors` localize whether it's a down link, a bad cable
  (errors), or congestion (high util). Maps to NOC scenarios #5 (interface down) and #3/#4
  (latency/loss from errors/congestion).
- **Document:** the counter evidence (errors climbing, util saturating) goes into the runbook;
  the prevention item is often "add the missing OID to monitoring."

---

## §8 — Practical Lab (build this yourself)

**Goal:** run a local `snmpd`, poll interface counters, and build `scripts/snmp_poll.sh` that
computes utilization from successive reads.

### Lens C — Manual → Automated → Why
- **Manual:** `snmpwalk`/`snmpget` interface counters and status.
- **Automated:** `snmp_poll.sh` polls `ifHCInOctets`/`ifHCOutOctets` twice, computes utilization %,
  reads `ifOperStatus`, and flags down/high-util interfaces — a mini SNMP monitor (what
  snmp_exporter/Zabbix do at scale).
- **Why:** understanding the counter→rate computation is the key SNMP insight; scripting it once
  demystifies every utilization graph you'll ever read.

### Steps
1. Install `net-snmp` and run `snmpd` locally with a **non-default** community (lab). `snmpwalk
   -v2c -c <COMMUNITY_STRING> localhost system` to confirm it works.
2. Walk `IF-MIB::ifDescr`, `ifOperStatus`, `ifHCInOctets`; identify your interface's ifIndex.
3. Build `scripts/snmp_poll.sh`:

```bash
#!/usr/bin/env bash
# snmp_poll.sh — poll an interface counter twice, compute utilization %. Lesson 24.
# Usage: ./snmp_poll.sh <host> <community> <ifIndex> [interval_s] [link_mbps]
set -euo pipefail
host="${1:?}"; comm="${2:?}"; idx="${3:?}"; iv="${4:-5}"; mbps="${5:-1000}"
get(){ snmpget -v2c -c "$comm" -Oqv "$host" "IF-MIB::ifHCInOctets.$idx"; }
status=$(snmpget -v2c -c "$comm" -Oqv "$host" "IF-MIB::ifOperStatus.$idx")
echo "ifOperStatus.$idx = $status"
a=$(get); sleep "$iv"; b=$(get)
bits=$(( (b - a) * 8 ))
util=$(awk -v bits="$bits" -v iv="$iv" -v mbps="$mbps" 'BEGIN{printf "%.2f", (bits/iv)/(mbps*1000000)*100}')
echo "in-utilization over ${iv}s: ${util}% of ${mbps}Mbps"
# TODO (operator): also poll ifHCOutOctets + ifInErrors; alert if util>80 or status!=1.
```

4. `bash -n` → `shellcheck` → run it; generate some traffic and watch utilization rise.
5. **Drill:** `ip link set <if> down` → re-poll → `ifOperStatus` flips to 2 (down); maps to drill 5.

### Lens D — counter wrap + BER
Read about Counter32 wrap on fast links (why `ifHC*` exists) and note that SNMP encodes in ASN.1
BER over UDP — capture an `snmpwalk` with `tcpdump -ni any udp port 161` to see it.

---

## §9 — GitHub Artifact (evidence 5-tuple)

1. **Script:** `scripts/snmp_poll.sh` (counter → utilization, status flag).
2. **Config:** a lab `snmpd.conf` snippet (with `<COMMUNITY_STRING>` placeholder) in `infra/configs/`.
3. **Drill:** interface-down detected via `ifOperStatus` (drill 5).
4. **NAVI ticket:** `NAVI-24` (Task: "snmp_poll.sh + SNMP interface monitoring").
5. **Incident report:** an SNMP-detected interface-down/error runbook.

---

## §10 — Portfolio Artifact

- **Resume bullet:** "Built SNMP interface-utilization polling (`snmp_poll.sh`) computing rate from
  64-bit counters and detecting link-down via `ifOperStatus`; explained the SNMP engine behind NOC
  dashboards."
- **Interview talking point:** OIDs/MIBs, v2c-vs-v3 security, polling-vs-traps, and the
  counter→utilization computation (and the 32-bit wrap gotcha) — strong NetOps signal.
- **Serves:** Network Operations / NOC (Stages 1–2); the engine behind Lessons 22–23.

---

## §11 — RHCSA Crossover Notes

Mostly **N/A for RHCSA** as an objective, but `net-snmp`/`snmpd` runs on RHEL (package + systemd
service + firewalld UDP/161 — RHCSA skills), and SNMP is how a RHEL host can be monitored by an
NMS. The service-management mechanics overlap with RHCSA.

---

## §12 — Security Notes (Lens E — Attacker & Defender)

> Frameworks: [MITRE ATT&CK](https://attack.mitre.org/).

**🔴 Attacker:** **default/weak community strings** (`public`/`private`) let an attacker
`snmpwalk` an entire device's config and topology (`T1590` Gather Victim Network Information) — and
with a writable community (`private`), **reconfigure** the device (`T1602` Data from Configuration
Repository / config tampering). SNMP is also a **DDoS amplification** vector. v1/v2c send the
community in cleartext (sniffable, Lesson 19).

**🔵 Defender:** use **SNMPv3** (authPriv: SHA auth + AES privacy); if stuck on v2c, use **unique,
strong communities, read-only**, and **restrict SNMP to the management VLAN + the NMS IP** (ACL +
firewall on UDP 161); disable SNMP where unused; monitor for SNMP scans. Verify with `snmpwalk -c
public` against your lab device returning **nothing** (proves the default is closed).

---

## Quiz (Interview-Style, Graded)

**Q1.** Explain the SNMP manager/agent/MIB/OID model in your own words.
> **Your answer:**

**Q2.** Difference between polling and traps — and why would you want both?
> **Your answer:**

**Q3.** v2c vs v3 — what's the security difference, and what does a community string actually do?
> **Your answer:**

**Q4.** **Scenario:** Your utilization graph for a 10G uplink shows wild spikes and occasional
negative values. What's the likely cause and the fix?
> **Your answer:**

**Q5.** How do you compute interface utilization % from `ifInOctets`?
> **Your answer:**

**Q6.** Why is a default `public` community a serious vulnerability, and how do you remediate it?
> **Your answer:**

*(After you answer, request the "Professional Answer" comparison under each — graded before Lesson 25.)*

---

## Reflection
*(Fill in after the quiz)* — What did you learn? · What confused you? · What would you do differently?

---

## Search Keywords For Further Understanding

**Core**
- `snmp mib oid explained`
- `snmp v2c vs v3 security`
- `snmp polling vs traps`
- `if-mib ifinoctets utilization`
- `snmp counter32 wrap ifhc`

**Tools**
- `snmpwalk snmpget examples`
- `net-snmp snmpd configuration`
- `snmptrap snmptrapd`

**Going further (future lessons)**
- `snmp_exporter prometheus` (L22) · `zabbix snmp` (L23) · `netflow sflow`

**Red / Blue (Lens E):**
- 🔴 `snmp default community public attack T1590`, `snmp write private reconfigure`, `snmp amplification ddos`
- 🔵 `snmpv3 authpriv`, `restrict snmp management vlan acl`, `detect snmp scan`

---

## Lesson Status
- [ ] §8 lab completed (snmpd + snmp_poll.sh utilization)
- [ ] §4 drill done (interface-down via ifOperStatus)
- [ ] Evidence committed (§9)
- [ ] Quiz answered + professional-answer comparisons (graded)
- [ ] Reflection + Search Keywords reviewed

When complete, run the Update Protocol, then move to **Lesson 25 — Syslog & Centralized Logging**.

---

*Lesson 24 written by Navi · 2026-06-20 · full-depth. Sources to cite when worked: RFC 3416/3414
(SNMP/v3), IF-MIB (RFC 2863), net-snmp docs, CompTIA Network+ N10-009, MITRE ATT&CK T1590/T1602.*
