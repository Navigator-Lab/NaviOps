# Lesson 26 — Capstone: Chaos Engineering & Incident Response Project

**Status:** ready for self-study · **Date written:** 2026-06-11
**Gate Rule:** Concept → Real-World Use → Alternatives → Hands-On → Verification → Quiz → Reflection → Search Keywords

> **How to use this lesson:** **the capstone** — this is the lesson where
> **everything from Lessons 01-25 operates together**. You'll run Lesson 25's
> Terraform-provisioned, Lesson 24's multi-service stack, watched by Lesson
> 22's Prometheus/Grafana and Lesson 23's Wazuh — then **deliberately break
> it** (chaos engineering) and respond using Lesson 19's runbook process.
> This is your strongest portfolio artifact.

---

## Step 1 — Concept

### What it is

**Chaos engineering** is the practice of deliberately injecting failures into
a system (kill a process, fill a disk, cut network access) **under
controlled conditions** to verify that monitoring detects it, alerting
notifies you, and your runbook/recovery process actually works — **before**
a real failure happens at 2am.

### Why it exists

Lesson 19 gave you a runbook and had you simulate one incident on a single
service. But a runbook **you've never actually tested under realistic
conditions** is a hypothesis, not a proven process. Per [Google Cloud's
chaos engineering
guide](https://cloud.google.com/blog/products/devops-sre/getting-started-with-chaos-engineering)
and [Quinnox's SRE chaos engineering
overview](https://www.quinnox.com/blogs/chaos-engineering-for-devops-sre/),
organizations that run chaos drills report **30-50% faster MTTR** (Mean Time
To Recovery) — because the team has *already seen* the failure mode, the
alerts that fire, and the exact recovery steps, in a low-stakes setting.

### What problem it solves

| Problem | Solution |
|---|---|
| "Our monitoring/alerting has never actually been tested against a real failure" | Chaos experiment: inject a known failure, confirm detection works |
| "Our runbook says to do X, but has anyone actually tried it?" | Follow the runbook live during the experiment — find gaps |
| "How do I prove to an interviewer I can handle production incidents?" | A documented chaos experiment + postmortem is concrete evidence of SRE skills |
| "Multiple lessons' tools (Prometheus, Wazuh, Traefik, CloudWatch) — do they actually work together during a real failure?" | This capstone is the integration test for your entire learning project |

### Three-Level Depth (Lens A)

- **Level 1 — Beginner:** Pick **one failure mode** (e.g., "kill the `app1`
  container"), have a **hypothesis** ("Traefik will route all traffic to
  `app2` within the health-check interval, Prometheus/Grafana will show
  `app1`'s metrics drop to zero"), **inject the failure**, **observe** what
  actually happens, and **compare to your hypothesis**.
- **Level 2 — SysAdmin:** Per [Harness's chaos engineering
  glossary](https://www.harness.io/harness-devops-academy/what-is-chaos-engineering)
  and [SRE School's chaos engineering
  tutorial](https://sreschool.com/blog/chaos-engineering-a-comprehensive-tutorial-for-site-reliability-engineering/):
  real chaos engineering follows a structured loop: **(1) define steady
  state** (what does "healthy" look like — e.g., Grafana dashboard baseline,
  `curl` response time), **(2) hypothesize** what should happen during the
  failure, **(3) inject the failure** (start small/contained), **(4)
  observe/measure** against the hypothesis, **(5) document findings**, **(6)
  fix gaps and re-test**. Tools like Gremlin/Chaos Toolkit/AWS Fault Injection
  Simulator automate this at scale — for this capstone, manual injection
  (`docker kill`, `tc` for network latency, `fallocate` for disk fill) is
  sufficient and more educational.
- **Level 3 — Systems/Kernel (Lens D):** Each chosen failure mode maps to a
  specific systems-level mechanism you've studied: **`docker kill -s SIGKILL
  app1`** sends SIGKILL directly (Lesson 04's signal handling — uncatchable,
  immediate termination, unlike SIGTERM); **`tc qdisc add dev eth0 root netem
  delay 500ms`** uses the kernel's traffic-control subsystem to inject
  artificial network latency (testing Lesson 21's load-balancer/health-check
  timeout behavior under degraded-but-not-down conditions — often a *worse*
  failure mode than total outage, because health checks may still pass while
  users experience timeouts); **`fallocate -l 10G /fillfile`** rapidly
  consumes disk space (testing Lesson 06/07's disk-full failure signature and
  Lesson 22's `HighDiskUsage` alert in one shot, at the kernel's block-
  allocation level).

### Analogy (Lens B)

- **Chaos engineering** = a fire drill — you don't wait for an actual fire to
  discover that the fire alarm doesn't reach the basement, or that the
  emergency exit door is blocked. You **deliberately trigger the alarm** on a
  Tuesday afternoon and watch what actually happens.
- **Steady state** = knowing what "normal" looks like on the building's
  dashboards (temperature, occupancy) **before** the drill, so you can tell
  the drill caused a deviation and not something else.
- **Network latency injection (`tc netem`)** = simulating "the fire alarm
  still rings, but takes 30 seconds to reach the basement" — a **degraded**
  signal, often more dangerous than "alarm doesn't ring at all" because
  people might not react with appropriate urgency.
- **Postmortem after the drill** = the fire marshal's report: "the alarm
  reached the basement in 45 seconds (target: 10s) — action item: replace
  the basement's relay unit."

The "fire drill" analogy holds well but breaks down for **measuring MTTR
quantitatively** — a fire drill rarely produces a precise "time to full
evacuation: 4 minutes 12 seconds" metric that's then tracked release-over-
release the way SRE teams track MTTR trends.

---

## Step 2 — Real-World Use

### How SysAdmins use this daily

```bash
# Failure injection examples (run against your Lesson 24/25 stack)
docker kill -s SIGKILL app1                       # hard-kill a container
tc qdisc add dev eth0 root netem delay 500ms      # inject network latency (revert: tc qdisc del dev eth0 root)
fallocate -l 10G /tmp/fillfile                     # fill disk (cleanup: rm /tmp/fillfile)
docker network disconnect naviops_backend db       # simulate db connectivity loss

# Observation
curl -w "%{time_total}\n" -o /dev/null -s http://<HOST>/    # response time
docker compose ps                                            # health status
# Grafana dashboard, Prometheus alerts tab, Wazuh dashboard - all observed live
```

**Real production scenarios:**
1. **"Game days"** — scheduled team exercises where one engineer secretly
   injects a failure and the on-call engineer responds in real time, scored
   against the runbook.
2. **Disaster-recovery validation** — per [Google Cloud's DR + chaos
   engineering post](https://cloud.google.com/blog/products/devops-sre/using-chaos-engineering-to-test-dr-plans),
   chaos experiments validate that DR plans (Lesson 17's backup/restore)
   actually work, not just that they're documented.
3. **Pre-launch readiness** — before a new service goes live, run chaos
   experiments against it to find monitoring gaps while the blast radius of
   a real incident would still be zero (no real users yet).

### Common mistakes

| Mistake | Impact | Fix |
|---|---|---|
| Injecting failures with no hypothesis/steady-state baseline first | Can't tell if the failure caused the observed behavior or it was already like that | Always establish "what does normal look like" before injecting |
| Running an experiment with unbounded blast radius (e.g., on shared production with no rollback plan) | Turns a controlled experiment into a real incident | Start in your isolated lab (this capstone); production chaos engineering requires careful scoping, off-peak timing, and abort criteria |
| Not actually following the runbook during the experiment (just "knowing" what to do) | The whole point — testing the *runbook* — is lost | Literally open `service-down.md` and follow it step by step, noting any place it's unclear/wrong |
| Treating the capstone as "make everything green again" rather than "learn what broke and why" | Missed the actual goal — a capstone with no findings/gaps documented looks incomplete to an interviewer | The most valuable output is the **postmortem with gaps found and fixed**, not a clean run |
| Skipping documentation because "I'll remember" | Six months later, this is your strongest portfolio piece — undocumented, it's wasted | Write it up as if a stranger (interviewer, future employer) will read it |

### When NOT to over-engineer

- One well-executed chaos experiment with a thorough postmortem is more
  valuable than five shallow ones — per [Quinnox's SRE
  guide](https://www.quinnox.com/blogs/chaos-engineering-for-devops-sre/),
  depth of analysis matters more than breadth of scenarios for a learning
  capstone.

---

## Step 3 — Alternatives

| Topic | Alternative | Note |
|---|---|---|
| Manual injection (`docker kill`, `tc`, `fallocate` — this lesson) | Gremlin, Chaos Toolkit, AWS Fault Injection Simulator | Manual injection teaches the underlying mechanisms directly; dedicated chaos tools add scheduling, automated rollback, and safety guardrails for production use |
| Single-engineer exercise (this lesson) | "Game day" with a team (one injects, one responds blind) | Team game days better simulate real on-call pressure/unknowns; solo is the right starting point for building the skill |
| Manual observation (watching dashboards) | Automated chaos-to-CI integration (Lesson 14) | Per [Quinnox], mature orgs run chaos experiments in CI continuously; manual observation is the right learning step first |

---

## Step 4 — Hands-On Task (build this yourself)

**Goal:** Run a structured chaos experiment against your Lesson 24/25 stack
(deployed on the Lesson 25 EC2 instance, or locally if AWS resources are
already torn down), follow Lesson 19's runbook live, and produce a
portfolio-quality writeup.

### Lens C — Manual → Automated → Why

**Manual (Lesson 19, single-incident):** you simulated one chmod/disk-full
incident on one service, wrote one postmortem.

**This capstone — structured experiment, full stack:**

```markdown
# Chaos Experiment: app1 hard-kill

## Steady state (baseline, BEFORE injection)
- Grafana: app1 + app2 both responding, ~Xms avg response time
- Prometheus: `up{job="app"}` = 1 for both instances
- curl http://<HOST>/ : alternates app1/app2 (Lesson 24)

## Hypothesis
- Traefik's health check (interval: 10s) will detect app1 down within ~10-30s
- All traffic routes to app2; users see no errors (just slightly higher app2 load)
- Prometheus `up{instance="app1"}` -> 0; Grafana shows app1 metrics flatline
- (If Wazuh deployed) no security alert (this is an operational failure, not a security event - confirms Wazuh correctly does NOT alert on this)

## Injection
docker kill -s SIGKILL app1

## Observation (timestamps!)
- T+0s: injected
- T+?s: Traefik marks app1 unhealthy (check logs)
- T+?s: curl http://<HOST>/ - 100% from app2
- T+?s: Grafana dashboard reflects app1 down
- Any errors/timeouts experienced by `curl` during the transition?

## Findings vs hypothesis
- What matched? What didn't?
- Was detection time acceptable? (define your own SLO, e.g., "<30s")

## Runbook follow-through
- Did docs/runbooks/service-down.md's steps apply here?
- What's missing/wrong in the runbook for THIS failure mode?

## Recovery
docker compose up -d app1   # restart the killed container
- Confirm app1 rejoins rotation (Traefik health check passes again)

## Action items
- (e.g.) "Add a Grafana panel specifically for per-replica health status"
- (e.g.) "Runbook should mention: check `docker compose ps` exit codes first"
```

**Why this matters:** per [Google Cloud's chaos engineering
guide](https://cloud.google.com/blog/products/devops-sre/getting-started-with-chaos-engineering),
this hypothesis→inject→observe→compare→document loop **is** the practice —
and doing it against **your own multi-lesson stack**, with **your own
runbook**, produces findings that are uniquely yours (not generic) — exactly
what makes a capstone project credible in an interview.

### What to build, step by step

1. Ensure your Lesson 24 stack is running (locally, or on the Lesson 25 EC2
   instance — your choice; note which in your writeup).
2. Establish and record the **steady state**: Grafana screenshot/description,
   `curl` timing, `docker compose ps` output, Prometheus `up` values.
3. Choose **at least 2** failure modes from different categories, e.g.:
   - **Process failure**: `docker kill -s SIGKILL app1`
   - **Resource exhaustion**: `fallocate -l <size> /tmp/fillfile` until disk
     alert threshold (Lesson 22's `HighDiskUsage`) fires
   - (Optional, if comfortable) **Network degradation**: `tc qdisc add dev
     eth0 root netem delay 500ms loss 10%`
4. For each: write the hypothesis **before** injecting, inject, observe with
   timestamps, compare to hypothesis, follow `docs/runbooks/service-down.md`
   live, recover, note findings.
5. Update `docs/runbooks/service-down.md` with at least one finding per
   experiment (this is the "runbooks evolve from incidents" loop from Lesson
   19, now exercised twice more).
6. Write the full capstone report:
   `docs/runbooks/postmortems/2026-06-11-capstone-chaos-experiment.md` —
   include both experiments, findings, action items, and a final
   "what I'd do differently in production" reflection.
7. Clean up: remove `/tmp/fillfile`, revert `tc` rules, ensure stack is
   healthy.
8. If using the Lesson 25 EC2 instance, decide whether to `terraform destroy`
   now or keep it briefly for Lesson 27 review — document your choice.
9. Commit everything on `lesson/26-capstone-incident-response-project`.

---

## Step 5 — Verification

```bash
# Steady state confirmed before AND after experiments
docker compose ps
curl -w "%{time_total}\n" -o /dev/null -s http://<HOST>/

# After fallocate experiment - confirm cleanup
df -h /tmp
ls /tmp/fillfile 2>/dev/null && echo "CLEANUP NEEDED" || echo "clean"

# After tc experiment - confirm reverted
tc qdisc show dev eth0   # should show default, not netem

# Confirm runbook was actually updated
git diff docs/runbooks/service-down.md
```

### Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| `docker kill` doesn't trigger Traefik failover | Health check interval longer than your observation window, or health check endpoint doesn't reflect container death quickly | Wait the full health-check interval x retries; this itself is a finding (document the actual detection time) |
| `fallocate` fails: "fallocate failed: Operation not supported" | Filesystem doesn't support `fallocate` (some filesystems/overlay configs) | Use `dd if=/dev/zero of=/tmp/fillfile bs=1M count=10000` instead |
| `tc netem` commands fail: "RTNETLINK answers: Operation not permitted" | Need root/`sudo`, or `tc` not installed | `sudo tc ...`; install `iproute2` package if missing |
| Prometheus alert doesn't fire during disk-fill experiment | `for` duration (Lesson 22) longer than your fill+observe window, or threshold not reached | Either wait longer, or temporarily lower the threshold for the experiment (revert after) |
| Can't tell if Traefik or Docker's embedded DNS handled the failover | Both might be involved — investigate logs from both | `docker compose logs traefik` AND check DNS resolution behavior; document which mechanism you conclude was responsible |

### Redaction check ✅

Same as Lessons 19/24/25 — redact hostnames/IPs in the postmortem and
runbook updates.

---

## Step 6 — Quiz (Interview-Style, Graded)

**Q1.** What is "steady state" in chaos engineering, and why must you
establish it **before** injecting a failure?

> **Your answer:**

**Q2.** **Scenario:** You inject `docker kill -s SIGKILL app1` and Traefik
takes 45 seconds to stop routing to it — longer than your 30s SLO
hypothesis. Is this a "failed experiment"? What do you do next?

> **Your answer:**

**Q3.** Why might network latency injection (`tc netem delay`) be a "worse"
failure mode in some ways than total process death (`docker kill`)? Tie this
to health-check design (Lesson 21).

> **Your answer:**

**Q4.** How does this capstone connect Lesson 19's runbook process to Lesson
22's monitoring and Lesson 24's architecture? Give a concrete example of one
finding that could only emerge from running all three together.

> **Your answer:**

**Q5.** Per the research, organizations practicing chaos engineering report
30-50% faster MTTR. Explain *why*, mechanistically — what specifically about
having run this experiment before would make a real incident faster to
resolve?

> **Your answer:**

**Q6.** If you were presenting this capstone in a job interview, what would
you highlight as the most important finding, and why? (There's no "correct"
answer here — this tests your ability to communicate technical work.)

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
- `chaos engineering hypothesis steady state injection observation`
- `mttr mean time to recovery sre metrics`
- `tc netem network latency simulation linux`
- `game day sre incident response exercise`

**Tools**
- `docker kill signals container failure simulation`
- `fallocate dd disk fill testing`
- `gremlin chaos toolkit aws fault injection simulator`

**Going further (future lessons)**
- `rhcsa exam objectives review`
- `sre interview questions incident response`
- `portfolio projects devops sre github`

---

## Lesson Status

- [ ] Hands-on task completed (Step 4)
- [ ] Verification passed (Step 5)
- [ ] Quiz answered + professional-answer comparisons requested (Step 6)
- [ ] Reflection completed (Step 7)
- [ ] Search Keywords reviewed (Step 8)

When complete, run the Update Protocol, then move to **Lesson 27 — RHCSA Exam
Prep & Review**.

---

*Lesson 26 written by Navi v28 · 2026-06-11 · WebSearch sources:
[Google Cloud Getting Started with Chaos Engineering](https://cloud.google.com/blog/products/devops-sre/getting-started-with-chaos-engineering),
[Google Cloud Using Chaos Engineering to Test DR Plans](https://cloud.google.com/blog/products/devops-sre/using-chaos-engineering-to-test-dr-plans),
[Quinnox Why Chaos Engineering Is Essential for SRE & DevOps](https://www.quinnox.com/blogs/chaos-engineering-for-devops-sre/),
[Harness What is Chaos Engineering?](https://www.harness.io/harness-devops-academy/what-is-chaos-engineering),
[SRE School Chaos Engineering: A Comprehensive Tutorial](https://sreschool.com/blog/chaos-engineering-a-comprehensive-tutorial-for-site-reliability-engineering/)*
