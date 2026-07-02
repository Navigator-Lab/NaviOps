# Lesson 28 — Pure Practical: Network Security Fundamentals

> **Companion to [`README.md`](./README.md).** Pure practice: 3 scenario tasks, guided → ticket-driven
> → on-call. **Lab:** the topology + firewalls (`nftables`) on `clab-r1`/hosts. **Rules:** type it,
> diagnose before you fix, run ✅ **Verify** each task.

Each task: **Scenario · Objective · Given/constraints · Hints · ✅ Verify · Pitfalls · 🎯 Stretch.**

---

## Task 1 — Guided: segment and least-privilege the network (fluency)

**Scenario.** `NOC-281`. Apply defense-in-depth basics: segment traffic and default-deny between zones.

**Objective.** A policy allowing only intended inter-zone flows; everything else denied.

**Given / constraints.** Default-deny between segments; allow the specific required flow.

**Hints.**
1. Identify the intended flows (h1→service on h2 only).
2. Router firewall: default drop forward, allow the one flow + established.
3. Test allowed + a denied flow.

✅ **Verify.**
```bash
docker exec clab-h1 nc -vz 10.10.2.10 <allowed> 2>&1 | grep -qi succeeded && echo "ALLOWED OK ✅"
docker exec clab-h1 nc -vz 10.10.2.10 <denied> 2>&1 | grep -qi 'refused\|timed out' && echo "DENIED OK ✅"
```

**Pitfalls.**
- Allow-all "temporarily".
- Forgetting established/return traffic.
- Segmentation with no enforcement (VLAN without ACL).

🎯 **Stretch.** Add egress filtering (not just ingress) — often forgotten.

---

## Task 2 — Ticket-driven: "unexpected traffic between segments" (diagnose → fix)

**Scenario.** `NOC-282` (P2). *"A host is reaching a zone it shouldn't."* A segmentation gap. Find and
close it.

**Objective.** Identify the leaking flow and close it without breaking legitimate traffic — diagnose
first.

**Given / constraints.** Recreate an over-permissive rule. Tighten to intent.

**Hints.**
1. Capture the unexpected flow (`tcpdump`), find the rule allowing it (`nft ... -a` counters).
2. Tighten/remove that rule.
3. Re-test: leak closed, legit flow intact.

✅ **Verify.**
```bash
docker exec clab-h1 nc -vz 10.10.2.10 <should-be-denied> 2>&1 | grep -qi 'refused\|timed out' && echo "LEAK CLOSED ✅"
```

**Pitfalls.**
- A broad early allow shadowing specific denies (rule order).
- Closing the leak but breaking a legit flow.
- Not verifying with an actual connection test.

🎯 **Stretch.** Add logging on denied flows to catch future attempts.

---

## Task 3 — On-call: scan/recon activity detected (synthesis)

**Scenario.** `NOC-283` (P1, time-boxed). Port-scan / recon traffic spotted from a host. Detect the
pattern, contain the source, and document with IoCs.

**Objective.** Confirm the scan signature, block/contain the source, and write a note with indicators.

**Given / constraints.** Simulate with `nmap` from one host; detect on the target/router. Contain by
rule, preserve evidence.

**Hints.**
1. Signature: many SYNs to many ports from one source (`tcpdump`/counters).
2. Contain: firewall-block the source (scoped), log it.
3. Record source IP/MAC, ports hit, time.

✅ **Verify.**
```bash
docker exec clab-h1 nmap -Pn -p1-100 10.10.2.10 >/dev/null 2>&1; echo "scan generated"
test -f docs/learning/reports/NOC-283-recon.md && echo "REPORT ✅"
```

**Deliverable.** `docs/learning/reports/NOC-283-recon.md`: scan evidence · source IoCs · containment · prevention.

**Pitfalls.**
- Blocking overly broadly (collateral).
- No evidence captured before blocking.
- Missing that recon often precedes a real attack (escalate).

🎯 **Stretch.** Add a rate-limit/portscan detection rule that auto-flags this pattern.

---

## Done?
- [ ] All ✅ Verify pass · [ ] leak closed without breakage · [ ] recon note with IoCs.
- [ ] **Guardrails:** lab only; fake IoCs. → [README Reflection](./README.md).
