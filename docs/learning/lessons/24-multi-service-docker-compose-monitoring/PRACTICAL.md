# Lesson 24 — Pure Practical: Multi-Service Docker Compose + Monitoring

> **Companion to [`README.md`](./README.md).** Pure practice: 3 scenario tasks, guided → ticket-driven
> → on-call. Do them after the README.
>
> **Lab:** the full stack (`./infra/bootstrap.sh all`) — app services + Prometheus/Grafana/Nagios.
> Work in a copy under `/tmp/stack-drill` for destructive tasks. **Rules:** type it, diagnose before you
> fix, run ✅ **Verify** each task.

Each task: **Scenario · Objective · Given/constraints · Hints · ✅ Verify · Pitfalls · 🎯 Stretch.**

---

## Task 1 — Guided: a fully-observed multi-service stack (fluency)

**Scenario.** `NAVI-241`. Bring up an app + db + reverse proxy stack that is monitored end to end:
metrics scraped, a dashboard, and an uptime check.

**Objective.** Compose stack up + healthy, exporters scraped by Prometheus, and one working alert on a
service being down.

**Given / constraints.** Healthchecks on every service; exporters wired; no secrets inline.

**Hints.**
1. Compose with app/db/proxy + node/cadvisor exporters on the monitoring network.
2. Prometheus scrape config includes the exporters; a `service_down` alert (`up == 0`).
3. `compose config -q`, then bring up and confirm `:9090/targets` all UP.

✅ **Verify.**
```bash
docker compose ps --format '{{.Service}} {{.Health}}' | grep -vq unhealthy && echo "ALL HEALTHY ✅"
curl -s localhost:9090/api/v1/targets | grep -c '"health":"up"'   # matches exporter count
```

**Pitfalls.**
- Monitoring the app but not the monitoring (no `up==0` alert).
- Exporters not on the same network as Prometheus.
- Healthchecks missing → orchestrator can't tell degraded from down.

🎯 **Stretch.** Add cAdvisor and a per-container resource dashboard row.

---

## Task 2 — Ticket-driven: "one service is unhealthy and dragging the stack" (diagnose → fix)

**Scenario.** `NAVI-242` (P2). *"The stack is up but the app returns 5xx intermittently; one dependency
looks unhealthy."* Localize and fix without restarting everything.

**Objective.** Identify the unhealthy service from health + metrics, fix its root cause, and restore the
app — **diagnose before restarting the world.**

**Given / constraints.** Recreate: a dependency with a failing healthcheck (bad config / resource cap).
Restart/fix only the offending service.

**Hints.**
1. `docker compose ps` (health) + `docker compose logs <svc>` + the Grafana panel for that service.
2. Is it resource starvation (hitting a `mem_limit`)? `docker stats`.
3. Fix the specific cause; `docker compose up -d <svc>` to recreate just that one.

✅ **Verify.**
```bash
docker compose ps --format '{{.Service}} {{.Health}}' | grep -q unhealthy && echo "STILL UNHEALTHY ❌" || echo "HEALTHY ✅"
for i in $(seq 20); do curl -s -o /dev/null -w '%{http_code}\n' localhost:8080/; done | sort | uniq -c   # all 200
```

**Pitfalls.**
- `docker compose restart` (whole stack) for one bad service → needless disruption.
- Ignoring `mem_limit` OOM-kills (exit 137) — check `docker inspect`.
- Fixing the symptom (restart) without addressing why it went unhealthy.

🎯 **Stretch.** Add `deploy.resources` limits + an alert so the OOM condition pages *before* it kills the container.

---

## Task 3 — On-call: cascading failure across the stack (synthesis)

**Scenario.** `NAVI-243` (P1, time-boxed). The DB slows, the app's connection pool exhausts, the proxy
times out — a cascade. Find the origin, break the cascade, and document with a dependency-aware timeline.

**Objective.** Trace the failure to its origin (not the loudest symptom), apply the smallest fix that
breaks the cascade, verify recovery, and write an incident note with the dependency chain.

**Given / constraints.** Induce DB latency (`tc`/a slow query). Timebox 15 min. Fix the origin, then let
downstream recover; don't just restart the proxy.

**Hints.**
1. Order by time: which service degraded *first*? Use metrics timestamps, not gut feel.
2. Map the dependency chain (proxy → app → db) and walk it to the origin.
3. Mitigate at the origin (relieve DB), confirm downstream latency/errors recover.

✅ **Verify.**
```bash
for i in $(seq 20); do curl -s -o /dev/null -w '%{http_code}\n' localhost:8080/; done | sort | uniq -c   # back to 200
grep -qi 'dependency\|chain\|origin' docs/learning/reports/NAVI-243-postmortem.md && echo "CHAIN DOCUMENTED ✅"
```

**Deliverable.** `docs/learning/reports/NAVI-243-postmortem.md`: Impact · Timeline · Dependency chain · Root cause · Fix · Prevention.

**Pitfalls.**
- Restarting the proxy (loudest symptom) while the DB origin keeps the cascade going.
- No dependency map → chasing symptoms in the wrong order.
- Missing that connection-pool exhaustion is a symptom, not the cause.

🎯 **Stretch.** Add a circuit-breaker/timeout at the app→db boundary so a slow DB degrades gracefully instead of cascading.

---

## Done?
- [ ] All ✅ Verify pass · [ ] fixed the origin not the symptom · [ ] dependency chain documented · [ ] postmortem written.
- [ ] Secrets in `.env`. **Redaction:** no real creds/endpoints. → [README Step 7](./README.md).
