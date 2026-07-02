# Lesson 11 — Pure Practical: Docker Fundamentals

> **Companion to [`README.md`](./README.md).** Pure practice: 3 scenario tasks, guided → ticket-driven
> → on-call. Do them after the README.
>
> **Lab:** the host Docker engine (the lab itself runs on it). Work in `/tmp/docker-drill`.
> **Rules:** type it, diagnose before you fix, run ✅ **Verify** each task. No cloud, no pushes.

Each task: **Scenario · Objective · Given/constraints · Hints · ✅ Verify · Pitfalls · 🎯 Stretch.**

---

## Task 1 — Guided: containerize a small app the right way (fluency)

**Scenario.** `NAVI-111`. Package `scripts/healthcheck.sh` (or a tiny Python/HTTP app) into a lean,
reproducible image with a proper `HEALTHCHECK`.

**Objective.** A `Dockerfile` that builds a small image, runs as a non-root user, and reports healthy.

**Given / constraints.** Pin a base tag (no `:latest`), run as non-root, `.dockerignore` present.

**Hints.**
1. Small base (`alpine`/`debian:stable-slim`), `COPY` only what's needed, `USER app`.
2. Add `HEALTHCHECK CMD` that exercises the app.
3. `docker build -t naviops-app:0.1 .` → `docker run --rm naviops-app:0.1`.

✅ **Verify.**
```bash
docker build -t naviops-app:0.1 . && echo "BUILD ✅"
docker run -d --name t naviops-app:0.1; sleep 3
docker inspect --format '{{.State.Health.Status}}' t   # healthy
docker inspect --format '{{.Config.User}}' t           # non-root
docker rm -f t
```

**Pitfalls.**
- `FROM x:latest` → non-reproducible builds.
- Running as root inside the container (default) — set `USER`.
- Fat images from copying the whole context — use `.dockerignore`.

🎯 **Stretch.** Convert to a **multi-stage** build so the final image ships without build tools; compare `docker images` sizes.

---

## Task 2 — Ticket-driven: "the container keeps restarting / exits immediately" (diagnose → fix)

**Scenario.** `NAVI-112` (P2). *"I deployed the image and it just crash-loops. `docker ps` shows it
restarting."* Find why and fix it.

**Objective.** Determine the exit cause from logs + exit code and fix the real fault — **diagnose
before rebuilding.**

**Given / constraints.** Recreate a broken image (bad `CMD`, missing file, or a foreground process
that exits). Fix the specific cause, don't just add `restart: always`.

**Hints.**
1. `docker logs <c>` and `docker inspect --format '{{.State.ExitCode}}' <c>` — read the actual error.
2. Common causes: `CMD` isn't a long-running foreground process (PID 1 exits), missing binary/file, wrong path.
3. Reproduce interactively: `docker run --rm -it --entrypoint sh <image>` and run the command by hand.

✅ **Verify.**
```bash
docker run -d --name fixed naviops-app:fix; sleep 3
docker inspect --format '{{.State.Status}} {{.RestartCount}}' fixed   # running, RestartCount stops climbing
docker rm -f fixed
```

**Pitfalls.**
- "Fixing" a crash-loop with `restart: always` — it still crashes, just quietly.
- Backgrounding the main process so PID 1 exits and the container stops.
- Rebuilding blindly instead of reproducing with `--entrypoint sh`.

🎯 **Stretch.** Add a `HEALTHCHECK` + `restart: on-failure` and show the difference between "restarting because unhealthy" vs "exited".

---

## Task 3 — On-call: a container is eating the host (disk/CPU/mem) (synthesis)

**Scenario.** `NAVI-113` (P1, time-boxed). The host is under pressure and you suspect a container:
runaway logs filling disk, or unbounded CPU/memory. Contain it without killing unrelated workloads.

**Objective.** Identify the offending container, cap its resources, control its log growth, and
document — without taking down the rest of the lab.

**Given / constraints.** Simulate: a container with `--log-driver json-file` and no limits doing a
busy loop / log spam. Don't `docker system prune -a -f` blindly (destroys images/volumes).

**Hints.**
1. `docker stats --no-stream` (CPU/mem) and `docker ps -s` (writable/log size). Find the log file under `/var/lib/docker/containers/<id>/`.
2. Cap it: recreate with `--memory`, `--cpus`, and `--log-opt max-size=10m --log-opt max-file=3`.
3. Reclaim safely: `docker container prune` (stopped only) — never `-a` on a live host without reading what it removes.

✅ **Verify.**
```bash
docker stats --no-stream <c> | tail -1        # CPU/mem within the cap
docker inspect --format '{{.HostConfig.LogConfig.Config}}' <c>   # max-size present
test -f docs/learning/reports/NAVI-113-postmortem.md && echo "POSTMORTEM ✅"
```

**Deliverable.** `docs/learning/reports/NAVI-113-postmortem.md`: Impact · Detection · Root cause · Fix · Prevention.

**Pitfalls.**
- `docker system prune -a --volumes -f` in a panic → deletes data volumes and images others need.
- Killing the container but not fixing the unbounded log driver → it refills.
- Setting limits at `run` time but the old container still running unbounded — recreate.

🎯 **Stretch.** Set daemon-wide log limits in `/etc/docker/daemon.json` so every future container inherits sane defaults.

---

## Done?
- [ ] All ✅ Verify pass · [ ] reproduced before rebuilding · [ ] postmortem written.
- [ ] Non-root, pinned base, resource limits. **Redaction:** no registry creds committed. → [README Step 7](./README.md).
