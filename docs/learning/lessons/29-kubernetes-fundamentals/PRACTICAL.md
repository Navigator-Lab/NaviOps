# Lesson 29 — Pure Practical: Kubernetes Fundamentals

> **Companion to [`README.md`](./README.md).** Pure practice: 3 scenario tasks, guided → ticket-driven
> → on-call. Do them after the README.
>
> **⚠️ Offline-first (no cloud spend).** Use a **local cluster** — `kind create cluster` or `minikube`
> (both run on the lab host, no cloud). Practice the exact `kubectl` you'd use in prod. Never commit real
> kubeconfigs/secrets. **Rules:** type it, diagnose before you fix, run ✅ **Verify** each task.

Each task: **Scenario · Objective · Given/constraints · Hints · ✅ Verify · Pitfalls · 🎯 Stretch.**

---

## Task 1 — Guided: deploy, expose, scale a service (fluency)

**Scenario.** `NAVI-291`. Deploy a small app as a Deployment, expose it with a Service, scale it, and
confirm self-healing when a pod dies.

**Objective.** A Deployment (≥2 replicas) + Service reachable; deleting a pod auto-recreates it.

**Given / constraints.** Manifests (YAML), not imperative one-offs. Resource requests/limits set.
Liveness/readiness probes present.

**Hints.**
1. `deployment.yaml` (replicas, probes, resources) + `service.yaml` → `kubectl apply -f`.
2. `kubectl get pods -w`; `kubectl delete pod <p>` → watch it come back.
3. `kubectl scale deploy/<name> --replicas=4`; `kubectl port-forward svc/<name>` to test.

✅ **Verify.**
```bash
kubectl get deploy <name> -o jsonpath='{.status.readyReplicas}'   # matches desired
kubectl delete pod -l app=<name> --wait=false; sleep 5
kubectl get pods -l app=<name> --no-headers | grep -c Running     # self-healed
```

**Pitfalls.**
- No resource requests → scheduler can't place well; no limits → noisy-neighbor.
- No readiness probe → traffic routed to a not-ready pod.
- Imperative `kubectl run` instead of version-controlled manifests.

🎯 **Stretch.** Add a rolling update (change the image) and watch `kubectl rollout status`; then `rollout undo`.

---

## Task 2 — Ticket-driven: "pods are CrashLoopBackOff / Pending" (diagnose → fix)

**Scenario.** `NAVI-292` (P2). *"My app won't come up — pods stuck in CrashLoopBackOff (or Pending)."*
Find why and fix — **diagnose before re-applying.**

**Objective.** Get pods to `Running`/`Ready`, identifying the real cause (bad image, failing probe,
missing config/secret, or unschedulable due to resources).

**Given / constraints.** Recreate a fault (wrong image tag, a probe that always fails, or requests
larger than any node). Fix the specific cause.

**Hints.**
1. `kubectl describe pod <p>` (Events!) + `kubectl logs <p> --previous`.
2. Pending → `describe` shows scheduling reason (insufficient cpu/mem, no node). CrashLoop → logs show the app error.
3. Missing ConfigMap/Secret? `kubectl get events --sort-by=.lastTimestamp`.

✅ **Verify.**
```bash
kubectl get pods -l app=<name> --no-headers | awk '{print $3}' | sort -u   # Running only
kubectl get pods -l app=<name> -o jsonpath='{.items[*].status.containerStatuses[*].ready}' | grep -qv false && echo "READY ✅"
```

**Pitfalls.**
- Re-applying blindly instead of reading `describe`/Events (where the answer usually is).
- Confusing Pending (scheduling) with CrashLoop (app) — different root causes.
- Ignoring `--previous` logs for a container that already restarted.

🎯 **Stretch.** Add a PodDisruptionBudget and reason about how it protects availability during node drain.

---

## Task 3 — On-call: a bad rollout is serving errors (synthesis)

**Scenario.** `NAVI-293` (P1, time-boxed). A new image rolled out and users get 5xx. Roll back safely
with zero/minimal downtime, confirm recovery, and document.

**Objective.** Detect the bad revision, `rollout undo` to the last-good, verify error rate → 0, and
write an incident note.

**Given / constraints.** Deploy a "bad" image revision. Use rollout history; don't delete the
Deployment. Keep the Service serving throughout.

**Hints.**
1. `kubectl rollout history deploy/<name>`; `kubectl rollout status` shows the stuck/bad rollout.
2. `kubectl rollout undo deploy/<name>` (optionally `--to-revision=N`).
3. Verify with repeated requests through the Service; confirm all healthy.

✅ **Verify.**
```bash
kubectl rollout status deploy/<name> --timeout=60s && echo "ROLLED BACK ✅"
for i in $(seq 20); do kubectl exec deploy/<name> -- true 2>/dev/null; done
kubectl get pods -l app=<name> --no-headers | grep -c Running   # all good revision
test -f docs/learning/reports/NAVI-293-postmortem.md && echo "POSTMORTEM ✅"
```

**Deliverable.** `docs/learning/reports/NAVI-293-postmortem.md`: Impact · Detection · Root cause · Fix · Prevention (+ "add readiness gates / canary").

**Pitfalls.**
- Deleting/recreating the Deployment (downtime) instead of `rollout undo`.
- No readiness probe → the bad rollout took traffic before it was caught.
- Rolling forward with a hotfix under pressure instead of the known-good rollback.

🎯 **Stretch.** Add `maxUnavailable`/`maxSurge` tuning + a readiness gate so a bad image never receives traffic.

---

## Done?
- [ ] All ✅ Verify pass (local kind/minikube) · [ ] read Events/logs before fixing · [ ] clean rollback · [ ] postmortem written.
- [ ] **No cloud spend; no real kubeconfig/secrets committed.** → [README Step 7](./README.md).
