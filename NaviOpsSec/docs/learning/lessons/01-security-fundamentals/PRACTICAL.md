# Lesson 01 — Pure Practical: Security Fundamentals

> **Companion to [`README.md`](./README.md)** (§8 Practical Lab is the single build; this file is pure
> practice: 3 scenario tasks, guided → ticket-driven → on-call). Do them after the README.
>
> **Lab:** `./infra/bootstrap.sh up` (Wazuh SIEM + `siem-victim`). Dashboard **https://localhost:8443**
> (`admin`/`SecretPassword` — change it). Manager: `docker exec -it wazuh.manager bash` · Victim:
> `docker exec -it siem-victim bash`. Rule tests: `wazuh-logtest`. **Rules:** evidence before verdict,
> run the ✅ **Verify** after each task. Reports → `docs/learning/reports/`.

Each task: **Scenario · Objective · Given/constraints · Hints · ✅ Verify · Pitfalls · 🎯 Stretch.**

---

## Task 1 — Guided: baseline the security posture of a host (fluency)

**Scenario.** `SOC-011`. Before you can spot "abnormal", you need "normal". Baseline the victim: users,
listening services, running processes, and auth config.

**Objective.** A written baseline of `siem-victim`'s attack surface + auth posture.

**Given / constraints.** Read-only enumeration inside the victim.

**Hints.**
1. Surface: `ss -tulpn` (listeners), `ps auxf` (processes), `getent passwd` (accounts).
2. Auth posture: SSH config, sudoers, password policy.
3. Save the baseline for later diffing.

✅ **Verify.**
```bash
docker exec siem-victim sh -c 'ss -tulpn | grep -q . && getent passwd | grep -q root' && echo "BASELINE DATA ✅"
test -f docs/learning/reports/SOC-011-baseline.md && echo "BASELINE WRITTEN ✅"
```

**Pitfalls.**
- No baseline → every later "anomaly" is a guess.
- Confusing exposed (0.0.0.0) vs local (127.0.0.1) listeners.
- Ignoring the auth config (the real attack surface).

🎯 **Stretch.** Score the surface against a CIS-style checklist; list the top 3 hardening wins.

---

## Task 2 — Ticket-driven: "is this host exposed?" (diagnose → assess)

**Scenario.** `SOC-012` (P3). *"Security asks: what's this box exposed to and how risky is it?"* Assess
and prioritize.

**Objective.** Enumerate exposure, rate each finding (likelihood × impact), and recommend fixes —
evidence-based.

**Given / constraints.** Recreate an exposure (a service on 0.0.0.0, a weak SSH setting). Rate, don't
just list.

**Hints.**
1. Which services face outward? Which auth paths are weak (password login, root SSH)?
2. Rate each: exploitability × impact.
3. Prioritized recommendations.

✅ **Verify.**
```bash
docker exec siem-victim ss -tulpn | grep -E '0.0.0.0|\*:' | grep -q . && echo "EXPOSURE FOUND ✅"
test -f docs/learning/reports/SOC-012-exposure.md && echo "ASSESSMENT ✅"
```

**Deliverable.** `docs/learning/reports/SOC-012-exposure.md`: findings · risk rating · prioritized fixes.

**Pitfalls.**
- Listing findings without risk ratings (unactionable).
- Treating all findings as equal severity.
- Missing auth weaknesses (focusing only on ports).

🎯 **Stretch.** Map each finding to a CIA impact (confidentiality/integrity/availability).

---

## Task 3 — On-call: first-hour triage of a "something's wrong" report (synthesis)

**Scenario.** `SOC-013` (P1, time-boxed). Vague report: "the server is acting weird." Apply
fundamentals to quickly determine if it's a security event, contain if needed, and document.

**Objective.** Rapidly assess for compromise indicators, reach a preliminary verdict with evidence, and
write a first-hour note.

**Given / constraints.** Plant a subtle indicator (odd process/cron/user). Timebox 15 min; preserve
evidence.

**Hints.**
1. Quick sweep: new users, odd processes/listeners, unexpected cron, recent file changes.
2. Corroborate before concluding.
3. Contain (disable, don't wipe) if a real indicator is found; document.

✅ **Verify.**
```bash
grep -qiE 'verdict|indicator' docs/learning/reports/SOC-013-first-hour.md && echo "FIRST-HOUR NOTE ✅"
```

**Deliverable.** `docs/learning/reports/SOC-013-first-hour.md`: what checked · evidence · preliminary verdict · next steps.

**Pitfalls.**
- Declaring compromise (or "all clear") without evidence.
- Wiping/rebooting → destroys volatile evidence.
- Not writing anything down in the first hour.

🎯 **Stretch.** Turn the sweep into a reusable triage checklist for the SOC.

---

## Done?
- [ ] All ✅ Verify pass · [ ] baseline before anomaly-hunting · [ ] evidence-backed verdicts.
- [ ] **Guardrails:** change the default dashboard password; no real IoCs/IPs committed. → [README Reflection](./README.md).
