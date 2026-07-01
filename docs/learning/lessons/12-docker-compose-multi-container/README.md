# Lesson 12 — Docker Compose & Multi-Container Apps

**Status:** ready for self-study · **Date written:** 2026-06-11
**Gate Rule:** Concept → Real-World Use → Alternatives → Hands-On → Verification → Quiz → Reflection → Search Keywords

> **How to use this lesson:** same as Lessons 03–11. Completing this lesson's
> hands-on satisfies the **Junior SysAdmin Definition of Done** for Docker
> (per `PROJECT_MISSION.md`) and unlocks **M2** in `JOB_MILESTONES.md`.

---

## Step 1 — Concept

### What it is

**Docker Compose** is a tool for defining and running **multi-container**
applications using a single YAML file (`docker-compose.yml` /
`compose.yaml`). Instead of running multiple `docker run` commands by hand
(error-prone, hard to reproduce), you declare all services, their networks,
volumes, and dependencies in one file, and start everything with
`docker compose up`.

### Why it exists

Real applications are rarely a single container — a typical web app needs an
**app server**, a **database**, maybe a **cache** (Redis), and a **reverse
proxy** (nginx). Manually running `docker run` for each, getting networking
between them right, managing startup order, and reproducing this on another
machine is tedious and error-prone. Compose makes the **entire stack**
declarative, version-controllable, and reproducible with one command.

### What problem it solves

| Problem | Compose solution |
|---|---|
| "Run my app + Postgres + Redis together, networked" | One `compose.yaml`, `docker compose up` |
| "New developer needs the full stack running locally" | `git clone && docker compose up` |
| "The app starts before the database is ready and crashes" | `depends_on` with `condition: service_healthy` |
| "I need the database data to survive container restarts" | Named volumes |
| "Services should reach each other by name, not hardcoded IPs" | Compose's built-in DNS (service name = hostname) |

### Three-Level Depth (Lens A)

- **Level 1 — Beginner:** A `compose.yaml` has a top-level `services:` key; each
  service is roughly equivalent to one `docker run` command's worth of config
  (`image`, `ports`, `environment`, `volumes`). `docker compose up -d` starts
  everything in the background; `docker compose down` stops and removes
  containers (but not named volumes, by default); `docker compose logs -f
  <service>` follows one service's logs.
- **Level 2 — SysAdmin:** Per [Reintech's Compose networking guide](https://reintech.io/blog/docker-compose-networking-best-practices)
  and [GeeksforGeeks healthchecks guide](https://www.geeksforgeeks.org/devops/docker-compose-healthchecks-ensuring-container-availability/):
  Compose creates a **default network** where every service can reach every
  other service **by service name** (built-in DNS — e.g., your app connects to
  `postgres://db:5432`, not an IP). Use `internal: true` on a network to prevent
  external access (e.g., the database network shouldn't be reachable from
  outside the host at all). **Named volumes** (declared under top-level
  `volumes:`) persist data independent of container lifecycle — `docker compose
  down` removes containers but named volumes survive (`docker compose down -v`
  removes them too — be careful). **`depends_on`** alone only waits for the
  dependency container to **start** (not be *ready*) — per
  [Cyril Baah's healthchecks guide](https://medium.com/@cbaah123/docker-compose-health-checks-made-easy-a-practical-guide-3a340571b88e),
  combine with a `healthcheck:` block (`interval`, `timeout`, `retries`) and
  `depends_on: <service>: condition: service_healthy` so dependent services wait
  until the database **actually accepts connections**, not just "the container
  process started."
- **Level 3 — Systems/Kernel (Lens D):** Compose's "service name = hostname"
  magic is implemented via Docker's **embedded DNS server** (at `127.0.0.11`
  inside each container's network namespace, Lesson 11) — each container's
  `/etc/resolv.conf` points to it, and it resolves other service names to their
  container IPs on the same Docker network (a Linux **bridge** network device,
  using `iptables`/`nftables` rules for NAT between the bridge and the host —
  directly extending Lesson 09's NAT concepts). Healthchecks run **inside** the
  container's namespace via `docker exec`-equivalent — the result feeds into the
  container's reported status, which `depends_on: condition: service_healthy`
  polls.

### Analogy (Lens B)

- **Compose file** = a recipe for a multi-course meal that lists not just each
  dish (service) but also which dishes need to be ready before others are
  plated (`depends_on`), shared serving dishes (volumes), and which courses are
  served on the same table vs. separate tables (networks).
- **Service discovery by name** = an office directory where you call a
  colleague by their name/extension ("db", "redis") rather than memorizing
  their desk's physical room number (IP) — and if they move desks (container
  restarts with a new IP), the directory updates automatically.
- **`depends_on` without healthcheck** = "wait for your coworker to arrive at
  the office" vs. **with healthcheck** = "wait for your coworker to arrive AND
  finish their coffee AND be at their desk ready to take calls" — the
  difference between "started" and "ready."

The "recipe" analogy holds well for structure but breaks down for the **embedded
DNS/bridge networking** mechanism (Level 3) — there's no real-world equivalent of
"every dish on this table can automatically discover and connect to every other
dish by name via an automatic internal phone system."

---

## Step 2 — Real-World Use

### How SysAdmins/developers use this daily

```bash
docker compose up -d            # start all services, detached
docker compose ps                # status of all services in this project
docker compose logs -f app       # follow logs for one service
docker compose exec db psql -U postgres   # shell/command into a running service
docker compose down              # stop and remove containers (keeps named volumes)
docker compose down -v           # also remove named volumes (DESTRUCTIVE - data loss)
docker compose config            # validate and print the resolved config
```

**Real production scenarios:**
1. **Local dev environment mirrors production stack** — app + DB + cache + proxy,
   all in one `compose.yaml`, so "works on my machine" actually means something.
2. **CI integration tests** — spin up a real Postgres container for tests instead
   of mocking the database (ties to the integration-testing principle).
3. **Small production deployments** — single-host apps (not yet needing
   Kubernetes) often run via Compose with `restart: unless-stopped`.

### Common mistakes

| Mistake | Impact | Fix |
|---|---|---|
| Relying on `depends_on` alone for "DB is ready" | App crashes on startup with "connection refused" — DB container started but Postgres hasn't finished initializing | Add `healthcheck:` to db service + `condition: service_healthy` |
| Hardcoding `localhost` for inter-service connections | Each container has its own `localhost` — won't reach other containers | Use the **service name** as hostname (Compose DNS) |
| Not using named volumes for databases | Data lost every `docker compose down` | Declare a named volume, mount it at the DB's data directory |
| `docker compose down -v` on production | Deletes all persistent data | Reserve `-v` for dev/throwaway environments; never run on prod without explicit confirmation |
| One giant `compose.yaml` with secrets hardcoded | Secrets committed to git | Use `.env` files (gitignored) + `environment:` referencing variables, or Docker secrets |

### When NOT to use Compose

- Multi-host deployments needing auto-scaling, rolling updates, self-healing
  across nodes — that's Kubernetes territory (beyond NaviOps' current scope, but
  good to know the boundary).
- When you only have one container with no dependencies — plain `docker run` (or
  a systemd unit wrapping it, Lesson 05) is simpler.

### Interview Angle

**Question:** "Your app container starts fine but immediately throws
'connection refused' when it tries to reach Postgres. `depends_on` is set
correctly. What's going on, and how do you fix it?"

A junior answer says "the DB container isn't running" and stops — but `docker
compose ps` shows it *is* running. The senior answer recognizes that
`depends_on` alone only waits for the container to *start*, not for Postgres
inside it to finish initializing and accept connections — "started" vs.
"ready." The fix is a `healthcheck:` on the db service plus `condition:
service_healthy` on the dependent service. A senior candidate also flags the
related trap: hardcoding `localhost` instead of the service name, since each
container has its own network namespace and `localhost` won't resolve to a
sibling container.

---

## Step 3 — Alternatives

| Tool | Use case |
|---|---|
| **Docker Compose** (this lesson) | Single-host multi-container apps; local dev; small production deployments |
| **Kubernetes** | Multi-host orchestration, auto-scaling, self-healing — the "next level" beyond Compose, large learning curve |
| **Podman Compose / Quadlet** | Podman's equivalents — relevant on RHEL/Alma if avoiding the Docker daemon |
| **systemd unit per container** (Lesson 05) | For a *single* container that needs to survive reboot without Compose's orchestration features |

---

## Step 4 — Hands-On Task (build this yourself)

> ▶ **Do this on the lab**: start the environment first — `./infra/bootstrap.sh up` (once: `pull`), then
> `docker exec -it naviops-web bash`. **Node:** the Docker host. **Artifact:** study/extend `infra/lab/docker-compose.yml`; add a service.
> Reference solution (after you try): `docs/learning/reference-solutions/` (gitignored answer key).

**Goal:** Build a `compose.yaml` for a small multi-service stack: an app
(can be a trivial script/web server) + a database, with proper networking,
named volumes, and healthchecks.

### Lens C — Manual → Automated → Why

**Manual:** running `docker run --network mynet ... postgres`, then separately
`docker run --network mynet ... myapp`, manually creating the network first,
remembering the exact flags every time.

**Automated (`compose.yaml`):**
```yaml
services:
  db:
    image: postgres:16-alpine
    environment:
      POSTGRES_PASSWORD: ${DB_PASSWORD}
      POSTGRES_DB: naviops
    volumes:
      - db_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 5s
      timeout: 5s
      retries: 5
    networks:
      - backend

  app:
    build: .
    environment:
      DATABASE_URL: postgres://postgres:${DB_PASSWORD}@db:5432/naviops
    depends_on:
      db:
        condition: service_healthy
    ports:
      - "8080:8080"
    networks:
      - backend
      - frontend

networks:
  frontend:
  backend:
    internal: true   # db not reachable from outside the host

volumes:
  db_data:
```

**Why this matters:** this is the **canonical pattern** —
[Reintech's networking guide](https://reintech.io/blog/docker-compose-networking-best-practices)
specifically recommends `internal: true` for backend networks so the database is
never directly exposed, and `condition: service_healthy` ensures the app doesn't
start until Postgres is genuinely accepting connections — both common
interview/code-review topics.

### What to build, step by step

1. Create a `.env` file (gitignored!) with `DB_PASSWORD=<your-local-password>`.
2. Write `compose.yaml` per the structure above (adapt `app`'s `build:` to a
   simple Dockerfile from Lesson 11, or use an existing image like
   `nginx:alpine` for `app` if you don't have an app yet — the goal is
   practicing the Compose patterns, not building a full app).
3. `docker compose up -d`, then `docker compose ps` — confirm both services show
   healthy/running.
4. Test service-name DNS: `docker compose exec app sh -c "nc -zv db 5432"`
   (or equivalent) — confirms `app` can reach `db` by name.
5. Test data persistence: `docker compose down` (without `-v`), then
   `docker compose up -d` again — confirm the database still has its data.
6. Commit `compose.yaml`, `.env.example` (template, no real secrets), and
   `.gitignore` entry for `.env` on `lesson/12-docker-compose-multi-container`.

---

## Step 5 — Verification

```bash
docker compose config              # validates YAML, shows resolved config
docker compose up -d
docker compose ps                  # all services should show "healthy"/"running"

# Test service discovery
docker compose exec app sh -c "getent hosts db"   # should resolve to db's container IP

# Test persistence
docker compose down
docker compose up -d
docker compose exec db psql -U postgres -d naviops -c "\dt"   # data still there

# Cleanup
docker compose down
```

### Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| `app` exits immediately with "connection refused" to `db` | `depends_on` without healthcheck — db container started but Postgres not ready | Add `healthcheck:` + `condition: service_healthy` |
| `app` can't resolve `db` as a hostname | Services on different networks | Ensure both services share at least one common network |
| `.env` variables not substituted (`${DB_PASSWORD}` literally appears) | `.env` file missing or in wrong directory | `.env` must be in the same directory as `compose.yaml` |
| Data gone after `docker compose down` | Used `-v` flag, or volume not properly declared/mounted | Remove `-v` for routine restarts; verify `volumes:` mapping |
| `docker compose up` fails: "port already in use" | Another process/container already bound to that host port | `docker ps` to find it, or change the host-side port mapping |

### Redaction check ✅

`.env` (with real passwords) must be gitignored — only commit `.env.example`
with placeholder values (`DB_PASSWORD=changeme`).

---

## Step 6 — Quiz (Interview-Style, Graded)

**Q1.** Explain how two services in the same `compose.yaml` reach each other —
what hostname would `app` use to connect to `db`, and how does that resolve
under the hood?

> **Your answer:**

**Q2.** **Scenario:** Your `app` service has `depends_on: - db` (no healthcheck)
and crashes on startup with "connection refused" about 1 in 5 times. Why does
this happen intermittently, and how do you fix it permanently?

> **Your answer:**

**Q3.** What's the difference between a named volume and a bind mount? When
would you use each?

> **Your answer:**

**Q4.** Why would you set `internal: true` on a network used only by your
database service? What does this protect against?

> **Your answer:**

**Q5.** What's the difference between `docker compose down` and
`docker compose down -v`? Give a scenario where running the wrong one would be
a serious incident.

> **Your answer:**

**Q6.** How would you store a database password used by `compose.yaml` without
committing it to git? Walk through the file(s) involved.

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

**🔴 Attacker (how it's abused — Step 2):** A multi-container stack widens the attack surface: over-published ports, secrets passed as plaintext `environment:` vars, and a flat compose network that lets one compromised service pivot to the rest. ATT&CK **T1610**, **T1078** (Valid Accounts).

**🔵 Defender (detect & harden — Step 5):** Put backends on an **internal** network, publish only what's needed, pass secrets via files/`secrets:` not env, add healthchecks, and scan the whole stack. Treat the reverse proxy as the only intended ingress.

## Step 8 — Search Keywords For Further Understanding

**Core**
- `docker compose healthcheck depends_on condition service_healthy`
- `docker compose networks internal explained`
- `docker compose named volumes vs bind mounts`
- `docker compose env file secrets best practices`

**Tools**
- `docker compose config validate`
- `docker compose logs follow multiple services`
- `docker embedded dns service discovery`

**Going further (future lessons)**
- `ansible docker_compose module`
- `github actions docker compose ci`
- `kubernetes vs docker compose migration path`

---

**Red / Blue (Lens E — study attacker & defender in parallel):**
- 🔴 **Red (attacker):** `docker compose secrets exposure environment`, `container lateral movement`, `MITRE ATT&CK T1610 deploy container`, `exposed docker published ports`
- 🔵 **Blue (defender):** `docker internal network isolation`, `docker secrets vs environment variables`, `compose security hardening`

## Lesson Status

- [ ] Hands-on task completed (Step 4)
- [ ] Verification passed (Step 5)
- [ ] Quiz answered + professional-answer comparisons requested (Step 6)
- [ ] Reflection completed (Step 7)
- [ ] Search Keywords reviewed (Step 8)

When complete, run the Update Protocol, then move to **Lesson 13 — Ansible
Fundamentals**.

---

*Lesson 12 written by Navi v28 · 2026-06-11 · WebSearch sources:
[Reintech Docker Compose Networking Best Practices](https://reintech.io/blog/docker-compose-networking-best-practices),
[GeeksforGeeks Docker Compose Healthchecks](https://www.geeksforgeeks.org/devops/docker-compose-healthchecks-ensuring-container-availability/),
[Cyril Baah Docker Compose Health Checks Guide](https://medium.com/@cbaah123/docker-compose-health-checks-made-easy-a-practical-guide-3a340571b88e),
[Docker Compose Services Reference](https://docs.docker.com/reference/compose-file/services/)*
