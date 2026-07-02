# Lesson 29 — Kubernetes Fundamentals

**Status:** ready for self-study · **Date written:** 2026-06-28
**Gate Rule:** Concept → Real-World Use → Alternatives → Hands-On → Verification → Quiz → Reflection → Search Keywords
**Builds on:** Lesson 11 (Docker), Lesson 12 (Compose), Lesson 24 (multi-service Compose). **Roadmap slot:** M3 Cloud-capable (~Day 60).

> **How to use this lesson:** same as Lessons 03–28. You already know containers (L11–12)
> and multi-container apps with Compose (L24). Kubernetes is "Compose, but across many
> machines, that heals itself." Goal is **conversational fluency + one deploy you can demo**
> — every junior cloud/DevOps JD asks for "Docker and *basic Kubernetes concepts*"; this
> closes that gap. This is **not** CKA-depth.

---

## Step 1 — Concept

### What it is

**Kubernetes (k8s)** is a container **orchestrator**: it runs and manages containers across
a fleet of machines so that the system keeps matching a desired state *you declare*, without
a human babysitting it. Per the [Kubernetes cluster architecture docs](https://kubernetes.io/docs/concepts/architecture/),
a cluster is a **control plane** plus a set of **worker nodes** that run your containers.

The core nouns:
- **Pod** — the smallest deployable unit: one (usually) container plus its shared network/storage. You rarely create Pods directly.
- **Deployment** — the object you *do* create: "I want N replicas of this image." It manages a **ReplicaSet**, which manages the Pods.
- **Service** — a stable virtual IP + DNS name in front of a set of Pods (Pods are ephemeral and get new IPs; the Service doesn't move).
- **Node** — a worker machine (VM or physical) running the **kubelet** + a container runtime.

### Why it exists

Docker (L11) runs a container on *one* host. Compose (L12/L24) runs several containers on
*one* host. Neither answers: *what happens when the host dies? when traffic triples at 2am?
when you push a new version and want zero downtime?* Kubernetes answers all three —
**self-healing** (restart/replace dead pods), **scaling** (run more replicas), **rolling
updates** (replace pods gradually), and **scheduling** (place pods on healthy nodes with room).

### What problem it solves

- **A container crashes at 3am and nobody's awake** — The controller notices observed ≠ desired and recreates it automatically
- **One host can't handle the load** — The scheduler spreads replicas across many nodes
- **"Deploy the new version without downtime"** — Rolling update: new pods come up, old ones drain, traffic shifts when ready
- **Pods keep changing IPs as they restart** — A Service gives a stable name/IP; clients never chase pod IPs
- **"It works in Compose but we have 40 services on 12 servers"** — Declarative manifests + a scheduler replace hand-placed `docker run`s

### Three-Level Depth (Lens A)

- **Level 1 — Beginner:** `kubectl get pods` lists running pods; `kubectl apply -f app.yaml`
  creates what the YAML describes; `kubectl get deploy` shows your Deployments; `kubectl logs <pod>`
  reads a pod's output. You *describe* what you want in YAML and apply it.
- **Level 2 — Operator:** A **Deployment** owns a **ReplicaSet** owns **Pods**. A **Service**
  (type `ClusterIP` internal / `NodePort` / `LoadBalancer`) gives stable access. Per the
  [2026 production checklist](https://learnkube.com/production-best-practices), every container
  gets **resource requests/limits** (a missing limit lets one runaway pod starve ~30 others on a
  node) and **liveness/readiness probes** — the **readiness** probe gates whether a pod receives
  traffic *right now*, the **liveness** probe decides whether to restart it.
- **Level 3 — Internals (Lens D):** The system is a set of **reconciliation loops**. Per
  [Kubernetes architecture](https://kubernetes.io/docs/concepts/architecture/) and
  [DevOpsCube's 2026 breakdown](https://devopscube.com/kubernetes-architecture-explained/), the
  **control plane** = `kube-apiserver` (the single front door; everything talks to it),
  **etcd** (distributed key-value store holding *all* cluster state), `kube-scheduler` (binds
  unscheduled pods to nodes), and `kube-controller-manager` (the control loops). On each worker:
  **kubelet** reads PodSpecs and uses the **CRI** (Container Runtime Interface, gRPC) to tell
  **containerd** to start containers — the *same* namespaces + cgroups from Lesson 11, just
  driven by kubelet instead of `docker run`. `kube-proxy` programs the node's networking so the
  Service VIP routes to real pod IPs.

### Analogy (Lens B)

- **Desired vs observed state** = a thermostat. You set "I want 21°C" (desired). The furnace
  (controller) keeps firing until the room (observed) matches, and re-fires whenever it drifts.
  You never manually toggle the furnace — you declare the target and the loop maintains it. That
  loop *is* Kubernetes; "3 replicas" is just a temperature for pods.
- **Pod vs Deployment** = a single worker vs a staffing contract. A Pod is one worker who might
  quit; a Deployment is the contract "always keep 3 on shift" — if one quits, HR (the ReplicaSet)
  hires a replacement automatically.
- **Service** = a department phone extension. Individual employees (pods) come and go and have
  different desk numbers (IPs), but "dial x4500 for Support" (the Service) always reaches whoever
  is on shift.

The thermostat analogy breaks down for **rolling updates** — a thermostat has no concept of
"replace the furnace gradually while keeping the room warm," which is exactly what a Deployment's
rollout does (new pods must pass readiness before old ones are removed).

---

## Step 2 — Real-World Use

### How SysAdmins/DevOps use this daily

```bash
kubectl get pods -o wide              # pods + which node/IP each is on
kubectl get deploy,svc,rs             # deployments, services, replicasets at a glance
kubectl describe pod <pod>            # events (why it's Pending/CrashLooping) — read the bottom
kubectl logs -f <pod>                 # follow a pod's logs
kubectl logs <pod> --previous         # logs from the crashed previous container (crash loops!)
kubectl exec -it <pod> -- /bin/sh     # shell into a running pod
kubectl apply -f app.yaml             # create/update from a manifest (declarative)
kubectl rollout status deploy/web     # watch a rolling update finish
kubectl rollout undo deploy/web       # roll back to the previous version
kubectl scale deploy/web --replicas=5 # scale out
```

**Real production scenarios:**
1. **A deploy goes bad** — `kubectl rollout status` hangs because new pods fail readiness;
   `kubectl rollout undo` reverts while you investigate. The bad version never took traffic
   (readiness gated it).
2. **A pod is `Pending`** — `kubectl describe pod` shows `FailedScheduling: insufficient cpu` —
   the node has no room for the pod's resource *requests*. Fix requests or add a node.
3. **A pod is `CrashLoopBackOff`** — `kubectl logs --previous` shows the app erroring on a missing
   env var/secret; Kubernetes keeps restarting it with growing backoff.

### Common mistakes

- **No resource requests/limits** — One runaway pod starves ~30 others on the node; scheduler can't place well
  **Fix:** Set requests + limits on every container ([source](https://learnkube.com/production-best-practices))
- **No readiness probe** — A still-booting or broken pod receives live traffic → user-facing errors
  **Fix:** Add a readiness probe to every network-facing workload
- **Treating Pods as pets (`kubectl run` by hand)** — No self-healing; gone on node failure
  **Fix:** Always use a Deployment (declarative, replicated)
- **`latest` image tag** — Non-reproducible rollouts/rollbacks
  **Fix:** Pin a real version tag
- **Editing live objects with `kubectl edit`** — Drift from your git manifests
  **Fix:** Change the YAML in git, `kubectl apply` (GitOps)
- **Running privileged / as root** — Container escape risk on the *node*
  **Fix:** Pod Security `restricted`, drop caps, non-root (Lens E)

### When NOT to use Kubernetes

- A single small app on one server — Compose (L24), a systemd unit (L05), or a PaaS is simpler
  and you won't drown in YAML.
- No ops capacity — Kubernetes has real operational overhead (upgrades, networking, RBAC). A
  managed PaaS (App Runner, Fly.io, Render) or **managed k8s** (EKS/AKS/GKE) offloads the hard parts.
- Stateful, single-instance workloads with no scaling need — the orchestration earns its keep at
  *scale* and with *failure*, not for one box.

### Interview Angle

**Question:** "You `kubectl apply` a Deployment for 3 replicas. Walk me through what actually
happens. Then: a pod is stuck `Pending` — what's your first command and what are you looking for?"

A junior answer says "it creates 3 pods." A senior answer narrates the **reconciliation loop**:
`kubectl` POSTs the Deployment to the **api-server**, which persists it to **etcd**; the
**deployment controller** creates a ReplicaSet, which creates 3 Pod objects in `Pending`; the
**scheduler** binds each to a node with enough room; each node's **kubelet** pulls the image and
(via the CRI/containerd) starts the container; readiness passes; the Service's endpoints update.
For `Pending`, they go straight to `kubectl describe pod` and read the **Events** at the bottom —
distinguishing `FailedScheduling` (no node has the requested resources / a taint blocks it) from
`ImagePullBackOff` (bad image/registry creds). Senior candidates name *which component* is
responsible at each step rather than treating k8s as one black box.

---

## Step 3 — Alternatives

- **Kubernetes (this lesson)** — Industry standard for orchestration at scale; what most cloud/DevOps JDs name
- **Docker Compose (L24)** — Single-host multi-container — dev environments and small deployments; no self-healing across nodes
- **Docker Swarm** — Simpler built-in orchestrator; far smaller ecosystem, largely superseded by k8s
- **HashiCorp Nomad** — Lighter scheduler; orchestrates containers *and* non-container workloads; smaller footprint
- **AWS ECS / Fargate** — AWS-native orchestration; less portable but much less to operate (ties to L16/L30)
- **Managed k8s — EKS / AKS / GKE** — Real Kubernetes with the control plane operated *for* you — the common production choice

**For NaviOps:** learn the concepts on a **local single-node cluster** (`kind`/`minikube`), then
know that in a job you'll almost always use **managed** k8s (EKS on AWS — ties to your L15–18 AWS
block). containerd/CRI-O from L11's "Alternatives" is what runs under k8s — you've already met the
runtime layer.

---

## Step 4 — Hands-On Task (build this yourself)

**Goal:** Stand up a local single-node cluster, deploy a 2-replica app behind a Service, prove
self-healing and a rolling update.

### Lens C — Manual → Automated → Why

**Manual (imperative — don't do this in prod):**
```bash
kubectl run web --image=nginx:1.27 --port=80   # one pod, no self-healing, no replicas
```
**Declarative (what you commit to git):**
```yaml
# app.yaml — a Deployment (3 replicas) + a Service in front of it
apiVersion: apps/v1
kind: Deployment
metadata: { name: web }
spec:
  replicas: 2
  selector: { matchLabels: { app: web } }
  template:
    metadata: { labels: { app: web } }
    spec:
      securityContext: { runAsNonRoot: true, runAsUser: 101 }   # nginx unprivileged user
      containers:
        - name: web
          image: nginxinc/nginx-unprivileged:1.27   # non-root image (Lens E)
          ports: [{ containerPort: 8080 }]
          resources:                                  # never omit these
            requests: { cpu: "50m",  memory: "64Mi" }
            limits:   { cpu: "200m", memory: "128Mi" }
          readinessProbe:                             # gate traffic until ready
            httpGet: { path: /, port: 8080 }
            initialDelaySeconds: 2
            periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata: { name: web }
spec:
  selector: { app: web }
  ports: [{ port: 80, targetPort: 8080 }]
  # type: ClusterIP (default) — reach it via port-forward in Step 5
```
**Why declarative wins:** the YAML *is* the source of truth — it's reviewable in a PR, diffable,
rollback-able, and reproducible on any cluster. Imperative `kubectl run` leaves no record and no
replicas; the moment the pod dies or the node reboots, it's gone with no self-healing.

### What to build, step by step

1. Install a local cluster: `kind create cluster` (needs Docker from L11) **or** `minikube start`.
2. `kubectl get nodes` — confirm one `Ready` node.
3. Save the manifest above as `app.yaml`; `kubectl apply -f app.yaml`.
4. `kubectl get pods -o wide` — watch 2 pods reach `Running` + `READY 1/1`.
5. **Prove self-healing:** `kubectl delete pod <one-pod>` then immediately `kubectl get pods` —
   a replacement is already being created (desired=2 ≠ observed=1 → reconcile).
6. **Prove a rolling update:** `kubectl set image deploy/web web=nginxinc/nginx-unprivileged:1.28`
   then `kubectl rollout status deploy/web` — new pods come up and pass readiness before old ones go.
7. **Roll back:** `kubectl rollout undo deploy/web`.
8. Commit `app.yaml` on `lesson/29-kubernetes-fundamentals`.

---

## Step 5 — Verification

```bash
kubectl get deploy web -o wide                 # READY should read 2/2
kubectl get pods -l app=web -o wide            # 2 pods Running, on a node
kubectl get svc web                            # Service has a ClusterIP

# Reach the app (ClusterIP isn't externally routable — port-forward to test locally):
kubectl port-forward svc/web 8080:80 &
curl -s http://localhost:8080 | head -n1       # expect the nginx welcome line
kill %1

kubectl rollout status deploy/web              # 'successfully rolled out'
kubectl delete pod -l app=web --field-selector=status.phase=Running --wait=false
kubectl get pods -l app=web                    # replacements already appearing → self-healing proven
```

### Troubleshooting

- **Pod `Pending`** — Scheduler can't place it — node lacks the requested cpu/memory, or a taint blocks it
  **Fix:** `kubectl describe pod <p>` → read **Events**; lower requests or add a node
- **`ImagePullBackOff`** — Wrong image name/tag, or private registry needs creds
  **Fix:** Fix the image ref; add an `imagePullSecret`
- **`CrashLoopBackOff`** — App exits on start (missing env/secret, bad config)
  **Fix:** `kubectl logs <pod> --previous` — read the actual error
- **Pod `Running` but `READY 0/1`** — Readiness probe failing
  **Fix:** `kubectl describe pod` → probe events; check path/port
- **`curl` to Service fails** — Service `selector` doesn't match pod `labels`, or wrong `targetPort`
  **Fix:** `kubectl get endpoints web` — empty = selector mismatch
- **`kubectl` `connection refused`** — No cluster / wrong context
  **Fix:** `kubectl config current-context`; `kind get clusters`

### Redaction check ✅

No real registry credentials, `imagePullSecret` values, kubeconfig tokens, or cluster API
endpoints in committed YAML. `kubeconfig` (`~/.kube/config`) holds cluster admin credentials —
**never commit it**; ensure it's gitignored.

---

## Step 6 — Quiz (Interview-Style, Graded)

**Q1.** Explain the relationship between a **Pod**, a **ReplicaSet**, and a **Deployment**. Which
one do you create, and why not just create Pods?

> **Your answer:**

**Q2.** Name the four **control-plane** components and say in one line what each does. Where is
cluster state actually stored?

> **Your answer:**

**Q3.** Walk through the **reconciliation loop** that runs after you `kubectl apply` a Deployment
for 3 replicas — from api-server to a running container.

> **Your answer:**

**Q4.** What is the difference between a **liveness** probe and a **readiness** probe? Which one,
if missing, causes a broken pod to receive live traffic?

> **Your answer:**

**Q5.** A pod is stuck in `Pending`. What single command do you run first, what part of its output
matters, and what does `FailedScheduling: insufficient cpu` tell you about resource **requests**?

> **Your answer:**

**Q6.** Why is a **Service** necessary even though every Pod already has an IP? What breaks if a
Service's `selector` doesn't match its Pods' `labels`?

> **Your answer:**

---

## Step 7 — Reflection

*(Fill in after the quiz)*

- What did you learn?
- What confused you (the control plane? probes? Services?)?
- How does the "desired vs observed state" loop change how you think about ops vs the imperative `docker run` model?

---

## Lens E — Attacker & Defender (Red / Blue)

> Red/Blue framing (Gate Rule **Lens E**, D14). Build *both* mindsets.
> Frameworks: [MITRE ATT&CK Containers matrix](https://attack.mitre.org/matrices/enterprise/containers/) · [Kubernetes security best practices 2026](https://core.cz/en/know-how/security-kubernetes-best-practices-2026/).

**🔴 Attacker (how it's abused — Step 2):** A `privileged` pod, a `hostPath` mount of the node
filesystem, or a mounted container runtime socket = **root on the node** (ATT&CK **T1611** Escape
to Host). Stolen/over-broad **ServiceAccount tokens** let an attacker call the api-server and pivot
across the cluster; an exposed/unauthenticated **kubelet** API (10250) allows remote `exec` into
pods.

**🔵 Defender (detect & harden — Step 5):** Enforce **Pod Security Admission** at `restricted`
(no privileged, non-root, drop capabilities); apply **RBAC least privilege** (devs read-only in
their namespace, CI deploys to specific namespaces only, `cluster-admin` reserved for platform
ops — [source](https://learnkube.com/production-best-practices)); use **NetworkPolicies** to limit
pod-to-pod traffic; scan images (Trivy/Grype) in CI before they ever run; never mount the runtime
socket or grant `hostPath` to untrusted workloads.

## Step 8 — Search Keywords For Further Understanding

**Core**
- `kubernetes pod vs deployment vs replicaset`
- `kubernetes control plane components explained`
- `kubernetes reconciliation loop desired state`
- `kubernetes service clusterip nodeport loadbalancer`

**Tools**
- `kind vs minikube local cluster`
- `kubectl describe pod events troubleshooting`
- `kubernetes liveness vs readiness probe`

**Going further (beyond this lesson)**
- `kubernetes ingress controller`
- `helm charts intro`
- `amazon eks getting started` (ties to L15–18)
- `kubernetes RBAC least privilege`

---

**Red / Blue (Lens E — study attacker & defender in parallel):**
- 🔴 **Red (attacker):** `kubernetes privileged pod escape`, `MITRE ATT&CK T1611 escape to host`, `kubelet api unauthenticated exec`, `serviceaccount token theft RBAC escalation`
- 🔵 **Blue (defender):** `pod security admission restricted`, `kubernetes rbac least privilege`, `kubernetes networkpolicy default deny`, `trivy image scanning ci`

## Lesson Status

- [ ] Hands-on task completed (Step 4)
- [ ] Verification passed (Step 5)
- [ ] Quiz answered + professional-answer comparisons requested (Step 6)
- [ ] Reflection completed (Step 7)
- [ ] Search Keywords reviewed (Step 8)

When complete, run the Update Protocol, then continue to **Lesson 30 — AWS Serverless: Lambda +
API Gateway** (or per `JOB_MILESTONES.md`).

---

*Lesson 29 written by Navi v28 · 2026-06-28 · WebSearch sources:
[Kubernetes Cluster Architecture (kubernetes.io)](https://kubernetes.io/docs/concepts/architecture/),
[DevOpsCube — Kubernetes Architecture Explained (2026)](https://devopscube.com/kubernetes-architecture-explained/),
[LearnK8s — Production Best-Practices Checklist](https://learnkube.com/production-best-practices),
[Kubernetes Security Best Practices 2026 (core.cz)](https://core.cz/en/know-how/security-kubernetes-best-practices-2026/),
[MITRE ATT&CK — Containers Matrix](https://attack.mitre.org/matrices/enterprise/containers/)*
