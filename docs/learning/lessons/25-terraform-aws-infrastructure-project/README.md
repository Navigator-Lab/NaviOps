# Lesson 25 — Terraform + AWS Infrastructure Project (Synthesis)

**Status:** ready for self-study · **Date written:** 2026-06-11
**Gate Rule:** Concept → Real-World Use → Alternatives → Hands-On → Verification → Quiz → Reflection → Search Keywords

> **How to use this lesson:** **Month 2-3 capstone** — provision a complete
> environment with Terraform **modules** (Lesson 20), deploy Lesson 24's
> multi-service Compose stack onto it via an IAM role + EC2 instance (Lesson
> 15/16), with CloudWatch alarms (Lesson 18) — everything earlier becomes one
> reviewable, destroyable, re-creatable project.

---

## Step 1 — Concept

### What it is

A **Terraform module-based AWS project**: instead of one flat `main.tf`
(Lesson 20), resources are organized into **modules** — reusable, focused
groups (a `network` module for VPC/subnets/IGW, a `compute` module for
EC2/security groups/IAM role, a `monitoring` module for CloudWatch alarms) —
composed together in a root module that wires them together with
**input/output variables**.

### Why it exists

Lesson 20's single `main.tf` worked for one VPC + one EC2 instance. A real
environment has **many related resources** (network, compute, storage,
monitoring, IAM) that benefit from being **organized by concern** — per
[Spacelift's module best-practices guide](https://spacelift.io/blog/terraform-modules-at-scale)
and [oneuptime's large-org module guide](https://oneuptime.com/blog/post/2026-02-23-how-to-use-terraform-module-best-practices-for-large-organizations/view),
modules let you **reuse** the same network/compute pattern across
environments (dev/staging/prod — different variable values, same module),
**review** changes more easily (a PR touching only the `monitoring` module is
obviously lower-risk than one touching `network`), and **test** in isolation.

### What problem it solves

| Problem | Solution |
|---|---|
| "I need the same VPC+EC2+IAM pattern for dev AND staging" | A `compute` module called twice with different variables |
| "A single 500-line `main.tf` is hard to review/understand" | Split into `modules/network`, `modules/compute`, `modules/monitoring` |
| "How does the EC2 instance get permission to write CloudWatch metrics, without stored credentials?" | IAM role (Lesson 15) + `aws_iam_instance_profile`, attached via the `compute` module |
| "I want this whole environment destroyable/recreatable in one command" | `terraform destroy` / `terraform apply` on the root module |
| "Reduce NAT gateway costs for S3/DynamoDB access" | VPC Gateway Endpoints (free) for S3/DynamoDB — per [oneuptime's VPC module guide](https://oneuptime.com/blog/post/2026-02-12-terraform-aws-vpc-module/view) |

### Three-Level Depth (Lens A)

- **Level 1 — Beginner:** A module is just a directory with its own
  `main.tf`/`variables.tf`/`outputs.tf` — called from the root via
  `module "network" { source = "./modules/network", vpc_cidr = var.vpc_cidr
  }`. Outputs from one module (e.g., `module.network.subnet_id`) become
  inputs to another (`module.compute`).
- **Level 2 — SysAdmin:** Per [dasroot's 2026 Terraform AWS modules
  guide](https://dasroot.net/posts/2026/01/terraform-aws-modules-production-infrastructure/)
  and the [12-step Terraform AWS
  tutorial](https://tech-insider.org/terraform-tutorial-aws-infrastructure-as-code-2026/):
  a typical project structure is `main.tf` (calls modules), `variables.tf`,
  `outputs.tf`, `backend.tf` (remote state, Lesson 20), and `modules/network`,
  `modules/compute`, `modules/monitoring` directories. **EC2 IAM instance
  profiles**: per [Spacelift's EC2 module
  guide](https://spacelift.io/learn/terraform-ec2-module), an
  `aws_iam_role` + `aws_iam_instance_profile` attached to `aws_instance` give
  the instance temporary credentials (Lesson 15's IAM role concept) to write
  CloudWatch custom metrics (Lesson 18) without any access keys on the
  instance. **Community modules** (e.g., `terraform-aws-modules/vpc/aws`,
  `terraform-aws-modules/ec2-instance/aws`) are pre-built, widely-used,
  parameterized — per [oneuptime's guide], using them for common patterns
  (VPC, EC2) is standard practice rather than reinventing; writing your own
  modules is for **your organization's specific** repeated patterns.
- **Level 3 — Systems/Kernel (Lens D):** The EC2 instance's **user data**
  script (passed via `aws_instance.user_data`) runs as **root at first
  boot** (via `cloud-init`, which itself runs early in the systemd boot
  sequence, Lesson 05) — this is how Terraform can provision an instance
  *and* bootstrap it (e.g., install Docker, pull and run Lesson 24's Compose
  stack) without a separate Ansible run, though the "Terraform provisions,
  Ansible configures" split (Lesson 20 Q3) remains the more maintainable
  pattern for anything beyond minimal bootstrapping. **VPC Flow Logs to
  CloudWatch** (mentioned in [oneuptime's VPC module
  guide](https://oneuptime.com/blog/post/2026-02-12-terraform-aws-vpc-module/view))
  capture metadata about IP traffic at the **ENI (Elastic Network Interface)
  level** — the cloud equivalent of running `tcpdump`/packet capture (Lesson
  09) on every interface, but as structured logs shippable to CloudWatch
  Logs (Lesson 18) for analysis.

### Analogy (Lens B)

- **Modules** = prefab building components (a "foundation+utilities" module,
  a "floor plan" module, an "alarm system" module) — an architect (root
  module) specifies which prefabs to use and how they connect (variables/
  outputs), rather than custom-designing every nail and beam each time.
- **Community modules** (`terraform-aws-modules/vpc/aws`) = buying a
  professionally-engineered, code-compliant prefab foundation from a
  reputable supplier, rather than designing your own from scratch — saves
  time and reduces the chance of subtle mistakes, for a component that's
  fundamentally the same across most buildings.
- **IAM instance profile** = the building issuing a **temporary employee
  badge** to a piece of equipment (the EC2 instance) the moment it's
  installed — the badge grants exactly the access that equipment needs (read
  this S3 bucket, write these CloudWatch metrics) and is automatically
  revoked if the equipment is removed (instance terminated).
- **`user_data`/cloud-init** = a setup checklist taped to a new piece of
  equipment that the building's maintenance crew (cloud-init) runs through
  automatically the moment it's powered on for the first time — useful for a
  short checklist, unwieldy for "configure this entire department" (better
  done by a dedicated configuration team — Ansible, Lesson 13).

The "prefab building" analogy holds well but breaks down for **module
output→input wiring across modules** — a prefab foundation doesn't
"output a value" that a prefab floor plan "consumes as input" the way
`module.network.subnet_id` flows into `module.compute`; that's a
distinctly software-dependency-graph concept.

---

## Step 2 — Real-World Use

### How SysAdmins use this daily

```bash
# Project structure
infra/terraform/
├── main.tf              # calls modules
├── variables.tf
├── outputs.tf
├── backend.tf           # remote state (Lesson 20)
├── terraform.tfvars.example
└── modules/
    ├── network/          # VPC, subnets, IGW, route tables
    ├── compute/           # EC2, security group, IAM role/instance profile
    └── monitoring/        # CloudWatch alarms, SNS topic

terraform init
terraform plan
terraform apply
terraform output app_url
```

**Real production scenarios:**
1. **Environment parity** — `module "network"` and `module "compute"` called
   once with `dev.tfvars`, once with `staging.tfvars` — nearly identical
   environments, one codebase, different variable files.
2. **Onboarding a new resource type** — adding an S3 bucket for backups
   (Lesson 17) means adding a small `modules/storage` module and one new
   `module` block in root `main.tf` — the network/compute modules are
   untouched.
3. **Full-stack teardown for cost control** — `terraform destroy` removes
   the VPC, EC2 instance (running Lesson 24's stack), CloudWatch alarms, and
   IAM role in one command — no manual hunting across the AWS console.

### Common mistakes

| Mistake | Impact | Fix |
|---|---|---|
| Writing custom VPC/EC2 modules from scratch when community modules exist | Reinventing well-tested code, more bugs, more maintenance | Use `terraform-aws-modules/vpc/aws` and similar for common patterns; write custom modules for your org-specific patterns only |
| Hardcoding values that should be variables (e.g., AMI ID, region) inside modules | Module can't be reused for a different environment/region | Pass region/AMI/CIDR as module input variables |
| `user_data` scripts that do everything (install Docker, configure app, set up monitoring, harden the OS) | Unmaintainable, untested shell scripts growing without bound | Minimal `user_data` (install Docker, basic bootstrap); hand off to Ansible (Lesson 13) for configuration |
| No `outputs.tf` exposing useful values (instance IP, ARNs) | Have to dig through `terraform state show` or the AWS console to find resource details | Define outputs for anything you'll need to reference (SSH IP, CloudWatch alarm ARNs) |
| Mixing environments in one state file | A mistake in `dev` can accidentally affect `prod` resources tracked in the same state | Separate state files per environment (different backend `key` per environment) |

### When NOT to over-engineer

- For this lesson's single learning environment, **3 modules** (network,
  compute, monitoring) is the right granularity — don't create a module per
  individual resource (e.g., a module that's just one `aws_security_group` —
  that's premature abstraction, Lesson 03 Q3/Lesson 20 Q6 again).

### Interview Angle

**Scenario:** "Your `user_data` script installs Docker, configures
firewall rules, hardens SSH, sets up log rotation, and deploys the app —
all in one 200-line bash script run at boot. What's your concern with this
design?"

A junior answer says "it works at boot, so it's fine" or focuses on script
readability alone. A senior answer identifies the architectural problem:
`user_data`/cloud-init runs **once, at first boot, as root**, with no easy
re-run, no idempotency guarantees, and no drift detection — anything beyond
minimal bootstrapping (install Docker, clone the repo, `docker compose up`)
belongs in a configuration-management tool like Ansible (Lesson 13) that
can be re-applied safely. The senior answer also connects this to the IAM
instance profile pattern in `modules/compute`: `user_data` should never
need embedded AWS credentials because the instance profile already grants
the EC2 instance scoped, temporary permissions — and explains why "Terraform
provisions, Ansible configures" is the maintainable split, not "Terraform
provisions and fully configures via user_data."

---

## Step 3 — Alternatives

| Topic | Alternative | Note |
|---|---|---|
| Hand-written modules (this lesson) | `terraform-aws-modules/*` registry modules | Per [oneuptime's guide](https://oneuptime.com/blog/post/2026-02-12-terraform-aws-vpc-module/view), the community VPC/EC2 modules are production-grade and widely used — good to know both how to write your own (this lesson, for understanding) and how to consume registry modules (real-world speed) |
| `user_data` bootstrap | Full Ansible run post-provision (Lesson 13) | `user_data` for minimal bootstrap (install Docker); Ansible for anything more — the "Terraform provisions, Ansible configures" split from Lesson 20 |
| Terraform | Pulumi, OpenTofu (Lesson 20 Q-series alternatives) | Same tradeoffs as discussed in Lesson 20 |
| Manual `terraform apply` | CI/CD-driven Terraform (plan on PR, apply on merge with approval) | Per [oneuptime's large-org guide], CI/CD + manual-approval-for-prod is standard at scale; manual `apply` is fine for a personal learning environment |

---

## Step 4 — Hands-On Task (build this yourself)

**Goal:** Build a 3-module Terraform project (`network`, `compute`,
`monitoring`) that provisions a VPC + EC2 instance (with an IAM role allowing
CloudWatch custom metrics) running Lesson 24's Docker Compose stack via
`user_data`, plus CloudWatch alarms (Lesson 18) — then `apply`/verify/
`destroy`.

### Lens C — Manual → Automated → Why

**Manual (Lessons 15-18, 24):** create IAM user/role, VPC, EC2 instance, SSH
in, manually `git clone` + `docker compose up` Lesson 24's stack, manually
create CloudWatch alarms — many separate console/CLI steps, easy to miss one
when recreating.

**Automated — project layout:**
```
infra/terraform/
├── main.tf
├── variables.tf
├── outputs.tf
├── backend.tf
└── modules/
    ├── network/
    │   ├── main.tf       # aws_vpc, aws_subnet, aws_internet_gateway, route table
    │   ├── variables.tf  # vpc_cidr, subnet_cidr
    │   └── outputs.tf    # vpc_id, subnet_id
    ├── compute/
    │   ├── main.tf       # aws_security_group, aws_iam_role + instance_profile, aws_instance
    │   ├── variables.tf  # subnet_id, ami_id, key_pair_name, my_ip_cidr, user_data
    │   └── outputs.tf    # instance_id, public_ip
    └── monitoring/
        ├── main.tf       # aws_sns_topic, aws_cloudwatch_metric_alarm (cpu, disk)
        ├── variables.tf  # instance_id, alert_email
        └── outputs.tf    # sns_topic_arn
```

Root `main.tf`:
```hcl
module "network" {
  source             = "./modules/network"
  vpc_cidr           = var.vpc_cidr
  public_subnet_cidr = var.public_subnet_cidr
}

module "compute" {
  source         = "./modules/compute"
  subnet_id      = module.network.subnet_id
  vpc_id         = module.network.vpc_id
  ami_id         = var.ami_id
  key_pair_name  = var.key_pair_name
  my_ip_cidr     = var.my_ip_cidr
  user_data      = file("${path.module}/userdata.sh")
}

module "monitoring" {
  source       = "./modules/monitoring"
  instance_id  = module.compute.instance_id
  alert_email  = var.alert_email
}
```

`userdata.sh` (minimal bootstrap) — **write this yourself.** It runs once at instance
launch and must: install Docker + git (handle both `dnf` and `apt` so it works on Alma
*or* Ubuntu AMIs), enable/start the Docker service, clone your repo into `/opt/naviops`,
`cd` into the Lesson 24 compose directory, and `docker compose up -d`. Keep your real
repo URL out of committed Terraform (pass it as a variable or placeholder).

The `compute` module's IAM role:
```hcl
resource "aws_iam_role" "instance_role" {
  name = "naviops-instance-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "cloudwatch" {
  role       = aws_iam_role.instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_instance_profile" "instance_profile" {
  name = "naviops-instance-profile"
  role = aws_iam_role.instance_role.name
}
```

**Why this matters:** per [the 12-step Terraform AWS
tutorial](https://tech-insider.org/terraform-tutorial-aws-infrastructure-as-code-2026/),
this structure is **exactly** the progression real teams follow: start with
one flat config (Lesson 20), then refactor into modules once the pattern is
clear (Lesson 03 Q3's "extract abstractions after you see repetition, not
before" — now applied to infrastructure).

### What to build, step by step

1. Set up remote state (`backend.tf`, reuse Lesson 20's S3+DynamoDB if still
   present, or recreate).
2. Build `modules/network` — adapt Lesson 20's VPC/subnet/IGW/route table
   resources into a module with `vpc_cidr`/`public_subnet_cidr` variables and
   `vpc_id`/`subnet_id` outputs.
3. Build `modules/compute` — security group (SSH from `my_ip_cidr` only,
   HTTP from `0.0.0.0/0` for Lesson 24's Traefik), IAM role + instance
   profile (CloudWatch policy), `aws_instance` with `user_data` and
   `iam_instance_profile`.
4. Write `userdata.sh` — installs Docker, clones your repo, runs Lesson 24's
   `docker compose up -d`. (If you haven't pushed your repo to a remote yet,
   note this in your reflection and use a placeholder/local approach.)
5. Build `modules/monitoring` — adapt Lesson 18's CPU/disk alarms +
   SNS topic into a module taking `instance_id`/`alert_email`.
6. Wire it all together in root `main.tf`/`variables.tf`/`outputs.tf`.
7. `terraform init && terraform plan` — review carefully (should show ~12-15
   resources across 3 modules).
8. `terraform apply`.
9. Verify: SSH to the output IP, confirm Docker Compose stack is running
   (`docker compose ps`), `curl http://<IP>/` reaches Traefik → app.
10. Confirm CloudWatch alarms exist and SNS subscription works (Lesson 18).
11. Document the full architecture (diagram + module descriptions) in
    `docs/aws/terraform-project-design.md`.
12. `terraform destroy` — confirm full teardown.
13. Commit `infra/terraform/` (no state files, no real `.tfvars`) and the
    design doc on `lesson/25-terraform-aws-infrastructure-project`.

---

## Step 5 — Verification

```bash
cd infra/terraform
terraform init
terraform validate
terraform plan
terraform apply

terraform output instance_public_ip
ssh -i ~/.ssh/<key>.pem <user>@$(terraform output -raw instance_public_ip) \
  "docker compose -f /opt/naviops/.../compose.yaml ps"

curl -s http://$(terraform output -raw instance_public_ip)/ | head

aws cloudwatch describe-alarms --alarm-names naviops-high-cpu naviops-high-disk

terraform destroy
terraform state list   # empty
```

### Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| `terraform plan` fails: module not found | Incorrect `source` path in `module` block | Confirm relative paths (`./modules/network`) match actual directory structure |
| EC2 instance up but `docker compose ps` shows nothing | `user_data` script failed silently | SSH in, check `/var/log/cloud-init-output.log` for errors (cloud-init logs all `user_data` output) |
| App unreachable via `curl http://<IP>/` | Security group missing port 80 inbound, or Traefik not started | Check security group rules (`compute` module); `docker compose logs traefik` |
| CloudWatch alarms created but instance can't write custom metrics | IAM instance profile not attached, or policy insufficient | `aws sts get-caller-identity` *from the instance* (using instance metadata) should show the role; confirm `CloudWatchAgentServerPolicy` attached |
| `terraform destroy` hangs or fails on VPC deletion | A resource (e.g., security group) still has dependencies (ENI from a not-fully-terminated instance) | Wait for instance termination to complete fully before destroying network resources; Terraform usually orders this correctly, but timing issues can occur |

### Redaction check ✅

`terraform.tfvars` (real IP, AMI, key pair name, repo URL, email) gitignored
— commit only `terraform.tfvars.example`. `userdata.sh` should not contain
real repo URLs with credentials (use a public repo URL or placeholder).
`docs/aws/terraform-project-design.md` uses `<ACCOUNT_ID>`/`<PUBLIC_IP>`
placeholders per prior lessons.

---

## Step 6 — Quiz (Interview-Style, Graded)

**Q1.** Why split this project into `network`, `compute`, and `monitoring`
modules instead of one flat `main.tf` (as in Lesson 20)? What's the
trade-off?

> **Your answer:**

**Q2.** **Scenario:** You need to add a `staging` environment identical to
your current one but in a different AWS region with a smaller instance type.
How does the module structure make this easier than Lesson 20's flat config?

> **Your answer:**

**Q3.** Explain how the IAM instance profile in the `compute` module relates
to Lesson 15's "IAM roles vs. IAM users" discussion. Why is this more secure
than putting AWS access keys in `userdata.sh`?

> **Your answer:**

**Q4.** What's the role of `user_data`/cloud-init here, and why does this
lesson recommend keeping it "minimal" rather than doing all configuration in
it? Tie back to Lesson 20 Q3 ("Terraform provisions, Ansible configures").

> **Your answer:**

**Q5.** When would you reach for a community module
(`terraform-aws-modules/vpc/aws`) instead of writing your own `network`
module like this lesson did? What did writing your own teach you that using
the community module from the start wouldn't have?

> **Your answer:**

**Q6.** Walk through what happens, in order, when you run `terraform destroy`
on this project. Why does the order matter (e.g., can the VPC be deleted
before the EC2 instance)?

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

**🔴 Attacker (how it's abused — Step 2):** At project scale a **single IaC misconfig becomes a breach at scale** — one open security group, public bucket, or over-broad IAM role exposes everything, and state still holds secrets. ATT&CK **T1190**, **T1552**.

**🔵 Defender (detect & harden — Step 5):** Gate the pipeline with **tfsec/checkov**, least-privilege every resource, encrypted remote state, security-review the `plan` before `apply`, and keep teardown discipline so nothing is left exposed and billing/attack surface stays minimal.

## Step 8 — Search Keywords For Further Understanding

**Core**
- `terraform modules network compute monitoring structure`
- `terraform aws iam instance profile ec2`
- `terraform user_data cloud-init bootstrap`
- `terraform-aws-modules vpc ec2 registry`

**Tools**
- `terraform module source variables outputs`
- `aws cloudwatch agent iam policy`
- `cloud-init logs troubleshooting`

**Going further (future lessons)**
- `incident response for terraform-managed infrastructure`
- `terratest terraform module testing`
- `rhcsa exam preparation linux fundamentals review`

---

**Red / Blue (Lens E — study attacker & defender in parallel):**
- 🔴 **Red (attacker):** `iac misconfiguration breach at scale`, `MITRE ATT&CK T1190 exploit public facing`, `open security group terraform`, `terraform state exfiltration`
- 🔵 **Blue (defender):** `tfsec checkov ci pipeline gate`, `least privilege iac provider`, `cloud teardown cost discipline`, `security review terraform plan`

## Lesson Status

- [ ] Hands-on task completed (Step 4)
- [ ] Verification passed (Step 5)
- [ ] Quiz answered + professional-answer comparisons requested (Step 6)
- [ ] Reflection completed (Step 7)
- [ ] Search Keywords reviewed (Step 8)

When complete, run the Update Protocol, then move to **Lesson 26 — Capstone
Incident-Response Project**.

---

*Lesson 25 written by Navi v28 · 2026-06-11 · WebSearch sources:
[dasroot Terraform AWS Modules: Building Production Infrastructure 2026](https://dasroot.net/posts/2026/01/terraform-aws-modules-production-infrastructure/),
[tech-insider 12-Step Terraform AWS Tutorial 2026](https://tech-insider.org/terraform-tutorial-aws-infrastructure-as-code-2026/),
[Spacelift 10 Best Practices for Managing Terraform Modules at Scale](https://spacelift.io/blog/terraform-modules-at-scale),
[oneuptime How to Use the Terraform AWS VPC Module](https://oneuptime.com/blog/post/2026-02-12-terraform-aws-vpc-module/view),
[Spacelift How to Use Terraform EC2 Module](https://spacelift.io/learn/terraform-ec2-module)*
