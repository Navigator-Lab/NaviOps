# Lesson 29 — Pure Practical: VPN Technologies

> **Companion to [`README.md`](./README.md).** Pure practice: 3 scenario tasks, guided → ticket-driven
> → on-call. **Lab:** WireGuard between two netshoot hosts (`clab-h1`/`clab-h2`) — container-to-container,
> offline. **Rules:** type it, diagnose before you fix, run ✅ **Verify** each task.

Each task: **Scenario · Objective · Given/constraints · Hints · ✅ Verify · Pitfalls · 🎯 Stretch.**

---

## Task 1 — Guided: a WireGuard tunnel between two hosts (fluency)

**Scenario.** `NOC-291`. Build an encrypted tunnel so two hosts communicate over a private overlay.

**Objective.** A WireGuard tunnel up (handshake) with traffic flowing over the overlay addresses.

**Given / constraints.** Keypairs per peer; correct `AllowedIPs`. Private keys never leave the host.

**Hints.**
1. `wg genkey | tee priv | wg pubkey > pub` on each; build `wg0` with `ip link add wg0 type wireguard`.
2. Set peers with each other's pubkey + `AllowedIPs` covering the overlay.
3. `wg show` → handshake; ping the overlay IP.

✅ **Verify.**
```bash
docker exec clab-h1 sh -c 'wg show 2>/dev/null | grep -qi "latest handshake"' && echo "TUNNEL UP ✅"
docker exec clab-h1 ping -c2 <peer-overlay-ip> >/dev/null && echo "TRAFFIC FLOWS ✅"
```

**Pitfalls.**
- Copying the *private* key to the peer (only pubkeys are exchanged).
- `AllowedIPs` too narrow → no routing over the tunnel.
- Committing real keys (guardrail).

🎯 **Stretch.** Add a third peer; reason about the hub-and-spoke `AllowedIPs` layout.

---

## Task 2 — Ticket-driven: "VPN connects but no traffic" (diagnose → fix)

**Scenario.** `NOC-292` (P2). Handshake succeeds but you can't reach the remote subnet. Split-tunnel /
routing / forwarding issue — find it.

**Objective.** Get traffic flowing, identifying `AllowedIPs`, routing, or `ip_forward` — diagnose first.

**Given / constraints.** Recreate: narrow `AllowedIPs` / forwarding off. Fix the specific cause.

**Hints.**
1. `wg show` handshake + transfer counters (bytes moving?).
2. `AllowedIPs` covers the remote subnet? Route present?
3. Gateway peer needs `net.ipv4.ip_forward=1`.

✅ **Verify.**
```bash
docker exec clab-h1 ping -c2 <remote-subnet-host> >/dev/null && echo "REMOTE REACHABLE ✅"
```

**Pitfalls.**
- Handshake success mistaken for "working".
- `AllowedIPs` = just the peer, not its subnet.
- Forwarding disabled on the gateway peer.

🎯 **Stretch.** Compare WireGuard vs IPsec trade-offs (simplicity vs interop).

---

## Task 3 — On-call: tunnel down / rekey failure (synthesis)

**Scenario.** `NOC-293` (P1, time-boxed). A site-to-site tunnel dropped; sites are cut off. Restore it,
determine why (key mismatch, endpoint change, MTU), and document.

**Objective.** Bring the tunnel back, root-cause the drop, verify both directions, write a note.

**Given / constraints.** Recreate a break (wrong pubkey/endpoint, or MTU black-holing large packets).
Fix the cause.

**Hints.**
1. `wg show` — no handshake = key/endpoint problem. Handshake but big transfers fail = MTU.
2. Fix key/endpoint; for MTU set `wg0` MTU lower (e.g. 1380).
3. Verify small + large packets both cross.

✅ **Verify.**
```bash
docker exec clab-h1 sh -c 'wg show | grep -qi "latest handshake"' && docker exec clab-h1 ping -M do -s 1200 -c2 <peer-overlay-ip> >/dev/null && echo "RESTORED (incl large pkts) ✅"
test -f docs/learning/reports/NOC-293-tunnel.md && echo "REPORT ✅"
```

**Deliverable.** `docs/learning/reports/NOC-293-tunnel.md`: Impact · root cause · fix · prevention.

**Pitfalls.**
- Ignoring MTU (works small, fails big → app timeouts).
- Wrong endpoint after an IP change.
- No monitoring on handshake age.

🎯 **Stretch.** Add a keepalive (`PersistentKeepalive`) for NAT'd peers and explain why.

---

## Done?
- [ ] All ✅ Verify pass · [ ] handshake + data both confirmed · [ ] tunnel note written.
- [ ] **Guardrails:** lab only; never commit VPN keys/PSKs. → [README Reflection](./README.md).
