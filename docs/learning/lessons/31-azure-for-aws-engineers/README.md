# Lesson 31 — Azure for AWS-Literate Engineers (Bridge)

**Status:** ready for self-study · **Date written:** 2026-06-28
**Gate Rule:** Concept → Real-World Use → Alternatives → Hands-On → Verification → Quiz → Reflection → Search Keywords
**Builds on:** the entire AWS block — L15 (IAM), L16 (EC2/VPC), L17 (S3), L18 (CloudWatch), L20/L25 (Terraform), L30 (Lambda). **Roadmap slot:** M4 differentiator (~Day 90) — *not* a first-apply blocker.

> **How to use this lesson:** read it as a **translation exercise**, not a from-scratch cloud.
> You already know the concepts (compute, storage, identity, networking, IaC) from AWS — here you
> learn Azure's **names**, its **resource hierarchy**, and the **`az` CLI**. Why bother when
> AWS = 58% of cloud jobs? Because Azure owns enterprise + government (≈68% of the Fortune 500),
> and "multi-cloud aware" is the cheapest résumé differentiator you can buy with one lesson.
> ⚠️ Free Azure account — tear down nightly, same discipline as AWS.

---

## Step 1 — Concept

### What it is

**Azure** is Microsoft's cloud — the same *category* of services you used on AWS, under different
names and a different **resource hierarchy**. Where AWS organizes by **Account → region →
resources**, Azure nests: **Tenant (the Entra ID directory) → Subscription (billing + isolation
boundary) → Resource Group (a lifecycle container) → Resources**. Identity is split: **Entra ID**
(formerly Azure AD) handles *authentication* (who you are), and **Azure RBAC** handles
*authorization* (what you may do) — where AWS **IAM** does both in one service.

### Why it exists / why learn it second

You learn Azure *second*, deliberately. Per the job-market research behind this curriculum, AWS is
the right *first* cloud (most jobs, best self-study path, remote-heavy). But a large slice of
enterprise and **all** of the Microsoft-shop / government world runs Azure, and Azure postings are
growing faster YoY. Because the **concepts transfer ~1:1**, a single bridge lesson converts your
AWS depth into "can work in an Azure shop" — multi-cloud-aware engineers command a real premium.

### What problem it solves

| Problem | Azure-bridge solution |
|---|---|
| "This great role is an Azure shop and I only know AWS" | The concepts map directly — you learn names + `az`, not cloud from zero |
| "Where's the 'account' in Azure?" | Subscription (billing/isolation) + Resource Group (lifecycle), not one flat account |
| "How do I do IAM here?" | Entra ID (authn) + Azure RBAC role assignments (authz) |
| "Do I have to relearn Terraform?" | No — same Terraform, swap the `aws` provider for `azurerm` |

### Three-Level Depth (Lens A)

- **Level 1 — Beginner:** Sign in to the **portal**; create a **Resource Group**; drop a VM and a
  Storage account into it; delete the Resource Group to delete *everything* in it (the lifecycle
  container — there's no AWS exact equivalent).
- **Level 2 — Operator:** Use the **`az` CLI** (`az login`, `az group create`, `az vm create`).
  Understand **scope**: an RBAC role assignment applies at a **management group / subscription /
  resource group / resource** scope and *inherits downward* (assign at the RG, it covers
  everything inside). Per [Microsoft Learn RBAC](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/scenarios-rbac),
  a role assignment binds a **principal** (user/group/**service principal** — managed identities
  are service principals) to a **role definition** at a **scope**.
- **Level 3 — Internals (Lens D):** Everything is an **ARM** (Azure Resource Manager) operation —
  the portal, `az`, Bicep, and Terraform all ultimately call the ARM control plane. Per
  [Microsoft Learn](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/scenarios-rbac),
  **Bicep** is Azure's native IaC (a friendlier language over ARM JSON, **no state file** — ARM is
  the source of truth). **Terraform `azurerm`** is the multi-cloud alternative (explicit state,
  works across AWS/Azure/GCP). A role assignment's `principalId` is the Entra **object ID** (a
  GUID) — set `principalType` explicitly for service principals/managed identities or you get
  intermittent deploy errors.

### Analogy (Lens B) — the AWS↔Azure Rosetta table

The heart of this lesson. Sources: [AWS↔Azure mapping cheat sheet (DEV)](https://dev.to/aws-builders/aws-azure-mapping-cheat-sheet-1dom),
[AWS vs Azure vs GCP service mapping 2026 (cloudjobs.io)](https://cloudjobs.io/insights/articles/aws-vs-azure-vs-gcp-comparison-2026).

| Concept | AWS (you know) | Azure (learn) | Note |
|---|---|---|---|
| Identity / authn | IAM (users, principals) | **Entra ID** | authn split from authz |
| Authorization | IAM policies | **Azure RBAC** role assignments | role + principal + **scope** (inherits down) |
| Account boundary | Account | **Subscription** (+ **Tenant** above) | billing + isolation |
| Resource grouping | (tags / no real container) | **Resource Group** | lifecycle container — delete RG = delete all |
| VM compute | EC2 | **Virtual Machines** | building-block, near-1:1 |
| Object storage | S3 | **Blob Storage** (Storage account) | |
| Serverless | Lambda (L30) | **Azure Functions** | same FaaS model |
| Private network | VPC | **Virtual Network (VNet)** | |
| Instance firewall | Security Group | **NSG** (Network Security Group) | |
| Managed DNS | Route 53 | **Azure DNS** | |
| Monitoring/logs | CloudWatch | **Azure Monitor** / Log Analytics | |
| Managed relational DB | RDS | **Azure SQL** / DB for PostgreSQL | |
| Secrets | Secrets Manager / SSM | **Key Vault** | |
| Native IaC | CloudFormation | **ARM / Bicep** | Terraform spans both |
| Workload identity | IAM role for service | **Managed Identity** (a service principal) | "no secrets" pattern |

The mapping analogy **breaks down** where parity needs a *combination* of services, not 1:1 — e.g.
AWS IAM ≈ Entra ID **+** Azure RBAC; some AWS services map to "a mix of Azure features," not a
single product. Treat the table as a starting index, not a literal dictionary.

---

## Step 2 — Real-World Use

### How engineers use this daily

```bash
az login                                            # device/browser auth into a tenant
az account show --query '{sub:name, id:id, tenant:tenantId}'   # which subscription am I in?
az group create -n navi-rg -l eastus                # the lifecycle container
az vm create -g navi-rg -n web --image Ubuntu2204 \  # ~ EC2 run-instances
  --size Standard_B1s --admin-username azureuser --generate-ssh-keys
az storage account create -g navi-rg -n navistore$RANDOM --sku Standard_LRS  # ~ S3
az role assignment create --assignee <objectId> \   # ~ attach IAM policy, but scoped
  --role "Storage Blob Data Reader" --scope <resource-or-rg-id>
az group delete -n navi-rg --yes --no-wait          # delete the RG = delete everything in it
```

**Real scenarios:**
1. **RG-scoped deploys** — everything for an app goes in one Resource Group; tear down the whole
   environment by deleting the RG (cleaner than chasing individual AWS resources).
2. **Terraform across both clouds** — the same workflow you learned in L25, with `provider
   "azurerm"`; a multi-cloud shop runs one toolchain.
3. **Managed Identity** — a VM/Function is granted an identity and an RBAC role; it calls Key Vault
   or Storage with **no secrets** — the Azure version of L30's execution-role pattern.

### Common mistakes

| Mistake | Impact | Fix |
|---|---|---|
| Confusing **Entra ID** (authn) with **Azure RBAC** (authz) | "I added them to the directory but they still can't do anything" | Directory membership ≠ permissions; create an RBAC **role assignment** at a scope |
| Forgetting which **subscription** you're in | Resources land in the wrong place / wrong bill | `az account show`; `az account set --subscription <id>` |
| **Resource Group sprawl** | Ungrouped resources, no clean teardown | One RG per environment/app lifecycle |
| Leaving resources running | Free-credit burn | `az group delete` nightly; budget alert |
| Not setting `principalType` in IaC role assignments | Intermittent deploy failures (esp. service principals/MIs) | Set it explicitly ([source](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/scenarios-rbac)) |

### When NOT to reach for Azure

- When the shop is **AWS-native** — don't fragment your depth chasing a second cloud before you've
  landed the first role. This lesson is a *bridge*, not a pivot.
- For a personal project with no enterprise/Microsoft constraint — staying single-cloud keeps you
  faster and deeper.

### Interview Angle

**Question:** "You're strong on AWS; we're an Azure shop. How would you get productive, and how do
permissions differ from IAM?"

A weak answer says "I'd have to learn Azure from scratch." A strong answer shows the **Rosetta-table
fluency**: "the building blocks map — EC2→VMs, S3→Blob, VPC→VNet, Lambda→Functions, and my
Terraform carries over via the `azurerm` provider. The real *conceptual* difference is identity:
AWS IAM is one service for authn+authz, while Azure splits **Entra ID** (who you are) from **Azure
RBAC** (what you can do, assigned at a **scope** that inherits downward). And Resource Groups give
me a clean lifecycle container AWS doesn't have." Senior candidates name the *split* and the
*scope-inheritance* model rather than just reciting service names.

---

## Step 3 — Alternatives

| Path | Use case |
|---|---|
| **Stay single-cloud (AWS)** | Deepest path to a first role; correct default until landed |
| **Azure bridge** (this lesson) | Cheap "multi-cloud aware" checkbox; required for Microsoft/gov shops |
| **GCP as the third cloud** | Only if a target role/employer is GCP-centric |
| **Terraform as the unifier** | One IaC skill spans all three — the highest-leverage cloud-agnostic investment |
| **Bicep** | Azure-only native IaC; simpler onboarding *if* you're Azure-only, but no multi-cloud ([source](https://medium.com/@StackGuardian/terraforming-your-azure-a-practical-guide-to-migrating-from-bicep-to-terraform-339f3b08c5fa)) |

**For NaviOps:** keep **Terraform** as your unifier (you already know it from L25) — learn *enough*
Bicep to read it, but don't invest deeply unless a job demands Azure-only IaC. The bridge's value
is breadth, not a second from-scratch specialty.

---

## Step 4 — Hands-On Task (build this yourself)

**Goal:** Mirror your AWS L16 build on Azure — a VM in a VNet with an NSG, plus a Storage account
(≈ S3) — first by `az` CLI, then as Terraform, then destroy.

### Lens C — Manual → Automation → Why

**Manual (`az` CLI):** the commands in Step 2 (`az group create` → `az vm create` → `az storage
account create`). Good for learning, no record.

**Automated (`main.tf` with `azurerm` — what you commit):**
```hcl
terraform { required_providers { azurerm = { source = "hashicorp/azurerm" } } }
provider "azurerm" { features {} }

resource "azurerm_resource_group" "rg" { name = "navi-rg" location = "eastus" }

resource "azurerm_virtual_network" "vnet" {           # ~ VPC
  name = "navi-vnet" address_space = ["10.0.0.0/16"]
  location = azurerm_resource_group.rg.location resource_group_name = azurerm_resource_group.rg.name
}
resource "azurerm_subnet" "subnet" {
  name = "app" resource_group_name = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name address_prefixes = ["10.0.1.0/24"]
}
resource "azurerm_network_security_group" "nsg" {     # ~ Security Group
  name = "navi-nsg" location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  security_rule {
    name = "SSH" priority = 100 direction = "Inbound" access = "Allow" protocol = "Tcp"
    source_port_range = "*" destination_port_range = "22"
    source_address_prefix = "<your.ip>/32" destination_address_prefix = "*"   # scope to YOUR ip
  }
}
resource "azurerm_storage_account" "store" {          # ~ S3
  name = "navistore${substr(md5(azurerm_resource_group.rg.id),0,8)}"
  resource_group_name = azurerm_resource_group.rg.name location = azurerm_resource_group.rg.location
  account_tier = "Standard" account_replication_type = "LRS"
}
# (VM + NIC omitted for brevity — add azurerm_network_interface + azurerm_linux_virtual_machine)
```
**Why IaC stays the same across clouds:** the *workflow* (`init`/`plan`/`apply`/`destroy`), the
review-in-a-PR discipline, and the destroy-to-clean-up habit are identical to L25 — only the
provider and resource names change. That portability is the whole point of investing in Terraform
over a cloud-native tool.

### What to build, step by step

1. `az login`; confirm subscription with `az account show`.
2. Do the **manual** `az` build (Step 2) once to feel the hierarchy; `az group delete` it.
3. Write `main.tf` above on `lesson/31-azure-for-aws-engineers`; `terraform init && apply`.
4. **Fill the Rosetta table from memory** (Lens B) as your portfolio artifact — map 12 AWS
   services to Azure without looking.
5. Add an RBAC role assignment (`Storage Blob Data Reader`) scoped to the storage account.
6. **Tear down:** `terraform destroy` (or `az group delete -n navi-rg`); confirm the RG is gone.

---

## Step 5 — Verification

```bash
az group show -n navi-rg --query properties.provisioningState        # 'Succeeded'
az resource list -g navi-rg -o table                                 # VNet, NSG, storage present
az role assignment list --scope <storage-id> -o table                # the reader assignment
terraform destroy -auto-approve
az group exists -n navi-rg                                           # 'false' = clean teardown ✅
```

### Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| `az login` fails / wrong tenant | Multiple tenants/subscriptions | `az login --tenant <id>`; `az account set --subscription <id>` |
| Can access portal but RBAC says denied | Entra membership ≠ authorization | Create a **role assignment** at the right scope |
| Storage account name error | Name not globally unique / invalid chars | Lowercase, 3–24 chars, globally unique (hence the hash suffix) |
| `AuthorizationFailed` in Terraform | Service principal lacks scope | Grant the SP an RBAC role at the subscription/RG |
| NSG still blocks SSH | Rule priority/source wrong | Lower priority number = higher precedence; scope source to your IP |
| Resources linger after "delete" | Deleted individual resources, not the RG | `az group delete` removes the whole container |

### Redaction check ✅

No real **tenant IDs**, **subscription IDs**, **object IDs (GUIDs)**, **client secrets**, or
**storage connection strings** committed. Terraform `*.tfstate` holds these — **gitignore it**.
Scope NSG source rules to *your* IP, never `0.0.0.0/0` for SSH.

---

## Step 6 — Quiz (Interview-Style, Graded)

**Q1.** Map these AWS services to Azure: IAM, EC2, S3, VPC, Lambda, Security Group, CloudWatch.
Which AWS service needs **two** Azure services to cover it, and why?

> **Your answer:**

**Q2.** Explain the difference between **Entra ID** and **Azure RBAC**. A user is in the directory
but "can't do anything" — what's missing?

> **Your answer:**

**Q3.** What is a **Resource Group**, and what's the operational advantage it gives you that a flat
AWS account doesn't?

> **Your answer:**

**Q4.** Describe the Azure resource hierarchy from **Tenant** down to a **resource**. Where does an
RBAC **scope** sit, and what does "inherits downward" mean?

> **Your answer:**

**Q5.** You know Terraform from AWS. What changes to use it on Azure, and when would you pick
**Bicep** instead?

> **Your answer:**

**Q6.** What is a **Managed Identity**, and which AWS pattern (from L30) is it the equivalent of?

> **Your answer:**

---

## Step 7 — Reflection

*(Fill in after the quiz)*

- What did you learn?
- What transferred for free from your AWS knowledge, and what's genuinely *different* vs just renamed?
- Did building the Rosetta table from memory expose any gaps?

---

## Lens E — Attacker & Defender (Red / Blue)

> Red/Blue framing (Gate Rule **Lens E**, D14). Build *both* mindsets.
> Frameworks: [MITRE ATT&CK Cloud](https://attack.mitre.org/matrices/enterprise/cloud/) · [Entra security for AWS (Microsoft Learn)](https://learn.microsoft.com/en-us/azure/architecture/reference-architectures/aws/aws-azure-ad-security).

**🔴 Attacker (how it's abused — Step 2):** **Consent phishing** (tricking a user into granting an
app broad Entra permissions), **over-privileged service principals / managed identities**, and
**RBAC scope creep** (Owner at subscription scope when Contributor at an RG would do) are the
classic Azure footholds (ATT&CK **T1078.004** Valid Cloud Accounts). Legacy auth protocols bypass
modern controls.

**🔵 Defender (detect & harden — Step 5):** **Conditional Access** + MFA as the control plane;
**Azure RBAC least privilege** scoped as narrowly as possible (resource/RG, not subscription);
**Privileged Identity Management (PIM)** for just-in-time admin; **Defender for Cloud** + **Entra
sign-in logs**; set `principalType` and avoid standing Owner assignments.

## Step 8 — Search Keywords For Further Understanding

**Core**
- `aws to azure service map cheat sheet`
- `entra id vs azure rbac authentication authorization`
- `azure resource hierarchy tenant subscription resource group`
- `azure rbac scope inheritance`

**Tools**
- `az cli cheat sheet`
- `terraform azurerm provider getting started`
- `bicep vs terraform azure`

**Going further**
- `azure managed identity vs service principal`
- `azure key vault secrets`
- `azure conditional access pim least privilege`
- `azure functions vs aws lambda`

---

**Red / Blue (Lens E — study attacker & defender in parallel):**
- 🔴 **Red (attacker):** `entra id consent phishing`, `azure over-privileged service principal`, `MITRE ATT&CK T1078.004 valid cloud accounts`, `azure rbac owner scope abuse`
- 🔵 **Blue (defender):** `azure conditional access mfa`, `azure rbac least privilege scope`, `privileged identity management pim`, `defender for cloud`

## Lesson Status

- [ ] Hands-on task completed (Step 4) + Rosetta table filled from memory
- [ ] Verification passed + resource group deleted (Step 5)
- [ ] Quiz answered + professional-answer comparisons requested (Step 6)
- [ ] Reflection completed (Step 7)
- [ ] Search Keywords reviewed (Step 8)

When complete, run the Update Protocol. Pairs with **NaviOpsEnterprise L37 (Entra ID)** for the
identity/help-desk side of Azure.

---

*Lesson 31 written by Navi v28 · 2026-06-28 · WebSearch sources:
[AWS↔Azure Mapping Cheat Sheet (DEV)](https://dev.to/aws-builders/aws-azure-mapping-cheat-sheet-1dom),
[AWS vs Azure vs GCP Service Mapping 2026 (cloudjobs.io)](https://cloudjobs.io/insights/articles/aws-vs-azure-vs-gcp-comparison-2026),
[Azure RBAC with Bicep/ARM/Terraform (Microsoft Learn)](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/scenarios-rbac),
[Entra security for AWS (Microsoft Learn)](https://learn.microsoft.com/en-us/azure/architecture/reference-architectures/aws/aws-azure-ad-security),
[Bicep→Terraform migration guide (StackGuardian)](https://medium.com/@StackGuardian/terraforming-your-azure-a-practical-guide-to-migrating-from-bicep-to-terraform-339f3b08c5fa)*
