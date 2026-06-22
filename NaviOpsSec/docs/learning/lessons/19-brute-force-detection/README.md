# Lesson 19 — Brute Force Detection

**Status:** ✅ ready for self-study (full depth) · **Date written:** 2026-06-20
**Schema:** 12-section SOC (`docs/learning/CLAUDE_TEACHING_RULES.md`)
**Focus:** threshold/frequency detection, single-source vs distributed vs password-spray, account
lockout/fail2ban, and the T1110 family — generalizing Lesson 18 into robust behavioral detection.
**Primary artifact:** `scripts/brute_force_detect.sh` + a tuned Wazuh frequency rule.

> **How to use this lesson:** read §1–§7, do §8 (generate variants + detect each), produce §9, quiz,
> reflect. Then Lesson 20.

---

## §1 — Concept (Scientific Theory)

### What it is
**Brute force** is automated credential guessing. Variants you must detect separately:
- **Single-source brute force:** many attempts from one IP against one/few accounts.
- **Distributed brute force:** the same against one account from *many* IPs (defeats per-IP
  thresholds).
- **Password spraying (T1110.003):** *few* attempts each against *many* accounts (stays under per-
  account lockout) — low and slow.
- **Credential stuffing (T1110.004):** reusing leaked credentials.

Detection is **behavioral**: count over a time window, keyed by the right dimension (source IP, or
target user, or aggregate), with a threshold above baseline.

### Why it exists
Lesson 18 detects the obvious single-source burst. Real attackers evade that with distribution +
spraying. This lesson makes your detection *robust* — the difference between catching a script kiddie
and catching a careful adversary. It's also the canonical "behavioral / frequency rule" you'll reuse
everywhere.

### Three-Level Depth (Lens A)
- **Level 1 — Beginner:** a program tries many passwords fast. Detect by counting attempts; block
  after N.
- **Level 2 — Analyst/SOC:** choose the **key** (per-IP catches single-source; per-user catches
  distributed; aggregate catches both), the **threshold**, and the **window**. Correlate with
  success (compromise). fail2ban/lockout is the prevention pairing.
- **Level 3 — Adversary/Kernel:** the detection is a stateful frequency count over a sliding window
  (Wazuh `<frequency>`/`<timeframe>` + `same_source_ip`/`same_user`). Spraying defeats per-account
  windows by spreading thin → detect by *per-source-across-many-users* or *org-wide failed-auth rate
  anomaly*. The fix is layering keys + widening windows, accepting some FP for coverage.

### Two Teaching Approaches (Lens B) — single vs distributed vs spray
**Approach 1 (technical):** brute force is a rate phenomenon; detection picks the dimension where the
rate concentrates. Single-source → rate per srcip; distributed → rate per target user; spray → low
per-user rate but elevated per-source-across-users and org-wide anomaly.

**Approach 2 (analogy):** a thief trying keys. Single-source = one thief trying 100 keys on your
door (loud, easy to spot). Distributed = 100 thieves each trying one key on your door (no single
thief looks busy — watch the *door*, not the thief). Spray = one thief trying one key on 100
*different* doors (watch the *neighborhood* rate). **Where it breaks down:** legit bursts (an app
outage causing retries) mimic the rate — context/baseline disambiguates.

### Visual (ASCII) — keying the detection
```
 SINGLE-SOURCE:  srcip=10.0.0.99 → 80 fails/2m            → key by srcip  ✓ (L18 rule)
 DISTRIBUTED:    user=svc_app ← 1 fail each from 80 IPs   → key by USER (same_user) ✓
 SPRAY:          80 users × 2 fails each from 10.0.0.99   → key by SOURCE-across-users / org rate ✓
```

---

## §2 — Linux Investigation Commands

```bash
# single-source (per IP)
grep "Failed password" /var/log/auth.log | awk '{print $(NF-3)}' | sort | uniq -c | sort -rn
# distributed (per target user — many IPs hitting one user)
grep "Failed password" /var/log/auth.log | sed -n 's/.*for \(invalid user \)\?\([^ ]*\) from.*/\2/p' \
  | sort | uniq -c | sort -rn
# spray signal (one source touching MANY users)
grep "Failed password" /var/log/auth.log | awk '{print $(NF-3)}' \
  | while read ip; do echo "$ip $(grep $ip /var/log/auth.log | grep -c 'invalid user')"; done | sort -u
fail2ban-client status sshd          # current bans (prevention layer)
bash scripts/brute_force_detect.sh   # multi-key detection
```
| Variant | Linux key | Wazuh key |
|---|---|---|
| single-source | per srcip | `same_source_ip` frequency |
| distributed | per user | `same_user` frequency |
| spray | source-across-users / rate | aggregate / org-wide anomaly |

---

## §3 — Real-World Threat Context & Use Cases

- **The evasive attacker:** any competent brute force is distributed/sprayed — per-IP-only detection
  misses it. Robust keying is the job.
- **Lockout trade-off:** account lockout stops brute force but enables DoS (lock out real users) +
  helps spray (attacker learns valid users from lockout behavior) — tune carefully.
- **Success is still the pivot:** any variant + a success = compromise → escalate.
- **Exam framing:** T1110 sub-techniques, lockout policy, and detection keying on
  Security+/CySA+/BTL1.

---

## §4 — Detection

- **Layer the keys:** run per-source *and* per-user (and an org-wide rate anomaly for spray). One
  rule can't catch all three variants.
- **Window tuning:** widen the timeframe to catch low-and-slow (cost: more state/FP).
- **Correlate success:** failed-burst → accepted = the high-fidelity, low-FP rule.
- **fail2ban as prevention + signal:** its bans are both a control and a log source.
- This is the reusable **frequency-rule** pattern (Lesson 15) applied with multiple keys.

---

## §5 — Investigation & Triage

Identify the variant (which key concentrated), check for success, scope (which accounts/hosts),
enrich (source reputation). Distributed/spray with no success → likely tune + monitor + maybe block
ranges; any success → escalate as compromise. Distinguish a legit retry storm (app outage) via
context + baseline.

---

## §6 — SOC Perspective

Brute force is a daily alert; the SOC value is catching the *evasive* variants and not drowning in
the noisy ones. The multi-key ruleset is detection-engineering content (Lesson 32). Lockout policy is
a recurring SOC/IT debate (security vs availability) — know the trade-offs.

---

## §7 — Incident-Response Perspective

On confirmed success: preserve, investigate the session (Lesson 21), check persistence (Lesson 22),
contain (block source(s) — for distributed, that may be ranges/geo; consider disabling the targeted
account). Capstone stage 2. Maps to `soc/soc-scenarios.md` #1/#2.

---

## §8 — Practical Lab (build this yourself)

**Goal:** generate all three variants and build detection that catches each.

### Lens C — Manual → Automated → Why
- **Manual:** aggregate by IP only (misses distributed/spray).
- **Automated:** `brute_force_detect.sh` checks per-IP, per-user, and source-across-users; Wazuh runs
  layered frequency rules.
- **Why:** evasive attackers require multi-key detection — automation makes running all keys every
  time feasible.

### Steps
1. **Generate (lab):** (a) single-source burst (drill 2); (b) distributed — script wrong-password
   attempts to one user from a couple of source identities; (c) spray — a few attempts each across
   several lab usernames from one source.
2. Build `scripts/brute_force_detect.sh`: report top-by-source, top-by-user, and
   source-touching-many-users; flag thresholds. `bash -n` + `shellcheck` clean.
3. In Wazuh, add a `same_user` frequency rule alongside the `same_source_ip` one (Lesson 15);
   confirm each variant fires the appropriate rule. Tag T1110.001/.003.
4. **Tune:** simulate a benign retry storm; adjust to avoid the FP while keeping coverage. Document.
5. Correlate one variant with a success → confirm the compromise rule.

### Lens D — the raw artifact
```
# spray signature: same source, MANY distinct users, FEW attempts each
10.0.0.99 → admin(2) oracle(2) test(2) git(2) backup(2) ...   (low per-user, high per-source spread)
# per-user-only or per-ip-only rules under-count this; the source-across-users key catches it.
```

---

## §9 — GitHub Artifact (the 6-artifact evidence package)

1. **Script:** `scripts/brute_force_detect.sh` (multi-key; committed, `shellcheck`-clean).
2. **Detection rule/config:** layered Wazuh frequency rules (per-source + per-user), tagged T1110.x.
3. **Runbook:** `docs/runbooks/runbook-brute-force.md` — identify variant → check success → act.
4. **Playbook:** `docs/playbooks/brute-force-play.md`.
5. **Incident report + notes:** the 3-variant drill (each detected) + tune note + notes.
6. **SOC ticket:** `SOC-19` (Task: "robust brute-force detection") → Closed.

---

## §10 — Portfolio Artifact

- **Resume bullet:** "Built robust brute-force detection (Bash + layered Wazuh frequency rules)
  covering single-source, distributed, and password-spray variants (T1110.x) with success
  correlation and FP tuning."
- **Interview talking point:** explain why per-IP detection misses distributed/spray and how you key
  detection per-variant — a strong detection-engineering answer.
- **Serves:** SOC T1 → Detection Engineer (Stages 2–4).

---

## §11 — Certification Crossover Notes

- **Security+:** password attacks (2.x). **CySA+:** detection. **SC-200:** brute-force analytics.
  **BTL1:** detection. Detail: `alignment/CERTIFICATION-MAPPING.md`.

---

## §12 — Security Notes (Lens E — Attacker & Defender)

**🔴 Attacker:** distribute across IPs (botnet/proxies) and spray across accounts to evade per-IP +
per-account thresholds (T1110.003); time slowly to beat windows; use leaked creds (stuffing,
T1110.004) for high hit rates with few attempts.

**🔵 Defender:** layer detection keys (source + user + org-rate), widen windows for low-and-slow,
correlate success, enforce MFA + key-only auth + smart lockout (without enabling DoS/user
enumeration), and feed threat intel (known brute-force sources). MFA is the control that makes
brute-force success nearly irrelevant.

---

## Quiz (Interview-Style, Graded)

**Q1.** Distinguish single-source, distributed, and password-spray brute force, and the detection
key each requires.
> **Your answer:**

**Q2.** Why does a per-IP frequency rule miss distributed and spray attacks?
> **Your answer:**

**Q3.** What are the trade-offs of account lockout as a control?
> **Your answer:**

**Q4.** **Scenario:** one source IP has 2 failed logins each against 60 different usernames in 10
minutes, no successes. What is it, severity, and how do you detect + respond?
> **Your answer:**

**Q5.** Why is MFA the control that most reduces the impact of brute force, even when detection
fails?
> **Your answer:**

*(Request the "Professional Answer" comparison under each before moving on.)*

---

## Reflection
*(After the quiz)* — What did you learn? · What confused you? · What would you do differently?

---

## Search Keywords For Further Understanding

**Core**
- `brute force vs password spraying vs credential stuffing`
- `distributed brute force detection`
- `wazuh frequency rule same_user same_source_ip`
- `account lockout policy tradeoffs`
- `mitre t1110 sub techniques`

**Tools**
- `fail2ban configuration`
- `brute force detection bash`

**Going further**
- `port scan detection` (L20) · `user account investigation` (L22) · `detection engineering` (L26)

**Red / Blue (Lens E):**
- 🔴 `password spraying T1110.003`, `credential stuffing T1110.004`, `distributed botnet brute force`
- 🔵 `layered frequency keys`, `mfa key-only auth`, `org-wide auth anomaly`

---

## Lesson Status
- [ ] §8 lab completed (3 variants generated + each detected; tuned)
- [ ] 6-artifact evidence package committed (§9)
- [ ] Quiz answered + professional-answer comparisons (graded)
- [ ] Reflection + Search Keywords reviewed

When complete, run the Update Protocol, then move to **Lesson 20 — Port Scan Detection**.

---

*Lesson 19 written by Navi · 2026-06-20 · full-depth. Sources to cite at study time: MITRE T1110.x,
Wazuh frequency rules, fail2ban docs, NIST password guidance (SP 800-63B).*
