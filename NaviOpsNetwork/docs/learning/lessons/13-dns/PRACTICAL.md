# Lesson 13 — Pure Practical: DNS

> **Companion to [`README.md`](./README.md).** Pure practice: 3 scenario tasks, guided → ticket-driven
> → on-call. **Lab:** `dnsmasq`/`bind` on a host serving `net_a`; clients on netshoot (`dig`, `drill`).
> **Rules:** type it, diagnose before you fix, run ✅ **Verify** each task.

Each task: **Scenario · Objective · Given/constraints · Hints · ✅ Verify · Pitfalls · 🎯 Stretch.**

---

## Task 1 — Guided: resolve records and read the query path (fluency)

**Scenario.** `NOC-131`. Query A, AAAA, PTR, MX, and CNAME records and understand the resolver path.

**Objective.** Successfully resolve several record types and read the authority/answer sections.

**Given / constraints.** Use `dig`; note recursion vs authoritative.

**Hints.**
1. `dig A example`, `dig +short`, `dig -x <ip>` (PTR), `dig MX`, `dig CNAME`.
2. `dig +trace` shows root→TLD→authoritative delegation.
3. Note TTLs (caching duration).

✅ **Verify.**
```bash
docker exec clab-h1 sh -c 'dig +short localhost @127.0.0.1 || getent hosts localhost' | grep -q . && echo "RESOLVES ✅"
```

**Pitfalls.**
- Assuming `dig` reflects what apps see (apps use nsswitch/`getent`).
- Ignoring TTL/caching when a record "won't update".
- Confusing recursive resolver vs authoritative server.

🎯 **Stretch.** Trace a name end to end with `dig +trace` and label each delegation hop.

---

## Task 2 — Ticket-driven: "name resolution broken" (diagnose → fix)

**Scenario.** `NOC-132` (P2). *"'could not resolve host' everywhere, but IPs work."* DNS-layer fault.
Find and fix.

**Objective.** Restore resolution, identifying `resolv.conf`, an unreachable server, or blocked 53.

**Given / constraints.** Recreate: bad `/etc/resolv.conf` / blocked UDP-53. Fix the cause.

**Hints.**
1. IP works, name fails → resolution. `cat /etc/resolv.conf`; test the server: `dig @<server> name`.
2. Port 53 reachable? `nc -vzu <server> 53`.
3. Fix the resolver/route; re-test with `getent`.

✅ **Verify.**
```bash
docker exec clab-h1 getent hosts <name> >/dev/null && echo "DNS FIXED ✅"
```

**Pitfalls.**
- Editing a managed `resolv.conf` that gets overwritten (fix the source).
- Testing with ping (ICMP) while DNS/53 is what's blocked.
- Wrong `search` domain breaking short names only.

🎯 **Stretch.** Configure a secondary resolver and prove failover.

---

## Task 3 — On-call: DNS poisoning / wrong answers (synthesis)

**Scenario.** `NOC-133` (P1, time-boxed). Users reach the wrong site — DNS is returning bad answers
(cache poisoning or a rogue resolver). Detect the tampering, restore trusted resolution, document.

**Objective.** Compare answers across resolvers, identify the bad source, switch to a trusted resolver,
and write a note.

**Given / constraints.** Simulate a resolver returning a wrong A record. Compare vs a known-good.

**Hints.**
1. `dig name @bad` vs `dig name @good` — mismatch reveals tampering.
2. Flush caches; point clients at the trusted resolver.
3. Note the poisoned record + blast radius.

✅ **Verify.**
```bash
docker exec clab-h1 sh -c 'dig +short <name> @<trusted>' | grep -q '<expected-ip>' && echo "TRUSTED ANSWER ✅"
test -f docs/learning/reports/NOC-133-dns-poison.md && echo "REPORT ✅"
```

**Deliverable.** `docs/learning/reports/NOC-133-dns-poison.md`: bad answer · source · impact · fix · prevention (DNSSEC).

**Pitfalls.**
- Trusting a single resolver's answer without cross-checking.
- Not flushing caches → poisoned entries persist.
- No DNSSEC/validation → poisoning stays possible.

🎯 **Stretch.** Explain how DNSSEC validation would have rejected the forged record.

---

## Done?
- [ ] All ✅ Verify pass · [ ] cross-checked resolvers · [ ] poisoning note written.
- [ ] **Guardrails:** lab only. → [README Reflection](./README.md).
