# Lesson 09 — VLANs

**Status:** ✅ ready for self-study (full depth) · **Date written:** 2026-06-20
**Schema:** 12-section (`docs/learning/CLAUDE_TEACHING_RULES.md`)
**Focus:** 802.1Q tagging, access vs trunk ports, native VLAN, inter-VLAN routing, Linux VLAN interfaces.
**Primary artifact:** `infra/configs/vlan-lab.md`.
**Difficulty:** **Difficult concept** — §1 uses two teaching approaches + an ASCII diagram (Lens B).

> **How to use this lesson:** VLANs are a top NOC/network-engineer interview and ticket topic
> ("VLAN misconfig"). Read §1–§7, build VLANs on a Linux bridge in §8, run drill 7. Lab only.

---

## §1 — Concept (Scientific Theory)

### What it is
A **VLAN** (Virtual LAN, IEEE **802.1Q**) splits one physical switch into multiple **logical**
switches — separate **broadcast domains** — without separate hardware. Each VLAN has an ID
(1–4094); ports are assigned to VLANs. Traffic in VLAN 10 cannot reach VLAN 20 except through a
**router** (or L3 switch). VLANs are tagged for transport across **trunk** links using a 4-byte
802.1Q tag inserted into the Ethernet frame.

### Why it exists
A flat L2 network (Lesson 08) is one big broadcast domain — it doesn't scale (broadcast noise),
mixes traffic that should be separated (guests with servers), and is a security risk (everyone
can reach everyone). VLANs give **segmentation without buying more switches**: logical
separation, smaller broadcast domains, and a security boundary, all on shared hardware.

### Access vs trunk (the core distinction)
| Port type | Carries | Tagging | Use |
|---|---|---|---|
| **Access** | ONE VLAN | untagged (frames have no tag) | end devices (PC, printer, phone) |
| **Trunk** | MANY VLANs | 802.1Q tagged (except the native VLAN) | switch-to-switch, switch-to-router |

The **native VLAN** on a trunk is the one VLAN whose frames are sent **untagged** (default VLAN
1). A **native-VLAN mismatch** between two trunk ends is a classic, subtle outage/security issue.

### Inter-VLAN routing (how VLANs talk)
VLANs are separate networks, so they need a **router**:
- **Router-on-a-stick:** one trunk to a router with **subinterfaces** (one per VLAN).
- **L3 switch with SVIs:** a Switched Virtual Interface (`interface vlan10`) per VLAN acts as the
  gateway — faster, the common enterprise design.
- **Linux:** create VLAN sub-interfaces (`ip link add link eth0 name eth0.10 type vlan id 10`)
  and route/forward between them.

### Three-Level Depth (Lens A)
- **Level 1 — Beginner:** VLANs are like putting walls inside one open-plan office so different
  teams have separate rooms — same building (switch), separate spaces (broadcast domains). A door
  (router) is needed to go between rooms.
- **Level 2 — NetOps/NOC:** you assign access ports to VLANs, configure trunks with an allowed
  VLAN list, match native VLANs, and set up inter-VLAN routing. Troubleshooting "VLAN misconfig"
  means checking: is the access port in the right VLAN? is the VLAN *allowed* on the trunk? do
  native VLANs match? is there an SVI/gateway for the VLAN? On Linux, `bridge vlan show` and VLAN
  sub-interfaces are the tools.
- **Level 3 — Wire/Kernel (Lens D):** the 802.1Q tag is 4 bytes inserted after the source MAC:
  TPID `0x8100` + 3-bit PCP (QoS priority) + 1-bit DEI + **12-bit VLAN ID** (hence 4094 usable).
  The Linux 802.1Q driver (`net/8021q/`) adds/removes tags; a VLAN sub-interface is a virtual
  netdev that tags egress and de-tags ingress for one ID. **VLAN-aware bridges** (`bridge vlan`)
  do per-port tagged/untagged membership exactly like a hardware switch.

### Two Teaching Approaches (Lens B) — tagging & trunks

**Approach 1 (technical):** an access port receives untagged frames and *internally* associates
them with its VLAN; when those frames must cross a trunk to another switch, the egress trunk port
**inserts the 802.1Q tag** so the far switch knows which VLAN they belong to; the far trunk port
**removes the tag** and delivers to the right VLAN. The native VLAN is the exception sent
untagged. Inter-VLAN traffic must be routed at L3.

**Approach 2 (analogy):** a shared corporate shuttle bus (the trunk) serving several departments
in one building.
- Inside each department's office (access port), people don't wear badges — everyone there is
  obviously in that department (untagged).
- When they board the shared shuttle (trunk) that carries *all* departments, each person puts on
  a **colored badge** (802.1Q tag) so the driver drops them at the right department at the next
  building.
- One "default" department rides **without** a badge by agreement (native VLAN) — but if the two
  buildings disagree about which department is the badge-less default (native mismatch), people
  end up in the wrong office.
- **Where it breaks down:** the analogy implies people choose badges; in reality the *switch*
  tags/untags automatically based on port config — the endpoint is unaware of VLANs.

### Visual (ASCII) — access ports, a trunk, and inter-VLAN routing

```
   VLAN10 (10.0.10.0/24)              VLAN20 (10.0.20.0/24)
   PC-A ─access(v10)─┐                ┌─access(v20)─ PC-B
                     │  ┌──────────┐  │
                     ├─►│ SWITCH 1 │◄─┤
                        └────┬─────┘
                       trunk │ (802.1Q tags v10,v20; native v1 untagged)
                        ┌────┴─────┐
                        │  ROUTER  │  subif .10 = 10.0.10.1 (gw v10)
                        │ (on a    │  subif .20 = 10.0.20.1 (gw v20)
                        │  stick)  │  routes BETWEEN v10 and v20
                        └──────────┘
   PC-A→PC-B: A→gw(10.0.10.1)→router routes→gw(10.0.20.1)→B  (L3 hop required)
```

---

## §2 — Linux Networking Commands

```bash
# VLAN sub-interface (router-on-a-stick style on a Linux host):
ip link add link eth0 name eth0.10 type vlan id 10
ip addr add 10.0.10.1/24 dev eth0.10
ip link set eth0.10 up
ip -d link show eth0.10              # show VLAN id + details

# VLAN-aware bridge (Linux switch with VLANs):
ip link add br0 type bridge vlan_filtering 1
bridge vlan add dev eth1 vid 10 pvid 10 untagged   # access port in VLAN 10
bridge vlan add dev trunk0 vid 10                    # allow VLAN 10 on a trunk (tagged)
bridge vlan add dev trunk0 vid 20
bridge vlan show                                     # per-port VLAN membership (verify!)
```

**Cisco/CCNA mapping:** `switchport mode access` / `switchport access vlan 10`;
`switchport mode trunk` / `switchport trunk allowed vlan 10,20` / `switchport trunk native vlan
99`; `show vlan brief`, `show interfaces trunk`; inter-VLAN via subinterfaces (`encapsulation
dot1q 10`) or SVIs (`interface vlan10`). CCNA tests this heavily.

---

## §3 — Real-World Use Cases

**Production scenarios:**
1. **Segmentation:** separate VLANs for servers / staff / voice / guest / management — smaller
   broadcast domains + a firewall boundary between them (Lesson 15).
2. **Adding a VLAN:** create it, assign access ports, **allow it on every trunk in the path**,
   and create its gateway (SVI) — forgetting any step = "new VLAN doesn't work."
3. **Voice VLAN:** phones tag voice traffic into a separate VLAN for QoS while a PC behind the
   phone uses the data VLAN on the same cable.
4. **Guest isolation:** a guest VLAN with internet-only access (no route to internal VLANs).

**How NOC engineers use it:** VLAN troubleshooting is a top recurring ticket. The checklist —
access VLAN, trunk allowed list, native mismatch, gateway/SVI — resolves most of them.

**When NOT to:** don't over-fragment into dozens of tiny VLANs you can't manage, and don't rely
on VLANs *alone* for security (VLAN hopping exists — §12).

**Exam framing (Net+/CCNA):** access vs trunk, 802.1Q tagging, native VLAN, inter-VLAN routing
(router-on-a-stick vs SVI), and the VLAN range are guaranteed exam content.

---

## §4 — Troubleshooting Section

| Symptom | Likely cause | Diagnose | Fix |
|---|---|---|---|
| Host can't talk to its VLAN peers | access port in wrong VLAN | `bridge vlan show` / `show vlan brief` | set correct access VLAN |
| New VLAN works locally, not across switches | VLAN not allowed on a trunk | `show interfaces trunk` / `bridge vlan` | add VLAN to trunk allowed list |
| Intermittent/weird cross-VLAN leakage | native VLAN mismatch | compare native on both trunk ends | match native VLAN |
| Inter-VLAN traffic fails | no gateway/SVI or routing off | check SVI/subinterface + `ip route` | create gateway, enable routing |
| Everything on a VLAN down | trunk down / VLAN pruned | trunk status, allowed list | restore trunk/allowed VLAN |

**Redaction check:** lab VLAN IDs + RFC-1918 in committed configs.

---

## §5 — Common Mistakes

| Mistake | Impact | Fix |
|---|---|---|
| Forgetting to allow the VLAN on a trunk | VLAN works on one switch only | add to every trunk in the path |
| Native VLAN mismatch | leakage / STP issues / VLAN hopping risk | match natives; avoid VLAN 1 as native |
| No SVI/gateway for a VLAN | hosts have no inter-VLAN path | create the gateway |
| Using VLAN 1 for everything | security + management risk | dedicate a mgmt VLAN, change native |
| Assuming VLANs = security | VLAN hopping bypasses it | add L3 ACLs/firewall (L15) |
| Putting the gateway IP in the wrong VLAN | hosts can't route out | gateway must be the VLAN's SVI/subif |

---

## §6 — NOC Perspective

> NOC Technician focus (Stage 1, `ROADMAP.md`).

"VLAN misconfiguration" is NOC scenario #7 and a frequent ticket, especially after a change (new
port, new VLAN, new switch). The NOC first-move checklist: access-port VLAN → trunk allowed list
→ native match → gateway. Scope matters: one host = access-port issue (Sev3); a whole VLAN across
sites = trunk/allowed-list issue (Sev2). Because VLANs are usually changed via **change tickets**
(`noc/ticketing.md`), "what changed?" is the fastest first question — correlate the outage with
the recent VLAN change.

---

## §7 — Incident-Response Perspective

- **Detect:** hosts in a VLAN can't communicate, or a new VLAN doesn't work, often post-change.
- **Triage:** scope (one host / one switch / cross-site) + correlate with the change record.
- **Diagnose (RCA):** walk the checklist — the failing element (wrong access VLAN / missing trunk
  allow / native mismatch / no SVI) is the root cause.
- **Fix → Recover → Document:** correct it, verify intra-VLAN + inter-VLAN reachability, document.
  Maps to **drill 7 (VLAN misconfiguration)**.

---

## §8 — Practical Lab (build this yourself)

**Goal:** build two VLANs on a VLAN-aware Linux bridge, route between them, break it (drill 7),
fix it; document in `infra/configs/vlan-lab.md`.

### Lens C — Manual → Automated → Why
- **Manual:** create the bridge, assign access PVIDs, allow VLANs on a trunk, build SVIs/gateways.
- **Automated:** a build script + a verifier that checks each access port's VLAN, the trunk's
  allowed list, and inter-VLAN reachability.
- **Why:** VLAN changes are error-prone and high-impact; a post-change verifier ("every access
  port in the intended VLAN, every VLAN allowed on the trunk, gateways reachable") catches the
  classic misconfigs before users do.

### Steps
```bash
# VLAN-aware bridge with v10 + v20 access hosts and inter-VLAN routing on the Linux "router".
ip link add br0 type bridge vlan_filtering 1 && ip link set br0 up
# attach veth hosts as access ports (pvid 10 / pvid 20), build router subifs as gateways
bridge vlan show                       # verify per-port membership
ip netns exec h10 ping -c1 10.0.10.<peer>   # intra-VLAN: works
ip netns exec h10 ping -c1 10.0.20.<host>   # inter-VLAN: works only with routing + gateways
```
1. Build v10 (`10.0.10.0/24`) and v20 (`10.0.20.0/24`); document topology + commands in
   `infra/configs/vlan-lab.md`.
2. Verify intra-VLAN reachability, then enable inter-VLAN routing (gateways + `ip_forward`) and
   verify cross-VLAN.
3. **Drill 7:** move a host to the wrong VLAN (or remove a VLAN from the trunk's allowed set);
   observe the failure; diagnose with `bridge vlan show`; fix.
4. Confirm guest-isolation logic: with a firewall rule (preview L15), block v-guest→v-internal
   while allowing v-guest→"internet."

### Lens D — see the tag
`tcpdump -e -ni trunk0 vlan` shows the 802.1Q-tagged frames on the trunk (with the VLAN ID), vs
untagged frames on access ports — the tag made visible.

---

## §9 — GitHub Artifact (evidence 5-tuple)

1. **Script:** the VLAN bridge build + verifier.
2. **Config/topology:** `infra/configs/vlan-lab.md` (VLAN plan, build, `bridge vlan` output).
3. **Drill:** drill 7 (VLAN misconfig) executed.
4. **NAVI ticket:** `NAVI-09` (Change: "add VLAN 20 + inter-VLAN routing" → then Incident for drill).
5. **Incident report:** `docs/runbooks/incident-vlan-misconfig.md` (symptom→checklist→fix→verify→RCA).

---

## §10 — Portfolio Artifact

- **Resume bullet:** "Designed and built a multi-VLAN segmented network (802.1Q) with inter-VLAN
  routing and guest isolation on Linux; diagnosed a VLAN-trunk misconfiguration end-to-end."
- **Interview talking point:** the access-vs-trunk + native-VLAN + inter-VLAN-routing explanation
  and your VLAN-misconfig troubleshooting checklist — core network-engineer material.
- **Serves:** Linux Net Admin / Jr Network Engineer (Stages 3–4); central to CCNA capstone (34).

---

## §11 — RHCSA Crossover Notes

RHCSA-relevant: creating VLAN interfaces with `nmcli con add type vlan dev eth0 id 10` is a
NetworkManager skill that appears in RHEL networking. Understanding tagged vs untagged and that
VLANs are separate networks needing routing helps RHEL host/VM network setup. Cisco trunk syntax
is "N/A for RHCSA."

---

## §12 — Security Notes (Lens E — Attacker & Defender)

> Frameworks: [MITRE ATT&CK](https://attack.mitre.org/).

**🔴 Attacker:** **VLAN hopping** — **switch spoofing** (pretending to be a switch to negotiate a
trunk and reach all VLANs) and **double tagging** (nesting two 802.1Q tags to jump from the
native VLAN into a target VLAN). Both map to bypassing segmentation (`T1599`/`T1557` family). A
flat or misconfigured native VLAN enables them.

**🔵 Defender:** disable DTP / **set ports to access explicitly**, **don't use VLAN 1**, set the
**native VLAN to an unused ID** and don't put hosts on it, **prune** unused VLANs from trunks,
and back VLAN segmentation with **L3 ACLs/firewalls** (don't trust VLANs alone). Verify by
attempting (lab-only) a double-tag and confirming it's dropped.

---

## Quiz (Interview-Style, Graded)

**Q1.** What problem do VLANs solve, and what do they do to broadcast domains?
> **Your answer:**

**Q2.** Access vs trunk port: what does each carry, and how does tagging differ?
> **Your answer:**

**Q3.** What is the native VLAN, and what goes wrong if two trunk ends disagree about it?
> **Your answer:**

**Q4.** **Scenario:** A new VLAN 30 works fine for hosts on Switch-1 but those hosts can't reach
VLAN 30 hosts on Switch-2. What's the most likely cause and how do you confirm it?
> **Your answer:**

**Q5.** How do two devices in different VLANs communicate? Name two designs.
> **Your answer:**

**Q6.** What is VLAN hopping (name both techniques) and how do you prevent it?
> **Your answer:**

*(After you answer, request the "Professional Answer" comparison under each — graded before Lesson 10.)*

---

## Reflection
*(Fill in after the quiz)* — What did you learn? · What confused you? · What would you do differently?

---

## Search Keywords For Further Understanding

**Core**
- `vlan 802.1q tagging explained`
- `access port vs trunk port`
- `native vlan mismatch`
- `inter vlan routing router on a stick svi`

**Tools**
- `linux vlan interface ip link`
- `bridge vlan filtering linux`
- `show vlan brief show interfaces trunk`

**Going further (future lessons)**
- `spanning tree per vlan` (L10) · `vlan acl firewall segmentation` (L15) · `voice vlan qos`

**Red / Blue (Lens E):**
- 🔴 `vlan hopping switch spoofing double tagging`, `dtp attack`
- 🔵 `disable dtp access port`, `change native vlan`, `vlan pruning segmentation`

---

## Lesson Status
- [ ] §8 lab completed (2-VLAN bridge + inter-VLAN routing)
- [ ] §4 drill done (drill 7 — VLAN misconfig)
- [ ] Evidence committed (§9)
- [ ] Quiz answered + professional-answer comparisons (graded)
- [ ] Reflection + Search Keywords reviewed

When complete, run the Update Protocol, then move to **Lesson 10 — Spanning Tree Protocol (STP)**.

---

*Lesson 09 written by Navi · 2026-06-20 · full-depth. Sources to cite when worked: IEEE 802.1Q,
Linux 8021q docs, CompTIA Network+ N10-009, Cisco VLAN references, MITRE ATT&CK VLAN-hopping.*
