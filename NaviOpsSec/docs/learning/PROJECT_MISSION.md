# NaviOpsSec — Project Mission (the constitution)

> The **why**. The teaching *method* lives in `CLAUDE_TEACHING_RULES.md`; the *map* (what to
> build, in what order, for which job) lives in `ROADMAP.md`; *where you are now* lives in
> `LEARNING_STATE.md`. This file is the mission they all serve.

## Mission

Turn a **Linux SysAdmin + NOC Technician** into a **Security Analyst** — and then into a **SOC
Analyst (Tier 1 → Tier 2), Security Operations Engineer, Incident Responder, or Junior Detection
Engineer** — by *building and operating a real Security-Operations capability*, lesson by lesson,
in public.

This is a **Blue-Team / Security-Operations** platform. Not a hacking course. Not a
penetration-testing course. The skill being built is **defensive**: detect, triage, investigate,
contain, eradicate, recover, and report on attacks — and engineer the detections that catch them.

## Philosophy (inherited from NaviOps / NaviOpsNetwork)

1. **Operations over exams.** Certs (Security+, CySA+, SC-200, BTL1) are *mapped*, not the goal.
   The goal is to do the job: work an alert queue, run an investigation, write the report.
2. **Build the SOC, don't read about it.** Every lesson improves a real platform — scripts,
   Wazuh rules, decoders, runbooks, playbooks, dashboards. Evidence accumulates into a portfolio.
3. **Linux-first, SIEM-second.** You must be able to investigate an incident *on the box* with
   `journalctl`/`grep`/`awk`/`auditd` before — and when — the SIEM can't help you. Then you
   express the detection in Wazuh and portable Sigma.
4. **Attacker and defender together.** You can't detect what you don't understand. Every lesson
   carries the attacker technique (MITRE ATT&CK + kill chain) *and* the defensive response — but
   all offense is **lab-only, self-owned, benign**.
5. **Evidence or it didn't happen.** A lesson is done when it produces its 6-artifact package
   (script + detection rule + runbook + playbook + incident report/notes + ticket). "Claim =
   committed evidence" — the same rule that governs the sibling platforms' resume/portfolio.

## Definitions of done

- **A lesson is done** when: all 12 sections are written, the §8 lab is performed, the
  6-artifact evidence package is committed, the quiz is answered to a professional standard
  (with the Professional-Answer comparison), and the reflection + keywords are written.
- **A milestone is done** when its lessons are done *and* it has a `PORTFOLIO.md` (resume bullets
  + interview talking points + a portfolio summary).
- **The platform is done** when the operator can: take an alert from a live Wazuh stack, triage
  it, investigate it on the box and in the SIEM, contain and recover, and produce a technical
  report + executive summary + evidence package — i.e. do a SOC analyst's job — proven by the
  capstone (Lesson 35, the compromised-server scenario).

## The bridge (why three platforms)

NaviOps (Linux/SysAdmin) + NaviOpsNetwork (Networking/NOC) + NaviOpsSec (Security Operations)
form **one career path**:

```
NOC Technician → Linux Support → Junior SysAdmin → Security Analyst → Security Operations Engineer
   (NaviOpsNetwork)   (NaviOps)        (NaviOps)        (NaviOpsSec)         (NaviOpsSec)
```

Security Operations sits on top of Linux fluency (NaviOps) and network literacy
(NaviOpsNetwork): you investigate Linux hosts, read network evidence, and reason about both to
catch an attacker. See `alignment/ROLE-MAPPING.md` for the full bridge.
