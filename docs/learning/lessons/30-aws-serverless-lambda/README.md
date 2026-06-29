# Lesson 30 — AWS Serverless: Lambda + API Gateway

**Status:** 🟡 stub — scaffold only (author on demand) · **Date written:** 2026-06-28
**Gate Rule:** Concept → Real-World Use → Alternatives → Hands-On → Verification → Quiz → Reflection → Search Keywords
**Schema:** 8-Step + Lens A–E (NaviOps Linux house schema — matches Lessons 03–28)
**Intended study position:** after the AWS block (**L15–L18**), alongside **L25** Terraform-on-AWS. **M3 Cloud-capable (~Day 60)**.
**Why this lesson exists (job signal):** junior cloud JDs list the trio *"EC2, S3, **Lambda**."* You cover EC2 (L16) and S3 (L17); this closes the serverless third.
**Primary artifact (TODO):** an S3-triggered (or API-Gateway-fronted) Lambda + IAM execution role + CloudWatch Logs, deployed via Terraform/SAM. ⚠️ tear down nightly — Free-Plan $5 budget alert (see strategy memory).

> **How to use this lesson:** build on AWS IAM (L15), CloudWatch (L18), Terraform (L20/L25).
> Keep everything inside Free-Plan limits; destroy after each session.

---

## Step 1 — Concept

### What it is
> TODO — functions-as-a-service: event → ephemeral container → response; no server to manage.

### Why it exists
> TODO — pay-per-invocation, auto-scale to zero, event-driven glue.

### What problem it solves
> TODO — "run code on an event without owning/patching an EC2 box."

### Three-Level Depth (Lens A)
> TODO — Beginner (upload a handler) → SysAdmin (IAM role, env, triggers, cold starts) → Internals (Firecracker microVMs, execution model).

### Analogy (Lens B)
> TODO — analogy + ASCII visual (event source → Lambda → downstream + CloudWatch Logs).

---

## Step 2 — Real-World Use

### How cloud engineers use this daily
> TODO — S3/SQS/EventBridge triggers, cron jobs, lightweight APIs, ops automation (auto-tag, auto-remediate).

### Common mistakes
> TODO — over-broad IAM, no timeout/memory tuning, cold-start surprises, no DLQ, secrets in env plaintext.

### When NOT to use Lambda
> TODO — long-running/stateful, heavy compute, steady high-throughput → EC2/ECS/Fargate.

### Interview Angle
> TODO — "how does a Lambda get permission to write to S3?" (execution role, not keys).

---

## Step 3 — Alternatives
> TODO — EC2, ECS/Fargate, App Runner, Step Functions; Azure Functions / GCP Cloud Functions cross-map.

---

## Step 4 — Hands-On Task (build this yourself)

### Lens C — Manual → Automated → Why
> TODO — console click-deploy (manual) → Terraform/SAM (automated) → why IaC for serverless.

### What to build, step by step
> TODO — write a handler; create execution role (least privilege); wire an S3 or API-GW trigger; deploy via Terraform; invoke; read CloudWatch Logs; `terraform destroy`.

---

## Step 5 — Verification
> TODO — invoke and assert output; confirm log group entries; confirm IAM role scope; confirm teardown (no lingering billable resources).

### Troubleshooting
> TODO — `AccessDenied` (role/policy), timeout, throttling, cold start, missing log permissions.

### Redaction check ✅
> TODO — no account IDs, ARNs with account numbers, or access keys committed.

---

## Step 6 — Quiz (Interview-Style, Graded)
> TODO — 5–8 questions (execution role vs resource policy, concurrency, cold start, event vs request/response, cost model).

---

## Step 7 — Reflection
> TODO — where serverless fits vs the EC2 mental model you built in L16.

---

## Lens E — Attacker & Defender (Red / Blue)
- 🔴 **Red (attacker):** TODO — `lambda over-privileged role`, `event injection`, `MITRE ATT&CK cloud T1648 serverless execution`, `stolen execution role credentials`.
- 🔵 **Blue (defender):** TODO — `least-privilege IAM`, `CloudTrail on Lambda`, `secrets in SSM/Secrets Manager`, `function URL auth`, `GuardDuty`.

## Step 8 — Search Keywords For Further Understanding
> TODO — `aws lambda execution role`, `lambda cold start`, `terraform aws_lambda_function`, `aws sam`, `api gateway lambda proxy integration`.

---

## Lesson Status

- [ ] Hands-on task completed (Step 4)
- [ ] Verification passed + resources torn down (Step 5)
- [ ] Quiz answered + professional-answer comparisons requested (Step 6)
- [ ] Reflection completed (Step 7)
- [ ] Search Keywords reviewed (Step 8)

When complete, run the Update Protocol, then continue per `ROADMAP`/`JOB_MILESTONES.md`.

---

*Lesson 30 scaffolded by Navi v28 · 2026-06-28 · stub — WebSearch sources to be gathered at authoring time (≥2 validating sources, e.g. docs.aws.amazon.com Lambda).*
