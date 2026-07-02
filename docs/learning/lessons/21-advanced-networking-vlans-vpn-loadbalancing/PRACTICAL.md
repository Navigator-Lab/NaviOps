# Lesson 21 — Pure Practical: Advanced Networking (VLANs, VPN, Load Balancing)

> **Companion to [`README.md`](./README.md).** Pure practice: 3 scenario tasks, guided → ticket-driven
> → on-call. Do them after the README.
>
> **Lab:** `naviops-web`/`naviops-db` + a small nginx/haproxy container for LB. WireGuard for the VPN
> task (offline, container-to-container). **Rules:** type it, diagnose before you fix, run ✅ **Verify**.

Each task: **Scenario · Objective · Given/constraints · Hints · ✅ Verify · Pitfalls · 🎯 Stretch.**

---

## Task 1 — Guided: load-balance two backends (fluency)

**Scenario.** `NAVI-211`. Put a reverse proxy / load balancer in front of two identical web backends
so traffic is distributed and one backend can die without an outage.

**Objective.** An nginx/haproxy config balancing across two backends, with a health check that pulls a
dead backend out of rotation.

**Given / constraints.** Two backend containers returning identifiable responses. Health check
configured. No single point of failure ignored.

**Hints.**
1. `upstream` block with both backends; `proxy_pass` to it (nginx) or `backend`/`server` (haproxy).
2. Enable active health checks (or `max_fails`/`fail_timeout` in nginx).
3. Curl the LB repeatedly — responses alternate; kill one backend — traffic still served.

✅ **Verify.**
```bash
for i in $(seq 6); do curl -s localhost:8080/whoami; done | sort | uniq -c   # both backends seen
docker stop backend2; sleep 3
curl -sf localhost:8080/ >/dev/null && echo "SURVIVES BACKEND LOSS ✅"; docker start backend2
```

**Pitfalls.**
- No health check → LB keeps sending traffic to a dead backend (502s).
- Session stickiness assumptions when the app isn't stateless.
- Balancing algorithm mismatch (round-robin vs least-conn) for the workload.

🎯 **Stretch.** Add TLS termination at the LB and pass through to plain-HTTP backends; verify with `curl -k`.

---

## Task 2 — Ticket-driven: "the VPN connects but no traffic flows" (diagnose → fix)

**Scenario.** `NAVI-212` (P2). A WireGuard tunnel shows "connected" but you can't reach the other
side's subnet. Classic split-tunnel/routing/firewall issue — find which.

**Objective.** Get traffic flowing across the tunnel, identifying whether it's `AllowedIPs`, routing,
NAT/forwarding, or a firewall drop — **diagnose first.**

**Given / constraints.** Recreate a WireGuard config between two containers with a fault (missing
`AllowedIPs`, `net.ipv4.ip_forward=0`, or no route). Fix the specific cause.

**Hints.**
1. Handshake OK? `wg show` (latest handshake, transfer counters). Handshake but no data → routing/firewall.
2. `AllowedIPs` on each peer must cover the remote subnet (it's both crypto-routing *and* the route).
3. Forwarding: `sysctl net.ipv4.ip_forward` must be 1 for a gateway peer; check firewall FORWARD chain.

✅ **Verify.**
```bash
wg show | grep -q 'latest handshake' && echo "TUNNEL UP ✅"
ping -c2 <remote-tunnel-ip> >/dev/null && echo "TRAFFIC FLOWS ✅"
```

**Pitfalls.**
- Handshake success mistaken for "working" — data still needs routing.
- `AllowedIPs` too narrow (just the peer IP, not its subnet).
- Forwarding disabled on the gateway peer.

🎯 **Stretch.** Add a second peer and reason about the hub-and-spoke `AllowedIPs` layout.

---

## Task 3 — On-call: LB is up but half of requests fail (synthesis)

**Scenario.** `NAVI-213` (P1, time-boxed). Users get intermittent errors through the load balancer.
One backend is unhealthy but still in rotation, or a VLAN/segmentation issue splits traffic. Localize
and fix; document.

**Objective.** Identify which backend/path is failing, pull it from rotation or fix segmentation,
confirm 100% success, and write an incident note.

**Given / constraints.** Make one backend return 500s intermittently. Don't take the whole LB down;
surgically remove/repair the bad backend.

**Hints.**
1. Hit each backend directly (bypass LB) to find the sick one.
2. LB stats/health endpoint (haproxy stats page / nginx logs) — is the health check catching it?
3. Fix the health check threshold so the bad backend is ejected; verify error rate → 0.

✅ **Verify.**
```bash
for i in $(seq 20); do curl -s -o /dev/null -w '%{http_code}\n' localhost:8080/; done | sort | uniq -c   # all 200
test -f docs/learning/reports/NAVI-213-postmortem.md && echo "POSTMORTEM ✅"
```

**Deliverable.** `docs/learning/reports/NAVI-213-postmortem.md`: Impact · Detection · Root cause · Fix · Prevention.

**Pitfalls.**
- A too-lax health check that keeps a flapping backend in rotation.
- Taking the whole LB offline instead of ejecting one backend.
- Not measuring the *rate* (one curl can hit the healthy backend and look fine).

🎯 **Stretch.** Add graceful draining so in-flight requests to the ejected backend complete before removal.

---

## Done?
- [ ] All ✅ Verify pass · [ ] survives backend loss · [ ] error rate → 0 · [ ] postmortem written.
- [ ] **Redaction:** lab IPs/keys only; no real VPN keys committed. → [README Step 7](./README.md).
