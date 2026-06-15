# Lesson 15 — AWS Fundamentals (Account & IAM)

**Status:** ready for self-study · **Date written:** 2026-06-11
**Gate Rule:** Concept → Real-World Use → Alternatives → Hands-On → Verification → Quiz → Reflection → Search Keywords

> **How to use this lesson:** same as Lessons 03–14. **Cost-safety lesson**:
> Step 4's first task (billing alerts) must be done **before** anything else in
> Lessons 15-20 — set this up first, even before creating any other resources.

---

## Step 1 — Concept

### What it is

**AWS (Amazon Web Services)** is a cloud platform — instead of buying/hosting
your own servers, you rent compute, storage, networking, and managed services
on-demand. **IAM (Identity and Access Management)** is AWS's system for
controlling **who** (identity) can do **what** (permissions) to **which**
resources.

### Why it exists

Cloud platforms replaced "buy a server, rack it, wire it" with "click a button,
get a server in seconds, pay per hour/second." But this also means **anyone with
valid credentials can create (and be billed for) resources** — IAM exists to
ensure only the right people/services can do the right things, and the AWS root
account (created at signup) is so powerful that AWS itself recommends never
using it for daily work.

### What problem it solves

| Problem | Solution |
|---|---|
| "I need a server for testing but don't want to buy hardware" | EC2 (Lesson 16) |
| "My laptop's lab VM needs to be reachable when I'm not home" | Cloud-hosted VM |
| "Anyone who has my AWS password can do ANYTHING, including delete everything and rack up charges" | IAM users with **least privilege**, never use root day-to-day |
| "I accidentally left a resource running and got a surprise bill" | Billing alerts + AWS Budgets + Free Tier alerts |
| "An EC2 instance needs to read from an S3 bucket — without hardcoding credentials" | IAM **roles** (temporary credentials, no stored keys) |

### Three-Level Depth (Lens A)

- **Level 1 — Beginner:** The **root user** (the email/password you signed up
  with) has unlimited access — log in to it only for account-level tasks
  (billing setup, MFA), then create an **IAM user** for yourself with
  appropriate permissions for daily work. **IAM Groups** let you assign
  permissions to a group (e.g., "Admins") and add/remove users from it, instead
  of managing permissions per-user.
- **Level 2 — SysAdmin:** Per [AWS's IAM intro docs](https://docs.aws.amazon.com/IAM/latest/UserGuide/introduction.html)
  and [techoral's IAM roles/policies guide](https://techoral.com/aws/aws-iam-roles-policies.html):
  **IAM Users** = long-term identities (username/password, optional access
  keys) for humans or legacy automation. **IAM Roles** = **temporary**
  credentials assumed by services (EC2 instances, Lambda functions) or users —
  issued via AWS STS (Security Token Service), auto-expiring, **no stored
  long-term keys**. This is the AWS-native equivalent of "don't hardcode
  passwords" (Lesson 12 Q6) — an EC2 instance with an attached IAM role can call
  AWS APIs without any credentials ever being stored on it. **Policies** are
  JSON documents: `Effect` (Allow/Deny), `Action` (e.g., `s3:GetObject`),
  `Resource` (which specific bucket/ARN), optional `Condition`. **Principle of
  least privilege**: grant only the specific actions/resources needed — never
  attach `AdministratorAccess` to a role/user that only needs to read one S3
  bucket.
- **Level 3 — Systems/Kernel (Lens D):** Less direct kernel tie-in here, but
  conceptually: an IAM **role** assumed by an EC2 instance works similarly to
  Lesson 13's Ansible "agentless" model — the instance gets **temporary,
  auto-rotating credentials** injected via the instance metadata service
  (`169.254.169.254`, a special link-local address only reachable from within
  the instance — note: a known SSRF attack vector if a web app on the instance
  can be tricked into making requests to this address, hence newer **IMDSv2**
  requiring session tokens). This is the cloud analog of "no agent, no stored
  secret, ephemeral access" — the same theme as Ansible's agentless SSH and
  GitHub Actions' ephemeral runners (Lesson 14).

### Analogy (Lens B)

- **Root account** = the master key to an entire building, including the
  ability to demolish it — you keep it in a safe and use it only for
  building-level decisions (locked away, MFA-protected), not for daily entry.
- **IAM user** = an employee's keycard, scoped to the rooms (resources) their
  job requires — **least privilege** = "don't give the intern a keycard to the
  server room and the CEO's office just because it's easier."
- **IAM role** = a **visitor badge** that's valid only for today, automatically
  expires, and is issued fresh each visit — vs. an IAM user's access keys, which
  are like a permanent keycard that keeps working until someone manually
  deactivates it (and is much more dangerous if lost/leaked).
- **Billing alerts** = a smoke detector for your wallet — by the time you
  "smell smoke" (check the bill manually), real money may already be spent;
  alerts notify you the moment usage crosses a threshold.

The "keycard" analogy holds well for IAM users/roles but breaks down for
**policy evaluation logic** (explicit Deny always wins, multiple policies can
apply and are combined) — that's closer to "multiple overlapping security
clearances being evaluated by precise rules" than a single physical keycard.

---

## Step 2 — Real-World Use

### How SysAdmins use this daily

```bash
# AWS CLI (after configuring credentials via `aws configure`)
aws sts get-caller-identity        # "who am I" - confirms which IAM identity is active
aws iam list-users
aws iam list-roles
aws iam get-account-summary        # quick account-wide overview

aws budgets describe-budgets --account-id <ACCOUNT_ID>
```

**Real production scenarios:**
1. **New team member onboarding** — create an IAM user (or, increasingly,
   federated SSO access), add to the appropriate group with least-privilege
   policies, enforce MFA.
2. **Application needs AWS access** — attach an IAM **role** to the EC2
   instance/Lambda function (never embed access keys in application code).
3. **Cost control** — billing alerts + AWS Budgets catch a forgotten
   `t3.2xlarge` instance left running before it becomes a $200 surprise.

### Common mistakes

| Mistake | Impact | Fix |
|---|---|---|
| Using the root account for daily work | If credentials leak, attacker has **total** account control | Create an IAM user/role for yourself immediately; lock root away with MFA |
| Attaching `AdministratorAccess` "to make it work" | Massive blast radius if that user/role/key is compromised | Start with minimal policy, add specific permissions as needed (least privilege) |
| Hardcoding access keys in code/scripts | Keys leaked via git (a very common real breach pattern) | Use IAM roles for AWS resources; for local dev, use `aws configure` (stored outside repo) |
| Not setting up billing alerts before creating any resources | Forgotten resources accumulate charges silently | Step 4 — set this up **first**, before Lesson 16 |
| No MFA on root/IAM users | Password-only access to a cloud account controlling real money | Enable MFA on root immediately, and on IAM users with console access |

### When NOT to over-provision IAM

- For a personal learning account, you don't need a complex multi-account
  organization (AWS Organizations) — one account, one IAM admin user (for
  yourself, not root), and roles for any resources you create, is sufficient
  for Lessons 15-20.

### Interview Angle

**Question:** "A developer asks you to give their app's EC2 instance
`AdministratorAccess` so it can write to an S3 bucket, because 'it works and
we're behind schedule.' How do you respond?"

A junior answer either grants it to unblock the team or refuses without
offering an alternative. A senior answer explains the blast-radius problem
concretely — if that instance is compromised, the attacker now has total
account control, not just S3 access — and proposes the actual fix: attach an
IAM **role** to the instance (never embed access keys) scoped to a
least-privilege policy covering only the specific bucket/actions needed
(`s3:PutObject`, `s3:GetObject` on that ARN). Bonus points for mentioning
`aws sts get-caller-identity` to verify which role the instance is actually
running as, and for noting this should've had billing alerts configured
*before* any resources existed.

---

## Step 3 — Alternatives

| Topic | Alternative | Note |
|---|---|---|
| AWS (this lesson) | Azure, Google Cloud (GCP) | Concepts (IAM, compute, storage, least privilege) transfer almost directly; AWS has the largest market share and most job postings |
| Long-term IAM user access keys | **IAM Identity Center (SSO)** + temporary credentials | Increasingly the recommended approach even for individuals — but IAM users/keys are still widely used and good to understand fundamentally |
| Manual billing checks | AWS Budgets + Cost Anomaly Detection (free) | Set up once, runs continuously |

---

## Step 4 — Hands-On Task (build this yourself)

**Goal:** Set up AWS account safety nets (billing alerts) **first**, then create
a least-privilege IAM user for yourself (stop using root), and practice
writing/reading IAM policy JSON.

### Lens C — Manual → Automated → Why

This lesson is mostly **account configuration** (one-time setup), but the
"automation" angle: once you reach Lesson 20 (Terraform), IAM users/roles/
policies become **code** (`aws_iam_role`, `aws_iam_policy` resources) —
understanding the JSON policy structure now makes Terraform's IAM resources
much easier to read later.

### What to build, step by step

1. **Billing safety first** (per [AWS's Free Tier tracking guide](https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/tracking-free-tier-usage.html)
   and [oneuptime's Free Tier overage guide](https://oneuptime.com/blog/post/2026-02-12-track-and-avoid-aws-free-tier-overages/view)):
   - Enable **Free Tier usage alerts** (Billing Preferences) — emails you at 85%
     of any Free Tier limit.
   - Create an **AWS Budget** (e.g., $5/month) with an alert at 80% — per
     [Pluralsight's free-tier alerting guide](https://www.pluralsight.com/resources/blog/cloud/aws-free-tier-alerting).
   - Enable **Cost Anomaly Detection** (free, flags unusual spend same-day).
   - Enable **MFA on the root account** immediately.
2. **Create your daily-use IAM user**:
   - IAM console → create a user for yourself (e.g., `sysctl-admin`).
   - Create a group (e.g., `Admins`) with a policy appropriate for learning
     (AWS managed `PowerUserAccess` is more appropriate than
     `AdministratorAccess` for a learner — it excludes IAM management itself,
     reducing blast radius).
   - Add your user to the group, enable MFA on this user too.
   - Log out of root; do all subsequent work as this IAM user.
3. **Write a least-privilege policy** (practice, don't necessarily attach yet):
   write a JSON policy that allows `s3:GetObject` and `s3:ListBucket` on a
   single named bucket only (you'll use this in Lesson 17). Document why each
   field (`Effect`, `Action`, `Resource`) is scoped the way it is.
4. **Verify**: `aws sts get-caller-identity` should show your IAM user's ARN,
   not the root account.
5. Document your setup (redacted account ID, no real ARNs with account numbers)
   in `docs/aws/account-setup.md`. Commit on
   `lesson/15-aws-fundamentals-account-iam`.

---

## Step 5 — Verification

```bash
aws sts get-caller-identity
# Should show your IAM user's ARN (arn:aws:iam::<ACCOUNT_ID>:user/sysctl-admin),
# NOT the root account

aws iam list-mfa-devices --user-name sysctl-admin   # confirm MFA registered

# Confirm billing alerts exist (check console: Billing -> Budgets)
aws budgets describe-budgets --account-id <ACCOUNT_ID>
```

### Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| `aws sts get-caller-identity` returns root ARN | Still using root credentials | Switch to your IAM user's credentials (`aws configure` with the IAM user's keys) |
| `aws` CLI: "Unable to locate credentials" | `aws configure` not run, or wrong profile | `aws configure` (or `aws configure --profile <name>` and `--profile` flag on commands) |
| Budget alert email not received | Alert threshold not yet crossed (expected — this is a safety net, not a confirmation test) | Verify the budget exists in the console; the test is "it exists," not "it fired" |
| IAM policy JSON has a typo and won't save | JSON syntax error | Use the AWS console's policy visual editor to generate valid JSON, then inspect it |

### Redaction check ✅

**Never** commit your AWS account ID, access keys, or real ARNs to the public
repo. Use `<ACCOUNT_ID>` placeholders. Access keys, if ever created, must never
appear in git history — if one is accidentally committed, **rotate it
immediately** (deactivate + delete in IAM console), don't just remove it from a
later commit.

---

## Step 6 — Quiz (Interview-Style, Graded)

**Q1.** Why does AWS recommend never using the root account for day-to-day
work, even though it's the account you signed up with?

> **Your answer:**

**Q2.** Explain the **principle of least privilege** using a concrete IAM
policy example (e.g., for an app that only needs to read from one S3 bucket).

> **Your answer:**

**Q3.** What's the difference between an **IAM user** and an **IAM role**? Give
a scenario where you'd use each.

> **Your answer:**

**Q4.** **Scenario:** You find an AWS access key hardcoded in a script that was
committed to a public GitHub repo 6 months ago. What do you do, in order, and
why is "just delete it from the latest commit" insufficient?

> **Your answer:**

**Q5.** Why set up billing alerts/budgets **before** creating any AWS resources,
rather than after?

> **Your answer:**

**Q6.** What is IMDSv2 and why does it matter for EC2 instances with attached
IAM roles? (Tie back to Lesson 09's NAT/firewall concepts — what kind of attack
is this defending against?)

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

**🔴 Attacker (how it's abused — Step 2):** IAM is the cloud control plane attackers most want: stolen access keys, and **privilege escalation** via misconfig (`iam:PassRole`, `CreatePolicyVersion`, `AssumeRole` chains). They enumerate with the creds they get. ATT&CK **T1078.004** (Cloud Accounts), **T1098** (Account Manipulation).

**🔵 Defender (detect & harden — Step 5):** Least-privilege policies, **MFA everywhere**, no long-lived keys (use roles/IAM Identity Center), enable **CloudTrail** + IAM Access Analyzer, and alert on anomalous or first-seen API calls and policy changes.

## Step 8 — Search Keywords For Further Understanding

**Core**
- `aws iam users groups roles policies explained`
- `aws principle of least privilege examples`
- `aws free tier billing alerts setup`
- `aws root account security best practices`

**Tools**
- `aws cli configure profiles`
- `aws cost anomaly detection`
- `aws iam policy json structure effect action resource`

**Going further (future lessons)**
- `aws ec2 iam instance profile`
- `aws imdsv2 ssrf protection`
- `terraform aws_iam_role example`

---

**Red / Blue (Lens E — study attacker & defender in parallel):**
- 🔴 **Red (attacker):** `aws iam privilege escalation paths`, `iam:PassRole exploit`, `MITRE ATT&CK T1078.004 cloud accounts`, `aws access key theft`
- 🔵 **Blue (defender):** `aws iam least privilege policy`, `cloudtrail logging monitoring`, `iam access analyzer`, `aws mfa enforcement`

## Lesson Status

- [ ] Hands-on task completed (Step 4)
- [ ] Verification passed (Step 5)
- [ ] Quiz answered + professional-answer comparisons requested (Step 6)
- [ ] Reflection completed (Step 7)
- [ ] Search Keywords reviewed (Step 8)

When complete, run the Update Protocol, then move to **Lesson 16 — AWS EC2 &
VPC Basics**.

---

*Lesson 15 written by Navi v28 · 2026-06-11 · WebSearch sources:
[AWS IAM Introduction](https://docs.aws.amazon.com/IAM/latest/UserGuide/introduction.html),
[techoral AWS IAM Roles and Policies Guide](https://techoral.com/aws/aws-iam-roles-policies.html),
[AWS Free Tier Usage Tracking](https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/tracking-free-tier-usage.html),
[oneuptime Track and Avoid AWS Free Tier Overages](https://oneuptime.com/blog/post/2026-02-12-track-and-avoid-aws-free-tier-overages/view),
[Pluralsight AWS Free Tier Alerting](https://www.pluralsight.com/resources/blog/cloud/aws-free-tier-alerting)*
