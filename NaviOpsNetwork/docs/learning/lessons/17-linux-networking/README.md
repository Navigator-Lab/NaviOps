# Lesson 17 — Linux Networking Deep-Dive

**Status:** ✅ ready for self-study (full depth) · **Date written:** 2026-06-20
**Schema:** 12-section (`docs/learning/CLAUDE_TEACHING_RULES.md`)
**Focus:** NetworkManager/nmcli, `ip`/`ss` internals, network namespaces, bridges, policy routing, `/proc/net`, `/etc/hosts` & `resolv.conf`.
**Primary artifact:** `scripts/net_diag.sh` (v2 — the consolidated diagnostic).

> **How to use this lesson:** this consolidates the Linux-networking stack you've used piecemeal
> (Lessons 01–16) into one operator-grade toolkit. Read §1–§7, finalize `net_diag.sh` v2 in §8.

---

## §1 — Concept (Scientific Theory)

### What it is
This lesson is the **Linux networking control plane**: how a Linux host's networking is actually
configured, stored, and manipulated — **NetworkManager**/`nmcli` (the config layer), the
**iproute2** suite (`ip`/`ss` — the kernel interface), **network namespaces** (isolated network
stacks — the basis of containers), **bridges** (software switches), **policy routing** (multiple
routing tables), and the kernel's network state in **`/proc/net`** and **`/sys/class/net`**.

### Why it exists
Every prior lesson touched Linux networking; here you learn the *system* so you can configure,
inspect, and isolate networking deterministically — the difference between "I ran some commands"
and "I understand how the host's networking is wired." This is the core skill of a **Linux Network
Administrator** (Stage 3).

### The layers of Linux network config
| Layer | What | Tool |
|---|---|---|
| **Config / intent** | persistent connection profiles | `nmcli` (NetworkManager), `/etc/NetworkManager`, netplan/systemd-networkd |
| **Kernel interface** | live addresses/links/routes/neighbours | `ip`, `ss` (iproute2) |
| **Name resolution** | host→IP order | `/etc/nsswitch.conf`, `/etc/hosts`, `/etc/resolv.conf`, `resolvectl` |
| **Kernel state** | raw counters/tables | `/proc/net/*`, `/sys/class/net/*` |
| **Isolation** | separate stacks | network **namespaces**, `veth`, bridges |

### Three-Level Depth (Lens A)
- **Level 1 — Beginner:** Linux has commands to see and change your network (addresses, routes,
  DNS), and a config system (NetworkManager) that remembers your settings across reboots.
- **Level 2 — NetOps/NOC:** you make changes **persistent** with `nmcli` (not just live with
  `ip`, which is lost on reboot), understand resolution order (`/etc/hosts` before DNS via
  `nsswitch`), and use **namespaces + veth + bridges** to build isolated labs (every prior lab!)
  and to understand container networking. **Policy routing** (multiple tables + rules) handles
  multi-homed hosts (route by source, not just destination).
- **Level 3 — Wire/Kernel (Lens D):** `ip`/`ss` talk to the kernel via **Netlink** sockets. A
  **network namespace** is a separate copy of the entire network stack (interfaces, routes,
  conntrack, `/proc/net`); a **veth** pair is a virtual cable between namespaces; a **bridge** is
  a software switch joining them — this trio *is* how Docker/Podman/Kubernetes networking works
  under the hood. `/proc/net/dev` (counters), `/proc/net/tcp` (sockets), `/proc/net/route`
  (routes), and `/proc/net/nf_conntrack` (NAT/firewall state) are the raw kernel views the tools
  format.

### Two Teaching Approaches (Lens B) — namespaces & veth (container networking)

**Approach 1 (technical):** a network namespace gives a process group its own isolated network
stack. To connect two namespaces (or a namespace to the host), you create a **veth pair** — two
virtual interfaces wired back-to-back; put one end in each namespace. To connect *many*
namespaces, attach their veth ends to a **bridge** (a software switch). Add addresses + routes,
enable forwarding, and you've built a virtual network — exactly the model container runtimes use.

**Approach 2 (analogy):** namespaces are **separate apartments in one building (the kernel)**.
- Each apartment (namespace) has its own plumbing, wiring, and mailbox (its own interfaces,
  routes, ARP table) — fully isolated from neighbors.
- A **veth pair** is a private intercom line strung between two apartments.
- A **bridge** is the building's shared switchboard connecting many apartments.
- The host is the **building manager's apartment**, which can also be wired into the switchboard.
- **Where it breaks down:** apartments are physically separate; namespaces share the same kernel
  *code* — isolation is logical (the same kernel enforces it), which is why a kernel bug can break
  isolation in a way a real wall never would. (This is the security nuance of containers.)

### Visual (ASCII) — namespaces + veth + bridge (the container model)

```
                         br0 (software switch, host)
                ┌──────────┬──────────┬──────────┐
              veth0      veth1      veth2     (host eth0 → NAT/route out, L14)
                │          │          │
            ┌───┴───┐  ┌───┴───┐  ┌───┴───┐
            │ ns A  │  │ ns B  │  │ ns C  │   each = isolated net stack
            │10.0.0.2│ │10.0.0.3│ │10.0.0.4│  (own routes, ARP, /proc/net)
            └───────┘  └───────┘  └───────┘
   This is exactly how Docker wires containers to docker0.
```

---

## §2 — Linux Networking Commands

```bash
# NetworkManager (persistent config — RHCSA-relevant)
nmcli device status                       # interfaces + connection state
nmcli connection show                     # saved profiles
nmcli con mod eth0 ipv4.addresses 10.0.0.10/24 ipv4.gateway 10.0.0.1 ipv4.dns 10.0.0.1
nmcli con mod eth0 ipv4.method manual ; nmcli con up eth0

# iproute2 (live kernel state)
ip -br addr ; ip route ; ip neigh ; ip -s link        # the core four
ip route get 8.8.8.8                                  # chosen route
ss -tulpn ; ss -s                                      # sockets + summary

# Name resolution
resolvectl status ; getent hosts host01               # what the OS apps resolve
cat /etc/nsswitch.conf | grep hosts                    # resolution order

# Namespaces / bridges (build a lab)
ip netns add nsA ; ip netns exec nsA ip link
ip link add veth0 type veth peer name veth0b
ip link add br0 type bridge ; ip link set veth0 master br0

# Policy routing (multi-homed)
ip rule show ; ip route show table 100

# Raw kernel views
cat /proc/net/dev ; cat /sys/class/net/eth0/statistics/rx_errors
```

**Cisco/CCNA mapping:** less direct (this is host-side), but the *concepts* (interface config,
routing tables, name resolution) parallel device config. The Linux-first depth here is the
platform's differentiator (D3) and what Linux-Network-Admin / NetOps-on-Linux roles want.

---

## §3 — Real-World Use Cases

**Production scenarios:**
1. **Persistent config:** a server's IP/route/DNS set via `nmcli` survives reboot (an `ip`-only
   change is lost — a classic "it broke after reboot" cause).
2. **Resolution-order bugs:** a stale `/etc/hosts` entry overriding DNS (because `nsswitch` checks
   `files` before `dns`) — confusing until you know the order.
3. **Container/VM networking troubleshooting:** understanding bridges + veth explains why a
   container can/can't reach another or the host.
4. **Multi-homed hosts:** policy routing so traffic from interface A leaves via A's gateway
   (source-based routing) — common on dual-WAN/cloud hosts.

**How NOC/Linux-admins use it:** this is the everyday toolkit; `net_diag.sh` v2 (the consolidated
diagnostic) is the artifact you'll reach for in most connectivity tickets.

**When NOT to:** don't make live-only `ip` changes on production (use `nmcli` for persistence);
don't hand-craft namespaces where a real tool (Docker) is the right abstraction.

**Exam framing:** more RHCSA than CCNA — `nmcli`, name resolution, and `ip`/`ss` are RHCSA core.

---

## §4 — Troubleshooting Section

| Symptom | Likely cause | Diagnose | Fix |
|---|---|---|---|
| Network breaks after reboot | live `ip` change not persisted | `nmcli con show` vs live `ip` | set via `nmcli` |
| Name resolves wrong | stale `/etc/hosts` (files before dns) | `getent hosts X`; `nsswitch` order | fix `/etc/hosts` / order |
| Container can't reach host/peer | bridge/veth/forwarding | `bridge link`, `ip -n <ns> route`, `ip_forward` | fix bridge attach / route / forwarding |
| Wrong egress on multi-homed host | missing policy route | `ip rule`, `ip route show table N` | add `ip rule`/table |
| Interface errors climbing | NIC/cable/driver | `/sys/class/net/*/statistics`, `ip -s link` | replace/reseat; driver |

**Redaction check:** RFC-1918 + lab interface names in committed output.

---

## §5 — Common Mistakes

| Mistake | Impact | Fix |
|---|---|---|
| Using `ip` for "permanent" changes | lost on reboot | persist with `nmcli`/netplan |
| Forgetting `nsswitch` order | DNS "ignored" due to `/etc/hosts` | know files→dns order |
| Deprecated `ifconfig`/`route`/`netstat` | missing on modern distros | iproute2 (`ip`/`ss`) |
| Disabling NetworkManager without a replacement | no network on reboot | use NM or systemd-networkd deliberately |
| Building namespaces without forwarding/NAT | isolated lab can't reach out | enable `ip_forward` + masquerade (L14) |

---

## §6 — NOC Perspective

> NOC Technician focus (Stage 1, `ROADMAP.md`).

For NOCs running on Linux infrastructure (and SOC/Linux-admin roles), fluent `ip`/`ss`/`nmcli` is
the baseline. The consolidated `net_diag.sh` v2 you finalize here is the "collect diagnostics"
button a NOC runs first on any Linux host ticket — it captures L1–L7 state into the ticket in one
shot, which is exactly the evidence escalation wants. Persistent-vs-live config is a frequent
"it broke after reboot/maintenance" incident.

---

## §7 — Incident-Response Perspective

- **Detect:** a Linux host's connectivity degraded (often post-change/reboot).
- **Triage:** scope + correlate with a change/reboot.
- **Diagnose (RCA):** persistence (nmcli vs live), resolution order, namespace/bridge wiring, or
  policy routing — `net_diag.sh` v2 captures the lot; the failing layer localizes it.
- **Fix → Recover → Document:** persist the fix (`nmcli`), verify across a reboot, document.

---

## §8 — Practical Lab (build this yourself)

**Goal:** finalize `scripts/net_diag.sh` **v2** — the consolidated L1–L7 + resolution + persistence
diagnostic — and build a 3-namespace bridged lab.

### Lens C — Manual → Automated → Why
- **Manual:** the iproute2 core four + `nmcli`/`resolvectl`.
- **Automated:** `net_diag.sh` v2 = the union of all prior diagnostics (links, addresses, routes,
  ARP, sockets, default-route + gateway ping, DNS check, and a persistence check comparing live
  `ip` vs `nmcli` config), labeled by OSI layer, exit non-zero on any red.
- **Why:** one command, full picture, dropped into the ticket — the single most useful artifact in
  the whole repo for day-to-day ops.

### Steps
1. Build the 3-namespace + bridge lab (the §1 diagram) and confirm inter-namespace ping; add
   masquerade so they reach "out" (ties L14). Document in `infra/topologies/netns-lab.md`.
2. Finalize `scripts/net_diag.sh` v2 consolidating: `ip -br link/addr`, `ip route` +
   default-route+gateway-ping check, `ip neigh`, `ss -tulpn`, `resolvectl`/`getent` DNS check,
   and a `nmcli con show` vs live-`ip` persistence note. Label sections by layer.
3. `bash -n` → `shellcheck` → run on the host and inside a namespace.
4. **Drill:** make a live-only `ip addr` change, "reboot" the namespace (recreate), show it's lost,
   then persist properly.

### Lens D — Netlink + /proc
`strace -e trace=network ip addr` shows the **Netlink** socket calls `ip` makes to the kernel;
compare `ip route` to `cat /proc/net/route` — same data, raw vs formatted.

---

## §9 — GitHub Artifact (evidence 5-tuple)

1. **Script:** `scripts/net_diag.sh` v2 (consolidated, shellcheck-clean).
2. **Config/topology:** `infra/topologies/netns-lab.md` (3-ns bridge lab).
3. **Drill:** persistence drill (live vs nmcli) executed.
4. **NAVI ticket:** `NAVI-17` (Task: "net_diag v2 + netns lab").
5. **Incident report:** `docs/runbooks/incident-config-not-persisted.md` (symptom→RCA→fix→verify).

---

## §10 — Portfolio Artifact

- **Resume bullet:** "Built a consolidated Linux network diagnostic (`net_diag.sh`) and a
  namespace/veth/bridge lab demonstrating container-style networking; debugged persistence and
  name-resolution-order issues."
- **Interview talking point:** explain how container networking works (namespaces + veth +
  bridge) and persistent-vs-live config — strong Linux-Network-Admin signals.
- **Serves:** Linux Network Admin / Infra Support (Stage 3); ties the whole stack together.

---

## §11 — RHCSA Crossover Notes

Heaviest RHCSA-overlap lesson: `nmcli` (addresses/gateway/DNS/routes/method), name resolution
(`/etc/hosts`, `/etc/resolv.conf`, `nsswitch`), `ip`/`ss`, and bridges are all RHCSA networking
objectives. `net_diag.sh` v2 doubles as an RHCSA troubleshooting aid.

---

## §12 — Security Notes (Lens E — Attacker & Defender)

> Frameworks: [MITRE ATT&CK](https://attack.mitre.org/) · [GTFOBins](https://gtfobins.github.io/).

**🔴 Attacker:** post-compromise, attackers use `ip`/`ss` for **discovery** (`T1016` System Network
Configuration Discovery, `T1049` System Network Connections Discovery), create **namespaces/veth**
to hide traffic, modify `/etc/hosts`/`resolv.conf` to **redirect** name resolution (`T1565`
Data Manipulation), and abuse `ip`/`nmcli` to alter routing for MITM.

**🔵 Defender:** monitor for unexpected `ip`/`ss`/`nmcli` execution and changes to
`/etc/hosts`/`resolv.conf` (FIM, Lesson 28), alert on new interfaces/namespaces on servers, and
baseline normal network config. Verify integrity-monitoring catches a `/etc/hosts` edit (lab).

---

## Quiz (Interview-Style, Graded)

**Q1.** Why does a network change made with `ip` disappear after a reboot, and how do you make it
persistent?
> **Your answer:**

**Q2.** Explain the resolution order from `/etc/nsswitch.conf` and how a stale `/etc/hosts` entry
can override DNS.
> **Your answer:**

**Q3.** Describe how namespaces, veth pairs, and bridges combine to create container networking.
> **Your answer:**

**Q4.** **Scenario:** After a reboot, a server has no network. `ip addr` is empty but the cable is
fine. Where do you look and why?
> **Your answer:**

**Q5.** What is policy routing and when would you need it?
> **Your answer:**

**Q6.** What `/proc/net` or `/sys/class/net` files would you read to check interface error counters,
and why prefer them sometimes?
> **Your answer:**

*(After you answer, request the "Professional Answer" comparison under each — graded before Lesson 18.)*

---

## Reflection
*(Fill in after the quiz)* — What did you learn? · What confused you? · What would you do differently?

---

## Search Keywords For Further Understanding

**Core**
- `nmcli persistent network config`
- `linux network namespaces veth bridge`
- `nsswitch.conf resolution order`
- `iproute2 ip ss cheat sheet`
- `linux policy routing ip rule`

**Tools**
- `ip netns examples`
- `resolvectl getent hosts`
- `/proc/net/dev tcp route`

**Going further (future lessons)**
- `docker networking bridge` · `network troubleshooting method` (L18) · `tcpdump capture` (L20)

**Red / Blue (Lens E):**
- 🔴 `network discovery T1016 T1049`, `etc hosts hijack T1565`, `namespace hide traffic`
- 🔵 `file integrity monitoring etc hosts`, `detect new interface`, `baseline network config`

---

## Lesson Status
- [ ] §8 lab completed (net_diag v2 + netns bridge lab)
- [ ] §4 drill done (persistence)
- [ ] Evidence committed (§9)
- [ ] Quiz answered + professional-answer comparisons (graded)
- [ ] Reflection + Search Keywords reviewed

When complete, run the Update Protocol, then move to **Lesson 18 — Network Troubleshooting Method**.

---

*Lesson 17 written by Navi · 2026-06-20 · full-depth. Sources to cite when worked: man7.org
ip/ss/network_namespaces, NetworkManager docs, RHCSA objectives, MITRE ATT&CK T1016/T1049/T1565.*
