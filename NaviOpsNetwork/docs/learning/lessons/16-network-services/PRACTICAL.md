# Lesson 16 — Pure Practical: Network Services

> **Companion to [`README.md`](./README.md).** Pure practice: 3 scenario tasks, guided → ticket-driven
> → on-call. **Lab:** netshoot hosts (`clab-h1`/`h2`) to run/consume services (HTTP, SSH, NTP, TFTP).
> **Rules:** type it, diagnose before you fix, run ✅ **Verify** each task.

Each task: **Scenario · Objective · Given/constraints · Hints · ✅ Verify · Pitfalls · 🎯 Stretch.**

---

## Task 1 — Guided: stand up and probe a service (fluency)

**Scenario.** `NOC-161`. Run a simple service on h1 and consume it from h2 — the service/consumer model.

**Objective.** A listener on h1 reachable from h2; you can identify the port/owner.

**Given / constraints.** e.g. `python3 -m http.server 8080`. Probe from the peer.

**Hints.**
1. h1: start the service. `ss -tlnp` — confirm it listens on `0.0.0.0`, not `127.0.0.1`.
2. h2: `curl`/`nc -vz clab-h1 8080`.
3. Note the socket (proto/addr/port/pid).

✅ **Verify.**
```bash
docker exec clab-h1 sh -c 'ss -tlnp | grep -q ":8080"' && echo "LISTENING ✅"
docker exec clab-h2 nc -vz clab-h1 8080 2>&1 | grep -qi succeeded && echo "REACHABLE ✅"
```

**Pitfalls.**
- Service bound to `127.0.0.1` → unreachable from peers.
- Firewall blocking the port.
- Confusing the listening port with the client's ephemeral port.

🎯 **Stretch.** Identify a service by banner: `nc clab-h1 8080` and read the response headers.

---

## Task 2 — Ticket-driven: "service is up but clients can't use it" (diagnose → fix)

**Scenario.** `NOC-162` (P2). *"The service process is running but users can't connect."* Bind address,
firewall, or wrong port — find it.

**Objective.** Make the service reachable, identifying the specific blocker — diagnose first.

**Given / constraints.** Recreate: bind to loopback, or firewall the port. Fix the real cause.

**Hints.**
1. `ss -tlnp` on the server — bound to `127.0.0.1` vs `0.0.0.0`?
2. From the client: refused (nothing there) vs timeout (filtered)?
3. Fix bind or firewall; re-test.

✅ **Verify.**
```bash
docker exec clab-h1 ss -tlnp | grep -qE '0.0.0.0:8080|\*:8080' && echo "BOUND CORRECTLY ✅"
docker exec clab-h2 nc -vz clab-h1 8080 2>&1 | grep -qi succeeded && echo "CLIENTS OK ✅"
```

**Pitfalls.**
- "It's running" ≠ "it's reachable" (bind address matters).
- Refused vs timeout misread (opposite causes).
- Checking the wrong port.

🎯 **Stretch.** Add a systemd/health check that verifies the service *and* its reachability.

---

## Task 3 — On-call: time skew (NTP) breaking dependent services (synthesis)

**Scenario.** `NOC-163` (time-boxed). Auth/logs fail intermittently — clocks have drifted. Diagnose the
NTP problem, correct time sync, and document the cascade.

**Objective.** Detect skew, restore sync, and write a note on which services the drift broke.

**Given / constraints.** Inspect offset; correct via NTP. Note dependent breakage (TLS, Kerberos, logs).

**Hints.**
1. `timedatectl` / `chronyc tracking` — offset + sync state.
2. Fix the NTP source/service; confirm offset shrinks.
3. Note what skew breaks (cert validity windows, log correlation, Kerberos tickets).

✅ **Verify.**
```bash
docker exec clab-h1 sh -c 'timedatectl 2>/dev/null | grep -i "synchronized" || date'
test -f docs/learning/reports/NOC-163-time-skew.md && echo "REPORT ✅"
```

**Deliverable.** `docs/learning/reports/NOC-163-time-skew.md`: offset · source fix · dependent services affected · prevention.

**Pitfalls.**
- Ignoring clock skew as a root cause of "random" auth/TLS failures.
- Manually setting time instead of fixing sync (drifts again).
- No monitoring on time offset.

🎯 **Stretch.** Add an alert when offset exceeds a threshold.

---

## Done?
- [ ] All ✅ Verify pass · [ ] bind/firewall diagnosed · [ ] time-skew note written.
- [ ] **Guardrails:** lab only. → [README Reflection](./README.md).
