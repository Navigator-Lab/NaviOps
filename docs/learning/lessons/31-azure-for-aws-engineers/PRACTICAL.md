# Lesson 31 — Pure Practical: Azure for AWS Engineers

> **Companion to [`README.md`](./README.md).** Pure practice: 3 scenario tasks, guided → ticket-driven
> → on-call, each anchored to the AWS equivalent you already know. Do them after the README.
>
> **⚠️ Offline-first (no cloud spend).** Use the **Azure CLI in local/what-if mode** (`az ... --dry-run`
> / `az deployment group what-if`) and **Azurite** (local emulator for Blob/Queue/Table) for storage.
> Practice the CLI + ARM/Bicep + RBAC *shape* without a subscription bill. Never commit real
> tenant/subscription IDs or secrets. **Rules:** type it, diagnose before you fix, run ✅.

Each task: **Scenario · Objective · Given/constraints · Hints · ✅ Verify · Pitfalls · 🎯 Stretch.**

---

## Task 1 — Guided: map the AWS mental model to Azure (fluency)

**Scenario.** `NAVI-311`. You know AWS. Build the Azure equivalents of a resource group (≈ nothing in
AWS / logical grouping), a VNet+subnet (≈ VPC+subnet), an NSG (≈ security group), and a storage account
(≈ S3) — as Bicep/ARM, validated locally.

**Objective.** A Bicep/ARM template that *validates* and a `what-if` that shows the intended resources,
with each mapped to its AWS analog in a comment.

**Given / constraints.** No deploy — `validate` + `what-if` only (offline). Storage practiced via
Azurite. Annotate each resource with its AWS equivalent.

**Hints.**
1. `az bicep build` / `az deployment group validate` (offline validation of the template).
2. `az deployment group what-if` shows the plan (Azure's `terraform plan` analog).
3. Azurite for Blob: `azurite-blob` + `az storage blob upload` against `http://127.0.0.1:10000`.

✅ **Verify.**
```bash
az bicep build --file main.bicep && echo "TEMPLATE VALID ✅"
grep -qiE 'VPC|security group|S3' main.bicep && echo "AWS MAPPING ANNOTATED ✅"
# Azurite blob round-trip:
az storage blob list --container-name test --connection-string "$AZURITE_CONN" >/dev/null && echo "BLOB OK ✅"
```

**Pitfalls.**
- Assuming 1:1 mapping — e.g. NSG rules are stateful like SGs, but subnet-vs-NIC association differs.
- Forgetting resource groups are mandatory (no direct AWS equivalent).
- Region/naming constraints (storage account names are globally unique + lowercase).

🎯 **Stretch.** Add RBAC: a custom role definition scoped to the resource group (≈ least-priv IAM policy).

---

## Task 2 — Ticket-driven: "RBAC says I'm authorized but access is denied" (diagnose → fix)

**Scenario.** `NAVI-312` (P2). *"The service principal has a role but still gets `AuthorizationFailed`."*
Diagnose Azure RBAC scope/assignment like you'd debug an IAM policy — **diagnose first.**

**Objective.** Explain why the assignment doesn't grant the action (wrong scope, wrong role, or scope
inheritance) and correct it to least privilege.

**Given / constraints.** Reason from `az role assignment`/`az role definition` output (offline-inspectable
JSON). Fix scope/role, don't hand Owner.

**Hints.**
1. Scope matters: assignment at RG vs resource vs subscription — is the target in scope?
2. `az role definition list --name <role>` — does the role actually include the action (`Microsoft.Storage/...`)?
3. `az role assignment list --assignee <sp> --all` — see effective assignments + scopes.

✅ **Verify.**
```bash
az role assignment list --assignee <sp> --all --query '[].{role:roleDefinitionName,scope:scope}' -o table
grep -qi 'Owner\|Contributor' /tmp/fix.md && echo "CHECK: is a narrower role possible?" || echo "LEAST-PRIV ROLE ✅"
```

**Pitfalls.**
- Granting **Owner/Contributor** to "fix" it — the Azure equivalent of `*` IAM.
- Assigning at the wrong scope (resource when the action needs RG-level, or vice-versa).
- Confusing a built-in role's name with its actual permitted actions.

🎯 **Stretch.** Author a custom role with exactly the needed `actions`/`dataActions` and assign at the tightest scope.

---

## Task 3 — On-call: a misconfigured resource is exposed / a deploy drifted (synthesis)

**Scenario.** `NAVI-313` (P1, time-boxed). Either a storage account allows public blob access or a
`what-if` shows drift from the template. Contain the exposure / reconcile drift, and document — mapping
the response to what you'd do in AWS.

**Objective.** Identify the exposure/drift, remediate to the template's intended state, verify, and
write an incident note comparing the Azure and AWS handling.

**Given / constraints.** Simulate public blob access (Azurite) or a template/reality mismatch. Reconcile
via template redeploy/`what-if`, not portal clicks. Note the AWS analog.

**Hints.**
1. Exposure: `az storage account show ... allowBlobPublicAccess` → set to `false` (≈ S3 block public access).
2. Drift: `az deployment group what-if` shows template vs reality; redeploy to converge (≈ `terraform plan`/apply).
3. Confirm the exposed surface is closed; record the AWS-equivalent control.

✅ **Verify.**
```bash
# public access disabled (or what-if clean):
az deployment group what-if --template-file main.bicep 2>&1 | grep -qi 'no change\|Resource changes: 0' && echo "CONVERGED ✅"
grep -qi 'aws' docs/learning/reports/NAVI-313-postmortem.md && echo "AWS-MAPPED POSTMORTEM ✅"
```

**Deliverable.** `docs/learning/reports/NAVI-313-postmortem.md`: Impact · Detection · Root cause · Fix · Prevention (+ AWS-equivalent control).

**Pitfalls.**
- Fixing in the portal → drift returns on next template deploy; fix in code.
- Assuming Azure defaults match AWS (public-access defaults, encryption) — verify explicitly.
- Over-broad remediation (disable the whole account) vs targeted (public access off).

🎯 **Stretch.** Add Azure Policy (≈ AWS SCP/Config rule) that denies public blob access account-wide.

---

## Done?
- [ ] All ✅ Verify pass (offline/Azurite) · [ ] each task mapped to its AWS analog · [ ] least-priv RBAC · [ ] postmortem written.
- [ ] **No real Azure spend; no tenant/subscription IDs or secrets committed.** → [README Step 7](./README.md).
