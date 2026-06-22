# PROJECT_MISSION — NaviOpsEnterprise

> The constitution. Mission, learning philosophy, and the definitions of "done" that every lesson
> and artifact is held to. The *how to teach* lives in
> [`CLAUDE_TEACHING_RULES.md`](CLAUDE_TEACHING_RULES.md); the *what, in order* lives in
> [`ROADMAP.md`](ROADMAP.md); the *where we are* lives in [`LEARNING_STATE.md`](LEARNING_STATE.md).

## Mission

Take a motivated beginner from **zero to employable in IT support** — Help Desk Tier 1 through
Infrastructure Support Engineer — by having them **do the actual job**: work real tickets, run
real troubleshooting, and produce real documentation. The output is a public GitHub portfolio
that proves they can do the work, plus the skills to pass the interview and survive day one.

## Why this platform exists

Most "IT support" training is multiple-choice trivia that doesn't survive contact with a real
queue. Employers don't hire someone who can define DHCP; they hire someone who can take "the
internet is down" at 9am, triage it, fix it, write a clean ticket note, and not break anything
else. NaviOpsEnterprise is built around that reality: **the ticket is the unit of work, and the
artifact is the proof.**

## Learning philosophy

1. **Operations over theory.** Every concept exists to resolve a ticket or run the desk. Theory is
   the *why* behind a fix, never the destination.
2. **GUI-first, then at scale.** Learn it the way you'll do it on the floor (the console), then
   learn the PowerShell/CLI that does it for 500 users, then the cloud admin center. (D3)
3. **The diagnostic spine, every time.** Symptoms → Possible Causes → Diagnostic Steps →
   Resolution Steps → Escalation Criteria → Post-Incident Documentation. This habit *is* the job.
4. **Build the evidence as you learn.** Each lesson ships a runbook, a troubleshooting guide,
   ticket notes, a KB article, an incident report, and a portfolio artifact — the 6-artifact
   contract. The portfolio is a byproduct of learning, not a separate chore.
5. **Service + security mindset from Lesson 01.** Communicate clearly, set expectations, document
   for the next tech; verify identity, apply least privilege, and recognize social engineering.
6. **Understanding over button-pushing.** Lens A always reaches Level 3 (what's actually happening
   underneath) so the operator can troubleshoot a problem they've never seen before.

## Who this is for

- A career-changer or new grad targeting their first IT/help-desk role.
- A help-desk tech wanting to level up to IT Support Specialist / Desktop Support / Junior
  SysAdmin.
- Anyone who needs a **portfolio that proves operational ability**, not just a certificate.

## Definitions of Done

**A lesson is done when:**
- `lessons/NN-<topic>/README.md` covers all 12 sections + the Integration Lenses.
- The diagnostic spine (Symptoms → … → Post-Incident Docs) is present and concrete in §5.
- The **6-artifact evidence package** is produced and committed (runbook, troubleshooting guide,
  ticket notes, KB article, incident report, portfolio artifact) plus a script where automatable.
- The **quiz** is answered to a professional standard (with the Professional-Answer comparisons).
- `LEARNING_STATE.md`, CHANGELOG/STATUS/TODO, and any alignment matrix are updated.

**A milestone is done when:** a `lessons/<milestone>/PORTFOLIO.md` rolls up the resume bullets,
interview talking points, and portfolio summary for the module.

**The platform is done (v1) when:** all 36 lessons are complete, the ticket library holds 100+
realistic tickets, the KB holds the named articles, and the three capstones each produce a
hireable portfolio package.

## Non-goals

- Not a certification brain-dump (though it maps to A+/Network+/MS-900/MD-102/ITIL).
- Not penetration testing or offensive security (that's the sibling NaviOpsSec).
- Not deep DevOps/cloud engineering (that's NaviOps); this is the **support** on-ramp to it.

## The bridge

NaviOpsEnterprise is the **front door** of a four-platform career path:

```
NaviOpsEnterprise → NaviOps      → NaviOpsNetwork → NaviOpsSec
(IT support /        (Linux /       (networking /     (security ops /
 service desk)        sysadmin)      NOC)              SOC)
Help Desk → IT Support → Junior SysAdmin → NOC/Infra → Security Analyst
```

Detail in [`alignment/ROLE-MAPPING.md`](alignment/ROLE-MAPPING.md).
