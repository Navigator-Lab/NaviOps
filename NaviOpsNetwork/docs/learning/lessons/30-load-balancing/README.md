# Lesson 30 — Load Balancing

**Status:** ✅ ready for self-study (full depth) · **Date written:** 2026-06-20
**Schema:** 12-section (`docs/learning/CLAUDE_TEACHING_RULES.md`)
**Focus:** L4 vs L7, algorithms, health checks, session persistence, HAProxy/nginx, ALB/NLB concepts.
**Primary artifact:** `infra/configs/haproxy.cfg`.
**Difficulty:** **Difficult concept** — §1 uses two teaching approaches + an ASCII diagram (Lens B).

> **How to use this lesson:** load balancing = scale + availability for services. Read §1–§7, build
> an HAProxy LB in front of two backends in §8, test failover + health checks. Lab only.

---

## §1 — Concept (Scientific Theory)

### What it is
A **load balancer (LB)** distributes incoming traffic across multiple backend servers so no single
server is overwhelmed, and so the service survives a backend failure. It presents one **virtual IP
(VIP)** / endpoint to clients and spreads requests to a **pool** of backends using an **algorithm**,
removing unhealthy backends via **health checks**. Two layers: **L4** (transport — distributes by
IP/port, fast, protocol-agnostic) and **L7** (application — reads HTTP host/path/cookies, can route
intelligently and terminate TLS).

### Why it exists
One server has finite capacity and is a single point of failure. To **scale** (handle more load)
and stay **available** (survive failures, deploy without downtime), you run multiple backends — but
clients need one address. The LB provides that single front door while spreading load and routing
around failures. It's foundational to every scalable web service.

### L4 vs L7 (the core distinction)
| | L4 (transport) | L7 (application) |
|---|---|---|
| Decides on | IP + port | HTTP host/path/headers/cookies |
| Speed | very fast (less inspection) | more work, more features |
| Capabilities | TCP/UDP balancing | content routing, TLS termination, WAF, rewrites |
| AWS analog | **NLB** (Network LB) | **ALB** (Application LB) |
| Example | HAProxy/IPVS L4, nginx stream | HAProxy/nginx HTTP, Traefik |

### Algorithms & persistence
- **Algorithms:** round-robin (even rotation), least-connections (to the least-busy backend),
  weighted (capacity-aware), IP-hash (same client → same backend).
- **Health checks:** the LB probes each backend (TCP connect, HTTP 200, Lesson 16) and **removes**
  failing ones from the pool automatically — the availability mechanism.
- **Session persistence ("sticky sessions"):** keep a given client pinned to one backend (via
  cookie or IP-hash) when the app stores session state locally — necessary for stateful apps, but
  reduces even distribution.

### Three-Level Depth (Lens A)
- **Level 1 — Beginner:** a load balancer is like a host at a busy restaurant who seats arriving
  guests across many waiters so no waiter is swamped — and stops sending guests to a waiter who
  went home (health check).
- **Level 2 — NetOps/NOC:** you configure the LB (VIP, backend pool, algorithm, health checks,
  persistence), choose L4 vs L7 for the use case, and troubleshoot the classics: all traffic to one
  backend (bad persistence/algorithm), backends marked down (health-check misconfig vs real
  failure), or uneven load. You monitor backend health + the VIP (an LB or its VIP down = the whole
  service down = Sev1).
- **Level 3 — Wire/Kernel (Lens D):** L4 LBs can operate via **DNAT/NAT** (Lesson 14) or **DSR**
  (direct server return); Linux **IPVS** is an in-kernel L4 LB. L7 LBs (HAProxy/nginx) terminate
  the client TCP+TLS (Lessons 03/16), inspect HTTP, then open a *new* connection to the chosen
  backend — so the backend sees the LB's IP (hence `X-Forwarded-For` to preserve the client IP).
  Health checks are the synthetic probes from Lesson 16/21.

### Two Teaching Approaches (Lens B) — distribution + health-based availability

**Approach 1 (technical):** clients connect to the VIP; the LB selects a backend per the algorithm
(optionally honoring persistence), forwards the request, and returns the response. Continuous health
checks gate pool membership — a backend failing its probe is removed (traffic shifts to the
healthy ones) and re-added when it recovers, giving zero-downtime failure handling and rolling
deploys. L7 LBs additionally inspect/route by application data and can terminate TLS.

**Approach 2 (analogy):** a load balancer is the **host stand at a busy restaurant**.
- The **host** (LB) greets every guest at one door (the VIP) and seats them across many **waiters**
  (backends) so service stays fast — **round-robin** (next waiter in rotation),
  **least-connections** (the waiter with the fewest tables), or **weighted** (the experienced
  waiter gets more).
- **Health checks** = the host notices a waiter clocked out (failed probe) and stops seating their
  section — guests never get sent to an empty table.
- **Sticky sessions** = a returning guest mid-meal goes back to *their* waiter who has their order
  (server-local state) — necessary, but it can unbalance the floor.
- **L4 vs L7** = an L4 host just counts heads and points to a section (fast, blind to the order);
  an L7 host reads the reservation ("vegetarian party → the chef who does veg") — smarter routing,
  more work.
- **Where it breaks down:** a restaurant host is one person; real LBs are themselves made redundant
  (Lesson 31) so the *host stand* isn't a single point of failure — the part this analogy must hand
  off to HA.

### Visual (ASCII) — L7 LB with health checks

```
                         ┌──────── health checks (HTTP 200?) ────────┐
   clients ──► VIP ──► [ LOAD BALANCER (HAProxy) ] ──► backend1 (UP) ◄┘
              :443        algorithm + persistence  ──► backend2 (UP)
              TLS term                              ──► backend3 (DOWN ✗ removed)
   round-robin: req1→b1, req2→b2, req3→b1 ...   (b3 skipped until its health check passes)
   L7: route /api → app pool, /img → static pool; add X-Forwarded-For (preserve client IP)
```

---

## §2 — Linux Networking Commands

```bash
# HAProxy (L4 and L7) — the lab tool
haproxy -c -f infra/configs/haproxy.cfg      # validate config
systemctl status haproxy
echo "show stat" | socat stdio /run/haproxy/admin.sock   # backend health/stats (or the stats page)
# nginx (L7 reverse proxy / LB)
nginx -t                                      # validate
# IPVS (in-kernel L4 LB)
ipvsadm -L -n                                 # show virtual services + real servers
# Test distribution + failover
for i in $(seq 1 6); do curl -s http://<VIP>/whoami; done   # see requests spread across backends
curl -s http://<VIP>/   # then stop a backend and confirm traffic shifts (health check removes it)
```

**Cisco/CCNA mapping:** CCNA references load balancing conceptually; in cloud it's **ALB (L7) /
NLB (L4)** (Lesson 33). Enterprise LBs (F5, Citrix) follow the same L4/L7 + algorithm + health-check
+ persistence model HAProxy teaches.

---

## §3 — Real-World Use Cases

**Production scenarios:**
1. **Scale a web service:** N backends behind a VIP; add capacity by adding backends.
2. **Zero-downtime deploys:** drain a backend (health check fails / set to MAINT), deploy, re-add —
   rolling updates with no outage.
3. **High availability:** a backend dies → health check removes it → users unaffected (pairs with
   Lesson 31 to make the LB itself redundant).
4. **L7 routing + TLS termination:** `/api` → app pool, `/static` → static pool; LB terminates TLS
   (Lesson 16) so backends don't have to.

**How NOC/NetOps engineers use it:** monitoring the VIP + backend pool health (a backend down is a
capacity/redundancy alert; the VIP down is a Sev1), and troubleshooting distribution/persistence/
health-check issues.

**When NOT to:** don't use sticky sessions if the app is stateless (it just unbalances load); don't
make the LB a single point of failure (Lesson 31); don't health-check on the wrong path (false
"down").

**Exam framing (Net+/CCNA):** load-balancing purpose, L4 vs L7, algorithms, health checks, and
session persistence are tested.

---

## §4 — Troubleshooting Section

| Symptom | Likely cause | Diagnose | Fix |
|---|---|---|---|
| All traffic to one backend | persistence/algorithm/others marked down | LB stats (`show stat`) | fix persistence/health checks |
| Backend wrongly marked down | health check path/port wrong | test the health-check URL directly | fix the check |
| Uneven load | algorithm not suited / sticky sessions | review algorithm + persistence | least-conn / drop unneeded stickiness |
| Backend sees LB IP, not client | L7 LB rewrites source | `X-Forwarded-For` header | log/honor XFF |
| Whole service down | the LB/VIP itself failed | check LB process/VIP | LB redundancy (Lesson 31) |

**Redaction check:** lab VIP/backends (RFC-1918) in committed `haproxy.cfg`.

---

## §5 — Common Mistakes

| Mistake | Impact | Fix |
|---|---|---|
| LB is a single point of failure | LB dies = total outage | make the LB redundant (L31) |
| Sticky sessions on a stateless app | uneven load | remove unnecessary persistence |
| Wrong health-check target | false up/down | check the right path/port |
| No health checks | sends users to dead backends | always health-check |
| Losing the client IP (L7) | logging/security blind | preserve via `X-Forwarded-For` |
| L4 when you needed L7 (or vice versa) | missing features / overhead | choose by requirements |

---

## §6 — NOC Perspective

> NOC + Network Operations (Stages 1–2, 4, `ROADMAP.md`).

The LB is a critical chokepoint: a **single backend down** is a capacity/redundancy alert (watch
item — service is fine but margin is reduced, `noc/shift-handover.md`), while the **VIP/LB itself
down** is a Sev1 (whole service offline). The NOC monitors the backend pool health (HAProxy stats /
ALB target health) and recognizes the "all traffic to one backend" and "backend flapping up/down"
(bad health check) signatures. Health-check-driven removal is *why* a single backend failure is
usually invisible to users — a good thing to articulate.

---

## §7 — Incident-Response Perspective

- **Detect:** backend-down (redundancy lost) or VIP-down (service down) alert; or latency rising as
  backends saturate.
- **Triage:** one backend (urgent, not yet impacting) vs the VIP/LB (Sev1).
- **Diagnose:** real backend failure vs health-check misconfig (test the check); LB itself vs
  network path.
- **Contain/Fix → Recover → Document:** drain/replace the backend or fail over the LB (Lesson 31),
  verify pool health + the VIP serves, document. Capacity-exhaustion incidents tie back to
  monitoring (Lesson 21).

---

## §8 — Practical Lab (build this yourself)

**Goal:** put **HAProxy** in front of two backends, configure health checks + an algorithm, test
distribution + failover; document `infra/configs/haproxy.cfg`.

### Lens C — Manual → Automated → Why
- **Manual:** configure HAProxy frontend/backend, run two backends, curl through the VIP.
- **Automated:** a test loop that hits the VIP repeatedly and tallies which backend answered
  (proves distribution), plus a failover test (kill a backend, confirm traffic shifts).
- **Why:** verifying distribution + failover before trusting an LB is essential; production teams
  test LB behavior in a lab/staging. The test loop is your evidence.

### Steps
1. Run two tiny backends that identify themselves (e.g. `python3 -m http.server` serving distinct
   "whoami" pages, or a one-liner that returns the hostname).
2. Write `infra/configs/haproxy.cfg`: a frontend on the VIP:port, a backend pool of the two servers,
   `balance roundrobin` (then try `leastconn`), and an HTTP **health check** (`option httpchk`).
   `haproxy -c -f` to validate.
3. Test distribution: `for i in $(seq 6); do curl -s http://<VIP>/; done` → see both backends answer.
4. **Failover drill:** stop one backend → health check marks it down → all traffic goes to the
   survivor (users unaffected) → restart → it re-joins. Capture the HAProxy stats before/after.
5. (Preview L31) note that the LB itself is now a single point of failure — Lesson 31 makes it HA.

### Lens D — L7 inspection + XFF
Enable L7 features (route by path, add `X-Forwarded-For`); `tcpdump` on a backend to see the LB's IP
as source and the XFF header preserving the real client IP — the L4-vs-L7 boundary made concrete.

---

## §9 — GitHub Artifact (evidence 5-tuple)

1. **Script:** the distribution + failover test loop.
2. **Config:** `infra/configs/haproxy.cfg` (frontend/backend/health-check/algorithm).
3. **Drill:** backend-failover demonstrated (traffic shifts, users unaffected).
4. **NAVI ticket:** `NAVI-30` (Change: "HAProxy load balancer + health checks").
5. **Incident report:** a backend-failure or capacity-saturation runbook.

---

## §10 — Portfolio Artifact

- **Resume bullet:** "Deployed an HAProxy L7 load balancer with health checks and session
  persistence across a backend pool; validated even distribution and transparent backend failover."
- **Interview talking point:** L4 vs L7, algorithms, health-check-driven availability, and the
  sticky-session trade-off (and why the LB itself must be HA) — strong infra signal.
- **Serves:** Jr Network Engineer + Network Operations + Cloud/DevOps (Stages 4, 6); feeds Lesson 31
  + AWS (33).

---

## §11 — RHCSA Crossover Notes

Mostly **N/A for RHCSA** as a topic, but HAProxy/nginx run on RHEL (package/service/firewalld
skills), and **load-balancing concepts + keepalived (Lesson 31)** appear in RHEL HA contexts. The
service-management mechanics overlap with RHCSA.

---

## §12 — Security Notes (Lens E — Attacker & Defender)

> Frameworks: [MITRE ATT&CK](https://attack.mitre.org/).

**🔴 Attacker:** the LB/VIP is a concentrated **DoS target** (`T1498`/`T1499` — take down the VIP,
take down the whole service); L7 LBs that don't preserve/inspect can hide attacker source IPs;
session-fixation/hijacking abuses weak persistence. Exposed LB admin/stats pages leak topology.

**🔵 Defender:** put a **WAF + rate limiting** at the L7 LB, **terminate TLS** there with strong
config, **preserve the client IP** (`X-Forwarded-For`) so detection/logging (Lesson 28) sees the
real source, secure the stats/admin interface, and pair with **HA** (Lesson 31) + upstream
DDoS protection so the VIP isn't a single chokepoint. Verify rate-limiting blunts a (lab) flood.

---

## Quiz (Interview-Style, Graded)

**Q1.** What two problems does a load balancer solve, and how?
> **Your answer:**

**Q2.** L4 vs L7 load balancing — what does each decide on, and what can L7 do that L4 can't?
> **Your answer:**

**Q3.** What do health checks accomplish, and what happens when a backend fails one?
> **Your answer:**

**Q4.** **Scenario:** Despite a round-robin LB, almost all traffic is hitting one backend. Name two
likely causes and how you'd confirm.
> **Your answer:**

**Q5.** What are sticky sessions, when do you need them, and what's the downside?
> **Your answer:**

**Q6.** Why is the load balancer itself a risk, and how do you address it (in availability and
security terms)?
> **Your answer:**

*(After you answer, request the "Professional Answer" comparison under each — graded before Lesson 31.)*

---

## Reflection
*(Fill in after the quiz)* — What did you learn? · What confused you? · What would you do differently?

---

## Search Keywords For Further Understanding

**Core**
- `load balancing l4 vs l7`
- `load balancing algorithms round robin least connections`
- `health checks load balancer`
- `session persistence sticky sessions`
- `haproxy vs nginx load balancing`

**Tools**
- `haproxy configuration tutorial`
- `nginx upstream load balancing`
- `ipvs linux load balancer`

**Going further (future lessons)**
- `high availability keepalived vrrp` (L31) · `aws alb nlb` (L33) · `waf rate limiting`

**Red / Blue (Lens E):**
- 🔴 `dos vip target T1498 T1499`, `session hijacking persistence`, `exposed haproxy stats`
- 🔵 `waf rate limiting l7`, `x-forwarded-for client ip`, `secure load balancer`

---

## Lesson Status
- [ ] §8 lab completed (HAProxy + health checks + failover)
- [ ] §4 drill done (backend failover)
- [ ] Evidence committed (§9)
- [ ] Quiz answered + professional-answer comparisons (graded)
- [ ] Reflection + Search Keywords reviewed

When complete, run the Update Protocol, then move to **Lesson 31 — High Availability**.

---

*Lesson 30 written by Navi · 2026-06-20 · full-depth. Sources to cite when worked: HAProxy/nginx
docs, AWS ELB docs, CompTIA Network+ N10-009, MITRE ATT&CK T1498/T1499.*
