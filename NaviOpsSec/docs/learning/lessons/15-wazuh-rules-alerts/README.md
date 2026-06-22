# Lesson 15 — Wazuh Rules & Alerts

**Status:** ✅ ready for self-study (full depth) · **Date written:** 2026-06-20
**Schema:** 12-section SOC (`docs/learning/CLAUDE_TEACHING_RULES.md`)
**Focus:** Wazuh **decoders** + **rules** — rule IDs/levels/groups, custom `local_rules.xml`,
frequency/correlation rules, and testing with `wazuh-logtest`. This is where you start *engineering*
detection.
**Primary artifact:** `infra/wazuh/local_rules.xml` (your first custom rules) + `local_decoders.xml`.

> **How to use this lesson:** read §1–§7, do §8 (write + test a custom rule), produce §9, quiz,
> reflect. Then Lesson 16.

---

## §1 — Concept (Scientific Theory)

### What it is
In Wazuh, detection is two layers:
- **Decoders** parse a raw log line into **fields** (`srcip`, `srcuser`, `program`, …). Without a
  decoder, a rule has nothing to match.
- **Rules** evaluate decoded events and fire **alerts**. A rule has an **id**, a **level** (0–15,
  severity), **groups** (tags, e.g. `authentication_failed`), and matching logic (regex/field
  match, parent rule via `if_sid`, and **frequency** for correlation).

You extend the built-in ruleset with **`local_rules.xml`** (custom rules) and `local_decoders.xml`
(custom decoders) — leaving the shipped files untouched (they're overwritten on upgrade).

### Why it exists
The built-in rules catch the common cases; *your environment* has specific things to detect (a
service account that should never log in interactively, an app's custom log format, a higher
brute-force threshold). Custom rules + decoders are how a SOC turns a generic SIEM into *its*
detection. This is detection engineering in practice (Lesson 26 generalizes it).

### Three-Level Depth (Lens A)
- **Level 1 — Beginner:** a decoder reads the log and pulls out the important words; a rule says
  "if you see this pattern, raise an alert at this severity."
- **Level 2 — Analyst/SOC:** you write a rule that matches decoded fields, set its level (severity)
  and group (so it shows on the right dashboard), and chain it to a parent rule (`if_sid`) or add a
  **frequency** condition (e.g. "10 of rule 5710 from the same `srcip` in 60s" → brute force). You
  test with `wazuh-logtest` before deploying.
- **Level 3 — Adversary/Kernel:** frequency/correlation rules maintain state across events (the
  same `same_source_ip` over a time window) — that's how a SIEM detects *behavior* (brute force,
  scan) rather than single lines. Rule order + `if_sid` form a decision tree; level drives
  alerting/active-response thresholds.

### Two Teaching Approaches (Lens B) — decoder vs rule
**Approach 1 (technical):** decoders are field extractors (regex → named fields); rules are boolean
predicates over those fields (+ stateful aggregation for frequency). Detection = correct extraction
∧ correct predicate.

**Approach 2 (analogy):** a **mail-sorting + flagging** line. The decoder is the sorter that reads
each envelope and writes the sender/subject on a standard slip (fields). The rule is the inspector
who flags slips matching a watch-condition ("10 angry letters from one address this hour" =
frequency). **Where it breaks down:** the inspector can also remember across letters (state) — more
than a simple per-item check.

### Visual (ASCII) — decode → rule → alert
```
 RAW: "...sshd: Failed password for admin from 10.0.0.99..."
        │ DECODER → {program:sshd, srcuser:admin, srcip:10.0.0.99}
        ▼
 RULE 5710 (level 5, group authentication_failed)  → ALERT
        │ FREQUENCY child rule: if 8× rule 5710, same srcip, 60s
        ▼
 RULE 100100 (level 10, "SSH brute force") → high-sev ALERT → (optional) active response
```

---

## §2 — Linux Investigation Commands

```bash
# TEST a rule/decoder against a sample line (the core loop — do this before deploying)
/var/ossec/bin/wazuh-logtest
# (paste:)  Jun 20 02:14 web01 sshd[1]: Failed password for admin from 10.0.0.99 port 1 ssh2
#  → shows: which decoder, extracted fields, which rule matched, the level

# files you edit (custom only)
sudoedit /var/ossec/etc/rules/local_rules.xml
sudoedit /var/ossec/etc/decoders/local_decoders.xml
/var/ossec/bin/wazuh-control restart        # apply (lab)
grep -E "rule id|level" /var/ossec/logs/alerts/alerts.json | tail   # see fired rules
```
| Task | Wazuh tool |
|---|---|
| test decode + rule | `wazuh-logtest` |
| custom rule | `local_rules.xml` (`<rule id="100xxx">`) |
| custom decoder | `local_decoders.xml` |
| frequency/correlation | `<frequency>` + `<timeframe>` + `<same_source_ip/>` |

---

## §3 — Real-World Threat Context & Use Cases

- **Tailor detections:** raise/lower thresholds, add environment-specific rules (service account
  interactive login = TP).
- **Parse custom apps:** write a decoder for an app's log so its events become detectable.
- **Build correlation:** frequency rules turn many low-sev events into one high-sev incident (brute
  force, scan).
- **Tune false positives:** override/adjust a noisy built-in rule with a local rule (Lesson 17/26).
- **Exam framing:** rule/correlation logic + tuning are core CySA+/BTL1/SC-200 (analytics rules)
  topics.

---

## §4 — Detection

This lesson *is* "how to build a detection in Wazuh." The pattern (used in Lessons 18–24):
1. Identify the log source + the field signal (Linux-first, Lessons 04–05).
2. Confirm the decoder extracts the field (`wazuh-logtest`).
3. Write the rule (match + level + group), or a **frequency** child for behavior.
4. **Test** it fires on the (lab) signal and is quiet on benign data.
5. Deploy + verify in `alerts.json`/dashboard; map to ATT&CK (Lesson 10).
A detection isn't done until step 4 passes — untested rules are `DRAFT` (`docs/detections/`).

---

## §5 — Investigation & Triage

Knowing the rule that fired (id/level/group) is the start of triage: the rule's intent tells you
what the SIEM thinks happened; you then validate against the raw event (does the decode look right?
is it a true match?). Misfiring rules are a triage outcome too → tune (Lesson 17).

---

## §6 — SOC Perspective

Rule levels map to severity → the SOC's alerting + escalation thresholds (e.g. level ≥10 pages T2).
Groups drive dashboards. The custom rule set (`local_rules.xml`) is version-controlled detection
content — the SOC's intellectual property and the detection engineer's portfolio (Lesson 32).

---

## §7 — Incident-Response Perspective

A good frequency/correlation rule *is* early detection — it turns the slow drip of an attack into a
single timely alert, cutting MTTD. After an incident (Phase 6), the new/tuned rule you write here is
the permanent improvement. The capstone's "new detection" deliverable is a Wazuh rule.

---

## §8 — Practical Lab (build this yourself)

**Goal:** write, test, and deploy your first custom Wazuh rule — a tuned SSH brute-force frequency
rule.

### Lens C — Manual → Automated → Why
- **Manual:** your Lesson 05 `awk` threshold found brute force on one box, once.
- **Automated:** the same logic as a Wazuh **frequency rule** runs continuously across all agents
  and alerts in real time.
- **Why:** porting a tested one-liner into a SIEM rule is the detection-engineer move — write once,
  detect everywhere, forever.

### Steps
1. In `wazuh-logtest`, paste a failed-login line; confirm it decodes to `srcip`/`srcuser` and
   matches rule 5710.
2. Write a custom frequency rule in `infra/wazuh/local_rules.xml` (then deploy from there):
   ```xml
   <group name="local,syslog,sshd,">
     <rule id="100100" level="10" frequency="8" timeframe="60">
       <if_matched_sid>5710</if_matched_sid>
       <same_source_ip />
       <description>SSH brute force: 8+ failed logins from same source in 60s (T1110)</description>
       <group>authentication_failures,attack,</group>
     </rule>
   </group>
   ```
3. Restart Wazuh (lab), generate ≥8 failed logins from one IP (drill 2), and confirm rule 100100
   fires at level 10 in `alerts.json`/dashboard.
4. **Tune test:** generate a few *legitimate* failed logins (typos) below the threshold — confirm it
   does *not* fire. Document the FP reasoning.
5. Commit the rule (sanitized) + map it to ATT&CK T1110 in `docs/detections/attack-coverage.md`.

### Lens D — the raw artifact
```
# wazuh-logtest output (proof the decode+rule work BEFORE deploying):
**Phase 2: decoder 'sshd'  → srcip:'10.0.0.99', srcuser:'admin'
**Phase 3: Rule id:'5710' level:'5'  ... (then your 100100 fires after 8 in 60s)
```

---

## §9 — GitHub Artifact (the 6-artifact evidence package)

1. **Script:** `scripts/rule_test.sh` — pipe sample lines through `wazuh-logtest` for regression
   testing of your rules.
2. **Detection rule/config:** `infra/wazuh/local_rules.xml` (+ `local_decoders.xml` if needed),
   committed.
3. **Runbook:** `docs/runbooks/runbook-ssh-bruteforce.md` — "when rule 100100 fires, do X."
4. **Playbook:** the write→test→tune→deploy detection play.
5. **Incident report + notes:** the rule firing on the drill (TP) + the tune test (no FP) + notes.
6. **SOC ticket:** `SOC-15` (Task: "custom brute-force rule, tested + tuned") → Closed.

---

## §10 — Portfolio Artifact

- **Resume bullet:** "Authored + tested custom Wazuh detection rules (incl. an SSH brute-force
  frequency rule, T1110), validated with `wazuh-logtest`, and tuned out false positives."
- **Interview talking point:** explain decoder vs rule and how a frequency rule detects *behavior*;
  show your `local_rules.xml`. This is detection engineering, demonstrated.
- **Serves:** SOC T1 → Detection Engineer (Stages 2–4). Foundation of Lesson 32.

---

## §11 — Certification Crossover Notes

- **CySA+:** detection/analytics. **SC-200:** analytics rules (Sentinel analog). **BTL1:**
  detections. **Security+:** monitoring (4.x). Detail: `alignment/CERTIFICATION-MAPPING.md`.

---

## §12 — Security Notes (Lens E — Attacker & Defender)

**🔴 Attacker:** stay under frequency thresholds (low-and-slow / distributed brute force from many
IPs to beat `same_source_ip`), or use a technique you have no rule for (coverage gap).

**🔵 Defender:** layer rules — `same_source_ip` *and* `same_user`/aggregate to catch distributed
attacks; widen timeframes to catch low-and-slow; close coverage gaps (Lesson 10). Test rules
against evasion, not just the happy path. Tuned, layered rules beat single-condition ones.

---

## Quiz (Interview-Style, Graded)

**Q1.** What's the difference between a Wazuh decoder and a rule, and why does the decoder come
first?
> **Your answer:**

**Q2.** Explain rule level, group, and `if_sid`/`if_matched_sid`. What does a frequency rule add?
> **Your answer:**

**Q3.** Why edit `local_rules.xml` rather than the shipped rules, and why test with `wazuh-logtest`
before deploying?
> **Your answer:**

**Q4.** **Scenario:** your brute-force rule keyed on `same_source_ip` misses an attack. What kind of
attack, and how do you adjust the rule?
> **Your answer:**

**Q5.** How would you tune a rule that's firing on legitimate failed logins (typos) without going
blind to real brute force?
> **Your answer:**

*(Request the "Professional Answer" comparison under each before moving on.)*

---

## Reflection
*(After the quiz)* — What did you learn? · What confused you? · What would you do differently?

---

## Search Keywords For Further Understanding

**Core**
- `wazuh custom rules local_rules.xml`
- `wazuh decoders local_decoders.xml`
- `wazuh frequency correlation rule same_source_ip`
- `wazuh rule levels groups if_sid`
- `wazuh-logtest test rule`

**Tools**
- `wazuh ruleset syntax`
- `wazuh brute force rule`

**Going further**
- `log analysis workflows` (L16) · `alert triage tuning` (L17) · `detection engineering` (L26) · `sigma` (L27)

**Red / Blue (Lens E):**
- 🔴 `distributed brute force evade same_source_ip`, `low and slow`, `coverage gap`
- 🔵 `layered frequency rules`, `evasion-aware tuning`, `att&ck rule mapping`

---

## Lesson Status
- [ ] §8 lab completed (custom rule written, tested firing + tuned no-FP, deployed)
- [ ] 6-artifact evidence package committed (§9)
- [ ] Quiz answered + professional-answer comparisons (graded)
- [ ] Reflection + Search Keywords reviewed

When complete, run the Update Protocol, then move to **Lesson 16 — Log-Analysis Workflows**.

---

*Lesson 15 written by Navi · 2026-06-20 · full-depth. Sources to cite at study time: Wazuh
ruleset/decoder documentation, `wazuh-logtest` docs, MITRE T1110.*
