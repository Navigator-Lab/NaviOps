# Lesson 12 — Pure Practical: Docker Compose (Multi-Container)

> **Companion to [`README.md`](./README.md).** Pure practice: 3 scenario tasks, guided → ticket-driven
> → on-call. Do them after the README.
>
> **Lab:** host Docker + Compose. Work in `/tmp/compose-drill` (don't disturb `infra/`).
> **Rules:** type it, diagnose before you fix, run ✅ **Verify** each task.

Each task: **Scenario · Objective · Given/constraints · Hints · ✅ Verify · Pitfalls · 🎯 Stretch.**

---

## Task 1 — Guided: a web + db stack with healthchecks and dependency order (fluency)

**Scenario.** `NAVI-121`. Stand up a two-service stack (a web app + a database) where the web service
only starts serving once the DB is actually ready.

**Objective.** A `compose.yaml` with a named network, a volume for DB data, healthchecks, and
`depends_on: condition: service_healthy`.

**Given / constraints.** No secrets in the file (use `.env`/`env_file`, gitignored). Pinned image tags.

**Hints.**
1. Two services, one network, one named volume for the DB.
2. DB `healthcheck` (e.g. `pg_isready`/`mysqladmin ping`); web `depends_on: db: condition: service_healthy`.
3. `docker compose up -d` → `docker compose ps` shows both healthy.

✅ **Verify.**
```bash
docker compose up -d && sleep 8
docker compose ps --format '{{.Service}} {{.Health}}'   # both healthy
docker compose config -q && echo "COMPOSE VALID ✅"
```

**Pitfalls.**
- `depends_on` without `condition: service_healthy` → web starts before DB is ready (start order ≠ readiness).
- Storing the DB password inline in `compose.yaml`.
- No volume → data lost on `down`.

🎯 **Stretch.** Add a `restart: unless-stopped` policy and an override file (`compose.override.yaml`) for local-only settings.

---

## Task 2 — Ticket-driven: "services can't talk to each other" (diagnose → fix)

**Scenario.** `NAVI-122` (P2). *"The web container can't reach the db container — connection refused,
even though both are up."* Fix the inter-service networking.

**Objective.** Restore service-to-service connectivity, identifying whether it's DNS (service name),
port, network membership, or bind address — **diagnose first.**

**Given / constraints.** Recreate a fault: services on different networks, DB bound to `127.0.0.1`
inside its container, or web using `localhost` instead of the service name.

**Hints.**
1. From web: `docker compose exec web getent hosts db` — does the service name resolve? (Compose DNS uses service names.)
2. Port reachable? `docker compose exec web nc -vz db <port>`. Is DB listening on `0.0.0.0` inside its container, not `127.0.0.1`?
3. Same network? `docker network inspect <net>` — both attached?

✅ **Verify.**
```bash
docker compose exec web nc -vz db <dbport> 2>&1 | grep -qi succeeded && echo "CONNECTED ✅"
docker compose exec web getent hosts db && echo "DNS OK ✅"
```

**Pitfalls.**
- Using `localhost`/`127.0.0.1` from web to reach db — that's the *web* container's loopback, not the DB.
- DB configured to listen only on `127.0.0.1` inside its own container → unreachable from peers.
- Assuming published ports (`ports:`) are needed for inter-service comms — they're not; the shared network is.

🎯 **Stretch.** Split into two networks (frontend/backend) and put the DB only on the backend so it's not reachable from the published side.

---

## Task 3 — On-call: a bad deploy — roll a stack back safely (synthesis)

**Scenario.** `NAVI-123` (P1, time-boxed). A new image tag was rolled out via Compose and the app is
erroring. Roll back to the last-good tag with minimal downtime and without losing DB data.

**Objective.** Identify the bad service, roll it back to the previous image, keep the DB volume intact,
and document.

**Given / constraints.** Simulate a "bad" web image tag vs a "good" one. Never `docker compose down -v`
(that deletes volumes). Data must survive.

**Hints.**
1. `docker compose ps` + `docker compose logs web` — confirm which service and why.
2. Roll back: set the previous tag (env var / edit), `docker compose up -d web` (recreates only that service).
3. Confirm DB volume untouched (`docker volume ls`, data still present).

✅ **Verify.**
```bash
docker compose ps --format '{{.Service}} {{.Image}} {{.Health}}'   # web on the good tag, healthy
docker volume ls | grep -q <db-volume> && echo "DATA VOLUME INTACT ✅"
test -f docs/learning/reports/NAVI-123-postmortem.md && echo "POSTMORTEM ✅"
```

**Deliverable.** `docs/learning/reports/NAVI-123-postmortem.md`: Impact · Detection · Root cause · Fix · Prevention.

**Pitfalls.**
- `docker compose down -v` to "reset" → wipes the DB volume; catastrophic.
- Rolling back all services when only one is bad → needless disruption.
- No pinned previous tag to roll back to (`:latest` everywhere) — you can't reproduce last-good.

🎯 **Stretch.** Add a smoke-test step (`curl` the health endpoint) to a `scripts/` deploy wrapper that auto-rolls-back on failure.

---

## Done?
- [ ] All ✅ Verify pass · [ ] `compose config` valid · [ ] data volume preserved · [ ] postmortem written.
- [ ] Secrets in `.env` only. **Redaction:** no real creds. → [README Step 7](./README.md).
