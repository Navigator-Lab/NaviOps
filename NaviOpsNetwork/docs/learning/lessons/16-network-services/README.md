# Lesson 16 — Network Services

**Status:** ✅ ready for self-study (full depth) · **Date written:** 2026-06-20
**Schema:** 12-section (`docs/learning/CLAUDE_TEACHING_RULES.md`)
**Focus:** reverse proxy, NTP, TFTP/HTTP boot, `curl`/`nc`/`socat`/`openssl s_client`, service reachability + TLS.
**Primary artifact:** `scripts/service_probe.sh`.

> **How to use this lesson:** this is the "application-layer toolkit" lesson — how to *probe and
> verify* services (HTTP, TLS, time, raw TCP/UDP). Read §1–§7, build `service_probe.sh` in §8.

---

## §1 — Concept (Scientific Theory)

### What it is
Beyond addressing and routing, networks run **services** at Layer 7: web/HTTP(S), reverse
proxies, **NTP** (time), TFTP/HTTP **boot/provisioning**, and many TCP/UDP services. This lesson
is the operator's **application-layer toolkit** — the commands that *generate* and *inspect*
service traffic: `curl`/`wget` (HTTP), `nc`/`ncat` (raw TCP/UDP), `socat` (relays/tunnels),
`openssl s_client` (TLS), and the role of a **reverse proxy** and **NTP** in real architectures.

### Why it exists
You can't operate what you can't probe. When "the service is down," you need to reach past
L3/L4 (Lessons 03, 07) into L7: is the HTTP server returning 200 or 502? is the TLS cert valid
and not expired? is time correct (an out-of-sync clock breaks TLS, Kerberos, logs, MFA)? These
tools answer those questions deterministically.

### The key building blocks
- **Reverse proxy** (nginx/HAProxy/Traefik): sits in front of backend servers; terminates TLS,
  routes by hostname/path, load-balances (Lesson 30), and is the single published entry point.
- **NTP** (chrony/`timedatectl`): keeps clocks synchronized — essential for TLS validity, log
  correlation, certificates, and authentication.
- **Probing tools:** `curl` (full HTTP + timing + TLS), `nc`/`ncat` (test any TCP/UDP port,
  banner-grab, simple servers), `socat` (bidirectional relays, port forwards, serial/socket
  bridges), `openssl s_client`/`x509` (inspect/verify TLS certs + expiry).

### Three-Level Depth (Lens A)
- **Level 1 — Beginner:** these are the tools that "act like a browser/client" from the command
  line so you can test a service without a GUI — fetch a page, check a port, look at a
  certificate, check the time.
- **Level 2 — NetOps/NOC:** you verify a published service end-to-end: `curl -v` shows DNS →
  TCP connect → TLS handshake → HTTP status + timing (you can see *which stage* is slow/failing);
  `openssl s_client -connect host:443` + `x509 -enddate` checks cert expiry (a top outage cause);
  `nc -vz` tests reachability (Lesson 03); `socat` builds a quick relay to test connectivity
  through a path. A reverse proxy returning **502/504** points at a dead/slow backend, not the
  proxy itself.
- **Level 3 — Wire/Kernel (Lens D):** `curl -v`/`openssl s_client` expose the **TLS handshake**
  (ClientHello → ServerHello → cert → key exchange → Finished) — the L6 layer of OSI made
  visible, riding on the L4 TCP handshake (Lesson 03). `socat` creates and bridges sockets with
  the same `socket()`/`connect()`/`accept()` syscalls the kernel uses; it's a Swiss-army knife for
  the socket layer.

### Two Teaching Approaches (Lens B) — verifying a service end-to-end

**Approach 1 (technical):** `curl -v https://host` performs, in order: DNS resolution (L7/Lesson
13), TCP connect (L4 handshake), TLS handshake (L6 — cert exchange + validation), then the HTTP
request/response (L7). Each stage is reported, so a failure or slowness is attributable to a
specific layer. A reverse proxy inserts itself at L7, terminating TLS and forwarding to a backend
— so a 502 is the *proxy* telling you the *backend* failed.

**Approach 2 (analogy):** `curl -v` is a **diagnostic stethoscope** that listens at each stage of
a phone call to a business:
- *Did directory assistance find the number?* (DNS)
- *Did the line connect?* (TCP)
- *Did they verify each other's identity before talking?* (TLS handshake — and is the ID badge
  expired? = cert expiry)
- *Did the receptionist actually answer your question?* (HTTP status)
- A **reverse proxy** is the **receptionist** who answers one public number, checks your ID
  (TLS), and routes you to the right department (backend) — if the department is out, the
  receptionist says "502, they're unavailable," not "wrong number."
- **Where it breaks down:** the stethoscope analogy implies passive listening; these tools
  *actively initiate* the exchange — they're a synthetic client, which is exactly why they're
  perfect for monitoring (Lesson 21).

### Visual (ASCII) — what `curl -v https://host` reveals

```
  curl -v https://app.example.com
   ├─ DNS:  app.example.com → 203.0.113.20         (L7 — Lesson 13)
   ├─ TCP:  connect 203.0.113.20:443 ... connected  (L4 — Lesson 03)
   ├─ TLS:  ClientHello→ServerHello→cert (valid? expiry?) →Finished  (L6)
   └─ HTTP: GET / → 200 OK  (or 502/504 = backend issue via reverse proxy)
            ▲ time_namelookup / time_connect / time_appconnect / time_total
              tell you WHICH stage is slow
```

---

## §2 — Linux Networking Commands

```bash
curl -v https://app.example.com               # full L7+TLS verbose trace
curl -sS -o /dev/null -w 'dns:%{time_namelookup} conn:%{time_connect} tls:%{time_appconnect} total:%{time_total} code:%{http_code}\n' https://app.example.com
curl -I https://app.example.com               # headers only (HTTP status quickly)
wget -qO- http://host/path                     # fetch content (scripting)
nc -vz host 443                                # TCP reachability (Lesson 03)
nc -lvk 8080                                    # quick listening server (test connectivity)
nc -u host 514                                  # UDP test (e.g. syslog)
socat -v TCP-LISTEN:9000,fork TCP:backend:80   # relay/port-forward for testing
openssl s_client -connect host:443 -servername host </dev/null 2>/dev/null | openssl x509 -noout -dates -subject   # cert validity + expiry
timedatectl status                              # is NTP synchronized? clock correct?
chronyc sources                                 # NTP sources + offset (chrony)
```

**Cisco/CCNA mapping:** `ntp server <ip>`, `show ntp status`, `show clock`; services like TFTP
(`tftp` for IOS image transfer) and HTTP boot are referenced in CCNA IP-Services. The probing
mindset transfers; Linux gives you far richer tooling.

---

## §3 — Real-World Use Cases

**Production scenarios:**
1. **Verify a deploy:** `curl -I` the new endpoint for `200`; `curl -w` timing to confirm it's
   fast; `openssl ... x509 -dates` to confirm the cert is valid.
2. **Cert-expiry outage (very common):** a service breaks at midnight because its TLS cert
   expired — `openssl s_client`/`x509 -enddate` confirms it instantly. Monitor expiry (Lesson 21).
3. **502/504 from the proxy:** the reverse proxy is up but the backend is dead/slow — probe the
   backend directly with `curl`/`nc` to isolate proxy vs backend.
4. **Time drift breaks auth/TLS/logs:** `timedatectl`/`chronyc` to confirm NTP sync.
5. **Build a quick test path:** `socat`/`nc` to relay or stand up a throwaway listener to prove
   connectivity through a firewall/NAT change (Lessons 14/15).

**How NOC engineers use it:** `curl -v` + `openssl s_client` are the L7 rung of bottom-up
troubleshooting — after L3/L4 check out, they tell you if the *application/TLS/time* is the
problem and which sub-stage.

**When NOT to:** don't leave `nc`/`socat` listeners or relays running in production (security
risk); they're diagnostic tools.

**Exam framing (Net+/CCNA):** NTP's purpose, ports for common services, TLS/HTTPS basics, and
reverse-proxy concepts appear on exams.

---

## §4 — Troubleshooting Section

| Symptom | Likely cause | Diagnose | Fix |
|---|---|---|---|
| HTTPS fails / cert warning | expired/invalid/misordered cert | `openssl s_client ... x509 -dates` | renew/fix the cert chain |
| Proxy returns 502/504 | backend down/slow | `curl` the backend directly; proxy logs | fix/restart the backend |
| Service slow, network looks fine | slow TLS or app | `curl -w` stage timings | target the slow stage |
| Auth/TLS intermittently fails | clock skew | `timedatectl`; `chronyc sources` | fix NTP sync |
| Port reachable but no response | wrong service / app hung | `nc` banner; app logs | restart/reconfigure service |

**Redaction check:** RFC 5737 host/IP placeholders in committed examples.

---

## §5 — Common Mistakes

| Mistake | Impact | Fix |
|---|---|---|
| Testing services with `ping` only | misses L7/TLS/app failures | `curl -v` / `openssl s_client` |
| Ignoring cert expiry monitoring | midnight outages | monitor `x509 -enddate` (L21) |
| Blaming the proxy for a 502 | wrong fix | 502 = backend; probe backend directly |
| Ignoring clock sync | TLS/auth/log breakage | keep NTP synced |
| Leaving `nc`/`socat` relays running | open backdoor | tear down diagnostic listeners |

---

## §6 — NOC Perspective

> NOC Technician focus (Stage 1, `ROADMAP.md`).

L7 probing is how the NOC confirms a service is *actually* serving, not just reachable. Synthetic
checks (Lesson 21) are `curl`/`nc` under the hood. **Cert expiry** deserves its own dashboard —
it's a predictable, preventable outage (a watch item in the handover when a cert is days from
expiry, `noc/shift-handover.md`). A 502/504 alert from a proxy routes the ticket to the **backend
app team**, not the network team — knowing that split saves wrong escalations.

---

## §7 — Incident-Response Perspective

- **Detect:** service-level synthetic check (curl/TLS) fails or slows.
- **Triage:** which stage (DNS/TCP/TLS/HTTP) via `curl -v`/`-w` → routes to the right owner.
- **Diagnose (RCA):** cert expired (renew), backend down (502 → app team), clock skew (NTP), DNS
  (Lesson 13).
- **Fix → Recover → Document:** fix the stage, re-probe to confirm `200`/valid cert, document.
  Cert-expiry incidents make excellent preventable-outage runbooks (add expiry monitoring as the
  prevention item).

---

## §8 — Practical Lab (build this yourself)

**Goal:** build `scripts/service_probe.sh` — a reachability + HTTP + TLS-expiry prober — and use
it to verify a small reverse-proxy setup.

### Lens C — Manual → Automated → Why
- **Manual:** `curl -v`, `openssl s_client ... x509 -dates`, `nc -vz` against a target.
- **Automated:** `service_probe.sh host port` → checks TCP reachability, HTTP status + timing, and
  (for TLS) cert expiry days remaining; exits non-zero on failure/expiry-soon.
- **Why:** this *is* a synthetic monitor (Lesson 21); turning manual probes into one script means
  consistent verification post-deploy and proactive cert-expiry alerts — both standard production
  practice.

### Steps
1. Stand up a tiny backend (`python3 -m http.server 8000`) and an nginx reverse proxy in front
   (or `socat`/`nc` as a stand-in) — document in `infra/configs/`.
2. Probe end-to-end with `curl -v` and `curl -w` (read the stage timings); break the backend and
   watch the proxy return 502.
3. Build `scripts/service_probe.sh`:

```bash
#!/usr/bin/env bash
# service_probe.sh — reachability + HTTP + TLS-expiry probe. Lesson 16.
# Usage: service_probe.sh <host> [port]
set -euo pipefail
host="${1:?usage: service_probe.sh <host> [port]}"; port="${2:-443}"
nc -vz -w3 "$host" "$port" 2>&1 | grep -qi succ && echo "TCP $host:$port OK" || { echo "TCP $host:$port FAIL"; exit 2; }
if [[ "$port" == "443" ]]; then
  end=$(openssl s_client -connect "$host:$port" -servername "$host" </dev/null 2>/dev/null | openssl x509 -noout -enddate | cut -d= -f2)
  echo "TLS cert expires: $end"
  exp=$(date -d "$end" +%s); now=$(date +%s); days=$(( (exp-now)/86400 ))
  echo "days until expiry: $days"; [[ $days -lt 14 ]] && { echo "WARN: cert expiring soon"; exit 3; }
fi
code=$(curl -sS -o /dev/null -w '%{http_code}' "http${port:+s}://$host" || true)
echo "HTTP status: $code"
```

4. `bash -n` → `shellcheck` → run it against your lab proxy. **Drill:** let a (lab) self-signed
   cert near expiry, confirm the script warns.

### Lens D — watch the TLS handshake
`openssl s_client -connect host:443 -msg` (or `curl -v`) shows the ClientHello/ServerHello/cert —
the L6 handshake riding on the L4 connection from Lesson 03.

---

## §9 — GitHub Artifact (evidence 5-tuple)

1. **Script:** `scripts/service_probe.sh` (reachability + HTTP + cert-expiry).
2. **Config:** a reverse-proxy + backend config in `infra/configs/` (nginx/socat).
3. **Drill:** induce a 502 (kill backend) and/or a near-expiry cert; confirm the probe catches it.
4. **NAVI ticket:** `NAVI-16` (Task: "service_probe.sh + reverse-proxy lab").
5. **Incident report:** `docs/runbooks/incident-cert-expiry.md` (or 502) — symptom→probe→fix→verify.

---

## §10 — Portfolio Artifact

- **Resume bullet:** "Built a service prober (`service_probe.sh`) validating TCP reachability,
  HTTP status, and TLS-certificate expiry; stood up an nginx reverse proxy and isolated a 502
  backend failure."
- **Interview talking point:** how `curl -v`/`openssl s_client` isolate DNS/TCP/TLS/HTTP failures,
  and why cert expiry + NTP drift are common, preventable outages.
- **Serves:** NOC + Network Operations (Stages 1–2); feeds monitoring (21) + load balancing (30).

---

## §11 — RHCSA Crossover Notes

RHCSA-relevant: `chrony`/NTP configuration and `timedatectl` are RHCSA objectives; `curl`/`ss`
for verifying services, and basic web-server (httpd) reachability appear in RHEL admin. TLS cert
handling overlaps with securing services. Reverse-proxy specifics are "useful, not required."

---

## §12 — Security Notes (Lens E — Attacker & Defender)

> Frameworks: [MITRE ATT&CK](https://attack.mitre.org/) · [GTFOBins](https://gtfobins.github.io/).

**🔴 Attacker:** `nc`/`socat`/`curl` are dual-use — attackers use them for **reverse shells**
(`nc -e`, `socat` shells), **C2 over HTTP(S)** (`T1071.001`), **exfiltration** (`curl`/`wget`
upload, `T1048`), and downloading tooling (`T1105` Ingress Tool Transfer). All appear on
**GTFOBins**. Expired/misconfigured TLS enables MITM.

**🔵 Defender:** **egress filtering** (Lesson 15) so `curl`/`nc` can't freely reach the Internet;
alert on `nc`/`socat` execution and unusual outbound from servers (Lesson 28); **monitor cert
validity** and enforce TLS; restrict who can run these tools on production hosts. Verify your
egress policy blocks an unexpected outbound connection (lab-only).

---

## Quiz (Interview-Style, Graded)

**Q1.** What does `curl -v https://host` show you at each stage, and how does that help isolate a failure?
> **Your answer:**

**Q2.** A reverse proxy returns **502 Bad Gateway**. What does that tell you, and where do you look next?
> **Your answer:**

**Q3.** How do you check a TLS certificate's expiry from the command line, and why does it matter?
> **Your answer:**

**Q4.** **Scenario:** Users report intermittent login/TLS failures across multiple services. The
network looks healthy. What non-obvious cause should you check, and how?
> **Your answer:**

**Q5.** What is a reverse proxy and name two things it does in a real architecture.
> **Your answer:**

**Q6.** Why are `nc`/`socat`/`curl` flagged by defenders, and what control limits their abuse?
> **Your answer:**

*(After you answer, request the "Professional Answer" comparison under each — graded before Lesson 17.)*

---

## Reflection
*(Fill in after the quiz)* — What did you learn? · What confused you? · What would you do differently?

---

## Search Keywords For Further Understanding

**Core**
- `curl verbose http debugging`
- `openssl s_client check certificate expiry`
- `reverse proxy explained nginx`
- `ntp time synchronization importance`

**Tools**
- `netcat nc examples`
- `socat tutorial relay`
- `curl write-out timing variables`

**Going further (future lessons)**
- `synthetic monitoring blackbox exporter` (L21/L22) · `load balancer l7` (L30) · `tls handshake wireshark` (L19)

**Red / Blue (Lens E):**
- 🔴 `netcat reverse shell gtfobins`, `c2 over https T1071`, `curl exfiltration T1048`
- 🔵 `egress filtering`, `detect netcat socat execution`, `certificate expiry monitoring`

---

## Lesson Status
- [ ] §8 lab completed (service_probe.sh + reverse-proxy lab)
- [ ] §4 drill done (502 / cert-expiry)
- [ ] Evidence committed (§9)
- [ ] Quiz answered + professional-answer comparisons (graded)
- [ ] Reflection + Search Keywords reviewed

When complete, run the Update Protocol, then move to **Lesson 17 — Linux Networking Deep-Dive**.

---

*Lesson 16 written by Navi · 2026-06-20 · full-depth. Sources to cite when worked: curl/openssl/socat
docs, chrony docs, CompTIA Network+ N10-009, MITRE ATT&CK T1071/T1048/T1105, GTFOBins.*
