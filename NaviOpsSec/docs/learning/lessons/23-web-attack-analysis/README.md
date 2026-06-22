# Lesson 23 — Web Attack Analysis

**Status:** ✅ ready for self-study (full depth) · **Date written:** 2026-06-20
**Schema:** 12-section SOC (`docs/learning/CLAUDE_TEACHING_RULES.md`)
**Focus:** reading web access logs for attacks — SQLi/XSS/LFI/path-traversal patterns,
enumeration vs successful exploitation (status codes + sizes), and WAF/Wazuh web rules (T1190).
**Primary artifact:** `scripts/weblog_analyze.sh`.

> **Danger zone:** generate web attacks only against your own lab app (`navi.project.md` #2). Read
> §1–§7, do §8 (attack your lab app + analyze the logs), produce §9, quiz, reflect. Then Lesson 24.

---

## §1 — Concept (Scientific Theory)

### What it is
Web servers log every request (method, URI, status, size, user-agent, referer) to an **access log**.
Attacks against the app leave tell-tale patterns in the URI/body: **SQL injection** (`UNION SELECT`,
`' OR 1=1`), **XSS** (`<script>`), **LFI/path traversal** (`../../etc/passwd`), **command injection**
(`;id`, `|nc`), and **enumeration** (scanning for `/admin`, `/.env`, `/wp-login`). The analyst reads
these logs to distinguish *probing* from *successful exploitation*.

### Why it exists
Public web apps are the most-attacked surface (kill-chain delivery/exploitation; T1190 exploit
public-facing application). The access log is often the only evidence. The crucial, subtle skill:
telling **noise/scanning** (constant, mostly 404/403) from a **successful hit** (a 200 + large
response to an injection, or a request followed by a new process/file).

### Three-Level Depth (Lens A)
- **Level 1 — Beginner:** the web log shows every page request; attacks look like weird URLs
  (`?id=1' OR 1=1`, `../../etc/passwd`, `<script>`). Lots of weird 404s = someone poking.
- **Level 2 — Analyst/SOC:** grep the patterns, then read the **status code + response size**:
  a `200` (success) with a *large* body for a SQLi attempt suggests data returned (real hit); `404`/
  `403`/`500` suggests probing/failure. Correlate a successful exploit with a **follow-on** (new
  file uploaded → webshell → a shell parented by the web server, Lesson 21).
- **Level 3 — Adversary/Kernel:** payloads are URL-encoded (`%27`=`'`, `%2e%2e%2f`=`../`) — decode
  before judging. A webshell upload → later requests to `/uploads/x.php?cmd=id` → `nginx`-parented
  `bash` (the tie to process investigation). WAF/Wazuh web rules pattern-match the payloads;
  response analysis confirms impact.

### Two Teaching Approaches (Lens B) — probing vs exploitation
**Approach 1 (technical):** an attack *attempt* is a request matching a malicious pattern; a
*successful exploit* is an attempt whose response (status/size/timing) or downstream effect (file/
process) indicates the payload worked. Detection finds attempts; analysis (response + correlation)
finds success.

**Approach 2 (analogy):** someone **rattling every doorknob and shouting test phrases** (probing,
lots of "no" responses) vs **a door that actually opens and they walk out with files** (success —
a "yes" response + something now missing). You alert on the rattling but *investigate* the door that
opened. **Where it breaks down:** a clever attacker makes a successful exploit look like a normal
200 — so you corroborate with host evidence (new file/process).

### Visual (ASCII) — reading the log
```
 PROBING:  GET /admin 404 · GET /.env 404 · GET /wp-login.php 404   (scanning, all "no")
 SQLi try: GET /item?id=1'+UNION+SELECT+... 500     (error = attempt, maybe blind)
 SQLi HIT: GET /item?id=1'+UNION+SELECT+user,pass.. 200  9.8KB  (200 + BIG body = data returned ✗)
 LFI HIT:  GET /view?f=../../../../etc/passwd 200 2.1KB  (returned /etc/passwd contents ✗)
 → status code + response SIZE separate the attempt from the success.
```

---

## §2 — Linux Investigation Commands

```bash
LOG=/var/log/nginx/access.log     # or apache2/access.log
# attack-pattern grep (decode-aware)
grep -Ei "union select|' or |%27|<script>|\.\./|%2e%2e|/etc/passwd|;id|/bin/sh" "$LOG"
# enumeration: top 404'd paths (scanning)
awk '$9==404{print $7}' "$LOG" | sort | uniq -c | sort -rn | head
# success analysis: injection attempts that returned 200 + large body
awk '$9==200 && $10>5000 {print $1,$7,$10}' "$LOG" | grep -Ei "select|\.\.|script"
# top attacking IPs + user-agents
awk '{print $1}' "$LOG" | sort | uniq -c | sort -rn | head
bash scripts/weblog_analyze.sh "$LOG"
```
| Linux | Wazuh / WAF |
|---|---|
| pattern grep | Wazuh web rules (31xxx) / ModSecurity |
| 404 enumeration | Wazuh web-scan rule |
| 200+large after injection | manual/response-analysis (success signal) |

---

## §3 — Real-World Threat Context & Use Cases

- **Constant background probing:** every public app is scanned for `/wp-login`, `/.env`, admin
  panels — mostly noise (404s).
- **The successful exploit:** the rare 200/large/odd response (or the follow-on webshell) is the
  incident — find it in the noise.
- **Webshell chain:** upload → request the shell → command execution → `nginx`-parented `bash`
  (Lesson 21).
- **Exam framing:** OWASP attacks (SQLi/XSS/LFI), T1190, and access-log analysis on
  Security+/CySA+/BTL1.

---

## §4 — Detection

- **Pattern detection (attempts):** Wazuh web ruleset / ModSecurity match the payloads; high volume,
  needs tuning (lots of harmless probing).
- **Success detection (the prize):** correlate an attack pattern with a **200 + anomalous size** or a
  **follow-on host event** (new file in web root, web-spawned shell) — far higher fidelity.
- **Enumeration detection:** 404-rate per source (scanning).
- **Tune:** scanners/security tools + legitimate odd URLs cause FPs; weight by response + follow-on.

---

## §5 — Investigation & Triage

Given a web alert: decode the payload, classify the attack, read the **response** (attempt vs
success), and check for a **follow-on** on the host (new file/process — pivot to Lesson 21/24).
Scope (other targets/attempts from the IP), enrich (IP reputation). Probing-only → likely monitor/
tune; success or follow-on → escalate as compromise.

---

## §6 — SOC Perspective

Web alerts are high-volume; the SOC skill is finding the successful exploit among endless probing —
response analysis + follow-on correlation are how. A WAF (block) + Wazuh web rules (detect) is the
common pairing. `weblog_analyze.sh` is the standard "what hit this web server" tool. Maps to
`soc/soc-scenarios.md` #6.

---

## §7 — Incident-Response Perspective

A successful web exploit is often the **initial access** of an intrusion (capstone-style): web log
gives the entry, then you pivot to the host (webshell file, web-spawned process — Lessons 21/24) to
trace what followed. Preserve the access log + the dropped file. Maps to capstone web-entry stage.

---

## §8 — Practical Lab (build this yourself)

**Goal:** attack your own lab web app, then find the attempts *and* the successful exploit in the
logs.

### Lens C — Manual → Automated → Why
- **Manual:** grep patterns one at a time.
- **Automated:** `weblog_analyze.sh` reports attack patterns, top 404 enumeration, top attacker IPs,
  and injection-attempts-that-returned-200+large (the success signal) in one run.
- **Why:** web logs are huge + noisy; automation surfaces the success in the flood. Production uses
  WAF + SIEM web rules.

### Steps
1. Stand up a tiny vulnerable lab app (e.g. a deliberately weak PHP/`flask` endpoint on your VM) —
   self-owned only.
2. **Generate (drill 8, lab):** `curl` an enumeration sweep (404s), a SQLi attempt, an LFI
   (`?f=../../../../etc/passwd`), and one that *succeeds* (returns data / a large 200).
3. Build `scripts/weblog_analyze.sh`: pattern grep, 404-enumeration top-N, attacker-IP top-N, and the
   "injection → 200 + large body" success finder. `bash -n` + `shellcheck` clean.
4. Detect via Wazuh web rules; confirm attempts alert. Map to T1190.
5. Identify the *successful* request by status+size, and (if you staged a webshell) correlate to the
   host process (Lesson 21). Document attempt-vs-success reasoning.

### Lens D — the raw artifact
```
10.0.0.99 - - [20/Jun/2026:02:30:11Z] "GET /view?f=../../../../etc/passwd HTTP/1.1" 200 2114 "-" "curl/8"
#                                            ^path traversal payload                  ^200 ^2114 bytes
# 200 + a 2KB body for an /etc/passwd request = the file was RETURNED = successful LFI (not just an attempt).
```

---

## §9 — GitHub Artifact (the 6-artifact evidence package)

1. **Script:** `scripts/weblog_analyze.sh` (committed, `shellcheck`-clean).
2. **Detection rule/config:** Wazuh web-attack rules / ModSecurity note (`infra/`), tagged T1190.
3. **Runbook:** `docs/runbooks/runbook-web-attack.md` — attempt vs success → action.
4. **Playbook:** `docs/playbooks/web-attack-play.md`.
5. **Incident report + notes:** the web-attack drill (attempts + the successful LFI/SQLi found;
   follow-on checked) + notes.
6. **SOC ticket:** `SOC-23` (Task: "web attack analysis") → Closed.

---

## §10 — Portfolio Artifact

- **Resume bullet:** "Built web access-log analysis (`weblog_analyze.sh`) detecting SQLi/XSS/LFI/path-
  traversal (T1190) and distinguishing enumeration from successful exploitation via response
  analysis + host correlation."
- **Interview talking point:** "how do you tell a probe from a successful exploit in a web log?" —
  the status-code + size + follow-on answer.
- **Serves:** SOC T2 (Stage 3). Common capstone initial-access vector.

---

## §11 — Certification Crossover Notes

- **Security+:** app attacks (2.x). **CySA+:** web/app analysis. **SC-200:** web signals. **BTL1:**
  web log analysis. Detail: `alignment/CERTIFICATION-MAPPING.md`.

---

## §12 — Security Notes (Lens E — Attacker & Defender)

**🔴 Attacker:** exploit public apps (T1190) via SQLi/XSS/LFI/RCE; URL-encode/obfuscate payloads to
evade pattern rules; upload a webshell for persistence; enumerate first (`/admin`, `/.env`).

**🔵 Defender:** WAF (block) + SIEM web rules (detect), decode-aware patterns, response + follow-on
correlation to find *success*, FIM on the web root (Lesson 24) to catch webshell uploads, and
patch the app (prevent). Detecting the attempt is easy; confirming + responding to the *success* is
the skill.

---

## Quiz (Interview-Style, Graded)

**Q1.** Give the log signature of SQLi, LFI/path-traversal, and XSS attempts.
> **Your answer:**

**Q2.** How do you distinguish a successful exploit from a mere attempt in an access log?
> **Your answer:**

**Q3.** Why must you decode URL-encoded payloads before judging a request, and what's an example?
> **Your answer:**

**Q4.** **Scenario:** access log shows `GET /view?f=../../etc/passwd` returning 200 with a 2KB body,
then a new file `/var/www/uploads/x.php`. Walk your investigation + response.
> **Your answer:**

**Q5.** What's the FIM/host link that confirms a web compromise beyond the access log?
> **Your answer:**

*(Request the "Professional Answer" comparison under each before moving on.)*

---

## Reflection
*(After the quiz)* — What did you learn? · What confused you? · What would you do differently?

---

## Search Keywords For Further Understanding

**Core**
- `web access log sqli lfi xss detection`
- `enumeration vs successful exploitation logs`
- `url encoding payload decode`
- `webshell detection web root`
- `mitre t1190 exploit public facing application`

**Tools**
- `wazuh web attack rules`
- `modsecurity owasp crs`

**Going further**
- `file integrity monitoring` (L24) · `suspicious process` (L21) · `capstone` (L35)

**Red / Blue (Lens E):**
- 🔴 `exploit public app T1190`, `sqli lfi xss`, `webshell upload`, `payload obfuscation`
- 🔵 `waf + siem web rules`, `response analysis`, `fim web root`, `decode-aware detection`

---

## Lesson Status
- [ ] §8 lab completed (attacked own app; found attempts + the successful exploit)
- [ ] 6-artifact evidence package committed (§9)
- [ ] Quiz answered + professional-answer comparisons (graded)
- [ ] Reflection + Search Keywords reviewed

When complete, run the Update Protocol, then move to **Lesson 24 — File Integrity Monitoring**.

---

*Lesson 23 written by Navi · 2026-06-20 · full-depth. Sources to cite at study time: OWASP Top 10,
MITRE T1190, Wazuh web ruleset, ModSecurity CRS.*
