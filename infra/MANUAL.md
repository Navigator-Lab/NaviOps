# infra/ — The Beginner's Manual (Docker, the Lab & bootstrap, explained)

> **Who this is for:** you, on day one of Docker. No prior Docker knowledge assumed.
> **Companion to** [`README.md`](./README.md) (the quick reference). This file is the *why* and the
> *how-it-actually-works*. Read it once top-to-bottom; then keep it open while you use the lab.
>
> **The one-sentence summary:** `infra/` is a fake data-center on your laptop — a couple of Linux
> "servers" and a monitoring room — built out of **Docker**, so you can practice real sysadmin work
> without renting cloud machines or risking your real computer.

---

## Part 0 — Why does this exist at all? (the problem it solves)

To learn Linux/ops you need **servers to break and fix**. Your options:

1. **Use your real laptop** — one typo (`rm -rf`, a bad firewall rule) and you've broken your daily
   machine. No "undo". ❌
2. **Rent cloud servers (AWS EC2)** — real, but costs money, needs an account, and a forgotten
   instance runs up a bill. ❌ (and NaviOps' rule is *no cloud spend*)
3. **Run throwaway "servers" as containers on your laptop** — free, offline, and if you wreck one you
   delete it and get a fresh one in 3 seconds. ✅ **This is what `infra/` does.**

So **Docker is the tool that gives you disposable, isolated practice servers.** That's the "why".

---

## Part 1 — Docker in plain English (the mental model)

Forget the jargon for a minute. Docker has **four nouns**. Learn these four and everything else clicks.

| Docker word | Plain-English analogy | In your lab |
|---|---|---|
| **Image** | A *recipe* / a frozen template of a machine | `jrei/systemd-ubuntu:22.04` — a frozen Ubuntu server |
| **Container** | A *running machine* made from that recipe | `naviops-web`, `naviops-db` — your two practice servers |
| **Volume** | A *USB drive* you plug in so data survives | `naviops-web-data` — keeps `/srv` even after you delete the container |
| **Network** | A *virtual switch/LAN* cabling machines together | `172.28.0.0/24` — the lab's private network |

### The key idea: image vs container

- An **image** is like a **class** in code, or a **cake recipe** — a definition, sitting on disk, not
  running.
- A **container** is a **running instance** of that image — like an **object**, or an actual **cake** you
  baked from the recipe. You can bake many cakes (containers) from one recipe (image).

You **pull** an image once (download it), then **run** it to get a container. Delete the container →
the recipe (image) is still there → run it again → brand-new container. This is why the lab is
"disposable": the container is throwaway, the image is kept.

### Why containers instead of full VMs?

A **virtual machine** boots a whole fake computer (its own kernel) — heavy, slow, GBs of RAM.
A **container** shares your laptop's Linux kernel and just isolates the *processes and filesystem* —
so it starts in **seconds** and is tiny. That's why your `lab/docker-compose.yml` comment says
*"containers (not VMs) so the lab is light and runs on any machine with Docker."*

> ⚠️ **Trade-off (be honest):** because containers share your kernel, running "a whole server" in one
> is slightly unnatural — that's why your lab nodes are `privileged: true` (more on that in Part 5).
> Fine for learning; **never** how you'd run production.

---

## Part 2 — A tour of *your* infra/ folder

Here's what's actually on disk (`find infra -type f`):

```
infra/
├── bootstrap.sh                      ← the "one button" you press (a Bash wrapper)
├── README.md                         ← quick reference (cheat card)
├── MANUAL.md                         ← this file (the teaching guide)
├── lab/
│   └── docker-compose.yml            ← defines the 2 practice servers (web + db)
└── monitoring/
    ├── docker-compose.yml            ← defines the NOC stack (Prometheus/Grafana/Nagios)
    ├── prometheus/prometheus.yml     ← Prometheus' config (what to scrape)
    └── grafana/provisioning/...      ← auto-wires Grafana to Prometheus
```

Two **"stacks"** (groups of containers that belong together):

1. **`lab/`** — your playground: `naviops-web` and `naviops-db`, two Linux servers you SSH into,
   break, and fix during lessons.
2. **`monitoring/`** — your "NOC wall": the dashboards a Network Operations Center stares at
   (Prometheus collects metrics, Grafana graphs them, Nagios is the classic alerting tool).

Each stack is described by a **`docker-compose.yml`** file. That's the next big concept.

> 📌 Note: the `README.md` table also lists `ansible/` and `terraform/` folders — those aren't created
> yet (the lessons ship those artifacts). Everything in *this* manual is about what exists now.

---

## Part 3 — What is docker-compose, and why not "just Docker"?

You *could* start each container with a long `docker run ...` command full of flags. For two servers +
four monitoring tools, that's six long fragile commands you'd have to type in the right order every time.

**Compose** is the fix: you write the whole setup **once, declaratively, in a YAML file**
(`docker-compose.yml`), and then one command (`docker compose up`) builds the entire stack — networks,
volumes, containers, all wired together. It's **infrastructure as a text file** you can version in git.

Think of it as the difference between:
- **`docker run`** = assembling furniture piece by piece, by hand, every time. 🔧
- **`docker compose up`** = handing over the IKEA instructions and it builds itself. 📋

**This is the professional habit:** real teams define infra as files (Compose, Terraform, Kubernetes
YAML), commit them, and rebuild identically anywhere. Your lab teaches you that habit from day one.

---

## Part 4 — bootstrap.sh: the one button (and what it *really* runs)

You almost never call Docker directly in this lab. You use [`bootstrap.sh`](./bootstrap.sh) — a small
Bash script that wraps the two Compose stacks so **you never have to remember paths or flags**.

### The commands (this is 90% of what you'll type)

```bash
./infra/bootstrap.sh pull         # ONE TIME: download all images (needs internet ONCE)
./infra/bootstrap.sh up           # start the 2 practice servers (web + db)
./infra/bootstrap.sh monitoring   # start the NOC stack (Grafana/Prometheus/Nagios)
./infra/bootstrap.sh all          # start both stacks
./infra/bootstrap.sh status       # what's running + the URLs/passwords
./infra/bootstrap.sh down         # stop everything (KEEPS your data)
./infra/bootstrap.sh destroy      # stop + DELETE data volumes (factory reset)
```

### What each one does under the hood (so it's not magic)

`bootstrap.sh` figures out whether you have `docker compose` (new) or `docker-compose` (old), then
`cd`s into the right folder and runs Compose for you. The mapping:

| You type | It really runs | In plain English |
|---|---|---|
| `pull` | `docker compose pull` in `lab/` **and** `monitoring/` | Download every recipe (image) once |
| `up` | `docker compose up -d` in `lab/` | Start web+db in the background (`-d` = detached) |
| `monitoring` | `docker compose up -d` in `monitoring/` | Start the dashboards |
| `all` | both `up -d` | Everything |
| `status` | `docker compose ps` in both + prints URLs | "what's alive?" |
| `down` | `docker compose down` | Stop & remove containers, **keep volumes** |
| `destroy` | `docker compose down -v` | Same, but `-v` also deletes volumes (your data) |

The single most important distinction here:

- **`down`** = stop the servers, **keep the disks**. Tomorrow, `up` and your work is still there.
- **`destroy`** = stop the servers **and wipe the disks**. Use this when a lesson says "start fresh"
  or you've made a mess you want gone. ⚠️ *This deletes data — it's the one to respect.*

### Your first-ever run

```bash
./infra/bootstrap.sh pull      # once, on wifi — grabs the images (~minutes)
./infra/bootstrap.sh all       # bring the whole lab up
./infra/bootstrap.sh status    # see it running; note the URLs
docker exec -it naviops-web bash   # <-- you are now root inside a Linux server. Play.
```

From then on, `up` / `down` need **no internet**. That's the "offline lab" promise.

---

## Part 5 — Reading your lab/docker-compose.yml line by line

This is where Docker stops being abstract. Here's *your* file, explained. (Open
[`lab/docker-compose.yml`](./lab/docker-compose.yml) alongside this.)

```yaml
name: naviops-lab            # the stack's name (groups these containers together)

services:                    # "services" = the containers this stack runs
  web:                       # service #1, nickname "web"
    image: jrei/systemd-ubuntu:22.04   # the RECIPE: an Ubuntu 22.04 that can run systemd
    container_name: naviops-web        # the fixed name you use: docker exec -it naviops-web bash
    hostname: web.naviops.lab          # its hostname *inside* the network
    privileged: true                   # ⚠️ gives it near-root over the kernel — needed so
                                       #    systemd/services work inside a container (learning only!)
    stop_signal: SIGRTMIN+3            # the signal systemd wants for a clean shutdown
    volumes:
      - /sys/fs/cgroup:/sys/fs/cgroup:rw   # lets in-container systemd manage services
      - naviops-web-data:/srv              # a VOLUME: /srv survives even if you delete the container
    tmpfs:
      - /run                               # scratch space in RAM (systemd needs it)
      - /run/lock
    networks:
      lab:
        ipv4_address: 172.28.0.10          # a FIXED IP on the lab network — so you can practice
                                           #   networking/subnetting against a stable address
    ports:
      - "2210:22"     # map laptop port 2210 -> container port 22 (SSH). "outside:inside"
      - "8080:80"     # laptop 8080 -> container 80 (web). Visit http://localhost:8080

  db:                        # service #2, the "database/backup" node — same idea, IP .11, port 2211
    ...

networks:
  lab:
    driver: bridge                 # a private virtual LAN just for this stack
    ipam:
      config:
        - subnet: 172.28.0.0/24    # the network range — this is real subnet math you practice in L08

volumes:
  naviops-web-data:                # declare the "USB drives" so Docker persists them
  naviops-db-data:
```

### The three concepts this file makes concrete

**1. Ports (`"2210:22"`) — the format is `HOST:CONTAINER`.**
A container is sealed by default. To reach a service inside it from your laptop you "publish" a port.
`"2210:22"` means: *traffic to `localhost:2210` on my laptop → port 22 (SSH) inside `naviops-web`.*
So after you set up SSH in Lesson 07: `ssh -p 2210 root@localhost`. Left number = your laptop, right
number = inside the container. **Remember: outside:inside.**

**2. Volumes (`naviops-web-data:/srv`) — data that outlives the container.**
Anything written *inside* a container's normal filesystem **vanishes** when the container is removed
(that's what makes them disposable). A **volume** is a managed disk Docker keeps separately and
"plugs in" at a path (`/srv`). So your files in `/srv` survive `down` and even a container rebuild —
but `destroy` (`-v`) wipes them. This is exactly how real servers separate the OS from the data.

**3. Networks (`172.28.0.0/24`, IPs `.10`/`.11`) — a real little LAN.**
Both nodes sit on one private network with fixed IPs, so `naviops-web` (.10) can `ping` / connect to
`naviops-db` (.11) by IP — and you practice **real subnetting** (Lesson 08) against a real network,
not a worksheet.

> ⚠️ **`privileged: true` — the honest caveat.** It hands the container broad control of your kernel.
> It's here *only* because running a full init system (systemd) inside a container needs it, and it's
> a throwaway local lab. In the real world, `privileged` is a red flag you'd almost never allow. The
> `README.md` says the same: *"never for production."* Good to internalize now.

The `monitoring/docker-compose.yml` follows the identical pattern — four services (prometheus,
node-exporter, grafana, nagios), each with an image, ports, and volumes, plus one detail worth noting:
`grafana` has `depends_on: [prometheus]` (start Prometheus first) and a **read-only config mount**
(`./prometheus/prometheus.yml:/etc/prometheus/prometheus.yml:ro`) — that's how you feed a tool its
config from a file on your disk.

---

## Part 6 — Native Docker commands you actually need

`bootstrap.sh` handles lifecycle. But once containers are up, you'll use **native `docker` commands**
to work *with* them. These are the professional core — learn these ~12:

### Look around
```bash
docker ps                       # what containers are running (add -a to include stopped ones)
docker images                   # what images (recipes) you have downloaded
docker volume ls                # your persistent "disks"
docker network ls               # your virtual LANs
docker stats --no-stream        # live CPU/memory per container (great for the "what's eating RAM?" drills)
```

### Get inside / interact
```bash
docker exec -it naviops-web bash   # open a shell INSIDE the running web node (your main move)
#            │  └─ the command to run                 -it = interactive terminal
#            └─ target container
docker logs naviops-prometheus     # see a container's output/logs (add -f to follow live)
docker logs --tail 50 naviops-web  # last 50 lines only
```

### Lifecycle (usually via bootstrap, but know the raw ones)
```bash
docker stop naviops-web     # stop one container
docker start naviops-web    # start it again
docker restart naviops-web  # stop + start
docker rm naviops-web       # delete a (stopped) container
docker rmi <image>          # delete an image (frees disk)
```

### Inspect (when debugging)
```bash
docker inspect naviops-web   # full JSON: IPs, mounts, ports, env — the source of truth
docker inspect --format '{{.State.Status}}' naviops-web   # just the status
docker exec naviops-web ip -br addr   # run one command without opening a shell
```

### The "I made a mess, reset" trio
```bash
docker compose -f infra/lab/docker-compose.yml down -v   # what 'bootstrap.sh destroy' does for the lab
docker system df                 # how much disk Docker is using
docker system prune              # clean up STOPPED containers + unused networks (safe-ish)
# ⚠️ docker system prune -a --volumes  → nukes images AND volumes. Powerful. Read before you run it.
```

**Mental link:** `bootstrap.sh` commands *are* these commands, pre-wired. Once you're comfortable,
peek at the script — every `bootstrap` verb maps to a `docker compose` line you now understand.

---

## Part 7 — Your daily workflows (copy these)

**Start a study session**
```bash
./infra/bootstrap.sh up            # (or 'all' if the lesson needs monitoring)
./infra/bootstrap.sh status        # confirm it's up, grab URLs
docker exec -it naviops-web bash   # go to work
```

**Do a lesson's hands-on (e.g. Lesson 05 systemd)**
```bash
docker exec -it naviops-web bash
# ...inside: systemctl, journalctl, edit unit files, run scripts/service_check.sh...
exit
```

**Stop for the day (keep your work)**
```bash
./infra/bootstrap.sh down          # your /srv data & volumes persist
```

**A lesson says "start clean" (or you broke something badly)**
```bash
./infra/bootstrap.sh destroy       # wipe volumes
./infra/bootstrap.sh up            # fresh servers
```

**Check the monitoring wall**
```bash
./infra/bootstrap.sh monitoring
# then browse: Grafana http://localhost:3000 (admin/naviops)
#              Prometheus http://localhost:9090  ->  Status ▸ Targets
#              Nagios http://localhost:8081/nagios (nagiosadmin/naviops)
```

---

## Part 8 — When it goes wrong (beginner troubleshooting)

| Symptom | Likely cause | Fix |
|---|---|---|
| `Cannot connect to the Docker daemon` | Docker isn't running | Start Docker (`sudo systemctl start docker`), or your Docker Desktop |
| `permission denied ... docker.sock` | Your user isn't in the `docker` group | `sudo usermod -aG docker $USER` then log out/in (or use `sudo`) |
| `bind: address already in use` on 3000/8080/9090 | Another program owns that port | Stop the other program, or change the left (host) number in the compose `ports` |
| `bootstrap.sh` says compose not found | Docker/Compose not installed | Install Docker Engine + the Compose plugin |
| Container keeps restarting / exits | Bad config inside it | `docker logs <name>` — read the actual error (see Lesson 11 Task 2) |
| Everything's weird after lots of tinkering | Accumulated cruft | `./infra/bootstrap.sh destroy && ./infra/bootstrap.sh up` — fresh start |
| `pull` fails | No internet (and images not cached yet) | The *first* `pull` needs internet once; after that you're offline-capable |

**Golden rule while learning:** if a container is confusing you, you can almost always
`destroy` + `up` for a clean slate. That fearlessness is the whole point of a disposable lab —
use it.

---

## Part 9 — Why you're doing this (the professional payoff)

You're not "learning Docker" as an end in itself. You're learning the modern shape of ops:

- **Containers** = disposable, reproducible servers → you practice fearlessly, and it's how real apps
  ship (dev, CI, and prod all run the same image).
- **Compose / infra-as-a-file** = your environment is *text in git*, rebuildable identically anywhere →
  this is the gateway habit to Terraform (Lesson 20/25) and Kubernetes (Lesson 29).
- **A wrapper like `bootstrap.sh`** = you turn a fiddly multi-step setup into one safe command →
  exactly what you'll do at a job (runbooks, Makefiles, deploy scripts).
- **The monitoring stack** = you see what a NOC/SRE actually watches all shift.

So the loop is: **`bootstrap.sh` to run the lab → `docker exec` into a server → do real Linux work →
read the monitoring → `destroy` and repeat.** Master that loop and you're doing entry-level ops for
real, on your own laptop, for free.

---

## One-page recap (screenshot this)

- **Image** = recipe (frozen). **Container** = running server (disposable). **Volume** = the disk that
  survives. **Network** = the LAN wiring them.
- **`docker-compose.yml`** = your whole setup as one text file. **`bootstrap.sh`** = the one button
  that runs it.
- **`up`/`down`** keep your data; **`destroy`** wipes it (that's the scary one).
- **`docker exec -it naviops-web bash`** = your way into a practice server.
- **Ports are `HOST:CONTAINER`.** Volumes persist. `privileged` is learning-only.
- Broke it? `destroy` → `up`. That's the superpower.

→ Next: run `./infra/bootstrap.sh pull` then `all`, and open **Lesson 05's** `PRACTICAL.md` to do
your first real task inside `naviops-web`.

---
---

# 📘 Worked Walkthrough — Finishing Lesson 06 (Cron & logrotate), step by step

> **Why this section exists.** You said Lesson 06's **Step 4 — Hands-On Task** was unclear. This is the
> *complete* worked path: every command, in order, with **where** to run it and **why**. Do it once
> following this, and you'll have the exact rhythm for every future lesson (the reusable loop is at the
> very end). Nothing here is skipped or hand-waved.
>
> **The single most important idea first:** there are **two places** you work, and mixing them up is
> what makes Lesson 06 confusing.
>
> | Marker | Where | What you do there | Why |
> |---|---|---|---|
> | **[HOST]** | your real machine, in `/home/sys-ctl/NaviOps` | **write + test the script** `scripts/backup.sh` | it's a real NaviOps artifact you commit to git |
> | **[LAB]** | inside `docker exec -it naviops-web bash` | **practice cron / systemd timers / logrotate** | installing/breaking schedulers is safe in a disposable container — never touch your real machine's cron |
>
> Every command below is tagged **[HOST]** or **[LAB]**. That tag *is* the lesson.

---

## Lesson 06 has exactly 3 deliverables

By the end you will have produced:

1. **`scripts/backup.sh`** — a script that tar-backs-up `docs/`, verifies the archive, and keeps only
   the N newest. *(Built on HOST.)*
2. **A schedule** that runs a job automatically — you'll do **both** ways to learn the difference:
   a **cron** entry *and* a **systemd timer**. *(Practised in LAB.)*
3. **A logrotate config** so the job's log file can't grow forever. *(Practised in LAB.)*

That's it. Steps 1–5 of the lesson's "What to build" all serve these three.

---

## Part A — Build `scripts/backup.sh` on the HOST

### A1. Make the folders the script needs — **[HOST]**
```bash
cd /home/sys-ctl/NaviOps
mkdir -p logs          # where the job's log will go (Lesson 06 references logs/*.log)
mkdir -p ~/backups     # where the .tar.gz archives will land
```

### A2. Create the script — **[HOST]**
Open `scripts/backup.sh` in your editor and **type this out** (typing, not pasting — you retain it that
way). Every block is commented with *why* it's there, mapped to the lesson's spec (README lines 202–218):

```bash
#!/usr/bin/env bash
# scripts/backup.sh — back up NaviOps docs/, verify the archive, keep only the newest N.
set -euo pipefail            # -e: stop on error · -u: error on unset var · -o pipefail: a pipe fails if any stage fails
IFS=$'\n\t'                  # safer word-splitting (spaces in names won't break loops)

# --- Variables (the lesson's "Variables" bullet) ---
BACKUP_SRC="/home/sys-ctl/NaviOps/docs"     # WHAT we back up
BACKUP_DEST="${HOME}/backups"               # WHERE archives go
KEEP=7                                       # retention: how many archives to keep
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"           # unique, sortable stamp
ARCHIVE="${BACKUP_DEST}/naviops-docs_${TIMESTAMP}.tar.gz"

# --- A tiny logger (same pattern as Lesson 03/04) ---
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"; }

# --- Create the archive (the "Create" bullet) ---
mkdir -p "$BACKUP_DEST"
# -C makes tar store RELATIVE paths (docs/... not /home/.../docs/...) — restores anywhere.
tar -czf "$ARCHIVE" -C "$(dirname "$BACKUP_SRC")" "$(basename "$BACKUP_SRC")"
log "Created $ARCHIVE"

# --- Verify BEFORE we prune (the key design decision in the lesson) ---
# List the archive contents to /dev/null: if it's corrupt, tar exits non-zero and set -e stops us
# here — so we never delete old good backups to make room for a broken new one.
tar -tzf "$ARCHIVE" > /dev/null
log "Verified $ARCHIVE OK"

# --- Report (the "Report" bullet) ---
log "Size: $(du -h "$ARCHIVE" | cut -f1)"

# --- Retention: keep only the newest $KEEP (the "Retention" bullet) ---
# ls -1t = newest first; tail -n +N+1 = everything AFTER the first N; xargs -r rm = delete them.
# -r (no-run-if-empty) matters: when there's nothing to prune, xargs won't run `rm` with no args.
ls -1t "${BACKUP_DEST}"/naviops-docs_*.tar.gz 2>/dev/null \
  | tail -n +$((KEEP + 1)) \
  | xargs -r rm -- \
  && log "Retention applied (kept newest $KEEP)"
```

> 💡 Stuck or want to compare after trying? The gitignored answer key is
> `docs/learning/reference-solutions/scripts/backup.sh`. Look **after** you've written your own.

### A3. Make it executable and test it by hand — **[HOST]**
```bash
chmod +x scripts/backup.sh
./scripts/backup.sh              # run it manually FIRST — never schedule an untested script
ls -lh ~/backups/               # you should see one naviops-docs_<stamp>.tar.gz
```
✅ **Expected:** log lines "Created / Verified / Size", and one archive in `~/backups/`.

### A4. Prove the retention logic — **[HOST]**
This is Step 5's retention test (README lines 255–258):
```bash
for i in $(seq 1 9); do touch -d "$i days ago" ~/backups/naviops-docs_test$i.tar.gz; done
./scripts/backup.sh
ls ~/backups/ | wc -l            # should be <= 8 (7 kept + the 1 new real archive)
```
✅ **Expected:** the count drops to ≤ 8 — older dummies were pruned, the newest kept. Clean up the
test files when done: `rm -f ~/backups/naviops-docs_test*`.

**Part A done.** You have deliverable #1, tested on the host.

---

## Part B — Practise scheduling INSIDE the lab (`naviops-web`)

Why the container now? Because the next steps install cron jobs, systemd timers, and logrotate configs
— you do **not** want those on your real laptop. The lab exists exactly for this (see Part 0 of this
manual). If you wreck it: `./infra/bootstrap.sh destroy && up` and you're fresh.

### B1. Start the lab and get a demo script + log inside it — **[HOST → LAB]**
```bash
# [HOST]
./infra/bootstrap.sh up                         # (first time ever: ./infra/bootstrap.sh pull)
docker cp scripts/user_audit.sh naviops-web:/root/user_audit.sh   # copy a script in to schedule
docker exec -it naviops-web bash                # now you're INSIDE the container — prompt changes
```
Everything from here until `exit` is **[LAB]** (inside `naviops-web`).

### B2. Prepare inside the container — **[LAB]**
```bash
mkdir -p /root/logs
chmod +x /root/user_audit.sh
/root/user_audit.sh /etc >/root/logs/audit.log 2>&1   # test it runs here; redirect output to a log
tail /root/logs/audit.log
```

### B3. Schedule it — **Option A: cron** — **[LAB]**
```bash
# Make sure cron is installed/running in the container:
command -v crontab || (apt-get update && apt-get install -y cron)
service cron start 2>/dev/null || systemctl start cron 2>/dev/null || true

# Add a job. NOTE the two lessons baked in here:
#   (1) ABSOLUTE path /root/user_audit.sh — cron has a minimal $PATH (README "Common mistakes")
#   (2) >> ... 2>&1 — capture output, or errors vanish into cron's mail (README line 109)
( crontab -l 2>/dev/null; echo "*/2 * * * * /root/user_audit.sh /etc >> /root/logs/audit.log 2>&1" ) | crontab -
crontab -l                                     # verify the line is there
```
✅ **Verify:** wait ~2 minutes, then `tail /root/logs/audit.log` — new entries appear on their own.
That's cron working. (`*/2 * * * *` = every 2 minutes, just so you see it quickly; real jobs use
`0 2 * * *` = 2am daily.)

### B4. Schedule it — **Option B: systemd timer** (the modern way, pairs with Lesson 05) — **[LAB]**
Two files: a **.service** (*what* to run) + a **.timer** (*when*). This is README lines 178–195.
```bash
cat > /etc/systemd/system/naviops-audit.service <<'EOF'
[Unit]
Description=NaviOps audit (oneshot)
[Service]
Type=oneshot
ExecStart=/root/user_audit.sh /etc
EOF

cat > /etc/systemd/system/naviops-audit.timer <<'EOF'
[Unit]
Description=Run NaviOps audit periodically
[Timer]
OnCalendar=*:0/2          # every 2 minutes (for the demo). "daily" for real.
Persistent=true           # if the machine was off at the scheduled time, catch up on next boot
[Install]
WantedBy=timers.target
EOF

systemctl daemon-reload
systemctl enable --now naviops-audit.timer
systemctl list-timers | grep naviops           # see the next scheduled run
```
✅ **Verify (the payoff of timers over cron):**
```bash
journalctl -u naviops-audit.service --no-pager | tail
```
Every run's output + exit code is in the journal **automatically** — no `>> logfile 2>&1` needed. That
is the concrete upgrade the lesson keeps pointing at.

### B5. logrotate — stop the log growing forever — **[LAB]**
This is deliverable #3 (README lines 220–230).
```bash
command -v logrotate || (apt-get update && apt-get install -y logrotate)

cat > /etc/logrotate.d/naviops <<'EOF'
/root/logs/*.log {
    daily
    rotate 7
    compress
    missingok
    notifempty
}
EOF

# ALWAYS dry-run first (README line 238) — shows what WOULD happen, changes nothing:
logrotate -d /etc/logrotate.d/naviops
# Then force one real rotation to see it work:
logrotate -f /etc/logrotate.d/naviops
ls -l /root/logs/                # you'll now see audit.log + audit.log.1 (or .gz)
```
✅ **Verify:** a rotated file (`audit.log.1` / `.gz`) appears — logrotate is managing the log.

### B6. Leave the container — **[LAB → HOST]**
```bash
exit                             # back to the HOST prompt
```

**Part B done.** You've scheduled a job **two ways** and set up rotation — deliverables #2 and #3.

---

## Part C — Finish the lesson properly (the part people skip)

### C1. Commit the real artifact — **[HOST]**
Only `scripts/backup.sh` is a committed artifact (the cron/timer/logrotate work was practice inside the
disposable lab). Optionally save your timer/logrotate files under `infra/` as reference.
```bash
cd /home/sys-ctl/NaviOps
git switch -c lesson/06-cron-scheduling-logrotate   # a branch per lesson (Lesson 02 habit)
git add scripts/backup.sh
git commit -m "feat(scripts): add backup.sh with verify-then-retain (Lesson 06)"
```
> Commit only — **do not push** unless you decide to (project rule: publishing is user-approved).

### C2. Answer the quiz (Step 6) — **[in the README]**
Open `docs/learning/lessons/06-cron-scheduling-logrotate/README.md`, fill in **Q1–Q6** under each
"Your answer:". Then ask me *"grade my Lesson 06 quiz"* and I'll compare against professional answers.

### C3. Tick the Lesson Status boxes + reflect (Step 7) — **[in the README]**
Fill Step 7 (what you learned / what confused you) and check the boxes at the bottom of the README.

### C4. Run the Update Protocol — **[HOST]**
This keeps a fresh session able to resume with zero re-explanation. Just tell me *"update docs"* and I
refresh `docs/learning/LEARNING_STATE.md` + `docs/CHANGELOG.md`. Then you're clear to start **Lesson 07**.

---

## 🔁 The reusable loop — how to finish EVERY lesson from here

Lesson 06 is the template. For lesson NN, the rhythm is always:

1. **Read** `docs/learning/lessons/NN-*/README.md` Steps 1–3 (Concept → Real-World → Alternatives).
2. **Open the companion** `PRACTICAL.md` in the same folder — it has 3 graded, do-it-yourself tasks
   (guided → ticket → on-call) with ✅ Verify checks. *(This is the "how do I actually practice" answer.)*
3. **Build the artifact** from Step 4: **write scripts on the [HOST]** (`scripts/…`), **practise the
   risky/system stuff in the [LAB]** (`docker exec -it naviops-web bash`).
4. **Verify** with Step 5's commands — don't trust, check.
5. **Commit** the real artifact on a `lesson/NN-*` branch (no push).
6. **Quiz + Reflect** (Steps 6–7), then say *"update docs"* and move to the next lesson.

**The one rule that removes all confusion:** *scripts and configs that belong to NaviOps are written and
committed on the **[HOST]**; anything that schedules, installs, or could break a machine is practised in
the disposable **[LAB]** container.* When in doubt, do it in the lab — `destroy && up` is your undo.

