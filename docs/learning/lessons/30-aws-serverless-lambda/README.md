# Lesson 30 — AWS Serverless: Lambda + API Gateway

**Status:** ready for self-study · **Date written:** 2026-06-28
**Gate Rule:** Concept → Real-World Use → Alternatives → Hands-On → Verification → Quiz → Reflection → Search Keywords
**Builds on:** L15 (IAM), L16 (EC2/VPC), L17 (S3), L18 (CloudWatch), L20/L25 (Terraform), L29 (Kubernetes — the "always-on orchestration" contrast). **Roadmap slot:** M3 Cloud-capable (~Day 60).

> **How to use this lesson:** same as Lessons 03–29. This closes the **"EC2, S3, *Lambda*"**
> trio that junior cloud JDs list — you have compute (L16) and storage (L17); this is
> event-driven compute. ⚠️ **Everything here fits the Free Plan** — set the **$5 budget
> alert** (L15) and `terraform destroy` after each session.

---

## Step 1 — Concept

### What it is

**AWS Lambda** runs your code in response to an **event** without you provisioning or managing
a server — "functions as a service." You upload a **handler** function; Lambda runs it when a
trigger fires (an HTTP request, an S3 upload, a queue message, a schedule), scales automatically
from zero to thousands of concurrent executions, and you pay only for the milliseconds it runs.
Per the [Lambda execution environment docs](https://docs.aws.amazon.com/lambda/latest/dg/lambda-runtime-environment.html),
each invocation runs inside an isolated **execution environment** (a Firecracker microVM) with
your runtime and code loaded.

**API Gateway** is the most common front door: it turns Lambda into a real HTTP API. Per the
[API Gateway Lambda integration docs](https://docs.aws.amazon.com/lambda/latest/dg/services-apigateway.html),
it invokes your function **synchronously** with a JSON event representing the HTTP request, and
returns your function's response to the caller.

### Why it exists

With EC2 (L16) you rent a *server* — you patch it, you pay for it 24/7 even when idle, and you
scale it yourself. A huge class of work is **event-driven and bursty**: "when a file lands in S3,
process it"; "when this HTTP endpoint is called, return JSON." Running a full EC2 box for that is
wasteful. Lambda flips the model: **no idle cost** (scales to zero), **no servers to patch**, and
**automatic scaling**. It's the serverless counterpart to L29's Kubernetes — both run containers,
but Lambda manages *everything* below your function, where k8s hands you the cluster.

### What problem it solves

| Problem | Lambda solution |
|---|---|
| "An EC2 box sits idle 95% of the day but I pay for all of it" | Lambda scales to zero — $0 when no events |
| "When a user uploads to S3, resize the image" | S3 event → Lambda, no polling server |
| "I need a small JSON API but don't want to run/patch a web server" | API Gateway → Lambda |
| "Run a cleanup job every night" | EventBridge schedule → Lambda (serverless cron) |
| "Traffic spikes 50× at launch and my server falls over" | Lambda scales out automatically per request |

### Three-Level Depth (Lens A)

- **Level 1 — Beginner:** Write a `handler(event, context)` function. It receives the `event`
  (the trigger's data — e.g. the HTTP request), does its work, and returns a response. You set a
  **trigger** (API Gateway, S3, EventBridge) and an **execution role** (its permissions).
- **Level 2 — Operator:** Per [Lambda best practices 2026](https://tasrieit.com/blog/aws-lambda-best-practices-production-2026)
  and [Lambda cost optimization](https://leanopstech.com/blog/aws-lambda-cost-optimization-2026/):
  **memory is the master dial** — CPU scales *proportionally* with memory (128 MB ≈ a fraction of
  a vCPU; 1,769 MB = a full vCPU), so raising memory often *lowers* total cost because the
  function finishes faster. **Duration is 60–85% of the bill.** Set **timeout to p99 + ~50%**, not
  the 15-min max (a hung invocation runs — and bills — until timeout). Prefer **ARM64/Graviton2**
  (~20% cheaper, ~19% faster, usually no code change for Python/Node).
- **Level 3 — Internals (Lens D):** Per the
  [execution environment lifecycle](https://docs.aws.amazon.com/lambda/latest/dg/lambda-runtime-environment.html)
  and [AWS's cold-start article](https://aws.amazon.com/blogs/compute/understanding-and-remediating-cold-starts-an-aws-lambda-perspective/):
  the environment passes through **Init → Invoke → Shutdown**. A **cold start** happens when no
  warm environment exists (first call, after idle, or during a scale-up burst) — it pays **Init +
  Invoke**; a **warm start** reuses the environment and pays only **Invoke**, and one environment
  serves thousands of warm calls before teardown. Cold starts are typically **<1% of invocations**
  (sub-100ms to ~1s). Mitigations: **Provisioned Concurrency** (pre-warmed environments) and
  **SnapStart** (snapshot/restore the initialized environment). The same **Firecracker microVM /
  cgroups / namespaces** isolation from L11/L29 is what AWS uses per-environment.

### Analogy (Lens B)

- **EC2 vs Lambda** = renting an apartment vs taking an Uber. EC2 (apartment) — you pay rent
  24/7 whether home or not, and you maintain it. Lambda (Uber) — you pay only for the trip
  (invocation), someone else owns and maintains the car, and you never think about parking.
- **Cold vs warm start** = a food truck that's already open and grilling (warm — order served
  fast) vs one that has to park, fire up the grill, and prep (cold — first order is slower). Once
  open it serves many orders quickly before closing for the night.
- **Execution role** = a building keycard scoped to exactly the floors the worker needs. The
  function doesn't carry your master keys (your AWS creds); it's *issued* a temporary, narrow
  keycard (the role) — and you make it open as few doors as possible.

The Uber analogy breaks down for **stateful / long-running** work — Lambda invocations are
ephemeral and time-boxed (15-min max), so it's the wrong tool for a long-lived process (that's
EC2/ECS, see Step 3).

---

## Step 2 — Real-World Use

### How cloud engineers use this daily

```bash
# Inspect / invoke (AWS CLI)
aws lambda list-functions --query 'Functions[].FunctionName'
aws lambda invoke --function-name hello --payload '{"name":"Navi"}' /tmp/out.json && cat /tmp/out.json
aws lambda get-function-configuration --function-name hello --query '{mem:MemorySize,timeout:Timeout,arch:Architectures}'

# Logs (CloudWatch — every Lambda auto-logs to /aws/lambda/<name>)
aws logs tail /aws/lambda/hello --follow

# Tighten the dials (cost + safety)
aws lambda update-function-configuration --function-name hello \
  --memory-size 256 --timeout 6 --architectures arm64
```

**Real production scenarios:**
1. **S3-triggered processing** — a file lands in a bucket → S3 event invokes Lambda → it
   thumbnails/validates/ingests the object. No polling server.
2. **HTTP API** — API Gateway (or a Lambda **Function URL**) → Lambda returns JSON. The whole
   backend is a function, scaling per request.
3. **Serverless cron / ops automation** — EventBridge schedule → Lambda that auto-tags untagged
   resources, snapshots volumes, or remediates a finding (ties to L18 CloudWatch).

### Common mistakes

| Mistake | Impact | Fix |
|---|---|---|
| Over-broad execution role (`*` actions) | A compromised function can touch your whole account; `iam:PassRole` is a top privesc path | One role **per function**, least privilege; generate it from CloudTrail with **IAM Access Analyzer** ([source](https://docs.aws.amazon.com/lambda/latest/dg/least-privilege.html)) |
| Secrets in environment variables | Visible in console, CloudFormation, deploy logs | **Secrets Manager / SSM Parameter Store** ([source](https://tasrieit.com/blog/aws-lambda-best-practices-production-2026)) |
| Timeout left at 900s "just in case" | Runaway/hung invocations bill the full duration | Set timeout to **p99 + 50%** from CloudWatch |
| Function URL with `AuthType: NONE` | Wiz found thousands of internal functions exposed to the public internet | Use **`AWS_IAM`** auth (or API Gateway authorizer) |
| Never tuning memory | Paying 50%+ too much; slow cold path | **Lambda Power Tuning** to find the cost/perf-optimal memory |
| Heavy work in the handler body, not Init | Re-pays setup every invoke | Initialize clients/connections **outside** the handler (reused across warm calls) |

### When NOT to use Lambda

- **Long-running / stateful** work (>15 min, persistent connections, big in-memory state) → EC2,
  ECS/Fargate, or k8s (L29).
- **Steady, high, predictable throughput** — at constant high volume, always-on compute can be
  cheaper than per-invocation pricing.
- **Heavy/spiky cold-start-sensitive latency** without mitigation — a chatty user-facing path may
  need Provisioned Concurrency or a different model.

### Interview Angle

**Question:** "Your Lambda needs to write objects to an S3 bucket. How does it get permission —
and what's wrong with attaching your own access keys? Then: the function is slow and the bill is
high — what two dials do you check first?"

A junior answer hardcodes credentials or says "give it S3 full access." A senior answer explains
the **execution role**: Lambda assumes a role you define, getting *temporary* credentials scoped
to exactly `s3:PutObject` on *that* bucket ARN — no long-lived keys to leak, generated from real
usage via IAM Access Analyzer. On cost/latency they go straight to **memory** (CPU scales with it;
more memory can finish faster *and* cheaper) and **timeout** (p99 + buffer, not 900s), and mention
**ARM64** as a near-free ~20% cut. Senior candidates connect the IAM model to *why* (no secrets,
least blast radius) and treat memory as a performance dial, not just a cost one.

---

## Step 3 — Alternatives

| Option | Use case |
|---|---|
| **Lambda** (this lesson) | Event-driven, bursty, scale-to-zero; glue + small APIs + ops automation |
| **EC2** (L16) | Long-lived, stateful, full OS control; steady high load |
| **ECS / Fargate** | Containerized services without managing nodes; longer-running than Lambda, container-native |
| **EKS / Kubernetes** (L29) | Portable orchestration at scale, multi-cloud; most ops overhead |
| **Step Functions** | Orchestrate *many* Lambdas into a workflow (retries, branching, state) |
| **App Runner / Fargate** | "Just run my container as a web service" without k8s |
| **Azure Functions / GCP Cloud Functions** | The same FaaS model on other clouds (ties to L31 bridge) |

**For NaviOps:** Lambda is the right serverless entry — it composes with everything you've built
(IAM L15, S3 L17, CloudWatch L18, Terraform L25). Mentally map it against L29: **Lambda = "AWS runs
the platform"; Kubernetes = "you run the platform."** Knowing *when each wins* is the interview-grade skill.

---

## Step 4 — Hands-On Task (build this yourself)

**Goal:** Deploy an HTTP API — API Gateway → Lambda — that returns JSON, with a least-privilege
execution role, via Terraform, then tear it down.

### Lens C — Manual → Automated → Why

**Manual (console / CLI — fine for learning, bad for repeatability):**
```bash
# zip a handler and create the function by hand (illustrative)
zip fn.zip handler.py
aws lambda create-function --function-name hello --runtime python3.12 \
  --handler handler.lambda_handler --zip-file fileb://fn.zip \
  --role arn:aws:iam::<acct>:role/hello-exec --architectures arm64
```
**Automated (`main.tf` — what you commit):**
```hcl
# handler.py:
#   def lambda_handler(event, context):
#       return {"statusCode": 200,
#               "headers": {"Content-Type": "application/json"},
#               "body": "{\"msg\": \"hello from Navi serverless\"}"}

data "archive_file" "fn" {
  type = "zip"  ; source_file = "handler.py" ; output_path = "fn.zip"
}

# Least-privilege execution role: assume-role for Lambda + the managed basic-logging policy ONLY
resource "aws_iam_role" "exec" {
  name = "hello-exec"
  assume_role_policy = jsonencode({ Version = "2012-10-17", Statement = [{
    Effect = "Allow", Principal = { Service = "lambda.amazonaws.com" }, Action = "sts:AssumeRole" }]})
}
resource "aws_iam_role_policy_attachment" "logs" {
  role       = aws_iam_role.exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"  # CloudWatch Logs only
}

resource "aws_lambda_function" "hello" {
  function_name    = "hello"
  filename         = data.archive_file.fn.output_path
  source_code_hash = data.archive_file.fn.output_base64sha256
  handler          = "handler.lambda_handler"
  runtime          = "python3.12"
  architectures    = ["arm64"]        # ~20% cheaper
  memory_size      = 256              # tune later with Power Tuning
  timeout          = 6                # p99 + buffer, NOT 900
  role             = aws_iam_role.exec.arn
}

# HTTP API (cheaper/simpler than REST) with a proxy route to the function
resource "aws_apigatewayv2_api" "http" { name = "hello-api" protocol_type = "HTTP" }
resource "aws_apigatewayv2_integration" "lambda" {
  api_id = aws_apigatewayv2_api.http.id ; integration_type = "AWS_PROXY"
  integration_uri = aws_lambda_function.hello.invoke_arn ; payload_format_version = "2.0"
}
resource "aws_apigatewayv2_route" "r" {
  api_id = aws_apigatewayv2_api.http.id ; route_key = "GET /hello"
  target = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}
resource "aws_apigatewayv2_stage" "s" { api_id = aws_apigatewayv2_api.http.id ; name = "$default" ; auto_deploy = true }
resource "aws_lambda_permission" "allow_apigw" {        # let API Gateway invoke the function
  statement_id = "AllowAPIGW" ; action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.hello.function_name
  principal = "apigateway.amazonaws.com" ; source_arn = "${aws_apigatewayv2_api.http.execution_arn}/*/*"
}
output "url" { value = "${aws_apigatewayv2_stage.s.invoke_url}/hello" }
```
**Why IaC for serverless:** the function, its role, the API, and the invoke-permission are *one
reviewable unit*. `terraform destroy` removes **all** of it — critical for Free-Plan hygiene, where
a forgotten API Gateway or log group quietly accrues cost.

### What to build, step by step

1. Write `handler.py` + `main.tf` above on `lesson/30-aws-serverless-lambda`.
2. `terraform init && terraform apply` — note the `url` output.
3. `curl "$(terraform output -raw url)"` → expect `{"msg":"hello from Navi serverless"}`.
4. `aws logs tail /aws/lambda/hello --follow` in another shell; curl again; watch the log entry.
5. Inspect the role: confirm it has **only** logging permissions (no `s3:*`, no `*`).
6. **Tear down:** `terraform destroy` — verify no leftover function, API, or log group.

---

## Step 5 — Verification

```bash
terraform output -raw url                                  # the endpoint
curl -s "$(terraform output -raw url)"                     # 200 + JSON body
aws lambda get-function-configuration --function-name hello \
  --query '{mem:MemorySize,timeout:Timeout,arch:Architectures}'   # 256 / 6 / arm64
aws iam list-attached-role-policies --role-name hello-exec        # logging policy ONLY
aws logs tail /aws/lambda/hello --since 5m                        # invocation logged
# teardown proof:
terraform destroy -auto-approve
aws lambda get-function --function-name hello 2>&1 | grep -q ResourceNotFound && echo "destroyed ✅"
```

### Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| `403 {"message":"Forbidden"}` from the URL | Wrong route key / stage, or missing `aws_lambda_permission` | Check `route_key` matches `GET /hello`; ensure API Gateway has invoke permission |
| `AccessDenied` inside the function | Execution role lacks the action/resource | Add the *specific* `Action` on the *specific* ARN to the role |
| `502 Bad Gateway` | Handler returned a bad shape for proxy integration | Return `{statusCode, headers, body}` (body must be a string) |
| `Task timed out after 6.00 seconds` | Real work exceeds timeout (or hung call) | Fix the slow call; raise timeout to p99+buffer — don't jump to 900 |
| High bill / slow | Under-provisioned memory or x86 | Power-Tune memory; switch to `arm64` |
| Cold-start latency on a user path | No warm environment | Provisioned Concurrency or SnapStart (only if it matters) |

### Redaction check ✅

No real **account IDs**, full **ARNs with account numbers**, **access keys**, or
**API endpoint URLs** committed. `terraform.tfstate` contains ARNs and must be **gitignored**
(it can also hold secrets). Never commit `.tfstate` or `*.zip` build artifacts.

---

## Step 6 — Quiz (Interview-Style, Graded)

**Q1.** Explain how a Lambda function gets permission to call another AWS service (e.g. write to
S3). Why is an **execution role** safer than embedding access keys?

> **Your answer:**

**Q2.** What is a **cold start**? In which phase(s) does it occur, roughly what fraction of
invocations are affected, and name two mitigations.

> **Your answer:**

**Q3.** Why is **memory** described as the "master dial" for both performance *and* cost? Give the
counter-intuitive reason raising memory can *lower* the bill.

> **Your answer:**

**Q4.** A teammate sets every function's timeout to 900s "to be safe." What's the risk, and how do
you choose a correct timeout?

> **Your answer:**

**Q5.** What's the danger of a Lambda **Function URL** with `AuthType: NONE`, and what's the fix?

> **Your answer:**

**Q6.** When would you choose **EC2 or ECS/Fargate** over Lambda? Name two disqualifiers for
serverless.

> **Your answer:**

---

## Step 7 — Reflection

*(Fill in after the quiz)*

- What did you learn?
- What confused you (the event model? IAM roles? the cost dials?)?
- How does Lambda change how you'd architect something you'd previously have put on an EC2 box?

---

## Lens E — Attacker & Defender (Red / Blue)

> Red/Blue framing (Gate Rule **Lens E**, D14). Build *both* mindsets.
> Frameworks: [MITRE ATT&CK Cloud](https://attack.mitre.org/matrices/enterprise/cloud/) · [IAM security best practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html).

**🔴 Attacker (how it's abused — Step 2):** Over-privileged execution roles are the prize — a
function with `*` or broad `iam:PassRole` becomes a pivot across the whole account (ATT&CK
**T1078.004** Valid Cloud Accounts / privilege escalation). **Public Function URLs** (`NONE`) and
**event injection** (untrusted input reaching a downstream call) are common footholds; secrets in
**env vars** are harvested from a compromised function.

**🔵 Defender (detect & harden — Step 5):** One **least-privilege role per function** (generate
from CloudTrail via IAM Access Analyzer); **`AWS_IAM`** auth on Function URLs / API authorizers;
secrets in **Secrets Manager/SSM**, never env; **CloudTrail** on Lambda + **GuardDuty**; scope
`iam:PassRole` tightly; reserve `AdministratorAccess` for break-glass only.

## Step 8 — Search Keywords For Further Understanding

**Core**
- `aws lambda execution role vs resource policy`
- `lambda execution environment lifecycle init invoke shutdown`
- `lambda cold start mitigation provisioned concurrency snapstart`
- `api gateway lambda proxy integration event shape`

**Tools**
- `terraform aws_lambda_function example`
- `aws lambda power tuning memory`
- `iam access analyzer generate least privilege policy`

**Going further**
- `lambda function url auth_type iam`
- `eventbridge schedule lambda cron`
- `lambda arm64 graviton cost`
- `aws step functions orchestration`

---

**Red / Blue (Lens E — study attacker & defender in parallel):**
- 🔴 **Red (attacker):** `lambda over-privileged role privesc`, `MITRE ATT&CK T1078.004 valid cloud accounts`, `public lambda function url`, `iam passrole escalation`
- 🔵 **Blue (defender):** `least privilege lambda role`, `iam access analyzer`, `secrets manager lambda`, `cloudtrail guardduty lambda`

## Lesson Status

- [ ] Hands-on task completed (Step 4)
- [ ] Verification passed + resources torn down (Step 5)
- [ ] Quiz answered + professional-answer comparisons requested (Step 6)
- [ ] Reflection completed (Step 7)
- [ ] Search Keywords reviewed (Step 8)

When complete, run the Update Protocol, then continue to **Lesson 31 — Azure for AWS-Literate
Engineers** (or per `JOB_MILESTONES.md`).

---

*Lesson 30 written by Navi v28 · 2026-06-28 · WebSearch sources:
[Lambda execution environment lifecycle (AWS docs)](https://docs.aws.amazon.com/lambda/latest/dg/lambda-runtime-environment.html),
[Invoking Lambda via API Gateway (AWS docs)](https://docs.aws.amazon.com/lambda/latest/dg/services-apigateway.html),
[Understanding & Remediating Cold Starts (AWS Compute blog)](https://aws.amazon.com/blogs/compute/understanding-and-remediating-cold-starts-an-aws-lambda-perspective/),
[Lambda least-privilege (AWS docs)](https://docs.aws.amazon.com/lambda/latest/dg/least-privilege.html),
[Lambda Best Practices in Production 2026 (Tasrie)](https://tasrieit.com/blog/aws-lambda-best-practices-production-2026),
[Lambda Cost Optimization 2026 (LeanOps)](https://leanopstech.com/blog/aws-lambda-cost-optimization-2026/)*
