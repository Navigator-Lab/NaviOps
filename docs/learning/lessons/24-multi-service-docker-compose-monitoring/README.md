# Lesson 24 — Multi-Service Docker Compose + Monitoring (Synthesis Project)

**Status:** ready for self-study · **Date written:** 2026-06-11
**Gate Rule:** Concept → Real-World Use → Alternatives → Hands-On → Verification → Quiz → Reflection → Search Keywords

> **How to use this lesson:** **synthesis project** — combines Lesson 11/12
> (Docker/Compose), Lesson 21 (reverse proxy/load balancing), and Lesson 22
> (Prometheus/Grafana) into one realistic multi-container stack: a reverse
> proxy in front of 2+ app instances, a database, and a monitoring stack —
> all on one host.

---

## Step 1 — Concept

### What it is

A **multi-service Docker Compose stack** runs several interdependent
containers (reverse proxy, application replicas, database, monitoring) as one
managed unit, on isolated Docker networks (Lesson 12), with a **reverse
proxy** (e.g., Traefik or Nginx) as the single entry point that routes
requests to the right backend and load-balances across replicas (Lesson 21's
concepts, containerized).

### Why it exists

Lesson 12 gave you `db` + `app` (two services). Real applications are rarely
that simple: you need **multiple replicas** of the app for availability
(Lesson 21's load balancing), a **reverse proxy** to route traffic and
terminate TLS without each app instance needing its own public port, and
**monitoring** (Lesson 22) watching it all — and the database/monitoring
internals shouldn't be directly internet-reachable (Lesson 12's
`internal: true` network pattern, at a larger scale).

### What problem it solves

| Problem | Solution |
|---|---|
| "I have 2 instances of my app — how do users reach 'the app' as one address?" | Reverse proxy (Traefik/Nginx) load-balancing across replicas |
| "Only the reverse proxy should be reachable from outside; DB and app internals stay private" | Docker networks: `proxy` (external-facing) + `backend` (internal) |
| "I want to monitor this whole stack the way I learned in Lesson 22" | Prometheus + Node Exporter + (cAdvisor for container metrics) + Grafana, as additional services in the same Compose project |
| "One app replica crashes — does the whole stack go down?" | Reverse proxy health checks route around the unhealthy replica (Lesson 21) |
| "How do I know this whole thing is healthy at a glance?" | One Grafana dashboard covering proxy, app replicas, db, host |

### Three-Level Depth (Lens A)

- **Level 1 — Beginner:** A `compose.yaml` defines multiple `services:` —
  `proxy`, `app` (with `deploy.replicas` or simply two named services
  `app1`/`app2`), `db`, `prometheus`, `grafana`, `node-exporter`,
  `cadvisor`. Each connects to one or more **networks** (Lesson 12).
- **Level 2 — SysAdmin:** Per [DCHost's Docker Compose production VPS
  architecture guide](https://www.dchost.com/blog/en/docker-compose-production-vps-architecture-for-small-saas-apps/)
  and [dev.to's reverse-proxy + monitoring
  walkthrough](https://dev.to/chigozieco/dockerized-deployment-of-a-full-stack-application-with-reverse-proxy-monitoring-observability-5c04):
  the standard architecture is a **shared `proxy` network** — the reverse
  proxy (Traefik/Nginx) is the **only** service with published ports
  (80/443), connected to both the `proxy` network (app replicas) and
  exposing nothing else. App replicas connect to `proxy` (so the reverse
  proxy can reach them) **and** an internal `backend` network (so they can
  reach the database) — but are **not** individually published to the host.
  The database connects **only** to `backend` — completely unreachable from
  outside, exactly Lesson 12's pattern, now with a proxy layer in front.
  Production guidance: `restart: always` (or `unless-stopped`), explicit
  **resource limits** (`deploy.resources.limits` — ties to Lesson 11's
  `--memory`/cgroups), health checks on every service, and `depends_on:
  condition: service_healthy` (Lesson 12) so the proxy doesn't route to an
  app replica before its DB connection is ready.
- **Level 3 — Systems/Kernel (Lens D):** **cAdvisor** (Container Advisor)
  reads each container's **cgroup** statistics (Lesson 11's cgroups — CPU/
  memory/IO limits and usage **per container**) and exposes them in
  Prometheus format — this is Lesson 22's Node Exporter (host-level `/proc`/
  `/sys`), but scoped to **per-container** cgroup hierarchies, giving you
  "which container is using how much CPU/memory" rather than just
  host-wide totals. The reverse proxy's load-balancing across app replicas
  uses the **same Docker embedded DNS** (Lesson 12) — a service name like
  `app` can resolve to multiple container IPs if there are multiple
  replicas, and Docker's DNS round-robins between them (or the proxy
  performs its own service discovery via the Docker socket, as Traefik
  does).

### Analogy (Lens B)

- **The whole stack** = a small office building: the **reverse proxy** is the
  receptionist/front door (the only public entrance), **app replicas** are
  multiple identical service desks behind that front door (the receptionist
  sends visitors to whichever desk is free — load balancing), the
  **database** is the records room in the basement (no public access, only
  staff/service-desk badges work), and **Prometheus/Grafana/cAdvisor** are
  the building's facilities-management dashboard (tracking power/water usage
  per room — per-container resource usage).
- **`proxy` vs `backend` networks** = two separate keycard zones — the front
  door (proxy) and service desks (app) share a "public-facing" zone keycard;
  the service desks and records room share a separate "internal" zone keycard
  — the front door has no keycard for the records room at all.
- **cAdvisor** = a smart power meter on **each individual desk's outlet**
  (per-container), vs. Node Exporter's meter on **the building's main
  electrical panel** (per-host, total).

The "office building" analogy holds well but breaks down for **Docker's
embedded DNS round-robin across replicas** — a receptionist doesn't typically
look up "which desk" via a directory that *itself* automatically rotates
between multiple identically-named desks; that's a distinctly
software-defined-networking behavior.

---

## Step 2 — Real-World Use

### How SysAdmins use this daily

```bash
docker compose up -d
docker compose ps                       # all services + health status
docker compose logs -f proxy            # reverse proxy logs (routing decisions)

# cAdvisor / per-container resource usage
curl -s localhost:8080/metrics | grep container_memory_usage_bytes | head

# Scale app replicas (if using `docker compose up --scale`)
docker compose up -d --scale app=3
```

**Real production scenarios:**
1. **Small SaaS deployment** — per [DCHost's guide], a single VPS running
   reverse proxy + app replicas + db + monitoring is a legitimate, common
   production architecture for small-to-medium applications — not just a
   learning exercise.
2. **Rolling update** — update `app` image, `docker compose up -d
   --no-deps app1`, confirm health check passes and the proxy routes traffic
   to it, then repeat for `app2` — zero-downtime deploy using Lesson 21's
   health-check-driven routing.
3. **"Why is the site slow?"** — Grafana dashboard shows `app2`'s CPU pegged
   at 100% (cAdvisor metric) while `app1` is idle — proxy isn't
   load-balancing evenly, or `app2` has a stuck request — investigate using
   Lesson 19's methodology.

### Common mistakes

| Mistake | Impact | Fix |
|---|---|---|
| Publishing ports on app replicas directly (`ports: - "8081:8080"`) in addition to the proxy | Bypasses the proxy/load-balancing entirely; inconsistent access patterns | Only the proxy publishes ports to the host; app replicas reachable only via the `proxy` network |
| No resource limits on any service | One runaway container (e.g., a memory leak, Lesson 19) starves the whole host | Set `deploy.resources.limits` per service (Lesson 11's `--memory` at Compose scale) |
| Database on the same network as the reverse proxy | DB technically reachable from the public-facing network | Strict network segmentation: `backend` network for DB, `internal: true` (Lesson 12) |
| Monitoring stack (Prometheus/Grafana) exposed on public ports with default credentials | Attackers can read your entire metrics history / dashboards | Proxy-route monitoring UIs behind authentication, or keep on a VPN-only network (Lesson 21) |
| No `restart` policy | A crashed container stays down until someone notices | `restart: unless-stopped` (or `always`) on all long-running services |

### When NOT to over-engineer

- Two app replicas is enough to **demonstrate** load balancing for this
  lesson — real production scaling decisions depend on actual load testing,
  not "more replicas = better."

### Interview Angle

**Scenario:** "A teammate wants to add `ports: - '8081:8080'` to `app2` so
they can curl it directly for debugging. What's your reaction?"

A junior answer says "sure, that's convenient" or focuses only on "it
works, so it's fine." A senior answer flags the network-segmentation
tradeoff immediately: publishing a port on `app2` creates a second,
unmonitored entry point that bypasses Traefik entirely — traffic to it
skips load-balancing, health-check-driven routing, and any
auth/TLS the proxy provides, and it's easy to forget to remove before
shipping. The senior answer offers the safer alternative: `docker compose
exec app2 sh` to get a shell on the container directly, or `docker compose
logs app2` / `curl` from *within* the `proxy` or `backend` network (e.g.,
via another container or a temporary debug container attached to the same
network) — debugging access without widening the attack surface. This
mirrors the `db`-on-`backend`-only principle: only the proxy should be
internet-reachable, full stop.

---

## Step 3 — Alternatives

| Topic | Alternative | Note |
|---|---|---|
| Traefik (suggested reverse proxy) | Nginx, Caddy | Traefik auto-discovers services via the Docker socket (labels-based config) — less manual config than Nginx, but Nginx is more universally known; Caddy auto-handles TLS certificates |
| Docker Compose (single host, this lesson) | Kubernetes | Per [Distr's 2026 "Docker Compose in production" analysis](https://distr.sh/blog/running-docker-in-production/), Compose remains viable for single-host production; Kubernetes adds orchestration across multiple hosts at significant operational complexity — appropriate once one host's capacity is the bottleneck |
| cAdvisor | Docker's built-in `docker stats` | `docker stats` is fine for ad-hoc checks; cAdvisor exports the same data continuously to Prometheus for historical/dashboard use |

---

## Step 4 — Hands-On Task (build this yourself)

**Goal:** Build one `compose.yaml` with: Traefik (reverse proxy), 2 replicas
of a simple app, a Postgres database (Lesson 12), and a monitoring stack
(Lesson 22) with cAdvisor added — all on appropriately-segmented networks.

### Lens C — Manual → Automated → Why

**Manual (Lessons 11/12 separately):** one `compose.yaml` ran `db`+`app` with
direct port publishing — fine for one app instance, but doesn't model "what
if I need 2+ instances behind a single address with health-aware routing."

**Automated — `compose.yaml` sketch:**
```yaml
networks:
  proxy:
  backend:
    internal: true

services:
  traefik:
    image: traefik:v3.0
    command:
      - "--providers.docker=true"
      - "--providers.docker.exposedbydefault=false"
      - "--entrypoints.web.address=:80"
    ports:
      - "80:80"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
    networks:
      - proxy

  app1:
    build: ./app
    networks: [proxy, backend]
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.app.rule=PathPrefix(`/`)"
      - "traefik.http.services.app.loadbalancer.server.port=8080"
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
      interval: 10s
      retries: 3
    depends_on:
      db:
        condition: service_healthy
    deploy:
      resources:
        limits: { memory: 256M }

  app2:
    build: ./app
    networks: [proxy, backend]
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.app.rule=PathPrefix(`/`)"
      - "traefik.http.services.app.loadbalancer.server.port=8080"
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
      interval: 10s
      retries: 3
    depends_on:
      db:
        condition: service_healthy
    deploy:
      resources:
        limits: { memory: 256M }

  db:
    image: postgres:16-alpine
    networks: [backend]
    environment:
      POSTGRES_PASSWORD_FILE: /run/secrets/db_password
    secrets: [db_password]
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 5s
      retries: 5

  node-exporter:
    image: prom/node-exporter:latest
    network_mode: host

  cadvisor:
    image: gcr.io/cadvisor/cadvisor:latest
    volumes:
      - /:/rootfs:ro
      - /var/run:/var/run:ro
      - /sys:/sys:ro
      - /var/lib/docker:/var/lib/docker:ro
    networks: [backend]

  prometheus:
    image: prom/prometheus:latest
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml:ro
    networks: [backend, proxy]

  grafana:
    image: grafana/grafana:latest
    networks: [proxy]
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.grafana.rule=PathPrefix(`/grafana`)"

secrets:
  db_password:
    file: ./secrets/db_password.txt
```

**Why this matters:** per [dev.to's full-stack reverse-proxy +
monitoring example](https://dev.to/chigozieco/dockerized-deployment-of-a-full-stack-application-with-reverse-proxy-monitoring-observability-5c04),
this single file is a **realistic small-production architecture** —
**every** earlier lesson is represented: Lesson 11 (Dockerfiles for `app`),
Lesson 12 (Compose networks/healthchecks/secrets), Lesson 21 (Traefik
load-balancing across `app1`/`app2`), Lesson 22 (Prometheus/Grafana/
cAdvisor/Node Exporter).

### What to build, step by step

1. Reuse/adapt your Lesson 11 app image for `app1`/`app2` (add a `/health`
   endpoint if it doesn't have one).
2. Write `compose.yaml` per the sketch — two networks (`proxy`,
   `backend`), Traefik with Docker-provider labels, `app1`/`app2` on both
   networks, `db` on `backend` only.
3. Add `node-exporter`, `cadvisor`, `prometheus`, `grafana` per Lesson 22,
   with `prometheus.yml` scraping `node-exporter`, `cadvisor`, and (if your
   app exposes `/metrics`) the app itself.
4. `docker compose up -d` — confirm `docker compose ps` shows all healthy.
5. `curl localhost/` repeatedly — confirm Traefik routes to both `app1` and
   `app2` (e.g., have `/health` or root response include a hostname/instance
   ID to distinguish).
6. Stop `app1` (`docker compose stop app1`) — confirm Traefik stops routing
   to it (health check fails) and all traffic goes to `app2` — **this is
   Lesson 21's load-balancer failover, now containerized**.
7. Open Grafana (via Traefik's `/grafana` route) — build a dashboard showing
   per-container CPU/memory (cAdvisor) for `app1`/`app2`/`db`.
8. Document the architecture (with a simple diagram in markdown/ASCII) in
   `docs/architecture/multi-service-stack.md`.
9. Commit `compose.yaml`, `prometheus.yml`, app Dockerfile, and the
   architecture doc on `lesson/24-multi-service-docker-compose-monitoring`
   (`secrets/` gitignored, `secrets/db_password.txt.example` committed).

---

## Step 5 — Verification

```bash
docker compose ps                                 # all services healthy
for i in $(seq 1 6); do curl -s localhost/ ; echo; done  # alternating app1/app2

docker compose stop app1
for i in $(seq 1 4); do curl -s localhost/ ; echo; done  # all from app2 now
docker compose start app1

# Per-container resource metrics
curl -s localhost:8080/metrics | grep -E 'container_memory_usage_bytes\{.*app' 

# Confirm db is NOT reachable from outside backend network
docker compose exec traefik sh -c "wget -qO- db:5432" || echo "db unreachable from proxy network (expected)"
```

### Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| Traefik returns 404 for all requests | Missing/incorrect `traefik.http.routers.*.rule` label, or `exposedbydefault=false` with no `traefik.enable=true` label | Check labels match exactly; `docker compose logs traefik` shows discovered routers |
| Both `app1`/`app2` always get the same share but one is unhealthy and still receives traffic | Health check misconfigured (always passes) or Traefik not configured to respect it | Verify `healthcheck` actually fails when the app is broken (test by `docker compose exec app1 pkill <process>`) |
| `db` reachable from `proxy` network unexpectedly | `db` accidentally added to `proxy` network in `compose.yaml` | Remove `db` from any network except `backend` |
| Grafana via Traefik shows blank/broken UI | Grafana needs `GF_SERVER_ROOT_URL` set when served under a subpath (`/grafana`) | Set `GF_SERVER_ROOT_URL=http://<host>/grafana` and `GF_SERVER_SERVE_FROM_SUB_PATH=true` |
| cAdvisor container fails to start / permission errors | cAdvisor needs read access to `/sys`, `/var/lib/docker`, etc. | Confirm volume mounts match the sketch exactly; cAdvisor has known quirks on some host OSes — document if you hit this |

### Redaction check ✅

`secrets/db_password.txt` must be `.gitignore`d — commit only
`secrets/db_password.txt.example`. No real hostnames/IPs in
`docs/architecture/multi-service-stack.md`.

---

## Step 6 — Quiz (Interview-Style, Graded)

**Q1.** Why does only the reverse proxy (Traefik) publish ports to the host,
while `app1`/`app2` and `db` do not? Tie this back to Lesson 12's
`internal: true` network discussion.

> **Your answer:**

**Q2.** **Scenario:** You stop `app1` and traffic correctly continues to
`app2` with no errors. What specifically made this possible — name the two
mechanisms (one from Lesson 12, one from Lesson 21) working together.

> **Your answer:**

**Q3.** What's the difference between Node Exporter (Lesson 22) and cAdvisor?
When would a metric appear in one but not the other?

> **Your answer:**

**Q4.** Why is it a mistake to expose Grafana/Prometheus directly to the
internet with default credentials, in the context of this stack's network
design?

> **Your answer:**

**Q5.** A teammate suggests "let's just add `ports: - '8081:8080'` to `app2`
too, so we can debug it directly." What's the tradeoff of doing this, and is
there a safer way to access `app2` directly for debugging?

> **Your answer:**

**Q6.** This stack runs entirely on one host via Compose. At what point (what
signal/metric) would you know it's time to consider Kubernetes or
multi-host deployment instead? Reference [Distr's analysis](https://distr.sh/blog/running-docker-in-production/).

> **Your answer:**

---

## Step 7 — Reflection

*(Fill in after the quiz)*

- What did you learn?
- What confused you?
- What would you do differently?

---

## Step 8 — Search Keywords For Further Understanding

**Core**
- `traefik docker compose reverse proxy labels`
- `docker compose multi service production architecture`
- `cadvisor vs node exporter metrics`
- `docker compose health check load balancing failover`

**Tools**
- `traefik docker provider configuration`
- `docker compose secrets file`
- `grafana subpath reverse proxy configuration`

**Going further (future lessons)**
- `terraform deploy docker compose stack`
- `kubernetes vs docker compose decision criteria`
- `incident response multi-service architecture runbooks`

---

## Lesson Status

- [ ] Hands-on task completed (Step 4)
- [ ] Verification passed (Step 5)
- [ ] Quiz answered + professional-answer comparisons requested (Step 6)
- [ ] Reflection completed (Step 7)
- [ ] Search Keywords reviewed (Step 8)

When complete, run the Update Protocol, then move to **Lesson 25 — Terraform
+ AWS Infrastructure Project**.

---

*Lesson 24 written by Navi v28 · 2026-06-11 · WebSearch sources:
[DCHost Docker Compose Production VPS Architecture For Small SaaS Apps](https://www.dchost.com/blog/en/docker-compose-production-vps-architecture-for-small-saas-apps/),
[dev.to Dockerized Deployment with Reverse Proxy, Monitoring & Observability](https://dev.to/chigozieco/dockerized-deployment-of-a-full-stack-application-with-reverse-proxy-monitoring-observability-5c04),
[Distr Should I Run Plain Docker Compose in Production in 2026?](https://distr.sh/blog/running-docker-in-production/),
[DevToolbox Docker Compose: The Complete Guide for 2026](https://devtoolbox.dedyn.io/blog/docker-compose-complete-guide)*
