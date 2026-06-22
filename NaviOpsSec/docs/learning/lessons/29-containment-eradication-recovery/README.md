# Lesson 29 — Containment · Eradication · Recovery

**Status:** ✅ ready for self-study (full depth) · **Date written:** 2026-06-20
**Schema:** 12-section SOC (`docs/learning/CLAUDE_TEACHING_RULES.md`)
**Focus:** the active-response phase — short vs long-term containment, eradication (remove threat +
all persistence), recovery + validation, the CER playbook, and Wazuh **active response**.
**Primary artifact:** `docs/playbooks/containment-playbook.md` + Wazuh active-response config.

> **Danger zone:** containment actions (block/isolate/kill) + Wazuh active response can lock you out
> or down a service — lab-only, console fallback (`navi.project.md`). Read §1–§7, do §8, produce §9,
> quiz, reflect. Then Lesson 30.

---

## §1 — Concept (Scientific Theory)

### What it is
The action phase of IR (NIST 800-61 Phase 3):
- **Containment** — stop the incident spreading/worsening. **Short-term** (immediate: isolate host,
  block IP, kill process, disable account) vs **long-term** (temporary fixes to keep operating while
  you eradicate: segment, temp rules, rotate creds).
- **Eradication** — remove the threat + **all** persistence (Lesson 22's checklist) + close the entry
  vector.
- **Recovery** — restore to known-good, validate clean, and monitor closely for reinfection.

### Why it exists
Detection + investigation are worthless if you can't *stop* the attacker and *get back to normal
safely*. CER is where the incident actually ends — and where the two classic mistakes happen:
containing before preserving evidence (destroying the case), and recovering before eradicating
(reinfection). The lesson is doing it in the right order, completely.

### Three-Level Depth (Lens A)
- **Level 1 — Beginner:** stop the bad thing (containment), remove it for good (eradication), and get
  the system working again safely (recovery).
- **Level 2 — Analyst/SOC:** choose short vs long-term containment by the trade-off (stop-the-bleeding
  vs preserve-evidence/keep-operating); eradicate by the full persistence checklist (Lesson 22) +
  close the vector; recover from known-good (rebuild > clean when unsure) and *validate* (FIM, IOC
  re-sweep, heightened monitoring).
- **Level 3 — Adversary/Kernel:** the order is the skill: **preserve (L28) → contain → eradicate →
  recover**, and *validate* eradication before recovery (FIM clean, IOCs gone, no persistence).
  Automated containment (Wazuh **active response**: firewall-drop, disable-account, kill-process) cuts
  MTTR but risks self-inflicted outage/lockout — gated to lab with fallback.

### Two Teaching Approaches (Lens B) — short vs long-term containment
**Approach 1 (technical):** containment is a trade-off optimization across {stop spread, preserve
evidence, maintain operations, avoid tipping the attacker}. Short-term maximizes "stop spread"; long-
term balances operations while eradication proceeds.

**Approach 2 (analogy):** a **disease outbreak**. Short-term containment = immediately quarantine the
patient (isolate the host). Long-term = set up a treatment ward so the hospital keeps running while
you cure it. Eradication = the cure (remove the pathogen everywhere). Recovery = discharge once
tests are clean — and watch for relapse. **Where it breaks down:** you may *deliberately* keep a
contained attacker under observation (to learn scope) — a choice quarantine medicine doesn't make.

### Visual (ASCII) — order of operations
```
 PRESERVE (L28) ─► CONTAIN ─────────────► ERADICATE ──────────► RECOVER ─────► (monitor)
  evidence first   short-term: isolate/   remove payload +      restore known-  heightened
  (or you lose     block/kill/disable     ALL persistence +     good; rebuild   detection;
   the case)       long-term: segment/    close entry vector    > clean;        re-sweep IOCs;
                   temp rules                                    VALIDATE clean  FIM clean
   ⚠ never recover before eradication is VALIDATED  → else reinfection
```

---

## §2 — Linux Investigation Commands

```bash
# CONTAINMENT (lab; console fallback!)
nft add rule inet filter input ip saddr 203.0.113.50 drop   # block the attacker IP
ip link set eth0 down            # isolate host (⚠ cuts your access too — console only)
kill -9 <malicious_pid>          # kill the process (AFTER preserving it, L28/21)
usermod -L svc_app ; passwd -l svc_app   # lock the compromised account
# ERADICATION (the persistence checklist, L22)
userdel -r svc_tmp ; crontab -r -u svc_app ; sed -i '/attacker-key/d' ~/.ssh/authorized_keys
rm -f /tmp/.x /var/www/html/x.php ; systemctl disable --now rogue.service
# RECOVERY + VALIDATION
aide --check ; bash scripts/fim_check.sh        # files clean? (L24)
bash scripts/ioc_sweep.sh ; bash scripts/user_audit.sh   # IOCs gone? persistence gone? (L12/22)
# Wazuh active response (lab) — auto-contain
grep -A10 "<active-response>" /var/ossec/etc/ossec.conf
```
| Phase | Action | Validate with |
|---|---|---|
| contain | nft drop / isolate / kill / lock | confirm stopped |
| eradicate | remove payload + persistence + vector | `user_audit.sh`, `fim_check.sh` |
| recover | restore known-good | `ioc_sweep.sh`, FIM clean, monitoring |

---

## §3 — Real-World Threat Context & Use Cases

- **The containment decision:** block now (stop spread, but tips the attacker + may lose more
  evidence) vs watch (learn scope, risk more damage) — a real T2/IR judgment call.
- **Rebuild vs clean:** for a confirmed root compromise, rebuild from known-good is safer than
  cleaning (you can't be sure you found everything).
- **Active response trade-off:** auto-block cuts MTTR but a false-positive auto-block = self-inflicted
  outage — tune carefully, lab-first.
- **Exam framing:** CER phases, containment strategies, and recovery validation on
  Security+/CySA+/SC-200/BTL1.

---

## §4 — Detection

CER closes the loop with detection: **eradication validation** uses detections (FIM clean, IOC sweep
clean, no persistence) to *prove* the threat is gone; **recovery monitoring** raises detection
sensitivity on the affected asset to catch reinfection. Wazuh **active response** is detection →
automated containment (a detection that *acts*).

---

## §5 — Investigation & Triage

CER follows investigation: you can only eradicate what investigation found (all persistence, the
entry vector). Incomplete investigation → incomplete eradication → reinfection. The validation step
*re-investigates* to confirm clean. The containment decision is informed by triage's scope + severity.

---

## §6 — SOC Perspective

T1 may take an initial containment action (block an IP per runbook); deeper CER is T2/IR. The SOC
pre-builds containment runbooks/playbooks + (carefully) active-response so MTTR is low. The recovery-
monitoring step keeps the SOC watching the asset post-incident. Maps to `soc/escalation-matrix.md`.

---

## §7 — Incident-Response Perspective

This *is* IR Phase 3. The non-negotiables: preserve before contain (L28), eradicate **completely**
(L22 checklist) and **validate** before recover, and monitor for reinfection. The capstone (Lesson 35)
requires all of it, documented. The CER playbook is the reusable artifact.

---

## §8 — Practical Lab (build this yourself)

**Goal:** run CER on a contained lab incident — in the right order, validated.

### Lens C — Manual → Automated → Why
- **Manual:** block/kill/clean by hand.
- **Automated:** a containment script + Wazuh active response (auto-block on a high-sev rule) — fast,
  consistent response.
- **Why:** speed lowers impact (MTTR); but automation risks self-outage, so it's lab-gated with
  fallback. Production uses tested active-response + SOAR.

### Steps
1. Take the L28 incident (evidence already preserved). **Contain:** `nft` drop the attacker IP, lock
   the account, kill the (already-snapshotted) process.
2. **Eradicate:** run the L22 persistence checklist — remove the rogue user, key, cron, payload,
   rogue service; close the vector (disable password SSH).
3. **Validate eradication:** `user_audit.sh` + `fim_check.sh` + `ioc_sweep.sh` all clean. Prove it.
4. **Recover:** restore service, confirm functionality, raise monitoring on the asset.
5. **Wazuh active response (lab):** configure auto-firewall-drop on your brute-force rule (Lesson 15);
   trigger it; confirm the block; then **disable it** (note the self-outage risk). Write the CER
   playbook.

### Lens D — the raw artifact
```
# the validation that gates recovery — eradication is "done" only when these are clean:
$ bash scripts/user_audit.sh    | grep -i 'svc_tmp\|UID 0 dup'   → (empty)  ✓ no rogue account
$ bash scripts/fim_check.sh     | grep -v ': OK'                 → (empty)  ✓ files restored
$ bash scripts/ioc_sweep.sh     | grep -i hit                    → (empty)  ✓ IOCs gone
# all clean → safe to recover. Any hit → keep eradicating (do NOT recover yet).
```

---

## §9 — GitHub Artifact (the 6-artifact evidence package)

1. **Script:** `scripts/contain.sh` (block/lock/kill, lab, with confirmation) — committed,
   `shellcheck`-clean.
2. **Detection rule/config:** Wazuh active-response config (`infra/wazuh/active-response.conf`,
   lab-only) tied to the brute-force rule.
3. **Runbook:** `docs/runbooks/runbook-cer.md` — the CER steps + the gates.
4. **Playbook:** `docs/playbooks/containment-playbook.md` (the deliverable).
5. **Incident report + notes:** the L28 incident now closed through recovery (with validation
   evidence) + notes.
6. **SOC ticket:** `SOC-28/29` advanced To Do → Contained → Eradicated → Closed.

---

## §10 — Portfolio Artifact

- **Resume bullet:** "Executed containment, eradication, and recovery on a simulated intrusion —
  evidence-first, complete persistence eradication, validated-clean before recovery — and configured
  Wazuh active response (lab)."
- **Interview talking point:** short vs long-term containment trade-offs, *validate before recover*,
  and the active-response self-outage risk.
- **Serves:** Incident Responder / SOC T2 (Stage 3). Capstone CER phase.

---

## §11 — Certification Crossover Notes

- **Security+:** IR/CER (4.x). **CySA+:** IR phases. **SC-200:** respond actions. **BTL1:** IR.
  Detail: `alignment/CERTIFICATION-MAPPING.md`.

---

## §12 — Security Notes (Lens E — Attacker & Defender)

**🔴 Attacker:** plant redundant persistence so partial eradication fails (they return); watch for
your containment to relocate/escalate; re-infect during a premature recovery. They exploit *incomplete*
CER.

**🔵 Defender:** eradicate by complete checklist + **validate** (FIM/IOC/persistence sweeps) before
recovery; rebuild from known-good when in doubt; monitor the recovered asset closely; use tested,
gated active response for speed. Order + completeness + validation defeat the "they came back"
failure.

---

## Quiz (Interview-Style, Graded)

**Q1.** Distinguish short-term and long-term containment with an example of each and the trade-off.
> **Your answer:**

**Q2.** Why must eradication be validated before recovery, and how do you validate it?
> **Your answer:**

**Q3.** When would you rebuild rather than clean a compromised host?
> **Your answer:**

**Q4.** **Scenario:** you've contained an intrusion. Walk eradication → recovery, naming the
validation gates, on a host with a rogue account + SSH key + cron persistence.
> **Your answer:**

**Q5.** What's the upside and the danger of Wazuh active response (auto-containment)?
> **Your answer:**

*(Request the "Professional Answer" comparison under each before moving on.)*

---

## Reflection
*(After the quiz)* — What did you learn? · What confused you? · What would you do differently?

---

## Search Keywords For Further Understanding

**Core**
- `containment eradication recovery incident response`
- `short term vs long term containment`
- `eradication validation reinfection`
- `rebuild vs clean compromised host`
- `wazuh active response`

**Tools**
- `nftables block ip`
- `wazuh active-response configuration`

**Going further**
- `report writing` (L30) · `capstone` (L35) · `detection engineering` (L26)

**Red / Blue (Lens E):**
- 🔴 `redundant persistence`, `reinfection`, `watch containment`
- 🔵 `complete eradication + validation`, `rebuild known-good`, `gated active response`, `recovery monitoring`

---

## Lesson Status
- [ ] §8 lab completed (CER run in order; eradication validated; active response tested + disabled)
- [ ] 6-artifact evidence package committed (§9)
- [ ] Quiz answered + professional-answer comparisons (graded)
- [ ] Reflection + Search Keywords reviewed

When complete, run the Update Protocol, then move to **Lesson 30 — Report Writing for Security
Analysts**.

---

*Lesson 29 written by Navi · 2026-06-20 · full-depth. Sources to cite at study time: NIST SP
800-61r2 (CER), Wazuh active-response docs, SANS IR.*
