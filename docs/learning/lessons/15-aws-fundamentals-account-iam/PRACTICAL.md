# Lesson 15 — Pure Practical: AWS Fundamentals & IAM

> **Companion to [`README.md`](./README.md).** Pure practice: 3 scenario tasks, guided → ticket-driven
> → on-call. Do them after the README.
>
> **⚠️ Offline-first (no cloud spend).** Run everything against **LocalStack** with `awslocal`
> (`docker run -d -p 4566:4566 localstack/localstack`; `pip install awscli-local`). IAM policy
> *evaluation* logic is identical; you practice the real API and JSON without an account or a bill.
> **Rules:** type it, diagnose before you fix, run ✅ **Verify** each task. Never commit real ARNs/keys.

Each task: **Scenario · Objective · Given/constraints · Hints · ✅ Verify · Pitfalls · 🎯 Stretch.**

---

## Task 1 — Guided: a least-privilege IAM user + policy (fluency)

**Scenario.** `NAVI-151`. A CI job needs to read one S3 bucket and nothing else. Create the user, a
scoped policy, and attach it.

**Objective.** An IAM user with a customer-managed policy granting `s3:GetObject`/`ListBucket` on **one**
bucket ARN only — no `*`.

**Given / constraints.** LocalStack. Policy JSON scoped to a single resource; no `"Action":"*"` /
`"Resource":"*"`.

**Hints.**
1. `awslocal iam create-user --user-name ci-reader`.
2. Write `policy.json` (Effect Allow, the two actions, `Resource` = bucket + `/*`).
3. `awslocal iam create-policy` → `attach-user-policy`.

✅ **Verify.**
```bash
awslocal iam list-attached-user-policies --user-name ci-reader | grep -q PolicyArn && echo "ATTACHED ✅"
awslocal iam get-policy-version --policy-arn <arn> --version-id v1 | grep -q '"s3:GetObject"' && echo "SCOPED ✅"
grep -q '"Resource": "\*"' policy.json && echo "TOO BROAD ❌" || echo "LEAST-PRIV ✅"
```

**Pitfalls.**
- `"Action":"s3:*"` or `"Resource":"*"` — the #1 real-world IAM finding.
- Using the root account for daily work (in real AWS) — never.
- Long-lived access keys where a role would do.

🎯 **Stretch.** Add a `Condition` (e.g. `aws:SourceIp` or `s3:prefix`) and reason about how it narrows access.

---

## Task 2 — Ticket-driven: "AccessDenied but the user should have access" (diagnose → fix)

**Scenario.** `NAVI-152` (P2). *"ci-reader gets `AccessDenied` calling GetObject on the bucket it's
supposed to read."* Find why the policy doesn't grant what you think — **diagnose the evaluation.**

**Objective.** Make the call succeed by fixing the actual policy gap (wrong ARN, missing `ListBucket`,
explicit deny, or action/resource mismatch).

**Given / constraints.** Recreate a subtly-wrong policy (e.g. `GetObject` but resource is the bucket
not `bucket/*`, or a typo'd ARN). Fix the specific mismatch.

**Hints.**
1. Read the exact denied action + resource from the error.
2. `GetObject` needs the object ARN (`arn:...:bucket/*`); `ListBucket` needs the bucket ARN (no `/*`). Getting these swapped is the classic bug.
3. Check for an explicit `Deny` (always wins) anywhere applicable.

✅ **Verify.**
```bash
awslocal s3api get-object --bucket <b> --key test.txt /tmp/out 2>&1 | grep -qi denied && echo "STILL DENIED ❌" || echo "ACCESS OK ✅"
awslocal iam simulate-principal-policy --policy-source-arn <user-arn> \
  --action-names s3:GetObject --resource-arns <obj-arn> | grep -q allowed && echo "SIMULATED ALLOW ✅"
```

**Pitfalls.**
- Confusing bucket ARN vs object ARN (`/*`) — breaks Get vs List.
- Forgetting an explicit Deny overrides any Allow.
- Widening to `*` to "fix" it instead of correcting the ARN.

🎯 **Stretch.** Use `iam simulate-principal-policy` as a pre-deploy check in a script — policy testing without live calls.

---

## Task 3 — On-call: leaked access key / over-privileged principal (synthesis)

**Scenario.** `NAVI-153` (P1, time-boxed). An access key was found in a git history and one user has
`AdministratorAccess`. Contain the exposure and enforce least privilege; document.

**Objective.** Deactivate/rotate the compromised key, strip the excess privilege down to what's needed,
and write an incident note (rotation + blast-radius).

**Given / constraints.** LocalStack. Simulate a user with admin + an access key. In real AWS the key
is compromised the instant it hits git → deactivate then delete, never just "hide it".

**Hints.**
1. Inventory: `awslocal iam list-access-keys`, `list-attached-user-policies`.
2. Contain: `iam update-access-key --status Inactive` → create a new key → delete the old.
3. Least-priv: detach `AdministratorAccess`, attach a scoped policy for the actual job.

✅ **Verify.**
```bash
awslocal iam list-access-keys --user-name <u> | grep -q Inactive && echo "KEY DISABLED ✅"
awslocal iam list-attached-user-policies --user-name <u> | grep -q Administrator && echo "STILL ADMIN ❌" || echo "SCOPED DOWN ✅"
test -f docs/learning/reports/NAVI-153-postmortem.md && echo "POSTMORTEM ✅"
```

**Deliverable.** `docs/learning/reports/NAVI-153-postmortem.md`: Impact · Detection · Root cause · Fix · Prevention (assume the key is compromised).

**Pitfalls.**
- Deleting the key before creating/deploying a replacement → self-inflicted outage.
- Assuming "removed from git" = safe; the key is already scraped — rotate it.
- Removing admin but leaving another over-broad policy attached.

🎯 **Stretch.** Enable CloudTrail (LocalStack) and find which API calls the compromised key made — real IR scoping.

---

## Done?
- [ ] All ✅ Verify pass (LocalStack) · [ ] no `*` policies · [ ] key rotated · [ ] postmortem written.
- [ ] **No real AWS spend; no real ARNs/keys committed.** → [README Step 7](./README.md).
