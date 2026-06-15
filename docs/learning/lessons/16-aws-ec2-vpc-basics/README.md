# Lesson 16 — AWS EC2 & VPC Basics

**Status:** ready for self-study · **Date written:** 2026-06-11
**Gate Rule:** Concept → Real-World Use → Alternatives → Hands-On → Verification → Quiz → Reflection → Search Keywords

> **How to use this lesson:** same as Lessons 03–15. This lesson is where
> Lessons 08/09 (subnetting, NAT, firewalls) become directly applicable —
> you'll design a small VPC and recognize the same concepts at AWS scale.

---

## Step 1 — Concept

### What it is

**EC2 (Elastic Compute Cloud)** = AWS's virtual machine service — rent a
server (instance) by the hour/second. **VPC (Virtual Private Cloud)** = your
own isolated, logically-separated network within AWS, where you define IP
ranges (CIDR — Lesson 08), subnets, route tables, and gateways.

### Why it exists

EC2 gives you the "server" from Lessons 01-14, but in the cloud, **without a
network around it you control, that server is either unreachable or directly
exposed to the entire internet**. VPC gives you the same networking concepts
you learned in Lessons 08-09 (subnets, routing, firewalls) — but as
software-defined infrastructure you provision in seconds instead of physically
wiring switches/routers.

### What problem it solves

| Problem | Solution |
|---|---|
| "I need a Linux server in the cloud, on-demand" | EC2 instance |
| "My database shouldn't be reachable from the internet, only from my app server" | Private subnet + security groups |
| "My app server needs internet access, but the database doesn't" | Public subnet (with Internet Gateway) for app, private subnet (no IGW route) for DB |
| "Only I should be able to SSH into my instance" | Security group: allow port 22 only from my IP |
| "I need a second layer of network filtering at the subnet level" | NACLs (Network ACLs) |

### Three-Level Depth (Lens A)

- **Level 1 — Beginner:** Launch an EC2 instance: choose an **AMI** (Amazon
  Machine Image — a pre-configured OS template, e.g., AlmaLinux/Ubuntu),
  **instance type** (size — `t2.micro`/`t3.micro` are Free Tier eligible), a
  **key pair** (for SSH — same `ed25519` keys from Lesson 07), and a
  **security group** (firewall rules). A **VPC** has a CIDR block (e.g.,
  `10.0.0.0/16`, Lesson 08), divided into **subnets** (e.g., `10.0.1.0/24`
  public, `10.0.2.0/24` private).
- **Level 2 — SysAdmin:** Per [AWS's security groups docs](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-security-groups.html)
  and [cloudviz's Security Group vs NACL comparison](https://cloudviz.io/blog/aws-security-group-vs-nacl):
  **Security Groups** operate at the **instance/ENI level**, are **stateful**
  (return traffic automatically allowed — directly analogous to `conntrack`
  from Lesson 09's NAT discussion), and only support **Allow** rules (no
  explicit Deny — anything not allowed is implicitly denied). **NACLs** operate
  at the **subnet level**, are **stateless** (you must explicitly allow both
  inbound AND outbound/return traffic — like writing both directions of an
  `iptables` rule manually), and support both **Allow and Deny** rules,
  evaluated in **rule-number order**. Best practice: use NACLs as a coarse
  first layer (subnet-wide baseline), security groups as fine-grained
  per-instance rules — defense in depth, the same principle as Lesson 10. **An
  Internet Gateway (IGW)** attached to the VPC + a **route table** entry
  (`0.0.0.0/0 -> igw-xxxx`) on a subnet makes it "public." A subnet **without**
  that route is "private" — its instances have no direct internet path.
  **Critical security rule** (per [AWS's own guidance](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-security-groups.html)):
  never set SSH/RDP security group rules to `0.0.0.0/0` (anyone on the
  internet) — restrict to your own IP, exactly like Lesson 09's `ufw allow from
  <your-subnet> to any port 22`.
- **Level 3 — Systems/Kernel (Lens D):** Conceptually, a VPC's subnets, route
  tables, and security groups are AWS's **managed, software-defined** version
  of the exact primitives from Lessons 08-09: CIDR blocks (Lesson 08's subnet
  math applies directly to VPC/subnet sizing), routing tables (Lesson 09's `ip
  route`, but managed per-subnet by AWS), and stateful firewall rules
  (Lesson 09's `conntrack`/connection-tracking — security groups' "stateful"
  behavior is the cloud-managed equivalent). The actual underlying
  virtualization (Nitro hypervisor, etc.) is abstracted away — but the
  **mental model you built manually in Lessons 08-09 transfers directly** to
  reading/designing a VPC.

### Analogy (Lens B)

- **VPC** = your own private office building, built on land you lease (AWS's
  data center) — you design the floor plan (subnets), decide which floors have
  exterior doors to the street (public subnets with IGW routes) and which don't
  (private subnets).
- **Security Group** = a receptionist at each office door who remembers who
  they let in and automatically lets the **same person's response** back out
  (stateful) — but has only an "allow list," no "deny list" (implicit deny for
  everyone else).
- **NACL** = a security checkpoint at the building's floor entrance that checks
  **every** person entering or leaving against a numbered list of explicit
  allow/deny rules, with **no memory** of previous visits (stateless) — you
  must list both "people allowed to enter" and "people allowed to exit" rules
  separately.
- **Internet Gateway** = the building's only door to the public street — floors
  (subnets) with a hallway connecting to that door are "public"; floors without
  that connection are "private," reachable only from inside the building.

The building analogy holds well structurally but breaks down for **NACL rule
ordering** (lowest rule number evaluated first, first match wins, like an
ordered list of bouncers each checking one specific thing) — that precise
"first match wins, ordered" mechanism doesn't have a perfect physical-security
equivalent.

---

## Step 2 — Real-World Use

### How SysAdmins use this daily

```bash
# AWS CLI examples (read-only / planning)
aws ec2 describe-instances
aws ec2 describe-vpcs
aws ec2 describe-subnets --filters "Name=vpc-id,Values=<VPC_ID>"
aws ec2 describe-security-groups --group-ids <SG_ID>
aws ec2 describe-route-tables --filters "Name=vpc-id,Values=<VPC_ID>"

# SSH into an EC2 instance (same as Lesson 07, just a cloud IP)
ssh -i ~/.ssh/my-ec2-key.pem ec2-user@<PUBLIC_IP>
```

**Real production scenarios:**
1. **Three-tier architecture** — public subnet (load balancer/bastion), private
   subnet (app servers), private subnet (database) — each tier's security group
   only allows traffic from the tier in front of it.
2. **Bastion host pattern** — instead of exposing every instance's SSH to the
   internet, one hardened "bastion" host in a public subnet is the only SSH
   entry point; it then SSHs onward to private instances.
3. **"Why can't my app reach the database?"** — debug using the same bottom-up
   approach from Lesson 08: is there a route between the subnets? Does the
   DB's security group allow inbound from the app's security group (you can
   reference a security group as the source, not just an IP/CIDR)?

### Common mistakes

| Mistake | Impact | Fix |
|---|---|---|
| Security group allows SSH from `0.0.0.0/0` | Anyone on the internet can attempt SSH (brute-force target) | Restrict to your IP/CIDR (`<YOUR_IP>/32`) |
| Putting a database in a public subnet | Direct internet exposure of sensitive data | Databases belong in private subnets, no IGW route |
| Confusing "stateful" (security groups) with "stateless" (NACLs) | Forgetting outbound NACL rules for return traffic — connections mysteriously fail | Remember NACLs need explicit rules for **both directions** |
| Launching instances outside the Free Tier (`t2.micro`/`t3.micro`) while learning | Unexpected charges (ties to Lesson 15) | Stick to Free Tier instance types; terminate instances when not in use |
| Forgetting to terminate (not just stop) instances/resources after a lab | Stopped EBS volumes still incur storage charges | `terminate`, and check for orphaned EBS volumes/Elastic IPs |

### When NOT to over-engineer

- For a single learning instance, a single public subnet with a tightly-scoped
  security group is fine — full three-tier VPC design matters once you have
  multiple interacting services (Lesson 24-25).

### Interview Angle

**Scenario:** "We launched an EC2 instance in a public subnet, security group
allows port 22 from `0.0.0.0/0`, but our app server still can't reach the
database in a private subnet. Walk me through your debugging."

A junior answer jumps straight to "check the security group" and stops once
inbound SSH looks fine — missing that the question is about app-to-DB
traffic, not SSH. A senior answer works bottom-up: confirm the DB subnet's
route table, then check whether the DB's security group allows inbound from
the **app server's security group** (not just a CIDR — referencing a security
group as the source is the AWS-specific detail juniors often don't know
exists), then verify NACLs allow both directions (stateless — return traffic
needs explicit rules), and separately flags the `0.0.0.0/0` SSH rule as a
finding regardless of whether it's the root cause — because leaving it
unaddressed is itself a problem.

---

## Step 3 — Alternatives

| Topic | Alternative | Note |
|---|---|---|
| EC2 (this lesson) | **Lightsail** (simplified VPS), **ECS/Fargate** (containers without managing servers) | EC2 is the foundational building block — understand it first |
| Manually configuring VPC via console | **Terraform** (Lesson 20) | Console is fine for learning the concepts; real environments use IaC |
| Security Groups + NACLs | **AWS Network Firewall** | Advanced, for complex multi-VPC traffic inspection — beyond junior scope |

---

## Step 4 — Hands-On Task (build this yourself)

**Goal:** Design and launch a minimal VPC (1 public subnet) with one Free-Tier
EC2 instance, security group following least-privilege (Lesson 15), and SSH
access via your Lesson 07 key.

### Lens C — Manual → Automated → Why

This lesson is console/CLI-driven (manual), but **document your design** the
way you'll express it in Terraform in Lesson 20 — write out, in
`docs/aws/vpc-design.md`:
- VPC CIDR (e.g., `10.0.0.0/16`)
- Public subnet CIDR (e.g., `10.0.1.0/24`) — apply Lesson 08's subnet math
- Security group rules (table: port, protocol, source, purpose)
- Route table entries

This document **becomes your Terraform plan's spec** in Lesson 20 — Lens C's
"why" here is "design on paper/markdown first, implement as code later."

### What to build, step by step

1. In the AWS console (or CLI), create a VPC with CIDR `10.0.0.0/16` (or use
   the default VPC for simplicity if just starting — note in your doc which you
   chose and why).
2. Create a public subnet (`10.0.1.0/24`), attach an Internet Gateway, add a
   route `0.0.0.0/0 -> igw`.
3. Create a security group: allow inbound SSH (port 22) **only from your own
   IP** (`curl ifconfig.me` to find it), allow inbound HTTP (port 80) from
   `0.0.0.0/0` only if you plan to test a web server.
4. Launch a `t3.micro` (Free Tier) EC2 instance with an AlmaLinux/Ubuntu AMI,
   your Lesson 07 SSH key pair, in the public subnet, with this security group.
5. SSH in: `ssh -i ~/.ssh/<key>.pem <user>@<public-ip>`.
6. Run `scripts/hardening_audit.sh` (Lesson 10) on this fresh instance —
   compare its baseline to your local lab VM's.
7. Document the design in `docs/aws/vpc-design.md` (redacted — `<ACCOUNT_ID>`,
   `<PUBLIC_IP>` placeholders).
8. **Terminate the instance** when done with verification (Free Tier is
   time-limited — don't leave it running unnecessarily).
9. Commit `docs/aws/vpc-design.md` on `lesson/16-aws-ec2-vpc-basics`.

---

## Step 5 — Verification

```bash
# Confirm your IP is what the security group allows
curl ifconfig.me

# SSH connectivity
ssh -i ~/.ssh/<key>.pem <user>@<public-ip> "uptime"

# Run Lesson 10's audit on the fresh cloud instance
ssh -i ~/.ssh/<key>.pem <user>@<public-ip> "bash -s" < scripts/hardening_audit.sh

# CLI confirmation of security group rules
aws ec2 describe-security-groups --group-ids <SG_ID> --query 'SecurityGroups[0].IpPermissions'
```

### Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| SSH times out | Security group doesn't allow port 22 from your IP, or instance in private subnet with no route | Check security group inbound rules; confirm subnet has IGW route |
| SSH "Permission denied (publickey)" | Wrong username for the AMI (`ec2-user` for AlmaLinux/RHEL-based, `ubuntu` for Ubuntu AMIs), or wrong key | Match username to AMI vendor; verify `.pem` file permissions (`chmod 400`) |
| Instance launches but no public IP | Subnet's "auto-assign public IP" disabled | Enable auto-assign public IP on the subnet, or assign an Elastic IP |
| Unexpected charge appears | Instance left running, or Elastic IP not associated with a running instance (charged when idle) | Terminate unused instances; release unassociated Elastic IPs |

### Redaction check ✅

`docs/aws/vpc-design.md`: replace your real public IP with `<PUBLIC_IP>`, your
account ID with `<ACCOUNT_ID>`, and any real VPC/subnet/security-group IDs with
placeholders (`vpc-xxxxxxxx`).

---

## Step 6 — Quiz (Interview-Style, Graded)

**Q1.** What's the difference between a **security group** and a **NACL**? Name
one thing each can do that the other can't.

> **Your answer:**

**Q2.** **Scenario:** You launch an EC2 instance in a subnet, but you can't SSH
into it from your laptop. The security group allows port 22 from `0.0.0.0/0`.
What are 3 other things you'd check?

> **Your answer:**

**Q3.** What makes a subnet "public" vs "private" in AWS — what specific
configuration determines this? (Tie back to Lesson 09's NAT/routing concepts.)

> **Your answer:**

**Q4.** Why is "stateful" (security groups) different from "stateless" (NACLs)
in practice? Give an example of a rule you'd need to write twice for a NACL
but only once for a security group.

> **Your answer:**

**Q5.** A junior engineer sets a security group's SSH rule to `0.0.0.0/0`
"to make testing easier." What's the risk, and what should they do instead?
(Tie back to Lesson 07's SSH hardening and Lesson 10's hardening.)

> **Your answer:**

**Q6.** How does VPC subnet CIDR design relate to the subnet math you practiced
in Lesson 08? Give an example: if your VPC is `10.0.0.0/16`, how would you size
a public and a private subnet?

> **Your answer:**

---

## Step 7 — Reflection

*(Fill in after the quiz)*

- What did you learn?
- What confused you?
- What would you do differently?

---

## Lens E — Attacker & Defender (Red / Blue)

> Red/Blue framing (Gate Rule **Lens E**, D14). Build *both* mindsets: know how the
> tools in this lesson are abused, and how a defender detects and stops them.
> Frameworks: [GTFOBins](https://gtfobins.github.io/) · [MITRE ATT&CK](https://attack.mitre.org/) · [LOLBAS](https://lolbas-project.github.io/).

**🔴 Attacker (how it's abused — Step 2):** The signature cloud attack: SSRF → **instance metadata** (IMDSv1) → steal the instance role's credentials. Plus wide-open security groups and public AMIs/EBS. ATT&CK **T1552.005** (Cloud Instance Metadata API).

**🔵 Defender (detect & harden — Step 5):** **Require IMDSv2** (hop limit 1), least-privilege security groups (no `0.0.0.0/0` on SSH/RDP), keep instances in private subnets behind a bastion/SSM, and turn on **VPC Flow Logs** to spot scanning and exfil.

## Step 8 — Search Keywords For Further Understanding

**Core**
- `aws vpc subnets route tables explained`
- `security groups vs nacls aws`
- `aws ec2 instance types free tier`
- `aws internet gateway public private subnet`

**Tools**
- `aws cli describe-instances describe-vpcs`
- `aws bastion host pattern`
- `aws elastic ip charges idle`

**Going further (future lessons)**
- `aws s3 bucket policies vs iam policies`
- `terraform aws vpc module`
- `aws three tier architecture security groups`

---

**Red / Blue (Lens E — study attacker & defender in parallel):**
- 🔴 **Red (attacker):** `aws SSRF instance metadata IMDSv1`, `MITRE ATT&CK T1552.005 cloud metadata`, `open security group exploit`, `ec2 metadata credential theft`
- 🔵 **Blue (defender):** `enforce IMDSv2 metadata`, `vpc flow logs`, `security group least privilege`, `aws systems manager session manager bastion`

## Lesson Status

- [ ] Hands-on task completed (Step 4)
- [ ] Verification passed (Step 5)
- [ ] Quiz answered + professional-answer comparisons requested (Step 6)
- [ ] Reflection completed (Step 7)
- [ ] Search Keywords reviewed (Step 8)

When complete, run the Update Protocol, then move to **Lesson 17 — AWS S3, EBS
& Backups**.

---

*Lesson 16 written by Navi v28 · 2026-06-11 · WebSearch sources:
[AWS VPC Security Groups Docs](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-security-groups.html),
[cloudviz Security Group vs NACL](https://cloudviz.io/blog/aws-security-group-vs-nacl),
[Jay Tillu Amazon VPC Security with Subnets, NACL and Security Groups](https://jaytillu.medium.com/understanding-amazon-vpc-security-with-subnets-nacl-and-security-groups-f2baf2f21efc),
[AWS in Plain English VPCs/Security Groups/Route Tables Guide](https://aws.plainenglish.io/stop-getting-lost-in-aws-networking-a-developers-guide-to-vpcs-security-groups-and-route-tables-eca6b338d40b)*
