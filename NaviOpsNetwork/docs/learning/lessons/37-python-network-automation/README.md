# Lesson 37 — Python for Network Automation

**Status:** ✅ ready for self-study (full depth) · **Date written:** 2026-06-28
**Schema:** 12-section (`docs/learning/CLAUDE_TEACHING_RULES.md`)
**Focus:** automating device + cloud tasks with Python — **paramiko/netmiko** for SSH, **NAPALM**
for vendor-agnostic config + diff/rollback, **Nornir** for inventory + parallel execution, plus
the **boto3** bridge to cloud networking. The job signal: Python automation is now a *baseline*
network-engineer expectation, not a differentiator.
**Primary artifact:** `scripts/config_audit.py` — connect to N devices (or mock/lab), pull running
config + state, parse it, and **flag drift** vs a known-good baseline; committed with sample output.

> **How to use this lesson:** read §1–§7, build the automation in §8. Builds directly on **L17
> (Linux networking)** and **L18 (network troubleshooting)** — automation is those manual checks,
> scripted across a fleet. Feeds **Stage 6 (Cloud/DevOps Networking)**.

---

## §1 — Concept (Scientific Theory)

### What it is
**Network automation** replaces hand-typed CLI sessions with **Python scripts** that connect to
devices, push or read configuration, and validate state — reliably, repeatably, at fleet scale.
Per [The Network DNA's 2026 guide](https://www.thenetworkdna.com/2026/05/network-automation-with-python-complete.html)
and [APNIC's tool comparison](https://blog.apnic.net/2023/02/13/automation-tools-paramiko-netmiko-napalm-ansible-nornir-or/),
Python dominates because of its library ecosystem and readability for engineers without a dev
background.

### Why it exists
Configuring 3 switches by hand is fine. Configuring 300 — consistently, with an audit trail, and
proving none have **drifted** from standard — is impossible manually and error-prone. Automation
makes a change **once**, applies it **everywhere**, and can **detect** when a device no longer
matches its intended config (drift), which is where outages and security gaps hide.

### The tool stack (and how it layers)
Per [APNIC](https://blog.apnic.net/2023/02/13/automation-tools-paramiko-netmiko-napalm-ansible-nornir-or/)
and [TechTarget](https://www.techtarget.com/searchnetworking/tip/Network-automation-with-Python-Paramiko-Netmiko-and-NAPALM):

| Tool | Layer | Use it when |
|---|---|---|
| **paramiko** | raw SSH protocol | talking to a **Linux host / appliance** with no network API |
| **netmiko** | SSH for network gear (80+ vendors) | sends CLI commands, handles prompts/paging — the workhorse |
| **NAPALM** | vendor-agnostic API on top | config **merge/replace + diff + commit + rollback**, structured `getters` |
| **Nornir** | pure-Python framework | **inventory + parallel** execution (multithreaded — 100 devices at once) |

### Lens A — Three-Level Depth (Beginner → NetOps → Wire)
- **L1 Beginner:** a script SSHes to one device, runs `show run`, prints it.
- **L2 NetOps:** an **inventory-driven** Nornir run pulls config from 100 devices in parallel,
  compares each to a baseline, and reports drift — idempotently.
- **L3 Wire/Internals (Lens D):** netmiko sits on **paramiko**, which implements SSH at the
  protocol level (socket, key exchange, auth, channel multiplexing) — per
  [TechTarget](https://www.techtarget.com/searchnetworking/tip/Network-automation-with-Python-Paramiko-Netmiko-and-NAPALM).
  Screen-**scraping** `show` text is brittle (a firmware update changes the output and breaks your
  parser); prefer **structured data** (NAPALM getters / NETCONF/RESTCONF) where the device offers
  it — per [ipSpace](https://blog.ipspace.net/kb/CiscoAutomation/050-scraping/).

### Lens B — Technical + Analogy + Visual
- **Analogy:** netmiko is a **fast typist** who knows every vendor's prompts; NAPALM is an
  **editor** who shows you a redline (diff) before publishing and can un-publish (rollback);
  Nornir is the **shift manager** handing the same task sheet to 100 typists at once.
- **ASCII:**
```
 inventory.yaml ──> Nornir ──┬─> netmiko ──> SSH ──> [ switch-01 ]  ──> parsed result ─┐
 (hosts+groups+creds)        ├─> netmiko ──> SSH ──> [ switch-02 ]  ──> parsed result ─┤─> drift report
                             └─> NAPALM getters ──> [ router-01 ] ──> structured state ─┘
```

---

## §2 — Linux Networking Commands / Tooling

```bash
python3 -m venv .venv && source .venv/bin/activate     # isolate deps (RHCSA crossover, §11)
pip install netmiko napalm nornir nornir-netmiko nornir-utils boto3
python -c "import netmiko, napalm, nornir; print('ok')" # sanity

# Run from a Linux jump host (L17): these are the manual primitives automation replaces
ssh admin@switch-01 'show running-config'              # what netmiko does, by hand
ping -c1 switch-01 ; nc -zv switch-01 22               # reachability before you script

# Keep secrets OUT of code:
export NET_USER=automation ; read -rs NET_PASS         # env, or pull from Vault (§12)
```

Minimal **netmiko** connection:
```python
from netmiko import ConnectHandler
dev = {"device_type": "cisco_ios", "host": "switch-01",
       "username": os.environ["NET_USER"], "password": os.environ["NET_PASS"]}
with ConnectHandler(**dev) as conn:
    print(conn.send_command("show running-config"))
```

---

## §3 — Real-World Use Cases
1. **Config compliance / drift audit** — nightly Nornir run diffs every device's running config
   against a golden baseline; flags any that drifted (the artifact you build in §8).
2. **Bulk change** — push the same NTP/SNMP/ACL change to 100 devices with NAPALM **merge** —
   diff first, commit, rollback on failure.
3. **State collection during incidents** — pull `show` state from all devices in seconds for an
   IR timeline (§7).
4. **Cloud bridge** — the same Python skill, with **boto3**, audits AWS VPC route tables / security
   groups (Stage 6, ties to L32–33 cloud networking).
   [Selector's 2026 examples](https://www.selector.ai/learning-center/21-network-automation-examples-in-2026/) list these as standard.

---

## §4 — Troubleshooting Section

| Symptom | Likely cause | Fix |
|---|---|---|
| `NetmikoTimeoutException` | wrong host/unreachable/SSH closed | `ping` + `nc -zv host 22` first; check `device_type` |
| `NetmikoAuthenticationException` | bad creds / wrong enable secret | verify env/Vault values; check `secret` for enable mode |
| `paramiko ... Host key ...` | unknown/changed host key | manage `known_hosts` deliberately — don't blindly disable checking (§12) |
| Parser returns garbage | screen-scraping brittle output | use NAPALM **getters** / structured data instead of regex on `show` |
| One device fails, whole run aborts | no per-host error handling | wrap per-host work; Nornir isolates failures per host |
| Works for 1, hangs for 100 | sequential netmiko loop | use **Nornir** (parallel) instead of a `for` loop |

**Redaction check:** sample outputs in the repo must have real public/mgmt IPs, hostnames, SNMP
communities, and creds removed.

---

## §5 — Common Mistakes
- **Credentials hardcoded** in the `.py` or inventory — the #1 sin. Use env vars or a vault (§12).
- **No error handling** on a fleet loop — one unreachable device kills the run.
- **No dry-run** before a bulk change — always diff (NAPALM `compare_config`) before `commit`.
- **Screen-scraping** when structured data exists — brittle to firmware changes
  ([ipSpace](https://blog.ipspace.net/kb/CiscoAutomation/050-scraping/)).
- **Non-idempotent** scripts — running twice should yield the same end state, not double-apply
  ([AIMultiple](https://aimultiple.com/workload-automation-security)).
- **No version control** — automation that isn't in Git can't be reviewed or rolled back.

---

## §6 — NOC Perspective
Automation is the NOC's force-multiplier: one analyst audits the whole fleet in the time it took to
check one device. But the floor lives and dies by **guardrails** — a bad bulk push is an outage at
scale. Before automation touches prod: a **change window**, an **approval**, a **dry-run diff**, a
**blast-radius limit** (run on 1 device, then a canary group, then all), and a **rollback plan**
(NAPALM rollback). Read-only audits (drift detection) are safe to run anytime; *changes* go through
change management.

---

## §7 — Incident-Response Perspective
During an incident, automation collects **evidence fast**: "show me interface errors / ARP / routes
across all 80 devices" in seconds instead of an hour of manual SSH — a clean, timestamped snapshot
for the IR timeline. Pre-built **rollback scripts** revert a bad change quickly. Caveat: an
incident is a *bad* time to run an untested change script — collection (read-only) yes, risky
remediation only with care.

---

## §8 — Practical Lab (build this yourself)

**Goal:** build `config_audit.py` — pull running config from your lab devices, compare to a
baseline, and flag drift. Use **mock/EVE-NG/Cisco DevNet sandbox** if you have no hardware.

### Lens C — Manual → Automated → Why
- **Manual:** SSH to each device, `show run`, eyeball it against the standard. Slow, no record.
- **Automated:** an inventory-driven script does it for all devices and prints a pass/drift report.
- **Why:** repeatable, auditable, scales to 100s, and *detects* drift a human would miss.

### Steps
1. `python3 -m venv .venv && source .venv/bin/activate ; pip install netmiko nornir nornir-netmiko`.
2. Create `inventory/hosts.yaml` (host, `device_type`, `groups`) — **no passwords in it** (creds
   from env/Vault).
3. Save a **golden** snippet per group (e.g. required NTP/SNMP/login-banner lines) as `baseline/`.
4. Script: for each host (Nornir, parallel) → `send_command("show running-config")` → check the
   baseline lines are present → collect missing/extra → write `reports/drift_<date>.md`.
5. Run it; intentionally change one device off-baseline; re-run; confirm it's flagged.
6. **Optional Lens D capture:** `tcpdump -ni any 'tcp port 22'` while it runs — see the SSH sessions.

```python
# config_audit.py — skeleton (env creds, per-host isolation, drift = missing baseline lines)
import os, datetime
from nornir import InitNornir
from nornir_netmiko.tasks import netmiko_send_command

BASELINE = open("baseline/ios.txt").read().splitlines()

def audit(task):
    out = task.run(task=netmiko_send_command, command_string="show running-config").result
    missing = [line for line in BASELINE if line and line not in out]
    return missing  # empty == compliant

nr = InitNornir(config_file="config.yaml")   # inventory + creds plugin (env/vault)
results = nr.run(task=audit)
with open(f"reports/drift_{datetime.date.today()}.md", "w") as f:
    for host, r in results.items():
        status = "✅ compliant" if not r.result else f"⚠️ DRIFT: missing {r.result}"
        f.write(f"- {host}: {status}\n")
```

---

## §9 — GitHub Artifact (the evidence 5-tuple / Artifact Contract)
1. **Script** — `scripts/config_audit.py` (env/Vault creds, per-host error handling).
2. **Config** — `inventory/hosts.yaml` + `baseline/` (redacted — no real IPs/communities/creds).
3. **Sample output** — a `reports/drift_<date>.md` showing one compliant + one drifted device.
4. **NET-NN ticket** — the worked ticket ("Audit fleet for NTP-config drift") with resolution note.
5. **Incident/drill note** — the §8 drill (introduced drift → detected → remediated) write-up.

---

## §10 — Portfolio Artifact
- **Résumé bullet:** "Built a Python (Nornir/netmiko) config-drift auditor that checks N network
  devices against a golden baseline in parallel and reports non-compliance."
- **LinkedIn line:** "Automated network config-compliance auditing in Python — fleet drift
  detection with structured reporting."
- **Interview talking point:** walk the tool layering (paramiko→netmiko→NAPALM→Nornir), why
  structured data beats screen-scraping, and your guardrails before a bulk change.

---

## §11 — RHCSA Crossover Notes
- **venv** + `pip` dependency isolation (Python packaging on RHEL).
- **SSH keys** + `known_hosts` management (the same trust model as L17 / RHCSA SSH).
- **cron / systemd timer** to schedule the nightly audit (RHCSA timers) — automation that runs
  itself.
- **File permissions** on the inventory/creds/report files (`chmod 600` for anything sensitive).

---

## §12 — Security Notes (Lens E — Attacker & Defender)
> Frameworks: [MITRE ATT&CK](https://attack.mitre.org/) · [OWASP Secrets Management](https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html).

- 🔴 **Attacker:** **stolen automation credentials** = keys to the whole fleet (ATT&CK **T1119**
  Automated Collection, **T1552** Unsecured Credentials); an **over-privileged service account**;
  **pip typosquat / supply-chain** packages; blindly disabling SSH host-key checking enables MITM.
- 🔵 **Defender:** secrets in a **vault** (HashiCorp Vault / AWS Secrets Manager), never in code —
  retrieve **just-in-time**, short TTL, **audit every access**
  ([Nautomation Prime](https://www.nautomationprime.io/blog/2026/02/26/credential-management-in-network-automation/),
  [JumpServer 2026](https://www.jumpserver.com/blog/secret-management-best-practices-2026)); a
  **least-privilege, read-only-by-default** automation account; **pin/verify** pip deps; manage
  `known_hosts` deliberately; **audit-log** every automation action.

---

## Quiz (Interview-Style, Graded)

**Q1.** Layer these correctly and say what each adds: paramiko, netmiko, NAPALM, Nornir. Which do
you use against a plain Linux host vs a Cisco switch?

> **Your answer:**

**Q2.** Why is **screen-scraping** `show` output considered fragile, and what's the more robust
alternative when the device supports it?

> **Your answer:**

**Q3.** What does **idempotent** mean for a network change script, and why does it matter?

> **Your answer:**

**Q4.** How do you keep credentials out of your automation, and what does a vault give you over env
vars?

> **Your answer:**

**Q5.** Before pushing a config change to 100 devices, what guardrails do you apply (name at least
three)?

> **Your answer:**

**Q6.** Your sequential netmiko loop takes 40 minutes for 120 devices. What changes, and roughly
why is it faster?

> **Your answer:**

---

## Reflection
- What did automating reveal about your manual L17/L18 workflow?
- Where did screen-scraping feel brittle?
- What's the next script you'd write (bulk change? cloud audit with boto3?)?

## Search Keywords For Further Understanding
- `netmiko tutorial cisco`
- `nornir automation framework inventory parallel`
- `napalm getters config diff rollback`
- `network config drift detection python`
- `boto3 describe security groups route tables`
- `paramiko known_hosts host key policy`
- 🔴 `T1552 unsecured credentials automation`  🔵 `hashicorp vault approle network automation`

---

## Lesson Status
- [ ] §8 lab completed (`config_audit.py` + baseline + drift report)
- [ ] §4 drill done (introduced drift → detected)
- [ ] Evidence committed (§9)
- [ ] Quiz answered + professional-answer comparisons (graded)
- [ ] Reflection + Search Keywords reviewed

When complete, run the Update Protocol, then continue per `ROADMAP` (feeds Stage 6 — Cloud/DevOps
Networking; pairs with NaviOps L29–L31 cloud lessons).

---

*Lesson 37 written by Navi v28 · 2026-06-28 · WebSearch sources:
[Network Automation with Python — complete guide 2026 (The Network DNA)](https://www.thenetworkdna.com/2026/05/network-automation-with-python-complete.html),
[Paramiko/Netmiko/NAPALM/Ansible/Nornir compared (APNIC)](https://blog.apnic.net/2023/02/13/automation-tools-paramiko-netmiko-napalm-ansible-nornir-or/),
[Paramiko vs Netmiko vs NAPALM (TechTarget)](https://www.techtarget.com/searchnetworking/tip/Network-automation-with-Python-Paramiko-Netmiko-and-NAPALM),
[Screen & Web Scraping is fragile (ipSpace)](https://blog.ipspace.net/kb/CiscoAutomation/050-scraping/),
[Credential Management in Network Automation (Nautomation Prime)](https://www.nautomationprime.io/blog/2026/02/26/credential-management-in-network-automation/),
[Secret Management Best Practices 2026 (JumpServer)](https://www.jumpserver.com/blog/secret-management-best-practices-2026)*
