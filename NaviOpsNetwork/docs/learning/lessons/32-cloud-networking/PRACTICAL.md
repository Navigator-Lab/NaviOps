# Lesson 32 — Pure Practical: Cloud Networking

> **Companion to [`README.md`](./README.md).** Pure practice: 3 scenario tasks, guided → ticket-driven
> → on-call.
>
> **⚠️ Offline-first (no cloud spend).** Use **LocalStack** + `awslocal` for VPC/subnet/route-table/SG
> API practice — the topology + rule logic transfer 1:1 to real cloud. Never commit real IDs/IPs.
> **Rules:** type it, diagnose before you fix, run ✅ **Verify** each task.

Each task: **Scenario · Objective · Given/constraints · Hints · ✅ Verify · Pitfalls · 🎯 Stretch.**

---

## Task 1 — Guided: a cloud VPC with public/private subnets (fluency)

**Scenario.** `NOC-321`. Build the standard cloud 2-tier network: public + private subnet, IGW, route
tables — the cloud version of the lab topology.

**Objective.** VPC + 2 subnets + IGW + routes; private subnet has no IGW route.

**Given / constraints.** LocalStack. `10.0.0.0/16` VPC. Private subnet isolated from the IGW.

**Hints.**
1. `awslocal ec2 create-vpc/create-subnet/create-internet-gateway/attach`.
2. Public route table: `0.0.0.0/0` → IGW, associate to public subnet only.
3. `describe-route-tables` to confirm isolation.

✅ **Verify.**
```bash
awslocal ec2 describe-subnets --query 'Subnets[].CidrBlock'
awslocal ec2 describe-route-tables --query 'RouteTables[].Routes[].GatewayId' | grep -qi igw && echo "IGW ROUTE (public) ✅"
```

**Pitfalls.**
- IGW route on the private subnet → not private.
- Overlapping CIDRs.
- IGW not attached to the VPC.

🎯 **Stretch.** Add a NAT gateway concept for private-subnet outbound-only access.

---

## Task 2 — Ticket-driven: "cloud instance unreachable" (diagnose → fix)

**Scenario.** `NOC-322` (P2). A public instance won't accept connections. Isolate SG vs NACL vs route vs
public-IP — the cloud reachability chain.

**Objective.** Restore reachability by fixing the specific layer — diagnose first.

**Given / constraints.** LocalStack. Recreate one fault (SG missing rule / no public route). Fix it.

**Hints.**
1. SG (stateful) inbound rule for the port? NACL (stateless, needs in+out)?
2. Subnet route to IGW? Instance has a public IP?
3. Fix the one that's wrong.

✅ **Verify.**
```bash
awslocal ec2 describe-security-groups --query 'SecurityGroups[].IpPermissions[?ToPort==`80`]' | grep -q 80 && echo "SG ALLOWS 80 ✅"
```

**Pitfalls.**
- SG (stateful) vs NACL (stateless) confusion.
- Private-subnet instance with no public IP.
- Opening everything to fix one port.

🎯 **Stretch.** Explain security-group referencing (SG-to-SG rules) vs CIDR rules.

---

## Task 3 — On-call: overly-open cloud network found in audit (synthesis)

**Scenario.** `NOC-323` (P1, time-boxed). Audit finds an SG open `0.0.0.0/0` on all ports. Close it
without cutting the app; document.

**Objective.** Replace the wide rule with least-exposure, confirm app still works, write a note.

**Given / constraints.** LocalStack. Add scoped rule before revoking the wide one.

**Hints.**
1. Find wide rules (`-1` from `0.0.0.0/0`).
2. Add the scoped replacement, then revoke the wide one.
3. Confirm intended flow allowed, world-open closed.

✅ **Verify.**
```bash
awslocal ec2 describe-security-groups --query 'SecurityGroups[].IpPermissions[?IpProtocol==`-1`]' | grep -q Cidr && echo "STILL WIDE ❌" || echo "LOCKED DOWN ✅"
test -f docs/learning/reports/NOC-323-cloud-exposure.md && echo "REPORT ✅"
```

**Deliverable.** `docs/learning/reports/NOC-323-cloud-exposure.md`: exposed rule · scope applied · verify · prevention.

**Pitfalls.**
- Revoke-first → outage; add scoped rule first.
- SSH/RDP to `0.0.0.0/0` (top breach vector).
- Another attached SG still holds the hole.

🎯 **Stretch.** Script an SG linter that flags any `0.0.0.0/0` on sensitive ports.

---

## Done?
- [ ] All ✅ Verify pass (LocalStack) · [ ] diagnosed the layer · [ ] exposure note written.
- [ ] **No cloud spend; no real IDs/IPs committed.** → [README Reflection](./README.md).
