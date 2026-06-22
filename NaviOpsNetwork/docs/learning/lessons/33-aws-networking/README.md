# Lesson 33 — AWS Networking

**Status:** ✅ ready for self-study (full depth) · **Date written:** 2026-06-20
**Schema:** 12-section (`docs/learning/CLAUDE_TEACHING_RULES.md`)
**Focus:** VPC/subnets/route tables/IGW/NAT GW, SG vs NACL, Route 53, VPC peering/TGW, flow logs.
**Primary artifact:** `docs/networking/aws-vpc-notes.md` (redacted).

> **How to use this lesson:** AWS is the dominant cloud; its VPC is Lesson 32's concepts made
> concrete. Read §1–§7, design a VPC on paper + (optionally, free-tier-aware, human-approved) build
> it in §8. **No spend without explicit approval** (`navi.project.md` danger zone). Redact
> everything before commit.

---

## §1 — Concept (Scientific Theory)

### What it is
**AWS networking** is building networks in Amazon's cloud using the **VPC** (Virtual Private Cloud)
— your isolated virtual network — and its components: **subnets** (public/private, per Availability
Zone), **route tables**, **Internet Gateway (IGW)** for public egress/ingress, **NAT Gateway** for
private-subnet outbound (Lesson 14), **Security Groups** (stateful, instance-level) + **Network
ACLs** (stateless, subnet-level) for filtering (Lesson 15), **Route 53** (managed DNS, Lesson 13),
**VPC peering / Transit Gateway** for connecting VPCs, and **VPC Flow Logs** for traffic visibility
(Lesson 20 analog). It's every fundamental in this curriculum, expressed as AWS services.

### Why it exists
AWS needs a way for customers to define isolated, secure, scalable networks for their workloads on
shared infrastructure. The VPC is that construct. It's the most in-demand cloud-networking skill
(and the bridge to Cloud Support / NetDevOps roles, Stage 6) — and it directly reuses subnetting,
routing, NAT, firewalls, DNS, and HA from earlier lessons.

### The VPC building blocks
| Component | Maps to (earlier lesson) | Role |
|---|---|---|
| **VPC (CIDR)** | a network (Lesson 04) | the isolated address space, e.g. `10.0.0.0/16` |
| **Subnet** | subnet (Lesson 04), per-AZ | public (route to IGW) or private (route to NAT GW) |
| **Route table** | routing (Lesson 07) | per-subnet routes (IGW / NAT GW / peering / local) |
| **Internet Gateway** | the default gateway to the Internet | public ingress/egress |
| **NAT Gateway** | NAT/PAT (Lesson 14) | private subnets reach out, not reachable in |
| **Security Group** | stateful firewall (Lesson 15) | instance-level, stateful, allow-only |
| **Network ACL** | stateless firewall (Lesson 15) | subnet-level, stateless, allow+deny |
| **Route 53** | DNS (Lesson 13) | managed DNS + health-checked routing |
| **ELB (ALB/NLB)** | load balancing (Lesson 30) | L7/L4 managed load balancers |
| **VPC Peering / TGW** | inter-network routing (Lesson 07) | connect VPCs |
| **VPC Flow Logs** | packet/flow capture (Lesson 20) | traffic metadata for monitoring/forensics |
| **Multi-AZ** | high availability (Lesson 31) | survive an AZ failure |

### Three-Level Depth (Lens A)
- **Level 1 — Beginner:** an AWS VPC is your own private network inside Amazon's cloud — you carve
  it into subnets, decide what's public vs private, and control what can talk to what.
- **Level 2 — NetOps/Cloud:** you design a VPC (a `/16`, public + private subnets across ≥2 AZs for
  HA), route public subnets to the IGW and private subnets to a NAT GW, apply least-privilege
  **security groups** + **NACLs**, use **Route 53** for DNS, and enable **flow logs**. You
  troubleshoot reachability with the same bottom-up method using AWS tools (route tables, SG/NACL,
  flow logs). The whole VPC is ideally **Terraform** (sibling NaviOps IaC track).
- **Level 3 — Wire/Kernel (Lens D):** under the hood it's SDN + overlays (Lesson 32) on AWS's
  underlay; instances are Linux (Lesson 17) so the *inside* is `ip`/`ss`/iproute2. SGs/NACLs are
  enforced in the AWS network fabric, not on the instance. Flow logs capture 5-tuple + action
  (ACCEPT/REJECT) — the cloud's `tcpdump`-metadata.

### Two Teaching Approaches (Lens B) — VPC design + the public/private pattern

**Approach 1 (technical):** define a VPC CIDR; create subnets per AZ, designating public (route
table → IGW, instances get public IPs) vs private (route table → NAT GW, no public IPs); attach SGs
(stateful, instance) and NACLs (stateless, subnet) for least-privilege; front workloads with an ELB
across AZs (HA); use Route 53 for DNS; enable flow logs. Reachability = "is there a route + is it
allowed by SG *and* NACL?" — the cloud bottom-up method.

**Approach 2 (analogy):** an AWS VPC is a **secure office park you design on a plot of land you rent**.
- The **VPC CIDR** is the plot's address range; **subnets** are buildings (some with a public street
  entrance = public subnet/IGW, some accessible only from inside = private subnet).
- The **IGW** is the main gate to the public road; the **NAT Gateway** is a one-way service exit —
  staff in private buildings can go *out* for supplies but visitors can't come *in* that way.
- **Security groups** = a stateful badge reader on each building's door (remembers you, lets you
  back); **NACLs** = a stateless checkpoint at each building's perimeter checking *every* pass each
  way.
- **Multi-AZ** = building duplicates in two separate districts so a district power outage doesn't
  close shop (HA, Lesson 31).
- **Where it breaks down:** an office park is physically bounded; a VPC's boundary is *configuration*
  — one wrong security-group rule (`0.0.0.0/0` to a database) is like leaving a vault door to the
  public street, instantly globally reachable. The "one rule = exposed worldwide" risk is the part
  the physical analogy can't convey (§12).

### Visual (ASCII) — a standard 2-AZ VPC

```
   VPC 10.0.0.0/16
   ┌─────────────── AZ-a ───────────────┐   ┌─────────────── AZ-b ───────────────┐
   │ public  10.0.1.0/24 ─rt→ IGW ──────┼─┐ │ public  10.0.3.0/24 ─rt→ IGW       │
   │   [ALB] [NAT GW]                   │ │ │                                     │
   │ private 10.0.2.0/24 ─rt→ NAT GW ───┼─┘ │ private 10.0.4.0/24 ─rt→ NAT GW(b) │
   │   [app/db instances, no public IP] │   │   [app/db instances]               │
   └────────────────────────────────────┘   └─────────────────────────────────────┘
        ALB spans AZs (HA, L31) → app in private subnets → DB in private subnets
        SG (stateful) on instances + NACL (stateless) on subnets ; Flow Logs on the VPC
```

---

## §2 — Linux Networking Commands (+ AWS CLI)

```bash
# INSIDE an EC2 instance it's still Linux networking (Lesson 17):
ip -br addr ; ip route ; curl -s http://169.254.169.254/latest/meta-data/   # instance metadata
ping / traceroute / dig / nc -vz / curl -v                                  # bottom-up method (L18)
dig <name>                                                                   # Route 53 resolution (L13)

# AWS CLI (read-only describes are safe; CREATE costs/risk — human-approved only):
aws ec2 describe-vpcs ; aws ec2 describe-subnets
aws ec2 describe-route-tables ; aws ec2 describe-security-groups
aws ec2 describe-network-acls ; aws ec2 describe-flow-logs
aws ec2 describe-nat-gateways ; aws ec2 describe-internet-gateways
# ^ redact account IDs / VPC IDs / public IPs from any output before committing.
```

**Cisco/CCNA mapping:** CCNA's cloud + automation domains cover VPC concepts and IaC/API-driven
networking. AWS networking is the most marketable concrete instance — and pairs with the **AWS Cloud
Practitioner** cert (Wave 4, `JOB_MILESTONES.md`).

---

## §3 — Real-World Use Cases

**Production scenarios:**
1. **Standard 3-tier VPC:** public subnets (ALB), private subnets (app), private subnets (DB) across
   2 AZs — the canonical secure, HA web-app architecture.
2. **Private outbound:** private instances reach the Internet for updates via a NAT Gateway (no
   public IP), staying unreachable from outside (Lesson 14 + least privilege).
3. **Hybrid/peering:** VPC peering or Transit Gateway to connect VPCs; Site-to-Site VPN (Lesson 29)
   to on-prem.
4. **DNS + LB:** Route 53 (health-checked DNS) in front of an ELB (Lesson 30) across AZs (Lesson 31).
5. **Security visibility:** VPC Flow Logs → SIEM (Lesson 28) for detection/forensics.

**How NOC/Cloud-Support engineers use it:** troubleshooting "instance unreachable" (route table /
SG / NACL / public IP), reading flow logs, and verifying SG least-privilege — the daily Cloud
Support / NetDevOps reality.

**When NOT to:** **no spend without explicit human approval** — NAT Gateways, ELBs, and data
transfer cost money; tear down after labs. Don't expose resources via broad SGs.

**Exam framing:** AWS Cloud Practitioner (VPC, SG/NACL, Route 53, AZs) + Network+/CCNA cloud
domains.

---

## §4 — Troubleshooting Section (the cloud bottom-up method)

| Symptom | AWS cause | Check (in order) | Fix |
|---|---|---|---|
| Can't reach instance from Internet | no public IP / IGW route / SG | public IP? route→IGW? SG allows? | add IP/route; open SG (least-priv) |
| Private instance no outbound | no NAT GW / route | route table → NAT GW? | add NAT GW + route (L14) |
| Subnets can't talk | route table / NACL / peering | local route? NACL allows both ways? | fix route/NACL/peering |
| Intermittent connect | **NACL** missing return rule (stateless) | NACL inbound+outbound + ephemeral ports | add return-traffic NACL rule |
| "Firewall" blocks | SG (stateful) vs NACL (stateless) | check **both** | fix the right layer |
| DNS not resolving | Route 53 / resolver | `dig` (L13); VPC DNS settings | fix records/resolver |

**Redaction check (critical):** **never commit real account IDs/VPC IDs/IGW IDs/public IPs** —
`<ACCOUNT_ID>`, `<VPC_ID>`, RFC-1918/5737 only (NaviOps' exact AWS-redaction rule).

---

## §5 — Common Mistakes

| Mistake | Impact | Fix |
|---|---|---|
| Broad security group (`0.0.0.0/0` to SSH/DB) | Internet-exposed → breach | least-privilege SGs |
| Forgetting NACLs are stateless | intermittent failures (no return rule) | add ephemeral-port return rules |
| No NAT GW for private outbound | private instances can't update | NAT GW + route |
| Single AZ (no HA) | AZ failure = outage | multi-AZ (L31) |
| Leaving costly resources running | surprise bill | tear down; tag + budget alerts |
| Committing real account/VPC IDs/IPs | leak | redact everything |

---

## §6 — NOC Perspective

> Network Operations → Cloud Support / NetDevOps (Stages 2, 6, `ROADMAP.md`).

For cloud-hosted workloads, the NOC monitors VPC reachability (synthetic checks to endpoints,
Lesson 21), reads **VPC Flow Logs** (the cloud capture), and treats SG/route-table/NACL changes as
high-impact, audited **changes** (`noc/ticketing.md`). The troubleshooting is the same bottom-up
method with AWS tools. Cost is an operational signal too (a runaway NAT GW/data-transfer bill is an
incident). This is the most marketable NOC→cloud bridge skill.

---

## §7 — Incident-Response Perspective

- **Detect:** a cloud resource unreachable, anomalous flow-log traffic, or an exposed SG finding.
- **Triage/Diagnose:** bottom-up with AWS tools (public IP → route table → SG → NACL → DNS); flow
  logs show ACCEPT/REJECT per flow (the capture).
- **Contain/Fix → Recover → Document:** tighten the SG/NACL/route (Lesson 15), revoke exposure,
  verify, document. **Exposed security groups / public resources** are a top cloud security-IR
  scenario (Lesson 28); flow logs are the forensic evidence (Lesson 20 analog).

---

## §8 — Practical Lab (build this yourself — design first, build only if approved)

**Goal:** design a 2-AZ VPC on paper and write `docs/networking/aws-vpc-notes.md` (redacted);
**optionally**, free-tier-aware and **human-approved**, build a minimal VPC and tear it down.

### Lens C — Manual → Automated → Why
- **Manual:** design the VPC (CIDR/subnets/routes/SGs/NACLs) on paper.
- **Automated:** the whole VPC as **Terraform** (sibling NaviOps IaC track) — reproducible,
  reviewable, and **destroyable** (cost control via teardown).
- **Why:** IaC is how cloud networks are actually built/operated; "the network is code" enables
  review, rollback, and clean teardown (the no-surprise-bill discipline). Design-first + IaC is the
  professional pattern.

### Steps
1. **Design (no spend):** in `docs/networking/aws-vpc-notes.md`, design a `10.0.0.0/16` VPC with
   public + private subnets in 2 AZs, route tables (public→IGW, private→NAT GW), least-privilege
   SGs, NACLs, Route 53 for DNS, and flow logs. Justify the subnet sizing (Lesson 04) and HA (Lesson
   31). Redact all real IDs.
2. **Map every component to its earlier lesson** (the §1 table) — prove it's fundamentals re-applied.
3. **Walk the troubleshooting table (§4)** for "instance unreachable" — the cloud bottom-up method.
4. **(Optional, approved, free-tier-aware):** build a minimal VPC via console/CLI/Terraform, launch a
   t-class instance, verify reachability, read flow logs, **then tear it all down** (confirm $0
   leftover). Redact every screenshot/output.

> ⚠️ **Danger zone:** `terraform apply` / creating NAT GW/ELB costs money. **Human-approved, specific
> command only** (`navi.project.md` Hard Rule #5). Default to design-only.

### Lens D — instance metadata + flow logs
From inside an EC2 instance, `curl http://169.254.169.254/latest/meta-data/` (the link-local
metadata service — note its security sensitivity, SSRF risk) and read VPC Flow Log records (5-tuple
+ ACCEPT/REJECT) — the cloud's traffic visibility.

---

## §9 — GitHub Artifact (evidence 5-tuple)

1. **Script/IaC:** (optional) a Terraform VPC module or the AWS CLI build/teardown — **redacted**.
2. **Config/doc:** `docs/networking/aws-vpc-notes.md` (the redacted VPC design + lesson mapping).
3. **Drill:** the "instance unreachable" bottom-up reasoning (or a built+torn-down VPC).
4. **NAVI ticket:** `NAVI-33` (Change: "design (build/teardown) a 2-AZ VPC").
5. **Incident report:** *(optional)* — an exposed-SG or unreachable-instance runbook (redacted).

---

## §10 — Portfolio Artifact

- **Resume bullet:** "Designed a multi-AZ AWS VPC (public/private subnets, IGW/NAT GW routing,
  least-privilege security groups + NACLs, Route 53, flow logs) mapping core networking fundamentals
  to AWS; cost-disciplined build/teardown."
- **Interview talking point:** the standard 3-tier multi-AZ VPC, SG-vs-NACL, NAT GW for private
  outbound, and "cloud networking is fundamentals via API + IaC" — the marketable cloud story.
- **Serves:** Cloud Support / NetDevOps (Stage 6) + Network Operations; AWS Cloud Practitioner (Wave
  4).

---

## §11 — RHCSA Crossover Notes

RHCSA-adjacent: EC2 instances are Linux (RHEL family) — RHCSA networking (`nmcli`, firewalld inside
the instance, `ip`/`ss`, name resolution) applies *inside* the VPC. The IaC/Terraform angle ties to
the sibling NaviOps cloud + automation lessons (a coordinated Linux-network-cloud skill set).

---

## §12 — Security Notes (Lens E — Attacker & Defender)

> Frameworks: [MITRE ATT&CK](https://attack.mitre.org/).

**🔴 Attacker:** the dominant cloud breach is **misconfiguration** — an overly-broad **security
group** exposing SSH/RDP/DB to `0.0.0.0/0` (`T1190` Exploit Public-Facing App), public storage
(`T1530`), and **stolen instance credentials via SSRF on the metadata service**
(`169.254.169.254` → IAM creds; mitigated by IMDSv2). Attackers continuously scan AWS IP ranges for
exposed services.

**🔵 Defender:** **least-privilege security groups** (no broad sensitive-port exposure), **private
subnets** for app/DB (no public IP; NAT GW outbound only), **IMDSv2** (defeats SSRF cred theft),
**enable + monitor VPC Flow Logs** → SIEM (Lesson 28), and treat SG/route changes as audited. Same
segmentation/least-privilege as Lessons 04/09/15, cloud-flavored. Verify (your own account) that no
SG exposes a sensitive port to the world and IMDSv2 is enforced.

---

## Quiz (Interview-Style, Graded)

**Q1.** Walk through the components of a standard 2-AZ VPC and what each does (VPC, subnets, route
tables, IGW, NAT GW, SG, NACL).
> **Your answer:**

**Q2.** Security Group vs Network ACL — stateful/stateless, instance/subnet — and a real consequence
of the difference.
> **Your answer:**

**Q3.** How does a private-subnet instance reach the Internet for updates without being reachable
from the Internet?
> **Your answer:**

**Q4.** **Scenario:** An EC2 instance in a public subnet has a public IP and an SG allowing 443, but
it's still unreachable from the Internet. What else do you check?
> **Your answer:**

**Q5.** What are VPC Flow Logs and how do you use them in troubleshooting/security?
> **Your answer:**

**Q6.** What's the most common AWS-networking breach, and the two controls that prevent it?
> **Your answer:**

*(After you answer, request the "Professional Answer" comparison under each — graded before Lesson 34.)*

---

## Reflection
*(Fill in after the quiz)* — What did you learn? · What confused you? · What would you do differently?

---

## Search Keywords For Further Understanding

**Core**
- `aws vpc subnets route tables`
- `aws security group vs nacl`
- `aws nat gateway internet gateway`
- `aws route 53 dns`
- `vpc flow logs`

**Tools**
- `aws cli describe-vpcs subnets`
- `terraform aws vpc module`
- `aws imdsv2 metadata security`

**Going further (future lessons)**
- `aws transit gateway vpc peering` · `aws direct connect hybrid` · `terraform networking iac`

**Red / Blue (Lens E):**
- 🔴 `open security group breach T1190`, `s3 public T1530`, `ec2 metadata ssrf credential theft`
- 🔵 `least privilege security groups`, `imdsv2 enforce`, `vpc flow logs siem`

---

## Lesson Status
- [ ] §8 lab completed (VPC design doc; optional build+teardown, approved)
- [ ] §4 drill done (cloud bottom-up reasoning)
- [ ] Evidence committed (§9 — fully redacted)
- [ ] Quiz answered + professional-answer comparisons (graded)
- [ ] Reflection + Search Keywords reviewed

When complete, run the Update Protocol, then move to **Lesson 34 — CCNA Capstone**.

---

*Lesson 33 written by Navi · 2026-06-20 · full-depth. Sources to cite when worked: AWS VPC/Route 53
docs, AWS Cloud Practitioner objectives, CompTIA Network+ N10-009, MITRE ATT&CK T1190/T1530.*
