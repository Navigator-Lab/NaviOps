# Lesson 25 — Syslog & Centralized Logging

**Status:** ✅ ready for self-study (full depth) · **Date written:** 2026-06-20
**Schema:** 12-section (`docs/learning/CLAUDE_TEACHING_RULES.md`)
**Focus:** rsyslog/syslog-ng, facilities/severities, central log server, correlation, journalctl.
**Primary artifact:** `infra/configs/rsyslog-central.conf`.

> **How to use this lesson:** logs are the other half of monitoring (metrics = numbers, logs =
> events). Centralized logging is the bridge to SIEM (Lesson 28). Read §1–§7, build a central
> rsyslog server in §8. Lab only; redact real hosts/IPs.

---

## §1 — Concept (Scientific Theory)

### What it is
**Syslog** is the long-standing standard for **event logging** on network devices and Unix/Linux
systems (RFC 5424/3164). Devices and hosts emit log **messages** tagged with a **facility** (what
subsystem) and a **severity** (how bad), which are written locally and/or forwarded over the
network (UDP/TCP **514**) to a **central log server**. Centralizing logs lets you **correlate**
events across many devices in one place — essential for troubleshooting and security (SIEM,
Lesson 28). On modern Linux, **systemd-journald** is the local log store and **rsyslog**/
**syslog-ng** handle forwarding/central collection. `journalctl` reads the journal.

### Why it exists
Logs scattered across hundreds of devices are useless during an incident — you can't see the
pattern, and a compromised device's local logs can be wiped by the attacker. Centralizing gives
you: one place to search, **correlation** across devices (the router logged a flap *and* the app
logged errors at the same second), retention, and **tamper-resistance** (logs are off the box).

### Facilities and severities (must-know)
- **Severities** (0 = worst): `0 emerg, 1 alert, 2 crit, 3 err, 4 warning, 5 notice, 6 info, 7
  debug`. You filter/alert by severity.
- **Facilities:** `kern, mail, auth/authpriv, cron, daemon, local0–local7` (network devices often
  use a configurable `localN`). Facility + severity = which messages to route/store/alert on.

### Three-Level Depth (Lens A)
- **Level 1 — Beginner:** every device keeps a diary of events; centralized logging copies all
  those diaries to one place so you can read them together and search them.
- **Level 2 — NetOps/NOC:** you configure devices to forward syslog to a central server, set up
  **rsyslog** to receive/filter/store by host/facility/severity, and search/correlate during
  incidents (e.g. a link-flap log on the switch + connection errors on the app at the same
  timestamp = one root cause). You know severities to filter noise (alert on `err` and worse).
  Centralized logs feed the **SIEM** (Lesson 28) for security detection. `journalctl -u <svc> -p
  err` is the local equivalent.
- **Level 3 — Wire/Kernel (Lens D):** a syslog message is `<PRI>TIMESTAMP HOST TAG: MSG` where
  **PRI = facility×8 + severity**. UDP/514 is fire-and-forget (can lose messages under load);
  **TCP/514** (or RELP/TLS) is reliable + encryptable. rsyslog has a modular pipeline (inputs →
  rulesets/filters → outputs to files/DB/forward). journald stores structured binary logs and can
  forward to rsyslog.

### Two Teaching Approaches (Lens B) — centralization & correlation

**Approach 1 (technical):** each source emits syslog messages with a PRI (facility+severity); a
central rsyslog server listens on 514, applies rulesets to filter and route (e.g. write
`auth`+`err` to a security file, everything from the core router to `/var/log/devices/core.log`),
and retains them. Correlation = querying the merged, time-ordered stream across sources to find
events that co-occur.

**Approach 2 (analogy):** centralized logging is a **city-wide CCTV control room**.
- Each camera (device) records locally, but the control room (central server) receives **all
  feeds in one place**, time-synchronized (NTP — Lesson 16 — is critical so timestamps line up).
- **Correlation** = watching multiple feeds at the same timestamp to see the *whole* event ("the
  alarm at the bank *and* the car speeding away on the next street, same minute").
- **Severities** = the control room ignores routine footage and zooms in on alarms.
- **Tamper-resistance** = even if a burglar smashes the on-site camera, the control room already
  has the footage off-site.
- **Where it breaks down:** CCTV is continuous video; syslog is discrete event messages — and if
  clocks aren't synced (no NTP), the "same timestamp" correlation falls apart, which is why time
  sync is a hard dependency the analogy makes vivid.

### Visual (ASCII) — devices → central rsyslog → search/SIEM

```
   SOURCES (facility/severity)         CENTRAL rsyslog (UDP/TCP 514)        CONSUMERS
   switch  ─localN.err──────┐
   router  ─localN.notice───┤── receive ─► rulesets/filter ─► /var/log/... ─► search/grep/awk
   linux   ─authpriv.* ─────┤              (by host/facility/severity)        │
   firewall─local0.warn ────┘                                                 └─► SIEM (L28)
   correlate across sources by timestamp (NTP-synced!) → find the root cause / detect attacks
```

---

## §2 — Linux Networking Commands

```bash
# Local journal (systemd-journald)
journalctl -u NetworkManager -p err          # errors from a unit
journalctl -k --since "10 min ago"            # kernel messages (link flaps etc.)
journalctl -f                                  # follow live

# rsyslog central server (receive) — /etc/rsyslog.conf or a drop-in
# module(load="imudp") input(type="imudp" port="514")        # UDP receiver
# module(load="imtcp") input(type="imtcp" port="514")        # TCP receiver (reliable)
systemctl restart rsyslog ; ss -ulnp | grep 514               # confirm it's listening

# Send a test message / forward
logger -p local0.err "test event from $(hostname)"            # generate a syslog message
logger -n 10.0.0.99 -P 514 -d "remote test"                   # send to a remote server (UDP)

# Search / correlate
grep -i "link down" /var/log/devices/*.log
awk '/error/{print $1, $2, $3, $0}' /var/log/syslog | tail
```

**Cisco/CCNA mapping:** `logging host 10.0.0.99`, `logging trap notifications`, `service
timestamps log datetime`, `show logging`. CCNA tests syslog severities, the central-server model,
and time-stamping (NTP). Devices forward; the Linux box collects.

---

## §3 — Real-World Use Cases

**Production scenarios:**
1. **Cross-device correlation:** a flapping uplink (switch syslog) + app connection errors (server
   syslog) at the same second → one root cause, seen only because both are centralized.
2. **Security detection (→ SIEM):** failed SSH logins, firewall denies, and IDS alerts aggregated
   for brute-force/scan detection (Lessons 28/36).
3. **Tamper-resistant audit:** logs forwarded off the device survive even if the device is
   compromised or rebooted.
4. **Retention/compliance:** centralized retention for audits and post-incident review.

**How NOC engineers use it:** during an incident, the central log search is where you confirm *what
the devices reported* and *when* — the timeline backbone of the RCA. Severity filtering keeps the
signal above the noise.

**When NOT to:** don't ship `debug` from everything (volume); don't use plain UDP/514 across
untrusted links (loss + cleartext — use TCP/TLS); don't forget NTP (timestamps must align).

**Exam framing (Net+/CCNA):** syslog severities, the central-server model, UDP/514, and the
importance of synchronized time are guaranteed.

---

## §4 — Troubleshooting Section

| Symptom | Likely cause | Diagnose | Fix |
|---|---|---|---|
| No logs arriving centrally | receiver not listening / firewall / device config | `ss -ulnp \| grep 514`; `tcpdump port 514` | enable input / allow port / fix device |
| Timestamps don't line up | clocks not NTP-synced | compare device times | fix NTP (Lesson 16) |
| Log volume overwhelming | shipping debug/everything | filter by severity | raise threshold to notice/err |
| Lost messages under load | UDP/514 drops | switch to TCP/RELP | reliable transport |
| Can't correlate | no central collection | logs only local | centralize |

**Redaction check:** redact real hostnames/IPs in committed configs/log samples.

---

## §5 — Common Mistakes

| Mistake | Impact | Fix |
|---|---|---|
| Logs only local | no correlation, lost on compromise | centralize |
| No NTP / unsynced clocks | correlation impossible | sync time first (L16) |
| Shipping debug from all sources | volume/cost, hides signal | filter by severity |
| Plain UDP/514 over untrusted links | loss + cleartext | TCP + TLS |
| No retention policy | logs gone when needed | define retention |
| Not feeding the SIEM | miss security detections | forward to SIEM (L28) |

---

## §6 — NOC Perspective

> NOC Technician focus (Stage 1, `ROADMAP.md`).

Centralized logs are the NOC's **timeline source**. When an alert fires (Lessons 22–24), the next
move is "what do the logs say, across the affected devices, at that timestamp?" — the central
search gives the device-reported truth (link down, BGP flap, auth failures) that turns a metric
anomaly into a diagnosed cause. Severity filtering is how you avoid drowning. This is also the
direct on-ramp to the **SOC/Security-Analyst track** (Lesson 28) — same logs, security lens.

---

## §7 — Incident-Response Perspective

- **Detect:** an alert + corroborating log entries (or logs *are* the detection — failed logins).
- **Triage/Diagnose:** centralized search builds the **timeline** (the backbone of the RCA,
  `noc/rca.md`) by correlating across devices at synchronized timestamps.
- **Preserve evidence:** centralized logs are tamper-resistant forensic evidence (critical in
  security IR — a compromised host's local logs can't be trusted).
- **Document:** the log timeline goes straight into the incident report. Used in drills 1–8 (each
  leaves log evidence) and the capstones.

---

## §8 — Practical Lab (build this yourself)

**Goal:** build a central rsyslog server, forward logs to it, correlate, and document
`infra/configs/rsyslog-central.conf`.

### Lens C — Manual → Automated → Why
- **Manual:** `journalctl` per host.
- **Automated:** central rsyslog receiving from multiple sources, filtered by facility/severity
  into per-host/per-type files — one searchable place.
- **Why:** correlation across devices is impossible without centralization; this is the foundation
  the SIEM (Lesson 28) builds on, and the timeline source for every RCA.

### Steps
1. On a "log server" (VM/namespace), configure rsyslog to receive on 514 (UDP and/or TCP) and
   route by source/facility into `/var/log/remote/<host>.log`. Save as
   `infra/configs/rsyslog-central.conf`.
2. From two "client" hosts, forward syslog to the server (`logger -n <server>` or rsyslog
   `*.* @@server:514`). Confirm arrival (`tcpdump port 514`, then the files).
3. **Correlate:** generate related events on both clients within the same second (e.g. a
   simulated "link down" + an app error) and find them together by timestamp with `grep`/`awk`.
4. Filter by severity (ship only `notice`+ to reduce noise). Verify NTP sync so timestamps align.
5. **Drill:** generate failed-login events (`logger authpriv.warn "Failed password..."`) and
   write a grep/awk one-liner that counts failures per source — the seed of brute-force detection
   (Lesson 28).

### Lens D — the PRI value
Compute PRI = facility×8 + severity for one of your `logger` messages and confirm it in a
`tcpdump -A port 514` capture — the `<PRI>` at the start of the wire format.

---

## §9 — GitHub Artifact (evidence 5-tuple)

1. **Script:** a log-correlation/failed-login counter (`grep`/`awk`) — seed for `port_scan_detect.sh`
   / brute-force detection (Lesson 28).
2. **Config:** `infra/configs/rsyslog-central.conf` (central receiver + routing).
3. **Drill:** cross-device correlation + a failed-login count demonstrated.
4. **NAVI ticket:** `NAVI-25` (Change: "deploy central syslog + correlation").
5. **Incident report:** a log-correlated incident runbook (timeline built from central logs).

---

## §10 — Portfolio Artifact

- **Resume bullet:** "Built a centralized rsyslog server with facility/severity routing and
  cross-device correlation; produced incident timelines and seeded failed-login detection — the
  foundation for SIEM."
- **Interview talking point:** why centralization + NTP + severity filtering matter, and how log
  correlation builds an incident timeline (and tamper-resistance for security IR).
- **Serves:** NOC + Network Operations + the SOC track (Stages 1–2, 5); direct on-ramp to Lesson 28.

---

## §11 — RHCSA Crossover Notes

Strong RHCSA overlap: **rsyslog** and **journald**/`journalctl` (including persistent journal,
filtering by unit/priority) are RHCSA logging objectives; configuring log forwarding and reading
`/var/log` are core. This lesson's central-server build directly extends RHCSA logging skills.

---

## §12 — Security Notes (Lens E — Attacker & Defender) — security on-ramp

> Frameworks: [MITRE ATT&CK](https://attack.mitre.org/). (Bridge to SIEM/Lesson 28.)

**🔴 Attacker:** **log tampering / clearing** to hide activity (`T1070` Indicator Removal —
clearing local logs); **disabling logging** (`T1562.002`). This is *why* centralization matters —
logs already shipped off-box can't be erased by the attacker. Attackers also know that *unmonitored*
log sources are blind spots.

**🔵 Defender:** **forward logs off-box immediately** (tamper-resistance), protect the log server,
use **TCP/TLS** transport (integrity + confidentiality), **alert on logging stopping** (a silent
source is suspicious), and feed everything to the **SIEM** for detection (failed logins,
denies, scans — Lesson 28). Verify that clearing a client's local log doesn't remove the central
copy (lab).

---

## Quiz (Interview-Style, Graded)

**Q1.** List the syslog severities from most to least severe (or vice versa) and explain how you'd
use them to reduce noise.
> **Your answer:**

**Q2.** Why centralize logs instead of leaving them on each device? Give two concrete benefits.
> **Your answer:**

**Q3.** Why is NTP/time synchronization critical for centralized logging?
> **Your answer:**

**Q4.** **Scenario:** An app had errors at 02:14. How do centralized logs help you find the network
root cause, and what would you search for?
> **Your answer:**

**Q5.** UDP/514 vs TCP/TLS for syslog transport — trade-offs?
> **Your answer:**

**Q6.** From a security standpoint, why is forwarding logs off-box important, and what attacker
technique does it defend against?
> **Your answer:**

*(After you answer, request the "Professional Answer" comparison under each — graded before Lesson 26.)*

---

## Reflection
*(Fill in after the quiz)* — What did you learn? · What confused you? · What would you do differently?

---

## Search Keywords For Further Understanding

**Core**
- `syslog facilities severities`
- `rsyslog central server configuration`
- `journalctl filtering priority unit`
- `log correlation timeline`
- `syslog rfc 5424 format`

**Tools**
- `rsyslog forwarding tcp tls`
- `logger command examples`
- `cisco logging host trap`

**Going further (future lessons)**
- `siem wazuh elk` (L28) · `failed login detection` · `netflow logging`

**Red / Blue (Lens E):**
- 🔴 `clear logs T1070 indicator removal`, `disable logging T1562.002`, `unmonitored log source`
- 🔵 `forward logs off-box tamper resistant`, `alert on log source silence`, `siem ingestion`

---

## Lesson Status
- [ ] §8 lab completed (central rsyslog + correlation + failed-login count)
- [ ] §4 drill done (cross-device correlation)
- [ ] Evidence committed (§9)
- [ ] Quiz answered + professional-answer comparisons (graded)
- [ ] Reflection + Search Keywords reviewed

When complete, run the Update Protocol, then move to **Lesson 26 — Network Incident Response**.

---

*Lesson 25 written by Navi · 2026-06-20 · full-depth. Sources to cite when worked: RFC 5424/3164,
rsyslog/journald docs, CompTIA Network+ N10-009, MITRE ATT&CK T1070/T1562.002.*
