# Lesson 18 — Failed SSH Login Detection

**Status:** ✅ ready for self-study (full depth) · **Date written:** 2026-06-20
**Schema:** 12-section SOC (`docs/learning/CLAUDE_TEACHING_RULES.md`)
**Focus:** the canonical first detection — the failed-auth signal in `auth.log`/`lastb`, the Wazuh
5710-family, baselining normal vs attack, and FP tuning. The pattern every later detection follows.
**Primary artifact:** `scripts/failed_logins.sh` (seeded) + a Wazuh rule.

> **How to use this lesson:** read §1–§7, do §8 (generate + detect + tune), produce §9, quiz,
> reflect. Then Lesson 19.

---

## §1 — Concept (Scientific Theory)

### What it is
A **failed SSH login** is the most common, most fundamental security event on an internet-facing
Linux host. `sshd` logs every failed authentication to `auth.log`/`secure` (and the binary `btmp`,
read by `lastb`). Detecting it — and distinguishing **noise** (constant internet background scanning)
from a **targeted attack** (a real brute force, Lesson 19) — is the analyst's first detection skill.

### Why it exists
Failed logins are step one of credential attacks (the kill-chain delivery/exploitation stages). They
are also extremely noisy — any public SSH host sees thousands daily. So the lesson is really about
**signal vs noise**: a single failed login is nothing; a *pattern* (many from one source, or failed-
then-success) is everything.

### Three-Level Depth (Lens A)
- **Level 1 — Beginner:** when someone types the wrong SSH password, Linux writes a "Failed password"
  line. Lots of those from one place = someone guessing.
- **Level 2 — Analyst/SOC:** you detect the line (`grep`/Wazuh rule 5710), aggregate by source IP +
  target user (Lesson 05 idiom), baseline what's normal for the host, and decide TP/FP. The critical
  pivot: did any attempt **succeed** (`Accepted`)? That flips noise into an incident (→ Lesson 19).
- **Level 3 — Adversary/Kernel:** `sshd` distinguishes "Failed password for `user`" vs "Failed
  password for **invalid user** `user`" (the account doesn't exist — a sign of guessing usernames).
  The source IP is `$(NF-3)`; PAM also logs to `auth.log`. `lastb` reads `/var/log/btmp` (a separate,
  binary record an attacker may also try to clear, T1070).

### Two Teaching Approaches (Lens B) — signal vs noise
**Approach 1 (technical):** failed-auth events are high-volume, low-individual-value; detection value
comes from aggregation (count per source/user over a window) and correlation (failed→accepted).
Severity scales with concentration + success, not raw count.

**Approach 2 (analogy):** a **door buzzer pressed all day** by passersby (noise) vs **someone trying
50 keys in your lock, then the door opens** (incident). You don't call the police for every buzz —
you call when one person systematically tries to get in *and succeeds*. **Where it breaks down:**
internet background noise is so constant that a naïve "any failed login = alert" is useless — you
must baseline.

### Visual (ASCII) — the signal
```
 NOISE:   1-2 failed logins each from 50 different IPs (internet scanning)        → low/ignore
 SIGNAL:  80 failed logins from 10.0.0.99 in 2 min                                → brute force (L19)
 INCIDENT: 80 failed THEN 1 "Accepted password for svc_app from 10.0.0.99"        → COMPROMISE
           grep "Failed password" → aggregate by srcip → check for "Accepted" from same srcip
```

---

## §2 — Linux Investigation Commands

```bash
grep "Failed password" /var/log/auth.log | tail                    # the raw signal
grep "Failed password" /var/log/auth.log | awk '{print $(NF-3)}' | sort | uniq -c | sort -rn   # by IP
grep "invalid user" /var/log/auth.log | awk '{print $(NF-5)}' | sort | uniq -c | sort -rn       # guessed usernames
lastb | head                                                        # failed logins (btmp)
grep "Accepted" /var/log/auth.log | grep <suspect_ip>              # did they get in? (the pivot)
bash scripts/failed_logins.sh                                       # automated count + threshold + success cross-check
```
| Linux | Wazuh equivalent |
|---|---|
| `grep "Failed password"` | rule **5710** (sshd auth failed) |
| aggregate by IP | rule **5712**/frequency (multiple failures) |
| failed-then-accepted | correlation: 5710 then 5715 same `srcip` |

---

## §3 — Real-World Threat Context & Use Cases

- **Every public host:** failed SSH logins are constant; the skill is filtering to the real attack.
- **The success pivot:** failed-then-accepted from one IP is a near-certain compromise → Sev2,
  escalate (`soc/escalation-matrix.md`).
- **Username intel:** lots of "invalid user" for `admin/root/test/oracle` = automated guessing.
- **Tuning is essential:** un-tuned, this alert is pure fatigue; tuned (threshold + success
  correlation), it's gold.
- **Exam framing:** auth-log analysis + brute-force basics on Security+/CySA+/BTL1.

---

## §4 — Detection

- **Linux-first:** `failed_logins.sh` counts per-source failures, flags ≥threshold, and cross-checks
  for a successful login from a flagged IP (exit 2 = escalate).
- **Wazuh:** rule 5710 fires per failure; a frequency child (Lesson 15 pattern) fires on the burst;
  a correlation catches failed→accepted. Tag T1110.
- **Baseline + tune:** set the threshold above your host's normal background; allowlist known
  scanners/automation; the *success* correlation is the high-fidelity rule (very low FP).
- **FP sources:** a user fat-fingering a password a few times; a misconfigured app retrying — handle
  with threshold + per-user context.

---

## §5 — Investigation & Triage

Alert fires → confirm it's real (the lines exist), aggregate by source + user, **check for success**
(the decisive pivot), scope (other hosts from the same IP? `ioc_sweep.sh`), enrich (IP reputation,
Lesson 09). No success + single source + below-normal = likely close/tune; success = escalate.

---

## §6 — SOC Perspective

This is the bread-and-butter T1 alert. The volume makes **tuning** the make-or-break SOC skill —
an un-tuned 5710 buries everything. The success-correlation rule is one of the highest-value, lowest-
FP detections a SOC runs; failed-only is informational. Maps to `soc/soc-scenarios.md` #1/#2.

---

## §7 — Incident-Response Perspective

If a success is confirmed, this becomes an active intrusion: preserve evidence (auth.log copy,
`last`), then proceed to investigate what the session did (Lesson 21) and contain. Maps to
`soc/soc-scenarios.md` #2 and feeds the capstone (Lesson 35 stage 2).

---

## §8 — Practical Lab (build this yourself)

**Goal:** generate failed logins, detect them (Linux + Wazuh), distinguish noise from attack, and
tune.

### Lens C — Manual → Automated → Why
- **Manual:** `grep`/aggregate by hand.
- **Automated:** `failed_logins.sh` (count + threshold + success cross-check) and a Wazuh rule —
  continuous, fleet-wide.
- **Why:** you can't watch auth.log all day; the rule does, and only pages you on the real pattern.

### Steps
1. **Generate (drill 1+2):** from another box, fail SSH to your VM a handful of times (noise), then
   a burst of ≥10 from one IP (attack); finally one *successful* login to a weak lab cred (the
   incident pivot).
2. **Detect (Linux):** run `scripts/failed_logins.sh` — confirm it lists the top source, flags the
   ≥threshold IP, and cross-checks the success. Confirm exit code 2.
3. **Detect (Wazuh):** confirm rule 5710 + your frequency rule fire; build/confirm a failed→accepted
   correlation. Map to T1110.
4. **Tune:** add a couple of legit typo-failures below threshold; confirm no false alert. Document
   the threshold + allowlist reasoning.
5. Write the runbook + playbook.

### Lens D — the raw artifact
```
Jun 20 02:14:07 web01 sshd[8123]: Failed password for invalid user admin from 10.0.0.99 port 51234 ssh2
Jun 20 02:14:55 web01 sshd[8131]: Accepted password for svc_app from 10.0.0.99 port 51299 ssh2
#   "invalid user" = guessing a non-existent account; the Accepted line from the SAME IP = compromise.
```

---

## §9 — GitHub Artifact (the 6-artifact evidence package)

1. **Script:** `scripts/failed_logins.sh` (committed, `shellcheck`-clean).
2. **Detection rule/config:** the Wazuh failed-login frequency + failed→accepted correlation rule
   (`infra/wazuh/local_rules.xml`), tagged T1110.
3. **Runbook:** `docs/runbooks/runbook-failed-ssh.md` — "when 5710-burst fires, do X (check
   success!)."
4. **Playbook:** `docs/playbooks/ssh-auth-play.md`.
5. **Incident report + notes:** the drill (noise vs attack vs compromise; success pivot caught) +
   notes.
6. **SOC ticket:** `SOC-18` (Task: "failed-SSH detection + tune") → Closed.

---

## §10 — Portfolio Artifact

- **Resume bullet:** "Built failed-SSH-login detection (Bash + Wazuh) distinguishing internet noise
  from targeted attacks, with a failed-then-success correlation (T1110/T1078) and FP tuning."
- **Interview talking point:** the failed→accepted pivot — *why a successful login changes
  everything* — plus the one-liner from memory.
- **Serves:** SOC T1 (Stage 2).

---

## §11 — Certification Crossover Notes

- **Security+:** attacks/monitoring. **CySA+:** detection/analysis. **SC-200:** auth detections.
  **BTL1:** detection. Detail: `alignment/CERTIFICATION-MAPPING.md`.

---

## §12 — Security Notes (Lens E — Attacker & Defender)

**🔴 Attacker:** SSH brute force / password spraying (T1110.001/.003), username enumeration ("invalid
user" probing), then valid-account use (T1078) on success; may clear `btmp` to hide failures (T1070).

**🔵 Defender:** detect the burst (frequency) *and* the success (correlation); enforce key-only auth +
fail2ban (prevent); ship `auth.log`/`btmp` off-box (Lesson 06) so clearing them locally doesn't
hide the trail; baseline + tune to keep signal high.

---

## Quiz (Interview-Style, Graded)

**Q1.** Write the one-liner for top failed-SSH source IPs and explain why raw count alone isn't a
good severity signal.
> **Your answer:**

**Q2.** What's the single most important thing to check after a failed-login burst, and why?
> **Your answer:**

**Q3.** What does "Failed password for invalid user" tell you vs "Failed password for root"?
> **Your answer:**

**Q4.** **Scenario:** 80 failed logins from 10.0.0.99 then one Accepted from the same IP. Triage:
severity, scope, action, ATT&CK?
> **Your answer:**

**Q5.** How would you tune this detection so legitimate password typos don't page you but real brute
force still does?
> **Your answer:**

*(Request the "Professional Answer" comparison under each before moving on.)*

---

## Reflection
*(After the quiz)* — What did you learn? · What confused you? · What would you do differently?

---

## Search Keywords For Further Understanding

**Core**
- `ssh failed password auth.log detection`
- `lastb btmp failed login`
- `wazuh rule 5710 5712 sshd`
- `failed then accepted login correlation`
- `ssh invalid user enumeration`

**Tools**
- `fail2ban ssh`
- `wazuh ssh authentication rules`

**Going further**
- `brute force detection` (L19) · `user account investigation` (L22) · `suspicious process` (L21)

**Red / Blue (Lens E):**
- 🔴 `brute force T1110`, `password spraying T1110.003`, `valid accounts T1078`, `clear btmp T1070`
- 🔵 `frequency + success correlation`, `key-only auth fail2ban`, `off-box auth logs`

---

## Lesson Status
- [ ] §8 lab completed (generated noise/attack/compromise; detected + tuned)
- [ ] 6-artifact evidence package committed (§9)
- [ ] Quiz answered + professional-answer comparisons (graded)
- [ ] Reflection + Search Keywords reviewed

When complete, run the Update Protocol, then move to **Lesson 19 — Brute Force Detection**.

---

*Lesson 18 written by Navi · 2026-06-20 · full-depth. Sources to cite at study time: OpenSSH
`sshd` logging, Wazuh SSH ruleset, MITRE T1110/T1078.*
