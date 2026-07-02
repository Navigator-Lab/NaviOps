# Lesson 30 — Pure Practical: AWS Serverless (Lambda)

> **Companion to [`README.md`](./README.md).** Pure practice: 3 scenario tasks, guided → ticket-driven
> → on-call. Do them after the README.
>
> **⚠️ Offline-first (no cloud spend).** Use **LocalStack** + `awslocal` (Lambda, IAM, logs, events are
> modeled) or the **AWS SAM CLI** local invoke (`sam local invoke`). Practice packaging/permissions/
> triggers without a bill. Never commit real ARNs/keys. **Rules:** type it, diagnose before you fix, run ✅.

Each task: **Scenario · Objective · Given/constraints · Hints · ✅ Verify · Pitfalls · 🎯 Stretch.**

---

## Task 1 — Guided: a function with a scoped role + a trigger (fluency)

**Scenario.** `NAVI-301`. Deploy a small function (e.g. process an S3 upload / return a health JSON)
with a **least-privilege** execution role and an event trigger.

**Objective.** Function deployed, invokes successfully, logs to CloudWatch, and its role grants only
what it needs.

**Given / constraints.** Execution role scoped (no `*`). Handler returns a real response. LocalStack/SAM.

**Hints.**
1. Package + `awslocal lambda create-function` (or `sam local invoke`) with a role that has only the required actions.
2. Wire the trigger (S3 event / API) → invoke → check logs.
3. Role policy: exactly the actions the code calls, nothing more.

✅ **Verify.**
```bash
awslocal lambda invoke --function-name <fn> /tmp/out.json && cat /tmp/out.json   # expected response
awslocal logs describe-log-groups | grep -q "/aws/lambda/<fn>" && echo "LOGS ✅"
grep -q '"Resource": "\*"' role-policy.json && echo "TOO BROAD ❌" || echo "LEAST-PRIV ✅"
```

**Pitfalls.**
- `AdministratorAccess`/`*` execution role — the default lazy choice; scope it.
- No logging/permissions to write logs → invisible failures.
- Handler not matching the configured `handler` path → import errors.

🎯 **Stretch.** Add environment variables + reason about where secrets belong (Secrets Manager/SSM, not env plaintext).

---

## Task 2 — Ticket-driven: "the function errors / times out" (diagnose → fix)

**Scenario.** `NAVI-302` (P2). *"The Lambda fails intermittently — some invokes error or time out."*
Find why from logs/config — **diagnose first.**

**Objective.** Make invokes succeed reliably, fixing the real cause (unhandled exception, timeout too
low, memory too low, or a missing permission for a downstream call).

**Given / constraints.** Recreate a fault (a downstream call the role can't make, or a too-short
timeout). Fix the specific cause, not by cranking everything to max.

**Hints.**
1. `awslocal logs filter-log-events --log-group-name /aws/lambda/<fn> --filter-pattern ERROR` — read the traceback.
2. Timeout vs error: `Task timed out` → raise timeout/optimize; `AccessDenied` → fix the role.
3. Memory-bound? Lambda CPU scales with memory; a too-low setting can cause timeouts.

✅ **Verify.**
```bash
for i in 1 2 3; do awslocal lambda invoke --function-name <fn> /tmp/o$i.json >/dev/null; done
awslocal logs filter-log-events --log-group-name /aws/lambda/<fn> --filter-pattern ERROR | grep -q ERROR && echo "STILL ERRORING ❌" || echo "STABLE ✅"
```

**Pitfalls.**
- Cranking timeout/memory to max instead of finding the real cause (cost + masks bugs).
- Swallowing exceptions so failures look like successes.
- Missing IAM permission for a downstream service the code calls.

🎯 **Stretch.** Add a dead-letter queue / retry config and reason about idempotency for retried events.

---

## Task 3 — On-call: a function is failing in prod (or costing/looping) (synthesis)

**Scenario.** `NAVI-303` (P1, time-boxed). Either the function errors on every event (blocking a
pipeline) or a recursive trigger is causing a runaway invoke loop. Contain, fix, document.

**Objective.** Stop the bleeding (disable the trigger / concurrency-cap), fix root cause, verify, and
write an incident note — including the runaway-cost lesson.

**Given / constraints.** Simulate a recursive S3 trigger (function writes to the bucket that triggers
it) or a hard-failing handler. Contain first, then fix. Note the cost implication.

**Hints.**
1. Contain: set **reserved concurrency = 0** (or remove the trigger) to halt invokes immediately.
2. Root cause: recursive trigger (fix the event filter / write to a different prefix/bucket) or the handler bug.
3. Re-enable with a safe concurrency limit; verify no loop.

✅ **Verify.**
```bash
awslocal lambda get-function-concurrency --function-name <fn>   # capped during containment
awslocal lambda invoke --function-name <fn> /tmp/out.json && echo "FIXED INVOKE ✅"
test -f docs/learning/reports/NAVI-303-postmortem.md && echo "POSTMORTEM ✅"
```

**Deliverable.** `docs/learning/reports/NAVI-303-postmortem.md`: Impact (incl. cost/loop) · Detection · Root cause · Fix · Prevention.

**Pitfalls.**
- A recursive trigger (write→trigger→write) → unbounded invokes + cost; the classic serverless footgun.
- Debugging live without capping concurrency → cost/loop keeps running.
- No concurrency limit as a standing guardrail.

🎯 **Stretch.** Add a CloudWatch alarm on invocation/error rate so a runaway pages you before the bill does.

---

## Done?
- [ ] All ✅ Verify pass (LocalStack/SAM) · [ ] contained before fixing · [ ] concurrency guardrail set · [ ] postmortem written.
- [ ] **No real AWS spend; no ARNs/keys committed.** → [README Step 7](./README.md).
