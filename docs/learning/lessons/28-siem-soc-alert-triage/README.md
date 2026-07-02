# Lesson 28 — SIEM Operations & SOC Alert Triage

**Status:** ready for self-study · **Date written:** 2026-06-15
**Gate Rule:** Concept → Real-World Use → Alternatives → Hands-On → Verification → Quiz → Reflection → Search Keywords

> **How to use this lesson:** same as Lessons 03–27. This lesson is the **Security-Analyst
> stage capstone for detection work** (D14): it takes the SIEM you stood up in Lesson 23
> (Wazuh) and the log-analysis skills from Lesson 19, and teaches the **day-job of a SOC
> Tier-1 analyst** — turning a flood of alerts into triaged, classified, escalated (or
> dismissed) incidents. It is the lesson where every prior lesson's **Lens E (attacker)**
> note becomes something you *detect and respond to*. Maps to **CompTIA Security+** domains
> (Security Operations, Incident Response) and the **MITRE ATT&CK** framework.

---

## Step 1 — Concept

### What it is

A **SOC (Security Operations Center)** is the team/function that monitors a SIEM, triages
the alerts it produces, and escalates real incidents. **Alert triage** is the core Tier-1
skill: for each alert, decide *true positive vs false positive*, *severity*, and *escalate
or close* — fast, consistently, and with evidence. A **SIEM** (Lesson 23) generates the
alerts; **triage** is what a human does with them.

### Why it exists

A SIEM watching a real fleet produces **hundreds–thousands of alerts a day**, the large
majority of which are benign (false positives or expected activity). Without a disciplined
triage process you get **alert fatigue** — the analyst rubber-stamps "close" and misses the
one real intrusion buried in the noise. Triage exists to make detection *actionable*: a
repeatable decision procedure so the real attack (the brute force that succeeded, the port
scan that preceded it) gets caught and escalated while noise gets tuned away.

### What problem it solves

- **Thousands of raw alerts, most benign** — A **triage workflow**: enrich → classify → severity → escalate/close
- **Real attacks hidden in noise (alert fatigue)** — **False-positive tuning** + severity rubric so signal rises
- **Inconsistent analyst decisions** — A documented **triage runbook** (every analyst triages the same alert the same way)
- **"Is this actually an attack?"** — **MITRE ATT&CK** mapping — name the technique, know the next step

### Three-Level Depth (Lens A)

- **Level 1 (Beginner):** an alert is the SIEM saying "this looks suspicious." Triage =
  "is it real, how bad, who needs to know."
- **Level 2 (SOC Analyst):** you enrich the alert (who/what/where, asset criticality,
  recent context), classify it as true/false positive, assign severity from a rubric,
  and either **escalate to Tier-2/IR** or **close with a reason** — then, if it's a false
  positive, propose a **tuning** so it doesn't fire again.
- **Level 3 (Detection engineering):** triage feedback loops into the detection rules.
  A rule's quality is measured by its **true-positive rate** and **alert volume**; you
  tune thresholds, add allow-lists, and map each rule to an ATT&CK technique so coverage
  gaps are visible. This is where "blue team" becomes a measurable engineering discipline.

### Analogy (Lens B)

Triage is the **hospital emergency room**. Patients (alerts) arrive constantly; the triage
nurse (Tier-1 analyst) doesn't treat everyone equally — they take vitals (enrichment),
decide who's critical vs who has a scraped knee (severity), send the critical ones to a
surgeon (escalate to Tier-2/IR), and send the rest home with advice (close). *Where the
analogy breaks down:* in a SOC, a "scraped knee" that recurs 10,000 times means the **alarm
itself is broken** — you fix the detection (tuning), which has no ER equivalent.

---

## Step 2 — Real-World Use

### How SOC analysts use this daily

A Tier-1 analyst lives in the SIEM's alert queue. For a typical "SSH brute force" alert:

```bash
# Enrich: who/where, how many, did any SUCCEED (the critical question)?
grep "Failed password" /var/log/auth.log | awk '{print $(NF-3)}' | sort | uniq -c | sort -rn | head
grep "Accepted password\|Accepted publickey" /var/log/auth.log | grep <suspect_ip>   # did they get in?
# Classify: external IP + hundreds of attempts + no success → true positive, contained (no breach)
#           one internal host + 3 attempts → likely a fat-fingered password → false positive
```

The decision is recorded — **classification, severity, action, reason** — so the next shift
has continuity.

### Common mistakes

- **Closing without checking for success** — a brute force that *succeeded* is a breach,
  not noise. Always check for an `Accepted` after the `Failed` burst.
- **Treating volume as severity** — 10,000 failed logins from a known scanner blocked at
  the firewall is *lower* severity than 5 failed + 1 success on a privileged account.
- **Closing a false positive without tuning** — if you don't tune it, you (or the next
  analyst) triage it again tomorrow. Triage and tuning are one loop.
- **No asset context** — the same alert on a test box vs a domain controller is a
  different severity.

### When NOT to over-engineer

Don't write a bespoke detection rule for a one-off. Don't escalate every alert "to be
safe" — that's alert fatigue pushed onto Tier-2. Tier-1's value is **confident closure**
of the 95% so Tier-2 can focus on the 5%.

### Interview Angle

> *"Walk me through how you'd triage a brute-force alert."* — Strong answer: enrich
> (source IP internal/external, count, **did any attempt succeed**, target account
> privilege, asset criticality), classify TP/FP, assign severity from the rubric, escalate
> to IR **if** there's a success or a privileged target, otherwise close with a reason and
> propose tuning if it's noise. Name the ATT&CK technique (**T1110 Brute Force**). The
> interviewer is listening for *"did it succeed?"* and a repeatable process, not a guess.

---

## Step 3 — Alternatives

| Approach / tool | Pros | Cons |
|---|---|---|
| **Wazuh** (Lesson 23, open-source) | Free, HIDS+FIM+SCA, ATT&CK-tagged rules | You operate it yourself |
| **Splunk** (SPL) | Industry standard, powerful search, huge ecosystem | Expensive; license by data volume |
| **Elastic SIEM (ELK)** | Flexible, open core, good for log volume | Detection rules need building/tuning |
| **Microsoft Sentinel** | Cloud-native, KQL, Azure integration | Azure-centric, cost scales with ingest |
| **Manual `grep`/`awk` on logs** (Lesson 19) | Zero infra, great for learning the signals | Doesn't scale, no correlation/alerting |

Triage *workflow* is tool-agnostic — the same enrich→classify→severity→act loop applies
whether the alert came from Splunk, Sentinel, or Wazuh.

---

## Step 4 — Hands-On Task (build this yourself)

**NaviOps artifacts:** `scripts/alert_triage.sh` + `docs/runbooks/soc-triage-runbook.md`.

### Lens C — Manual → Automated → Why

- **Manual:** for each alert, run the enrichment `grep`/`awk` one-liners by hand, look up
  the source IP, check asset criticality, write the verdict in a ticket.
- **Automated:** `scripts/alert_triage.sh` parses `auth.log` (or a Wazuh alerts file),
  groups failed logins by source IP, flags any IP that also has an `Accepted` (success =
  escalate), classifies by threshold, and prints a triage summary with a suggested
  severity and ATT&CK technique ID.
- **Why:** consistency and speed — every alert triaged the same way, in seconds, with the
  "did it succeed?" check never skipped. This is exactly what SOC automation/SOAR does.

### What to build, step by step (spec — write it in your own voice)

1. `scripts/alert_triage.sh` — accepts a log path (default `/var/log/auth.log`):
   - Count `Failed password` per source IP (`awk` + `sort | uniq -c`).
   - For each offending IP, check whether an `Accepted` line exists → **SUCCESS flag**.
   - Classify: `SUCCESS` → **CRITICAL / escalate (possible breach, T1110)**;
     `>=20 fails, no success` → **MEDIUM / likely brute force, blocked**;
     `<20` → **LOW / probable false positive, close**.
   - Print a table: IP · fails · success? · severity · suggested action · ATT&CK ID.
   - Use `set -euo pipefail`, quote variables, handle a missing/empty log gracefully
     (carry your Lesson 03 Bash hygiene + **Lens E** discipline — don't write a script an
     attacker could inject into).
2. `docs/runbooks/soc-triage-runbook.md` — the human procedure: the severity rubric, the
   "always check for success" rule, escalation criteria (when Tier-1 hands to IR), and the
   false-positive tuning step. This runbook is portfolio gold for a Security-Analyst
   application.

> Keep it small and real — this extends the log-analysis work from Lesson 19, it is not a
> from-scratch SIEM.

---

## Step 5 — Verification

```bash
# Seed a few failed logins safely on your VM (don't lock yourself out — Lesson 07 drill):
#   ssh wronguser@localhost   (a few times, Ctrl-C)
bash scripts/alert_triage.sh /var/log/auth.log
# Expect: a table grouping source IPs by failed-login count, severity, and action.
# Force the SUCCESS path: do one real successful login, confirm the script flags it CRITICAL.
shellcheck scripts/alert_triage.sh        # static analysis — should pass clean
```

### Troubleshooting

- **No output / empty table:** wrong log path (RHEL uses `/var/log/secure`, Debian uses
  `/var/log/auth.log`) — handle both or parameterize.
- **journald-only system:** no flat auth log — read from `journalctl -u sshd` instead.
- **Permission denied:** auth logs need `sudo`/`adm` group — note it in the runbook.

### Redaction check ✅

Use `203.0.113.x` / `10.0.x.x` for any example IPs in the README and runbook. Never paste a
real attacker IP from your own logs without confirming it's not an internal/identifying
address. No real hostnames or usernames in committed output.

---

## Step 6 — Quiz (Interview-Style, Graded)

> Answer inline under each question. Once answered, Navi writes the **Professional Answer**
> comparison beneath each (per the Gate Rule). Do not skip.

1. A brute-force alert shows 4,000 failed SSH logins from one external IP and **zero**
   successes. Another shows 6 failed + 1 accepted on the `root`-capable deploy account.
   Which is higher severity, and why?
   - *Your answer:*

2. You triage the same benign "scheduled backup touched /etc" FIM alert 50 times a day.
   You've confirmed it's a false positive. What do you do beyond closing it?
   - *Your answer:*

3. What single check most distinguishes "brute force attempt" (annoying) from "brute force
   breach" (incident)? Which log lines do you grep for?
   - *Your answer:*

4. Map these to MITRE ATT&CK tactics: (a) many ports probed from one host, (b) repeated
   failed logins, (c) `/etc/passwd` modified, (d) logs cleared.
   - *Your answer:*

5. What is "alert fatigue," and name two things a SOC does to reduce it.
   - *Your answer:*

6. (Scenario) An alert fires: "new SUID binary created in /tmp." Walk through your triage:
   enrichment, classification, severity, escalate-or-close.
   - *Your answer:*

7. Why is "escalate everything to be safe" a *bad* Tier-1 habit?
   - *Your answer:*

---

## Step 7 — Reflection

- What did you learn? *(your notes)*
- What confused you? *(your notes)*
- What would you do differently / automate next? *(your notes)*

---

## Lens E — Attacker & Defender (Red / Blue)

> Red/Blue framing (Gate Rule **Lens E**, D14). Build *both* mindsets: know how the tools
> in this lesson are abused, and how a defender detects and stops them.
> Frameworks: [GTFOBins](https://gtfobins.github.io/) · [MITRE ATT&CK](https://attack.mitre.org/) · [LOLBAS](https://lolbas-project.github.io/).

**🔴 Attacker (how it's abused — Step 2):** Sophisticated attackers specifically target the
SOC's ability to triage: they **generate decoy alerts / noise** so the real intrusion drowns
in false positives (a deliberate alert-fatigue attack), move **low and slow** to stay under
thresholds, and use **living-off-the-land** binaries so their activity looks like normal
admin work. Disabling or blinding the SIEM agent is itself a step. ATT&CK **T1562** (Impair
Defenses), **T1027** (Obfuscation), **T1070** (Indicator Removal).

**🔵 Defender (detect & harden — Step 5):** This lesson *is* the defense — but harden the
defense itself: tune detections so the **true-positive rate stays high** (noise is an
attacker's ally), alert on **detection-pipeline tampering** (agent down, rule disabled, log
gaps), correlate low-and-slow patterns across time, and keep an ATT&CK coverage map so blind
spots are visible. A well-tuned SOC is the counter to the noise-and-evasion playbook.

## Step 8 — Search Keywords For Further Understanding

**Core:** `SOC alert triage process`, `true positive vs false positive security`,
`alert fatigue SOC`, `incident severity classification`, `SOC Tier 1 vs Tier 2`.
**Tools:** `Wazuh alert tuning`, `Splunk SPL basics`, `Elastic SIEM detection rules`,
`MITRE ATT&CK Navigator`, `SOAR automation playbook`.
**Going further:** `detection engineering`, `MITRE ATT&CK technique mapping`,
`threat hunting hypothesis`, `CompTIA Security+ incident response domain`, `purple teaming`.

---

**Red / Blue (Lens E — study attacker & defender in parallel):**
- 🔴 **Red (attacker):** `soc alert fatigue evasion attack`, `MITRE ATT&CK T1562 impair defenses`, `low and slow attack under threshold`, `living off the land binaries lolbins`
- 🔵 **Blue (defender):** `soc alert triage process`, `false positive tuning detection`, `MITRE ATT&CK navigator`, `detection engineering true positive rate`

## Lesson Status

Ready for self-study. Build `scripts/alert_triage.sh` + `docs/runbooks/soc-triage-runbook.md`
yourself, then return to Navi to grade the quiz (professional-answer comparisons) and run the
Update Protocol. This is the **Security-Analyst stage** detection capstone (see
`docs/learning/ROADMAP.md`); pairs with Lesson 26 (incident response) for the full
detect→respond loop.
