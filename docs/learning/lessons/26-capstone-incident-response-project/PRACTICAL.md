# Lesson 26 — Pure Practical: Capstone — Incident Response Project

> **Companion to [`README.md`](./README.md).** This capstone is *already* practical — this file adds 3
> full end-to-end incident drills that combine skills from Lessons 01–25. Guided → ticket-driven → on-call.
>
> **Lab:** the full stack (`./infra/bootstrap.sh all`). **Rules:** you are Incident Commander; work the
> incident, then write the postmortem. Run ✅ **Verify** after each.

Each task: **Scenario · Objective · Given/constraints · Hints · ✅ Verify · Pitfalls · 🎯 Stretch.**

---

## Task 1 — Guided: dry-run the IR playbook on a known failure (fluency)

**Scenario.** `NAVI-261`. Before a real page, rehearse the IR process on a *known* failure (a stopped
service) so the steps become muscle memory: detect → triage → mitigate → verify → document.

**Objective.** Execute the 5-step IR loop on a planted, known failure and produce a clean postmortem.

**Given / constraints.** Stop a monitored service. Follow the loop in order; don't skip detection.

**Hints.**
1. Detect from monitoring (alert/`up==0`), not by already knowing what you broke.
2. Triage: scope + severity. Mitigate: restart/fix. Verify: ✅ check. Document.
3. Time each phase → you'll reuse MTTD/MTTR later.

✅ **Verify.**
```bash
systemctl is-active <svc> 2>/dev/null || curl -sf localhost:<port> >/dev/null && echo "RECOVERED ✅"
test -f docs/learning/reports/NAVI-261-postmortem.md && echo "POSTMORTEM ✅"
```

**Pitfalls.**
- Skipping detection ("I know what's wrong") — defeats the rehearsal.
- No timing → can't measure improvement.
- Fixing without a verify step.

🎯 **Stretch.** Turn the loop into a one-page runbook others could follow cold.

---

## Task 2 — Ticket-driven: unknown-cause incident (diagnose end to end)

**Scenario.** `NAVI-262` (P1). An alert fires; you do **not** know the cause (a peer planted it, or use
a random drill from `troubleshooting-drills.md`). Work it blind.

**Objective.** Find the true root cause across layers (service/network/disk/security), mitigate, verify,
and document — no prior knowledge of the fault.

**Given / constraints.** Genuinely unknown fault. Timebox 20 min. Correlate signals; don't guess-fix.

**Hints.**
1. Start broad: health of services, disk, load, network, recent changes (`journalctl --since`, git log).
2. Form a hypothesis, test it cheaply, confirm before acting.
3. Mitigate minimally; verify recovery; capture the timeline as you go (you'll forget later).

✅ **Verify.**
```bash
# app/service healthy again:
curl -sf localhost:<port> >/dev/null || systemctl is-active <svc> && echo "RESOLVED ✅"
grep -qi 'root cause' docs/learning/reports/NAVI-262-postmortem.md && echo "ROOT CAUSE NAMED ✅"
```

**Deliverable.** `docs/learning/reports/NAVI-262-postmortem.md`: Impact · Timeline · Detection · Root cause · Resolution · Prevention.

**Pitfalls.**
- Jumping to a fix before confirming the cause → treats a symptom.
- Not writing the timeline live → inaccurate postmortem.
- Tunnel vision on one layer.

🎯 **Stretch.** Add a detection improvement that would have caught this faster; implement it (alert/check).

---

## Task 3 — On-call: multi-failure game day (synthesis)

**Scenario.** `NAVI-263` (P1, time-boxed). Two independent failures at once (e.g. disk full + a security
alert). Prioritize, delegate mentally (IC role), resolve both, and run a blameless review.

**Objective.** Triage competing incidents by impact, resolve both without letting one worsen the other,
and produce a game-day report with MTTD/MTTR and action items.

**Given / constraints.** Two planted, unrelated failures. Timebox 25 min. Explicitly prioritize; note
the reasoning.

**Hints.**
1. Severity/impact triage first — which one is hurting users more *now*?
2. Contain the worse one; ensure your fix for A doesn't aggravate B.
3. Blameless review: what went well, what was slow, concrete action items with owners.

✅ **Verify.**
```bash
# both conditions cleared:
df -h / | awk 'NR==2{print $5}'      # under threshold
grep -qiE 'action item|mttr|mttd' docs/learning/reports/NAVI-263-postmortem.md && echo "GAME-DAY REPORT ✅"
```

**Deliverable.** `docs/learning/reports/NAVI-263-postmortem.md`: both incidents' timelines · prioritization rationale · MTTD/MTTR · action items.

**Pitfalls.**
- Working the *interesting* incident instead of the *impactful* one.
- Letting incident A's fix cause incident B to worsen.
- A blameful review → people hide problems next time.

🎯 **Stretch.** Schedule this as a recurring "game day" and track MTTR improvement over runs.

---

## Done?
- [ ] All ✅ Verify pass · [ ] worked detection→postmortem each time · [ ] blameless reviews with action items.
- [ ] **Redaction:** no real data in reports. → [README Step 7](./README.md).
