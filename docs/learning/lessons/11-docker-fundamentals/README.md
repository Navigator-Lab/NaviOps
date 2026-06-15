# Lesson 11 — Docker Fundamentals

**Status:** ready for self-study · **Date written:** 2026-06-11
**Gate Rule:** Concept → Real-World Use → Alternatives → Hands-On → Verification → Quiz → Reflection → Search Keywords

> **How to use this lesson:** same as Lessons 03–10. Marks the start of **Month 2**
> per `ROADMAP.md`.

---

## Step 1 — Concept

### What it is

**Docker** packages an application with everything it needs to run (code, runtime,
libraries, config) into a **container** — a lightweight, isolated process that
shares the host's kernel but has its own filesystem, network, and process namespace.
An **image** is the read-only template; a **container** is a running (or stopped)
instance of that image.

### Why it exists

The classic problem: "it works on my machine." Different developers/servers have
different installed library versions, OS configs, etc. — software that depends on
the environment is fragile to move. Docker solves this by **packaging the
environment with the application** — the same image runs identically on a
developer's laptop, a CI runner, and a production server. It's also far lighter than
a full virtual machine: a container shares the host kernel (boots in
milliseconds, MBs of overhead) vs. a VM (own kernel, full OS, GBs, seconds-to-minutes
to boot).

### What problem it solves

| Problem | Docker solution |
|---|---|
| "Works on my machine but not in production" | Same image runs everywhere |
| "This app needs Python 3.11 but the server has 3.9, and another app needs 3.9" | Each app's container has its own Python version, isolated |
| "Spinning up a full VM for a quick test is slow and heavy" | `docker run` starts in ~1 second |
| "I need to onboard a new developer and they spend a day installing dependencies" | `docker compose up` (Lesson 12) — one command, full stack |

### Three-Level Depth (Lens A)

- **Level 1 — Beginner:** `docker images` lists images (templates); `docker ps`
  lists running containers (instances). `docker run <image>` creates and starts a
  container from an image. `docker build -t myapp .` builds an image from a
  `Dockerfile`.
- **Level 2 — SysAdmin:** Per [Docker's official building best practices](https://docs.docker.com/build/building/best-practices/)
  and [oneuptime's Docker images guide](https://oneuptime.com/blog/post/2026-02-02-docker-images-best-practices/view):
  choose a **minimal base image** (e.g., `python:3.12-slim` or `alpine` variants) —
  smaller images mean fewer vulnerabilities and faster pulls. **Layer caching**: each
  Dockerfile instruction creates a layer; Docker caches layers and reuses them if
  unchanged — the golden rule is to **copy files that change rarely before files
  that change often** (e.g., copy `package.json`/`requirements.txt` and run
  install *before* copying application source code, so dependency installs are
  cached across code changes). **Multi-stage builds** (Step 4) use multiple `FROM`
  instructions — a "builder" stage with compilers/build tools, and a final stage
  that copies only the compiled artifacts, dramatically reducing final image size
  and removing build tools (and their CVEs) from production images.
- **Level 3 — Systems/Kernel (Lens D):** Per [Atlantbh's namespaces/cgroups deep
  dive](https://www.atlantbh.com/how-docker-containers-work-under-the-hood-namespaces-and-cgroups/)
  and [doogal.dev's "How Docker Actually Works"](https://doogal.dev/how-docker-actually-works-a-deep-dive-into-namespaces-and-cgroups):
  a container is **not a VM** — it's a regular Linux process with extra kernel
  isolation. `docker run` triggers (via `runc`) the `clone()` syscall with flags like
  `CLONE_NEWPID` (own PID namespace — container's "PID 1" is a different PID on the
  host), `CLONE_NEWNET` (own network interfaces), `CLONE_NEWNS` (own mount namespace
  — own filesystem view via **OverlayFS**: read-only image layers + a writable layer
  on top). **cgroups** (control groups) are the resource governors — they cap how
  much CPU/memory/IO the container's processes can consume (`docker run --memory=512m`
  writes to `/sys/fs/cgroup/.../memory.max`), preventing a "noisy neighbor" container
  from starving the host or other containers. This directly extends Lesson 05's
  cgroups discussion (systemd units also use cgroups) — Docker and systemd both rely
  on the same kernel primitive.

### Analogy (Lens B)

- **Image vs. container** = a class vs. an object (if you've done OOP) — or more
  concretely, a recipe vs. a cooked meal: the recipe (image) is the same every time,
  but each time you cook it (run a container), you get a separate meal (instance)
  that you can eat/modify/throw away without changing the recipe.
- **Layers/caching** = a layered cake where each layer is baked separately and
  cached: if you only change the topmost layer (your app code), Docker doesn't
  need to "re-bake" the lower layers (OS, dependencies) — it reuses what it already
  has.
- **Namespaces** = giving each container its own labeled set of "view filters" — its
  own phone book (network namespace: it can't see the host's other network
  connections), its own employee directory (PID namespace: it can't see the host's
  other processes), its own filing cabinet (mount namespace: its own filesystem
  view) — while all containers and the host still physically share the same
  building (kernel).
- **cgroups** = the building's circuit breakers — each tenant (container) gets a
  breaker limiting how much power (CPU/memory) they can draw, so one tenant can't
  black out the whole building.

The "recipe vs. meal" analogy breaks down for **layer caching across images** — real
recipes don't share "pre-baked" components across different dishes the way Docker
image layers can be shared/cached across multiple images built from a similar base.

---

## Step 2 — Real-World Use

### How SysAdmins/developers use this daily

```bash
docker images                       # list local images
docker ps                            # running containers
docker ps -a                         # all containers (including stopped)
docker build -t myapp:latest .       # build image from Dockerfile in current dir
docker run -d -p 8080:80 --name web myapp:latest   # run detached, map port 8080->80
docker logs -f web                   # follow container logs
docker exec -it web /bin/sh          # shell into a running container
docker stop web && docker rm web     # stop and remove
docker system prune                  # clean up unused images/containers (careful!)
```

**Real production scenarios:**
1. **CI builds an image, pushes to a registry, production pulls and runs it** —
   the same artifact tested in CI is what runs in prod (no "rebuilt differently").
2. **Debugging a container that keeps restarting** — `docker logs <name>`,
   `docker inspect <name>` (check `State.ExitCode`, `OOMKilled`).
3. **Resource limits** — `docker run --memory=512m --cpus=0.5 myapp` prevents one
   container from consuming a whole host's resources (cgroups, Level 3).

### Common mistakes

| Mistake | Impact | Fix |
|---|---|---|
| Using `latest` tag in production | Non-reproducible — "latest" can change underneath you | Pin specific version tags (`myapp:1.4.2`) |
| Running containers as `root` (default) | If compromised, attacker has root inside the container (and potentially escapes) | `USER` directive in Dockerfile to drop to a non-root user |
| Copying entire project (`COPY . .`) before installing dependencies | Breaks layer caching — every code change reinstalls all dependencies | Copy dependency manifests first, install, *then* copy source |
| Not using `.dockerignore` | `.git`, `node_modules`, secrets accidentally baked into image | Add a `.dockerignore` (like `.gitignore`) |
| Single-stage build with build tools left in final image | Large image, more CVEs | Multi-stage builds (Step 4) |

### When NOT to use Docker

- Applications requiring direct hardware access or kernel modules (containers share
  the host kernel — not suitable for kernel-level work).
- GUI desktop applications (possible but awkward — Docker is built for
  services/processes, not desktop apps).
- When the overhead of learning Docker isn't justified for a single, simple,
  long-lived script — though even then, containerizing it ensures reproducibility.

### Interview Angle

**Question:** "A container keeps restarting in a crash loop. Walk me through how
you'd debug it, and what's wrong with this Dockerfile if `COPY . .` comes before
`RUN npm install`?"

A junior answer stops at `docker logs <name>` and maybe `docker ps -a` to confirm
the restart count. A senior answer chains `docker inspect <name>` to check
`State.ExitCode` and `OOMKilled` (is it crashing or getting killed for memory?),
correlates with `docker run --memory=` limits, and on the Dockerfile question
explains *why* `COPY . .` before `npm install` breaks layer caching — every
source change invalidates the dependency-install layer, turning a 2-second
rebuild into a 2-minute one. Senior candidates connect symptoms to root cause
across the build *and* runtime lifecycle, not just one command.

---

## Step 3 — Alternatives

| Tool | Use case |
|---|---|
| **Docker** (this lesson) | Industry-standard, huge ecosystem, what most job postings expect |
| **Podman** | Daemonless, rootless-by-default alternative; drop-in CLI compatible with Docker (`alias docker=podman` often works) — increasingly common on RHEL/Alma (no Docker daemon needed) |
| **containerd / CRI-O** | Lower-level container runtimes — what Kubernetes uses under the hood; you won't interact with these directly as a beginner |
| **Virtual Machines** | Full isolation (own kernel) — needed for running different OSes or kernel-level work; heavier |
| **Docker Compose** (Lesson 12) | For multi-container apps — single containers are rarely the whole picture |

**For NaviOps:** Docker is the right starting point (most tutorials/jobs assume it);
note that AlmaLinux/RHEL environments increasingly favor **Podman** — the concepts
transfer almost 1:1, and knowing both is a resume plus.

---

## Step 4 — Hands-On Task (build this yourself)

**Goal:** Containerize one of your `/scripts` (e.g., `user_audit.sh` or
`hardening_audit.sh`) using a multi-stage Dockerfile, and run it.

### Lens C — Manual → Automated → Why

**Manual:** running `./scripts/user_audit.sh` requires the script's exact
dependencies (bash, coreutils) to be present on whatever machine runs it.

**Containerized (`Dockerfile`):**
```dockerfile
# Stage 1: (not strictly needed for a bash script, but demonstrates multi-stage)
FROM alpine:3.20 AS base
RUN apk add --no-cache bash coreutils findutils procps

# Stage 2: final runtime image
FROM base AS runtime
WORKDIR /app
COPY scripts/user_audit.sh .
RUN chmod +x user_audit.sh
USER nobody
ENTRYPOINT ["./user_audit.sh"]
```

```bash
docker build -t naviops-audit:1.0 .
docker run --rm naviops-audit:1.0
```

**Why this matters:** per [Docker's multi-stage builds guide](https://docs.docker.com/build/building/multi-stage/),
real applications use multi-stage builds to compile/build in one stage (with
compilers, dev dependencies) and copy only the final artifacts into a slim runtime
stage — this example is intentionally simple (a bash script needs no compilation),
but the **pattern** (separate "build" concerns from "runtime" concerns, run as
non-root) is what production Dockerfiles for compiled languages (Go, Node, Python
with C extensions) follow.

### What to build, step by step

1. Write the `Dockerfile` above (adjust the script and any tools it needs —
   `user_audit.sh` likely needs `find`, `awk`, `grep`).
2. Add a `.dockerignore` (exclude `.git`, `docs/`, anything not needed in the
   image).
3. `docker build -t naviops-audit:1.0 .`
4. `docker run --rm naviops-audit:1.0` — confirm it runs and produces the expected
   output.
5. `docker images` — note the image size; try switching the base image
   (`alpine` vs `ubuntu`) and compare sizes.
6. Commit the `Dockerfile` and `.dockerignore` on `lesson/11-docker-fundamentals`.

---

## Step 5 — Verification

```bash
docker build -t naviops-audit:1.0 .
docker images naviops-audit               # check size
docker run --rm naviops-audit:1.0         # should run and exit cleanly

# Confirm it's running as non-root
docker run --rm naviops-audit:1.0 id      # (temporarily change ENTRYPOINT to "id" to test, or use --entrypoint)
docker run --rm --entrypoint id naviops-audit:1.0
```

### Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| `docker: command not found` | Docker not installed | Install Docker Engine (or Podman) per your distro's docs |
| `permission denied` running `docker` commands | User not in `docker` group | `sudo usermod -aG docker $USER`, log out/in (note: docker group = root-equivalent — security tradeoff) |
| Build fails: `apk: command not found` | Used `apt`/`apk` mismatched to base image (Alpine uses `apk`, Debian/Ubuntu use `apt`) | Match package manager to base image |
| Script fails inside container but works on host | Missing dependency (e.g., `bash` not in `alpine` by default — it has `sh`/`ash`) | Install needed packages explicitly in the Dockerfile |
| Container exits immediately | Expected for a `oneshot`-style script (Lesson 05 parallel) — `docker ps -a` shows exit code | `docker logs <container-id>` to see output/errors |

### Redaction check ✅

No real findings to redact here — just ensure the Dockerfile doesn't hardcode any
real hostnames/IPs if your script takes them as parameters.

---

## Step 6 — Quiz (Interview-Style, Graded)

**Q1.** Explain the difference between a Docker **image** and a **container**. If you
run `docker run myapp` three times, what do you have?

> **Your answer:**

**Q2.** What are **namespaces** and **cgroups**, and how do they relate to each other
in providing container isolation? (Tie back to Lesson 05's cgroups discussion.)

> **Your answer:**

**Q3.** **Scenario:** Your Dockerfile does `COPY . .` followed by
`RUN pip install -r requirements.txt`. Every time you change a single line of
application code, the entire dependency install re-runs and takes 3 minutes. Why,
and how do you fix it?

> **Your answer:**

**Q4.** What is a multi-stage build, and what specific production benefit does it
provide (name two)?

> **Your answer:**

**Q5.** Why is running a container as `root` (the default) a security concern, even
though the container is "isolated"? How do you fix it in a Dockerfile?

> **Your answer:**

**Q6.** A container keeps restarting in a crash loop. What two commands would you run
first to diagnose it, and what are you looking for in each?

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

**🔴 Attacker (how it's abused — Step 2):** Containers break the 'isolation' assumption: a `--privileged` container or a mounted `/var/run/docker.sock` is **root on the host**, and membership of the `docker` group equals root. Malicious images embed backdoors. ATT&CK **T1610** (Deploy Container), **T1611** (Escape to Host).

**🔵 Defender (detect & harden — Step 5):** Run containers **non-root**, drop capabilities, read-only rootfs, never mount `docker.sock` into untrusted containers, **never add untrusted users to the `docker` group**, and scan images (Trivy/Grype) before running them.

## Step 8 — Search Keywords For Further Understanding

**Core**
- `docker image vs container explained`
- `dockerfile layer caching best practices`
- `docker multi-stage builds explained`
- `docker namespaces cgroups under the hood`

**Tools**
- `docker build buildkit cache`
- `dockerignore best practices`
- `podman vs docker rootless`

**Going further (future lessons)**
- `docker compose multi container app`
- `docker restart policies`
- `kubernetes vs docker compose when`

---

**Red / Blue (Lens E — study attacker & defender in parallel):**
- 🔴 **Red (attacker):** `docker container escape`, `MITRE ATT&CK T1611 escape to host`, `privileged container breakout`, `docker.sock mount privilege escalation`
- 🔵 **Blue (defender):** `docker non-root user`, `drop linux capabilities container`, `trivy image vulnerability scanning`, `docker bench security`

## Lesson Status

- [ ] Hands-on task completed (Step 4)
- [ ] Verification passed (Step 5)
- [ ] Quiz answered + professional-answer comparisons requested (Step 6)
- [ ] Reflection completed (Step 7)
- [ ] Search Keywords reviewed (Step 8)

When complete, run the Update Protocol, then move to **Lesson 12 — Docker Compose &
Multi-Container Apps**.

---

*Lesson 11 written by Navi v28 · 2026-06-11 · WebSearch sources:
[Docker Building Best Practices](https://docs.docker.com/build/building/best-practices/),
[Docker Multi-Stage Builds](https://docs.docker.com/build/building/multi-stage/),
[oneuptime Docker images best practices](https://oneuptime.com/blog/post/2026-02-02-docker-images-best-practices/view),
[Atlantbh namespaces/cgroups deep dive](https://www.atlantbh.com/how-docker-containers-work-under-the-hood-namespaces-and-cgroups/),
[doogal.dev How Docker Actually Works](https://doogal.dev/how-docker-actually-works-a-deep-dive-into-namespaces-and-cgroups)*
