# Lesson 25 — Pure Practical: Terraform + AWS Infrastructure Project

> **Companion to [`README.md`](./README.md).** Pure practice: 3 scenario tasks, guided → ticket-driven
> → on-call. Do them after the README.
>
> **⚠️ Offline-first (no cloud spend).** Run the whole project against **LocalStack** (`aws` provider →
> `http://localhost:4566`). You practice real modules/state/CI without a bill. Never `apply` to real
> AWS in a drill; never commit `.tfstate`/`.tfvars`. **Rules:** type it, diagnose before you fix, run ✅.

Each task: **Scenario · Objective · Given/constraints · Hints · ✅ Verify · Pitfalls · 🎯 Stretch.**

---

## Task 1 — Guided: a reusable module for the 2-tier stack (fluency)

**Scenario.** `NAVI-251`. Refactor the VPC+subnets+SG build (L16) into a **module** with variables so
you can stamp it out per environment.

**Objective.** A `modules/network` consumed by a root config with `dev` variables; plan/apply/destroy
clean against LocalStack.

**Given / constraints.** No duplicated resource blocks; inputs via variables; outputs exposed. `fmt` +
`validate` clean.

**Hints.**
1. `modules/network/{main,variables,outputs}.tf`; root calls `module "network" { source = "./modules/network" ... }`.
2. Parameterize CIDRs/names; expose subnet IDs as outputs.
3. `plan` → `apply` → `terraform output` → `destroy`.

✅ **Verify.**
```bash
terraform fmt -check && terraform validate && echo "VALID ✅"
terraform plan | grep -q 'module.network' && echo "MODULE WIRED ✅"
terraform state list | grep -q 'module.network' && echo "APPLIED ✅"
```

**Pitfalls.**
- Copy-pasting resources instead of a module (the anti-pattern this lesson fixes).
- Hard-coded env values instead of `*.tfvars` per environment.
- No outputs → the root can't reference module resources.

🎯 **Stretch.** Add a `prod` workspace/tfvars and diff the plans — same module, different inputs.

---

## Task 2 — Ticket-driven: "the module change broke a dependent resource" (diagnose → fix)

**Scenario.** `NAVI-252` (P2). A tweak to the network module makes `plan` want to replace resources that
depend on it, threatening downstream. Investigate the blast radius before applying — **diagnose first.**

**Objective.** Understand what the change forces and refactor so the intended change lands without a
destructive replacement of dependents.

**Given / constraints.** Recreate: change a `force-new` attribute (e.g. subnet CIDR) that dependents
reference. Resolve with `state mv`/lifecycle, not by nuking dependents.

**Hints.**
1. `plan` — trace `forces replacement` up the dependency graph (`terraform graph`).
2. Some attributes are immutable → change requires create-before-destroy (`lifecycle`).
3. Refactor address changes with `terraform state mv` to avoid recreation.

✅ **Verify.**
```bash
terraform plan | grep -c 'forces replacement'   # understand each; ideally 0 unintended
terraform validate && echo "VALID ✅"
```

**Pitfalls.**
- Applying a cascading replacement without understanding downstream data loss.
- Renaming a resource → Terraform sees destroy+create unless you `state mv`.
- Ignoring `create_before_destroy` where zero-downtime matters.

🎯 **Stretch.** Add `prevent_destroy` on the stateful resource so an accidental destructive plan is blocked outright.

---

## Task 3 — On-call: partial apply left infra half-built (synthesis)

**Scenario.** `NAVI-253` (P1, time-boxed). An `apply` failed midway (e.g. a quota/dependency error);
some resources exist, some don't, and state is partially updated. Reconcile to a known-good state and
document.

**Objective.** Determine what actually exists vs what state thinks, converge safely (targeted
apply/import), verify, and write an incident note.

**Given / constraints.** Simulate a mid-apply failure (make one resource error). Back up state first.
Don't blind `destroy`/`apply` — reconcile deliberately.

**Hints.**
1. `terraform plan -refresh-only` to see reality vs state; `state list` for what's tracked.
2. `terraform apply -target=<addr>` to converge one resource at a time; `import` anything created-but-untracked.
3. Full `plan` should end clean (no changes) once reconciled.

✅ **Verify.**
```bash
terraform plan -detailed-exitcode; echo "exit=$?"   # 0 = no changes = converged
test -f backup.tfstate && test -f docs/learning/reports/NAVI-253-postmortem.md && echo "BACKED UP + POSTMORTEM ✅"
```

**Deliverable.** `docs/learning/reports/NAVI-253-postmortem.md`: Impact · Detection · Root cause · Fix · Prevention (+ "remote state, smaller applies").

**Pitfalls.**
- `destroy` then `apply` to "start clean" → real data loss on stateful resources.
- Not backing up state before repair.
- Giant monolithic apply → larger blast radius on partial failure (recommend splitting).

🎯 **Stretch.** Wire a CI plan-gate (L14) that runs `terraform plan -detailed-exitcode` and blocks merge on unexpected changes.

---

## Done?
- [ ] All ✅ Verify pass (LocalStack) · [ ] blast radius understood · [ ] state backed up · [ ] postmortem written.
- [ ] **No real AWS spend; no `.tfstate`/`.tfvars` committed.** → [README Step 7](./README.md).
