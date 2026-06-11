# Lesson 20 — Terraform Fundamentals

**Status:** ready for self-study · **Date written:** 2026-06-11
**Gate Rule:** Concept → Real-World Use → Alternatives → Hands-On → Verification → Quiz → Reflection → Search Keywords

> **How to use this lesson:** same as Lessons 03–19. This is the **closing
> lesson of Month 2** — it ties together everything you've provisioned by hand
> in Lessons 15-18 (IAM, EC2/VPC, S3, CloudWatch) and expresses it as **code**,
> the same way Lesson 13 turned manual server config into Ansible playbooks.

---

## Step 1 — Concept

### What it is

**Terraform** (HashiCorp) is an **Infrastructure as Code (IaC)** tool: you
write `.tf` files declaring the infrastructure you *want* (a VPC, an EC2
instance, an S3 bucket), and Terraform figures out how to create, update, or
destroy real cloud resources to match. It tracks what it created in a
**state file** (`terraform.tfstate`).

### Why it exists

Lessons 15-18 had you click through the AWS console / run `aws ec2
run-instances`, `aws s3 mb`, `aws cloudwatch put-metric-alarm` — one-off
commands that aren't repeatable, reviewable, or version-controlled. If you
need to recreate the exact same VPC+EC2+S3+CloudWatch setup next month (or a
teammate needs an identical one), you'd have to remember every CLI flag and
console click. Terraform turns "the infrastructure" into a **file you can
read, diff, review in a pull request, and re-run** — exactly Lesson 13's
"Ansible playbook vs. SSH-and-type-commands" argument, applied to cloud
infrastructure *provisioning* rather than server *configuration*.

### What problem it solves

| Problem | Solution |
|---|---|
| "How was this VPC/EC2/S3 setup actually configured? No one remembers." | It's in a `.tf` file, version-controlled |
| "I need an identical dev/staging/prod environment" | Same `.tf` config, different variable values |
| "Someone changed a security group manually in the console and now things are inconsistent" | `terraform plan` shows the **drift** |
| "I want to review infrastructure changes before they happen, like a code review" | `terraform plan` output is the "diff" reviewed in a PR |
| "Tearing down a whole learning environment to avoid AWS charges" | `terraform destroy` removes everything Terraform created, in one command |

### Three-Level Depth (Lens A)

- **Level 1 — Beginner:** A `.tf` file declares **resources** —
  `resource "aws_instance" "web" { ami = "..."; instance_type = "t3.micro" }`.
  `terraform init` downloads the AWS **provider** (a plugin that knows how to
  talk to AWS's API). `terraform plan` shows what *would* change.
  `terraform apply` makes it happen. `terraform destroy` tears it all down.
- **Level 2 — SysAdmin:** Per [env0's 2026 Terraform best-practices
  guide](https://www.env0.com/blog/terraform-best-practices-state-management-reusability-security-and-beyond)
  and [Scalr's state file best practices](https://scalr.com/learning-center/terraform-state-files-best-practices):
  the **state file** is Terraform's source of truth for "what exists and its
  current attributes" — it maps your `.tf` resource blocks to real cloud
  resource IDs. **Never use local state for shared/important work** — store it
  in a **remote backend** (S3 bucket) with **state locking** (DynamoDB table)
  so two people (or two CI runs) can't `apply` simultaneously and corrupt the
  state. **`terraform plan`** computes a diff between your `.tf` config,
  the state file, and the **real infrastructure** (refreshing first) — this
  three-way comparison is how Terraform detects **drift** (someone manually
  changed something in the console). **Variables** (`variables.tf`) and
  **outputs** (`outputs.tf`) parameterize configs (e.g., different
  `instance_type` per environment) without duplicating resource blocks.
  **Modules** are reusable, parameterized bundles of resources (e.g., a "VPC
  module" you call once per environment) — per [env0's guide], extract a
  module once you see the same resource pattern repeated, not before
  (mirrors Lesson 03 Q3's "don't abstract prematurely").
- **Level 3 — Systems/Kernel (Lens D):** Terraform's **declarative,
  idempotent** model directly parallels Lesson 13's Ansible idempotency
  (Lesson 13 Q-series) — but at a different layer: **Ansible configures
  existing machines** (packages, files, services — operates *inside* an OS,
  via SSH), while **Terraform provisions the machines/infrastructure
  themselves** (the VPC, the EC2 instance, the S3 bucket — operates *against
  cloud provider APIs*, via the provider plugin). A common production pattern
  is **Terraform first** (create the EC2 instance, attach the IAM role/security
  group), **then Ansible** (SSH in and configure the OS — install packages,
  apply Lesson 10's hardening). The **provider plugin** is a separate binary
  Terraform launches and communicates with via gRPC — conceptually similar to
  how `journalctl` talks to `journald` over a socket (Lesson 05): a thin
  client/protocol talking to something that does the real work (here, AWS's
  API).

### Analogy (Lens B)

- **`.tf` files** = architectural blueprints for a building — they describe
  the *desired* building (3 floors, 2 elevators, specific room layout), not
  the step-by-step construction sequence.
- **`terraform plan`** = a contractor reading the blueprint, walking the
  current site, and saying "here's exactly what I'll build/change/demolish to
  match this blueprint" — **before** doing any work, so you can review and
  approve.
- **State file** = the contractor's master record of "what's actually been
  built so far and its exact specs (resource IDs, IPs)" — if this record gets
  lost or corrupted, the contractor no longer knows what exists vs. what the
  blueprint says should exist (a serious, real Terraform failure mode).
- **Remote state + locking** = that master record kept in a shared,
  access-controlled office safe (S3) with a sign-out sheet (DynamoDB lock) —
  so two contractors can't both "update the master record" at the same time
  and create two conflicting versions.
- **Modules** = a standardized "build a garage" blueprint sub-section you can
  reference (with different dimensions) whenever any building needs a garage,
  instead of redrawing it from scratch each time.

The blueprint analogy holds well but breaks down for **drift detection** — a
real building doesn't spontaneously change after construction, but cloud
resources frequently get manually modified (someone clicks a button in the
console), and `terraform plan` is uniquely good at catching "the building no
longer matches the blueprint."

---

## Step 2 — Real-World Use

### How SysAdmins use this daily

```bash
# Workflow
terraform init      # download providers, configure backend
terraform fmt       # auto-format .tf files (style consistency)
terraform validate  # syntax/type check, no API calls
terraform plan      # show what would change (review this!)
terraform apply     # make it happen (prompts for confirmation)
terraform destroy   # tear down everything Terraform manages here

# Inspecting state
terraform state list                 # list resources Terraform tracks
terraform state show aws_instance.web
terraform output                     # show output values (e.g., instance public IP)
```

**Real production scenarios:**
1. **Reproducible environments** — the exact VPC+EC2+security-group setup from
   Lesson 16, defined once as `.tf`, applied identically to `dev`/`staging`
   (different variable files for instance size, CIDR ranges).
2. **Code review for infrastructure changes** — a PR adding `terraform plan`
   output as a comment (CI integration, extending Lesson 14) lets teammates
   review "this change will create 1 security group rule and modify 1
   instance" before anyone runs `apply`.
3. **Safe teardown** — at the end of a learning session, `terraform destroy`
   removes the VPC/EC2/S3 you created in this lesson — no manual hunting
   through the console for "did I forget to delete something?" (directly
   addresses Lesson 16/18's "forgot to terminate, got charged" mistake).

### Common mistakes

| Mistake | Impact | Fix |
|---|---|---|
| Local state file (`terraform.tfstate`) committed to git or only on one laptop | Secrets/resource IDs in git history; lost state = Terraform "forgets" what it manages | Remote backend (S3 + DynamoDB lock), `.gitignore` state files |
| Running `apply` without reading `plan` output first | Unintended deletions/changes to real infrastructure | Always review `plan` — especially lines showing `-` (destroy) |
| Manually changing resources in the console that Terraform manages | Drift — next `apply` may revert your manual change unexpectedly, or `plan` shows confusing diffs | Make changes only via `.tf` + `apply`, OR `terraform import`/`refresh` if a manual change is intentional |
| Hardcoding secrets (AWS keys) in `.tf` files | Leaked credentials in git (same risk as Lesson 15 Q4) | Use environment variables / IAM roles for credentials, never in `.tf` |
| Massive single `main.tf` with everything in one file/module | Hard to review, hard to reuse | Split logically (`network.tf`, `compute.tf`, `variables.tf`); extract modules for repeated patterns |

### When NOT to over-engineer

- For this lesson's learning project, a **single root module** (no nested
  modules yet) with `main.tf`/`variables.tf`/`outputs.tf` is sufficient —
  modules become valuable once you're repeating the same VPC/EC2 pattern
  across multiple environments (Lesson 25).

---

## Step 3 — Alternatives

| Topic | Alternative | Note |
|---|---|---|
| Terraform (this lesson) | **OpenTofu** (open-source fork), **Pulumi** (IaC in general-purpose languages) | Per [zop.dev's 2026 IaC comparison](https://zop.dev/resources/blogs/infrastructure-as-code-best-practices-terraform-pulumi-and-opentofu-in-2026/), Terraform remains the most widely adopted with the largest job market; OpenTofu is a drop-in-compatible open-source alternative after HashiCorp's license change; Pulumi appeals if you'd rather write Python/TypeScript than HCL |
| Local state | **Terraform Cloud / S3+DynamoDB remote backend** | Local state is fine for solo learning experiments; remote state is mandatory the moment more than one person/process touches the same infrastructure |
| Terraform (provisioning) | **AWS CloudFormation/CDK** (AWS-native IaC) | CloudFormation is AWS-only; Terraform is multi-cloud — but CloudFormation/CDK are worth knowing if working in AWS-only shops |

---

## Step 4 — Hands-On Task (build this yourself)

**Goal:** Recreate Lesson 16's VPC + EC2 instance (and optionally Lesson 17's
S3 bucket) as Terraform `.tf` files, run the full `init`/`plan`/`apply`/
`destroy` cycle, and use **remote state**.

### Lens C — Manual → Automated → Why

**Manual (Lessons 15-18):** click through the AWS console / run individual
`aws ec2 run-instances`, `aws s3 mb`, `aws cloudwatch put-metric-alarm`
commands — each one-off, undocumented in any reviewable form, and easy to
forget to clean up.

**"Automated" (Terraform) — sketch of `infra/terraform/main.tf`:**
```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Remote state - configure this AFTER creating the S3 bucket + DynamoDB table
  backend "s3" {
    bucket         = "naviops-tfstate-<unique-suffix>"
    key            = "lesson20/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "naviops-tf-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region
}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "naviops-lesson20" }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  map_public_ip_on_launch = true
  tags = { Name = "naviops-public" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "ssh" {
  name        = "naviops-ssh"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_cidr]   # e.g. "203.0.113.5/32"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "web" {
  ami                    = var.ami_id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.ssh.id]
  key_name               = var.key_pair_name

  tags = { Name = "naviops-lesson20" }
}
```

`infra/terraform/variables.tf`:
```hcl
variable "aws_region"         { type = string, default = "us-east-1" }
variable "vpc_cidr"           { type = string, default = "10.0.0.0/16" }
variable "public_subnet_cidr" { type = string, default = "10.0.1.0/24" }
variable "my_ip_cidr"         { type = string }   # no default - set per-user, never commit your real IP
variable "ami_id"             { type = string }   # AlmaLinux/Ubuntu AMI for your region
variable "key_pair_name"      { type = string }   # your Lesson 07 SSH key pair name
```

`infra/terraform/outputs.tf`:
```hcl
output "instance_public_ip" {
  value = aws_instance.web.public_ip
}
```

**Why this matters:** notice this is **the exact same VPC/subnet/IGW/route
table/security-group/EC2 design you documented manually in Lesson 16's
`docs/aws/vpc-design.md`** — Terraform doesn't introduce new networking
concepts, it expresses the concepts you already understand as **declarative,
reviewable, repeatable code**. Per [Spacelift's Terraform best practices
guide](https://spacelift.io/blog/terraform-best-practices), starting with one
real resource and the plan→apply→destroy lifecycle (rather than jumping
straight to modules) is the right learning sequence.

### What to build, step by step

1. **Bootstrap remote state** (do this manually, once, via AWS CLI or
   console — chicken-and-egg: Terraform's own state needs somewhere to live):
   create an S3 bucket (`naviops-tfstate-<unique-suffix>`, versioning
   enabled) and a DynamoDB table (`naviops-tf-locks`, partition key
   `LockID`, string type).
2. Create `infra/terraform/main.tf`, `variables.tf`, `outputs.tf` per the
   sketch above (adjust AMI ID for your region — find a current
   AlmaLinux/Ubuntu AMI ID via `aws ec2 describe-images`).
3. Create `infra/terraform/terraform.tfvars` (gitignored — contains your real
   IP) and `infra/terraform/terraform.tfvars.example` (committed, with
   placeholders) for `my_ip_cidr`, `ami_id`, `key_pair_name`.
4. `terraform init` (downloads AWS provider, configures S3 backend).
5. `terraform fmt` and `terraform validate`.
6. `terraform plan` — read the output carefully: it should show **adding**
   ~7 resources (VPC, subnet, IGW, route table, association, security group,
   instance). Nothing should show "destroy" on a fresh apply.
7. `terraform apply` — confirm with `yes`, wait for completion.
8. `terraform output instance_public_ip` — SSH in, confirm it's the same
   instance you'd get manually (run Lesson 10's `hardening_audit.sh`).
9. **`terraform destroy`** — confirm everything is removed cleanly (check the
   AWS console: no leftover VPC/instance/security group).
10. Document in `docs/aws/terraform-design.md`: what you provisioned, the
    `plan` output summary, and a note on remote-state setup.
11. `.gitignore`: `*.tfstate*`, `.terraform/`, `terraform.tfvars` (real IP).
    Commit `infra/terraform/*.tf`, `terraform.tfvars.example`, and
    `docs/aws/terraform-design.md` on `lesson/20-terraform-fundamentals`.

---

## Step 5 — Verification

```bash
cd infra/terraform
terraform init
terraform validate
terraform plan -out=tfplan
terraform apply tfplan

# Confirm resources exist
terraform state list
terraform output instance_public_ip

# SSH + audit (Lessons 07/10)
ssh -i ~/.ssh/<key>.pem <user>@$(terraform output -raw instance_public_ip) \
  "bash -s" < scripts/hardening_audit.sh

# Clean teardown
terraform destroy
terraform state list   # should be empty after destroy
```

### Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| `terraform init` fails: backend config error | S3 bucket/DynamoDB table for remote state don't exist yet | Create them manually first (Step 4.1) — this is the one manual prerequisite |
| `terraform apply` fails: "InvalidAMIID.NotFound" | AMI ID is region-specific; you used an ID from a different region | `aws ec2 describe-images --owners amazon --filters "Name=name,Values=al2023-ami-*"` for your configured region |
| `terraform plan` shows changes on every run with no `.tf` edits | Drift — something was changed manually in the console, or a resource attribute Terraform can't fully control (e.g., AWS auto-assigns a value) | `terraform plan` diff shows what's drifting; investigate before assuming it's a bug |
| `terraform destroy` leaves orphaned resources | A resource was created outside Terraform, or manually deleted (state out of sync) | `terraform state list` to see what Terraform thinks exists; `terraform refresh` (or `plan`) to detect; manually clean up via console for anything Terraform doesn't track |
| State lock error: "Error acquiring the state lock" | A previous `apply`/`plan` crashed without releasing the DynamoDB lock | Confirm no other process is actually running, then `terraform force-unlock <LOCK_ID>` (use carefully) |

### Redaction check ✅

`terraform.tfvars` (real IP, AMI choices) must be `.gitignore`d — only commit
`terraform.tfvars.example` with placeholders. `docs/aws/terraform-design.md`
should use `<ACCOUNT_ID>`/`<PUBLIC_IP>` placeholders, same as Lessons 15-18.
Never commit `*.tfstate*` files — they contain resource IDs and sometimes
sensitive attribute values in plaintext.

---

## Step 6 — Quiz (Interview-Style, Graded)

**Q1.** What is the Terraform **state file**, and why is it dangerous to lose
or corrupt it? Why should it live in a remote backend (S3) rather than on your
laptop?

> **Your answer:**

**Q2.** **Scenario:** A teammate manually deleted a security group rule in the
AWS console that Terraform created. What will `terraform plan` show the next
time someone runs it, and what are the two ways to resolve the discrepancy?

> **Your answer:**

**Q3.** Explain the relationship between Terraform and Ansible (Lesson 13) —
"Terraform provisions, Ansible configures." Give a concrete example using a
resource from this lesson (the EC2 instance) and a task from Lesson 13's
`hardening.yml`.

> **Your answer:**

**Q4.** Why does Terraform's declarative model ("describe the desired end
state") support **idempotency** the same way Ansible modules do (Lesson 13
Q-series)? What happens if you run `terraform apply` twice in a row with no
`.tf` changes?

> **Your answer:**

**Q5.** What is **state locking**, and what concrete problem does it prevent?
(Tie back to "two engineers running `apply` at the same time.")

> **Your answer:**

**Q6.** When would you extract a **module** vs. keep resources in the root
module? Tie this back to Lesson 03 Q3's general "don't abstract prematurely"
principle.

> **Your answer:**

---

## Step 7 — Reflection

*(Fill in after the quiz)*

- What did you learn?
- What confused you?
- What would you do differently?

---

## Step 8 — Search Keywords For Further Understanding

**Core**
- `terraform init plan apply destroy explained`
- `terraform state file remote backend s3 dynamodb locking`
- `terraform variables outputs modules basics`
- `terraform vs ansible provisioning vs configuration`

**Tools**
- `terraform fmt validate`
- `terraform state list show import`
- `terraform aws_vpc aws_instance aws_security_group examples`

**Going further (future lessons)**
- `terraform modules reusable infrastructure`
- `terraform aws vpc module registry`
- `prometheus grafana terraform deployment`

---

## Lesson Status

- [ ] Hands-on task completed (Step 4)
- [ ] Verification passed (Step 5)
- [ ] Quiz answered + professional-answer comparisons requested (Step 6)
- [ ] Reflection completed (Step 7)
- [ ] Search Keywords reviewed (Step 8)

When complete, run the Update Protocol, then move to **Lesson 21 — Advanced
Networking (VLANs/VPNs/Load Balancing)**.

---

*Lesson 20 written by Navi v28 · 2026-06-11 · WebSearch sources:
[env0 Terraform Best Practices: State, Security and Reuse 2026](https://www.env0.com/blog/terraform-best-practices-state-management-reusability-security-and-beyond),
[Scalr Terraform State Files Best Practices](https://scalr.com/learning-center/terraform-state-files-best-practices),
[Spacelift 21 Terraform Best Practices](https://spacelift.io/blog/terraform-best-practices),
[zop.dev Infrastructure as Code: Terraform, Pulumi, OpenTofu in 2026](https://zop.dev/resources/blogs/infrastructure-as-code-best-practices-terraform-pulumi-and-opentofu-in-2026/)*
