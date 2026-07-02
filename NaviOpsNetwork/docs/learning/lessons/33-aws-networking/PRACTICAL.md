# Lesson 33 — Pure Practical: AWS Networking

> **Companion to [`README.md`](./README.md).** Pure practice: 3 scenario tasks, guided → ticket-driven
> → on-call.
>
> **⚠️ Offline-first (no cloud spend).** Use **LocalStack** + `awslocal` (VPC, subnets, route tables,
> SGs, NACLs, VPC peering, endpoints are modeled). Concepts transfer 1:1 to real AWS. Never commit real
> account data. **Rules:** type it, diagnose before you fix, run ✅ **Verify** each task.

Each task: **Scenario · Objective · Given/constraints · Hints · ✅ Verify · Pitfalls · 🎯 Stretch.**

---

## Task 1 — Guided: connect two VPCs with peering (fluency)

**Scenario.** `NOC-331`. Two VPCs must communicate privately. Create a peering connection and the
routes that make it work.

**Objective.** A peering connection (accepted) + routes both ways so subnets can reach each other.

**Given / constraints.** LocalStack. Non-overlapping VPC CIDRs. Routes on both sides.

**Hints.**
1. `awslocal ec2 create-vpc-peering-connection` + `accept-vpc-peering-connection`.
2. Add routes in each VPC's route table pointing the peer CIDR at the pcx.
3. `describe-vpc-peering-connections` = active.

✅ **Verify.**
```bash
awslocal ec2 describe-vpc-peering-connections --query 'VpcPeeringConnections[].Status.Code' | grep -qi active && echo "PEERING ACTIVE ✅"
awslocal ec2 describe-route-tables --query 'RouteTables[].Routes[].VpcPeeringConnectionId' | grep -qi pcx && echo "ROUTES ADDED ✅"
```

**Pitfalls.**
- Overlapping CIDRs → peering can't route.
- Peering active but no routes added (the common miss).
- Peering is not transitive (A-B, B-C ≠ A-C).

🎯 **Stretch.** Compare peering vs Transit Gateway for many-VPC topologies.

---

## Task 2 — Ticket-driven: "peered VPCs still can't talk" (diagnose → fix)

**Scenario.** `NOC-332` (P2). Peering shows active but instances can't reach across. Find the missing
piece.

**Objective.** Establish cross-VPC connectivity, identifying missing routes, SG/NACL, or DNS —
diagnose first.

**Given / constraints.** Recreate: peering active but no route / SG blocks. Fix the specific gap.

**Hints.**
1. Routes on *both* route tables? SG allows the peer CIDR? NACL both directions?
2. Peering active ≠ reachable — routes + SG must permit.
3. Fix and confirm.

✅ **Verify.**
```bash
awslocal ec2 describe-route-tables --query 'RouteTables[].Routes[?VpcPeeringConnectionId!=`null`]' | grep -qi pcx && echo "ROUTES OK ✅"
```

**Pitfalls.**
- Adding a route on one side only.
- SG referencing the wrong CIDR.
- Assuming active peering = working.

🎯 **Stretch.** Add a VPC endpoint for a service and reason about keeping traffic off the internet.

---

## Task 3 — On-call: cross-VPC exposure / misroute (synthesis)

**Scenario.** `NOC-333` (P1, time-boxed). A misconfiguration exposes one VPC's resources to another it
shouldn't reach (or routes traffic wrong). Contain and document.

**Objective.** Identify the offending route/SG, restore intended isolation, verify, write a note.

**Given / constraints.** LocalStack. Recreate an over-broad route/SG. Tighten to intent.

**Hints.**
1. Map intended vs actual routes/SG rules.
2. Remove/scope the offending route or SG rule.
3. Confirm the unintended path is gone, intended stays.

✅ **Verify.**
```bash
awslocal ec2 describe-route-tables --query 'RouteTables[].Routes[]' | grep -c pcx   # only intended peering routes remain
test -f docs/learning/reports/NOC-333-vpc-exposure.md && echo "REPORT ✅"
```

**Deliverable.** `docs/learning/reports/NOC-333-vpc-exposure.md`: misconfig · intended vs actual · fix · prevention.

**Pitfalls.**
- Over-broad peering routes bridging more than intended.
- Removing a route and breaking a legit path.
- No baseline of intended routes.

🎯 **Stretch.** Propose SCP/Config-rule guardrails that would block the misconfig org-wide.

---

## Done?
- [ ] All ✅ Verify pass (LocalStack) · [ ] routes+SG both checked · [ ] exposure note written.
- [ ] **No cloud spend; no account data committed.** → [README Reflection](./README.md).
