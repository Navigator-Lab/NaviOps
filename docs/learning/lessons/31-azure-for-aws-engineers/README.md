# Lesson 31 — Azure for AWS-Literate Engineers (Bridge)

**Status:** 🟡 stub — scaffold only (author on demand) · **Date written:** 2026-06-28
**Gate Rule:** Concept → Real-World Use → Alternatives → Hands-On → Verification → Quiz → Reflection → Search Keywords
**Schema:** 8-Step + Lens A–E (NaviOps Linux house schema — matches Lessons 03–28)
**Intended study position:** after the AWS block + serverless (**L15–L18, L30**). **M4 differentiator (~Day 90)** — not a first-apply blocker.
**Why this lesson exists (job signal):** AWS = 58% of cloud jobs (your primary, correctly), but Azure owns enterprise/gov (68% of Fortune 500) and is growing faster YoY. This is a **translation bridge**, *not* a from-scratch second cloud — you already know the concepts; you're learning Azure's names and the `az` CLI. Cheapest possible "multi-cloud aware" checkbox.

> **How to use this lesson:** read as a mapping exercise. Every section pivots off what you
> already built on AWS. Free Azure account → tear down nightly, same discipline as AWS.

---

## Step 1 — Concept

### What it is
> TODO — Azure's model: Tenants → Subscriptions → **Resource Groups** → resources; **Entra ID** as the identity plane.

### Why it exists / why learn it second
> TODO — enterprise + government default; hybrid AD; the multi-cloud premium.

### What problem it solves
> TODO — being deployable in shops that aren't AWS-first without relearning cloud from zero.

### Three-Level Depth (Lens A)
> TODO — Beginner (portal + RG) → SysAdmin (`az` CLI, RBAC, networking) → Internals (ARM/Bicep, control vs data plane).

### Analogy (Lens B) — the AWS↔Azure Rosetta table
> TODO — fill the mapping (this is the heart of the lesson):
>
> | AWS | Azure | Note |
> |---|---|---|
> | IAM | Entra ID + Azure RBAC | identity split from authz |
> | EC2 | Virtual Machines | |
> | S3 | Blob Storage | |
> | VPC | Virtual Network (VNet) | |
> | Security Group | NSG | |
> | Lambda | Azure Functions | |
> | CloudWatch | Azure Monitor | |
> | CloudFormation | ARM / Bicep | Terraform spans both |
> | Route 53 | Azure DNS | |
> | RDS | Azure SQL / DB for PostgreSQL | |

---

## Step 2 — Real-World Use

### How engineers use this daily
> TODO — `az login`, RG-scoped deploys, reading the portal, Terraform `azurerm` provider.

### Common mistakes
> TODO — confusing Entra ID vs Azure RBAC, RG sprawl, forgetting subscription scope, leaving resources running.

### When NOT to reach for Azure
> TODO — when the shop is AWS-native; don't fragment your depth before landing the first role.

### Interview Angle
> TODO — "you know AWS — how would you map our Azure stack?" (show the Rosetta table fluency).

---

## Step 3 — Alternatives
> TODO — staying single-cloud (AWS) vs GCP as the third; multi-cloud Terraform as the unifier.

---

## Step 4 — Hands-On Task (build this yourself)

### Lens C — Manual → Automated → Why
> TODO — portal click (manual) → `az` CLI → Terraform `azurerm` (automated) → why IaC stays the same across clouds.

### What to build, step by step
> TODO — create a free subscription; `az group create`; deploy a small VM + VNet + NSG (mirror your L16 VPC build); deploy a Storage account (mirror S3); destroy.

---

## Step 5 — Verification
> TODO — `az resource list -g <rg>`; SSH the VM; access the blob; confirm teardown (`az group delete`).

### Troubleshooting
> TODO — auth/tenant errors, NSG blocking, subscription/scope confusion, quota limits.

### Redaction check ✅
> TODO — no tenant IDs, subscription IDs, client secrets, or connection strings committed.

---

## Step 6 — Quiz (Interview-Style, Graded)
> TODO — 5–8 questions (map 5 AWS services to Azure; Entra ID vs RBAC; what a Resource Group is; subscription vs account).

---

## Step 7 — Reflection
> TODO — how much transferred for free; what's genuinely different vs just renamed.

---

## Lens E — Attacker & Defender (Red / Blue)
- 🔴 **Red (attacker):** TODO — `entra id consent phishing`, `over-privileged service principal`, `MITRE ATT&CK Azure AD`, `managed identity abuse`.
- 🔵 **Blue (defender):** TODO — `conditional access`, `azure rbac least privilege`, `defender for cloud`, `entra id sign-in logs`.

## Step 8 — Search Keywords For Further Understanding
> TODO — `aws to azure service map`, `az cli cheat sheet`, `entra id vs iam`, `terraform azurerm provider`, `azure resource group best practices`.

---

## Lesson Status

- [ ] Hands-on task completed (Step 4)
- [ ] Verification passed + resource group deleted (Step 5)
- [ ] Quiz answered + professional-answer comparisons requested (Step 6)
- [ ] Reflection completed (Step 7)
- [ ] Search Keywords reviewed (Step 8)

When complete, run the Update Protocol. Pairs with NaviOpsEnterprise L37 (Entra ID) for the identity side.

---

*Lesson 31 scaffolded by Navi v28 · 2026-06-28 · stub — WebSearch sources to be gathered at authoring time (≥2 validating sources, e.g. learn.microsoft.com + an AWS↔Azure mapping).*
