# Lesson 16 — Pure Practical: AWS EC2 & VPC Basics

> **Companion to [`README.md`](./README.md).** Pure practice: 3 scenario tasks, guided → ticket-driven
> → on-call. Do them after the README.
>
> **⚠️ Offline-first (no cloud spend).** Use **LocalStack** + `awslocal` for VPC/subnet/SG/route-table
> API practice (network topology + SG rules are fully modeled). For instance lifecycle, LocalStack
> mocks EC2 metadata so you can practice the API and IaC without a bill. Never commit real IDs/IPs.
> **Rules:** type it, diagnose before you fix, run ✅ **Verify** each task.

Each task: **Scenario · Objective · Given/constraints · Hints · ✅ Verify · Pitfalls · 🎯 Stretch.**

---

## Task 1 — Guided: build a VPC with public + private subnets (fluency)

**Scenario.** `NAVI-161`. Design the standard 2-tier network: a public subnet (web) and a private
subnet (db) in one VPC, with a route table sending the public subnet to an internet gateway.

**Objective.** VPC + 2 subnets + IGW + route table associations, created and inspectable via the API.

**Given / constraints.** `10.0.0.0/16` VPC, `10.0.1.0/24` public, `10.0.2.0/24` private. Private subnet
has **no** route to the IGW.

**Hints.**
1. `awslocal ec2 create-vpc`; `create-subnet` ×2; `create-internet-gateway` + `attach-internet-gateway`.
2. Route table: `create-route --destination-cidr-block 0.0.0.0/0 --gateway-id <igw>` → associate to the **public** subnet only.
3. `describe-route-tables` to confirm the private subnet has no IGW route.

✅ **Verify.**
```bash
awslocal ec2 describe-subnets --query 'Subnets[].CidrBlock'          # both CIDRs present
awslocal ec2 describe-route-tables --query 'RouteTables[].Routes[].GatewayId'  # IGW on public only
```

**Pitfalls.**
- Putting the IGW route on the private subnet → it's not "private" anymore.
- Overlapping subnet CIDRs.
- Forgetting to attach the IGW to the VPC (route to a detached gateway = black hole).

🎯 **Stretch.** Add a NAT gateway concept: how would the private subnet reach the internet *outbound only*? Diagram the route.

---

## Task 2 — Ticket-driven: "can't reach the web instance" (diagnose → fix, SG vs NACL vs route)

**Scenario.** `NAVI-162` (P2). *"The web server won't accept connections on 80 from the internet."*
Isolate whether it's the security group, the NACL, the route table, or a public-IP issue.

**Objective.** Restore reachability by fixing the specific layer — **diagnose the chain first.**

**Given / constraints.** Recreate: an SG missing the inbound 80 rule (or a NACL denying it, or no
public route). Fix the one that's actually wrong.

**Hints.**
1. SG (stateful) inbound: `describe-security-groups` — is 80 allowed from `0.0.0.0/0`?
2. NACL (stateless, needs in *and* out rules): `describe-network-acls`.
3. Route: does the subnet route `0.0.0.0/0` to the IGW? Does the instance have a public IP?

✅ **Verify.**
```bash
awslocal ec2 describe-security-groups --query 'SecurityGroups[].IpPermissions[?ToPort==`80`]' | grep -q 80 && echo "SG ALLOWS 80 ✅"
awslocal ec2 describe-route-tables --query 'RouteTables[].Routes[?DestinationCidrBlock==`0.0.0.0/0`]' | grep -q igw && echo "ROUTE OK ✅"
```

**Pitfalls.**
- Confusing SG (stateful — reply auto-allowed) with NACL (stateless — need explicit outbound rule too).
- Opening SSH/DB to `0.0.0.0/0` while fixing web access.
- Instance in a private subnet with no public IP — no SG rule will help.

🎯 **Stretch.** Scope the SG so 80 is world-open but 22 is only from your admin CIDR; explain the reasoning.

---

## Task 3 — On-call: a security group is dangerously wide open (synthesis)

**Scenario.** `NAVI-163` (P1, time-boxed). Audit finds an SG allowing `0.0.0.0/0` on all ports (or SSH
to the world). Close the exposure without cutting off legitimate app traffic; document.

**Objective.** Identify the offending rules, replace them with least-exposure rules, confirm the app
still works, and write an incident note.

**Given / constraints.** Recreate an SG with `-1` (all) from `0.0.0.0/0`. Don't strip the rule the app
needs. Snapshot rules before changing.

**Hints.**
1. Inventory: `describe-security-groups`; flag any `0.0.0.0/0` on `-1`/22/3389/db ports.
2. Revoke the wide rule (`revoke-security-group-ingress`), add scoped replacements (`authorize-...`).
3. Confirm the intended app port from the intended source still allowed.

✅ **Verify.**
```bash
awslocal ec2 describe-security-groups --query 'SecurityGroups[].IpPermissions[?IpProtocol==`-1`]' | grep -q Cidr && echo "STILL WIDE OPEN ❌" || echo "LOCKED DOWN ✅"
test -f docs/learning/reports/NAVI-163-postmortem.md && echo "POSTMORTEM ✅"
```

**Deliverable.** `docs/learning/reports/NAVI-163-postmortem.md`: Impact · Detection · Root cause · Fix · Prevention.

**Pitfalls.**
- Revoking the wide rule but leaving the app with no allow → outage. Add the scoped rule first.
- SSH/RDP open to `0.0.0.0/0` — top real-world breach vector.
- Editing one SG while another attached SG still has the hole.

🎯 **Stretch.** Write a script (awslocal + jq) that lists every SG rule open to `0.0.0.0/0` and exits non-zero — an SG linter.

---

## Done?
- [ ] All ✅ Verify pass (LocalStack) · [ ] diagnosed the layer · [ ] least-exposure SGs · [ ] postmortem written.
- [ ] **No real AWS spend; no real IDs/IPs committed.** → [README Step 7](./README.md).
