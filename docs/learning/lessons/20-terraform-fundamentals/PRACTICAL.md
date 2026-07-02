# Lesson 20 — Pure Practical: Terraform Fundamentals

> **Companion to [`README.md`](./README.md).** Pure practice: 3 scenario tasks, guided → ticket-driven
> → on-call. Do them after the README.
>
> **⚠️ Offline-first (no cloud spend).** Use the **`local`/`null`/`random` providers** (no cloud) or
> **LocalStack** with the `aws` provider pointed at `http://localhost:4566`. Practice `init/plan/apply/
> destroy` and state mechanics without a bill. **Never** run `apply` against real AWS in a drill; never
> commit `.tfstate`/`.tfvars`. **Rules:** type it, diagnose before you fix, run ✅ **Verify**.

Each task: **Scenario · Objective · Given/constraints · Hints · ✅ Verify · Pitfalls · 🎯 Stretch.**

---

## Task 1 — Guided: plan/apply/destroy a resource with variables + outputs (fluency)

**Scenario.** `NAVI-201`. Learn the core loop safely: define a `local_file` (or LocalStack S3 bucket)
via a variable, plan it, apply, inspect state, and destroy — cleanly.

**Objective.** A config that plans cleanly, applies, exposes an output, and destroys to zero resources.

**Given / constraints.** `local`/`null` provider (fully offline) or LocalStack. `terraform fmt` +
`validate` clean. No hard-coded values that should be variables.

**Hints.**
1. `main.tf` (resource + `variable` + `output`), `terraform init`.
2. `terraform plan` (read it!) → `apply` → `terraform output` → `terraform state list`.
3. `terraform destroy` and confirm state is empty.

✅ **Verify.**
```bash
terraform fmt -check && terraform validate && echo "VALID ✅"
terraform plan -out=tfplan && terraform apply tfplan && terraform output
terraform state list        # resources present
```

**Pitfalls.**
- Running `apply` without reading `plan` first — cardinal sin.
- Committing `.tfstate` (may hold secrets) — gitignore it.
- Hard-coding values that belong in `variables.tf`.

🎯 **Stretch.** Add a `terraform.tfvars` and a `for_each` to create N of the resource; observe the plan diff.

---

## Task 2 — Ticket-driven: "plan wants to destroy something it shouldn't" / drift (diagnose)

**Scenario.** `NAVI-202` (P2). *"`terraform plan` shows it wants to replace/destroy a resource nobody
changed."* Investigate drift vs config change before anyone applies — **diagnose first.**

**Objective.** Explain *why* the plan shows the change (drift, a forced-replacement attribute, or state
mismatch) and reconcile it safely without destroying real data.

**Given / constraints.** Recreate: change a resource "out of band" (edit the created file / LocalStack
object) so state and reality diverge. Reconcile with refresh/import, not a blind apply.

**Hints.**
1. `terraform plan` — read `# forces replacement` markers and the `~`/`-/+` symbols.
2. Drift? `terraform plan -refresh-only` shows reality vs state. `terraform apply -refresh-only` to accept.
3. Resource exists but not in state? `terraform import`. Never resolve by deleting real infra.

✅ **Verify.**
```bash
terraform plan -refresh-only          # shows the drift explicitly
terraform plan | grep -q 'forces replacement' && echo "REPLACEMENT UNDERSTOOD (know why)" || echo "NO DESTRUCTIVE CHANGE ✅"
```

**Pitfalls.**
- Applying a plan that says "destroy" without understanding why → data loss.
- Fixing drift by editing state by hand instead of `import`/`refresh`.
- Ignoring `forces replacement` on an attribute change (some changes recreate the resource).

🎯 **Stretch.** Use `terraform state mv` to refactor a resource address without destroying it; confirm plan is a no-op after.

---

## Task 3 — On-call: state is locked / corrupted mid-apply (synthesis)

**Scenario.** `NAVI-203` (P1, time-boxed). A teammate's `apply` crashed; now state is locked and the
next run errors. Recover safely without corrupting state or orphaning resources; document.

**Objective.** Diagnose the lock/partial-apply, recover state cleanly (unlock only if truly stale),
reconcile resources, and write an incident note.

**Given / constraints.** Simulate a stale lock (`.terraform.tfstate.lock.info`) or a hand-corrupted
state. Back up state before touching it. Don't force-unlock a *live* apply.

**Hints.**
1. Read the lock: who/when? Only `terraform force-unlock <id>` if you're certain no apply is running.
2. Back up: copy the state file before any repair. `terraform state pull > backup.tfstate`.
3. Reconcile: `plan -refresh-only` to see reality; `import` anything created-but-untracked.

✅ **Verify.**
```bash
terraform plan >/dev/null 2>&1 && echo "STATE USABLE ✅"
test -f backup.tfstate && echo "STATE BACKED UP ✅"
test -f docs/learning/reports/NAVI-203-postmortem.md && echo "POSTMORTEM ✅"
```

**Deliverable.** `docs/learning/reports/NAVI-203-postmortem.md`: Impact · Detection · Root cause · Fix · Prevention (+ "use remote state w/ locking").

**Pitfalls.**
- `force-unlock` while a real apply is mid-flight → two applies corrupt state.
- Editing state JSON by hand without a backup.
- Local state on a shared project — the root cause; recommend remote backend + locking.

🎯 **Stretch.** Configure a remote backend (LocalStack S3 + DynamoDB lock via `awslocal`) and migrate state to it.

---

## Done?
- [ ] All ✅ Verify pass (offline/LocalStack) · [ ] read plan before apply · [ ] state backed up · [ ] postmortem written.
- [ ] **No real AWS spend; no `.tfstate`/`.tfvars` committed.** → [README Step 7](./README.md).
