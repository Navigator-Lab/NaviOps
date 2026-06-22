# Lesson 28 — Documentation & Knowledge Bases

**Status:** ✅ ready for self-study (full depth) · **Date written:** 2026-06-21
**Schema:** 12-section IT-Support (`docs/learning/CLAUDE_TEACHING_RULES.md`)
**Focus:** the skill that multiplies every other one — **writing documentation the next person can
actually use**: runbooks, troubleshooting guides, and **KB articles**, plus the **KB lifecycle**
(create → review → retire) and **knowledge-centered service**. This lesson makes explicit the artifact
discipline the whole platform has been practicing.
**Primary artifact:** the documentation/KB playbook + a KB-quality checklist.

> **How to use this lesson:** read §1–§7, do §8 (audit + write/improve real KBs), produce §9, take the
> quiz, reflect. Then Lesson 29.

---

## §1 — Concept (Theory)

### What it is
**Documentation** in IT support is the durable, reusable record of *how things work and how to fix
them*: **runbooks** (step-by-step "when X, do Y" for techs), **troubleshooting guides** (symptom→cause→
fix, the diagnostic spine), **KB articles** (often end-user-facing self-service), **ticket notes**
(the per-incident record, L01/L15), and **incident reports/RCAs** (L31/L32). A **knowledge base (KB)**
is the searchable library of this knowledge, with a **lifecycle** (authored → reviewed → updated →
retired) so it stays accurate. The modern discipline is **Knowledge-Centered Service (KCS)**: capture
knowledge *as you solve*, not as a separate chore.

### Why it matters for support
Documentation is the **force multiplier** of a support team: a good KB **deflects tickets** (users
self-serve), **speeds resolution** (techs follow a known-good fix → FCR/MTTR, L16), enables **clean
handoffs and onboarding**, and turns one person's solution into the whole team's capability. Undocumented
knowledge lives in one tech's head — a single point of failure. Every lesson in this platform has
produced documentation precisely because **this is the meta-skill** that makes support scale.

### Three-Level Depth (Lens A)
- **Level 1 — User:** "I found the answer myself in the KB / the article actually worked."
- **Level 2 — Technician:** write the **right artifact** for the audience — runbook (tech procedure),
  troubleshooting guide (the spine), KB (plain-language self-service) — clear, accurate, and findable;
  capture knowledge **as you resolve** tickets.
- **Level 3 — Engineer/Knowledge-owner:** documentation is a **managed asset** with a **lifecycle**
  (owner, last-reviewed, review cadence, retirement of stale content), **findability** (search/structure/
  tags), and a **feedback loop** (KCS: tickets feed KB, KB deflects tickets, usage data prunes/promotes
  articles); quality is measured (deflection rate, article usage, "did this help?"). This is *why* a KB
  that isn't reviewed/owned **rots** and becomes worse than none (wrong answers erode trust).

### Two Teaching Approaches (Lens B) — write for the reader; keep it alive
**Approach 1 (technical):** good documentation matches **artifact → audience → purpose**: a **runbook**
is an ordered, verifiable procedure for a tech; a **troubleshooting guide** is the symptom→cause→fix
decision tree; a **KB article** is a plain-language, task-titled how-to for end users (or T1). All must
be **accurate, findable, owned, and reviewed** — and captured **at the point of solving** (KCS) so
knowledge accrues instead of evaporating.

**Approach 2 (analogy):** a knowledge base is a **library, not an attic**. An attic is where notes get
thrown and never found (or trusted); a library has **catalogued, titled, owned books** that are
**weeded** when out of date. A great KB article is like a good **recipe**: titled by the goal ("How to
connect to the VPN"), with prerequisites, exact steps, and what success looks like — so anyone can
follow it. **Where it breaks down:** unlike a library book, a wrong/stale IT article actively *causes*
harm (a user follows outdated steps and breaks something) — so **review/retirement** matters more than
in a library; an unmaintained KB is a liability, not just clutter.

### Visual (ASCII) — artifact → audience, and the KB lifecycle (KCS loop)
```
   ARTIFACT          AUDIENCE        PURPOSE
   Runbook        → technician     → repeatable "when X, do Y" (ordered, verifiable)
   Troubleshooting→ technician     → symptom → cause → fix (the diagnostic spine)
   KB article     → END USER / T1  → plain-language self-service how-to (deflect tickets)
   Ticket note    → next tech      → the per-incident record (L01/L15)
   Incident/RCA   → org            → what happened + prevent recurrence (L31/L32)

   KCS LIFECYCLE (keep it alive):  solve a ticket ─▶ CAPTURE/UPDATE a KB ─▶ users SELF-SERVE (deflect)
                                        ▲                                          │
                                        └────────── REVIEW (owner, cadence) ── RETIRE stale ◀── usage data
```

---

## §2 — Tools & Commands

Documentation is a craft, so the "toolkit" is standards + where artifacts live:

| Element | Standard | Lives in |
|---|---|---|
| **Templates** | use the repo templates (don't start blank) | `docs/templates/` (L0 foundation) |
| **Runbook** | trigger · ordered steps · verify each · rollback · escalate | `docs/runbooks/` |
| **Troubleshooting guide** | the diagnostic spine (Symptoms→…→Post-incident) | `docs/troubleshooting/` |
| **KB article** | task-title · audience · prereqs · numbered steps · "still stuck?" | `docs/kb/` |
| **Metadata** | **owner + last-reviewed date** on every artifact | in each doc's header |
| **Findability** | clear titles, structure, tags/search keywords | KB index + titles |
| **Quality bar** | "next person can follow it with zero help from you" | the KB checklist (this lesson) |

> The platform already lives this: every lesson ships the 6-artifact contract (`CLAUDE_TEACHING_RULES.md`
> §9). This lesson makes the **standard** explicit and adds the **lifecycle**.

---

## §3 — Real-World Support Context & Use Cases

- **Deflection + speed:** a good self-service KB (password reset, VPN, Wi-Fi, printer — KB-0001…0010)
  cuts ticket volume and raises FCR/MTTR (L16). The biggest lever a desk has after fixing root causes
  (L32).
- **Onboarding new techs:** good runbooks/guides let a new hire be productive fast — institutional
  knowledge isn't trapped in one person.
- **Handoffs & continuity:** shift handover (L16), escalation packages (L16), and incident timelines
  (L31) all depend on written records.
- **The rot problem:** an un-reviewed KB gives **wrong answers** → users break things, techs lose trust →
  worse than no KB. **Owner + review cadence** is non-negotiable.
- **KCS culture:** capture knowledge **while solving** (a ticket's good fix → a KB) rather than "I'll
  document it later" (never happens).
- **Exam framing:** ITIL (knowledge management practice — L17), A+ (Core 2 — documentation, KB, ticketing
  procedures).

---

## §4 — Demonstration (worked walkthrough)

**Watch me turn a solved ticket into a reusable KB article (KCS in action).**

> You just resolved several "I can't connect to the VPN" tickets the same way. That's a deflection
> opportunity.

1. **Spot the pattern:** repeated identical tickets → a **KB candidate** (KCS: capture as you solve).
2. **Choose the artifact + audience:** end users hit this → a **KB article** (plain language), not a
   tech runbook. (You'd *also* keep a tech troubleshooting guide for the complex cases.)
3. **Write to the standard** (template `kb-article.md`): a **task title** ("Connect to the VPN"),
   **applies-to**, **before you start** (prereqs), **numbered steps** with what success looks like, a
   **"still not working?"** section, and **owner + last-reviewed**. (This is exactly KB-0003.)
4. **Make it findable:** clear title + keywords; link it from related KBs and from the ticket's closing
   note.
5. **Close the loop:** point future tickets at it; if the steps change (new VPN client), **update** it;
   set a **review date**.
6. **Result:** the next VPN ticket either self-deflects or resolves in one link — one solve, multiplied.

The teaching point: **capture knowledge at the moment of solving, write it for the reader, and keep it
alive (owner + review)** — that's what turns documentation from a chore into the team's force multiplier.

---

## §5 — Troubleshooting Workflow (the diagnostic spine)

**Problem class: documentation/KB problems (a KB that doesn't help — the meta-troubleshooting).**

### 1 · Symptoms
Users can't self-serve (volume stays high) · techs can't find the fix (low FCR) · articles give **wrong/
outdated** steps · duplicate/conflicting articles · "tribal knowledge" (only one person knows) · no one
updates the KB.

### 2 · Possible Causes (most-likely first)
1. **Stale/un-reviewed content** (no owner/review cadence) → wrong answers.
2. **Poor findability** (bad titles/structure/search) → exists but unused.
3. **Wrong artifact/audience** (a tech runbook where users need a plain KB, or vice-versa).
4. **Knowledge not captured** (solved but never documented — no KCS).
5. **Duplicates/conflicts** (multiple articles, unclear which is right).
6. **No quality standard** (incomplete steps → users get stuck/call anyway).

### 3 · Diagnostic Steps (ordered)
| # | Check | If… | …then |
|---|---|---|---|
| 1 | Does the article have an owner + recent review? | no/stale | assign owner + review/update/retire |
| 2 | Can a user actually find it (title/search)? | no | fix title/keywords/structure |
| 3 | Right audience/artifact for the need? | mismatched | rewrite as KB (user) or runbook (tech) |
| 4 | Is recurring knowledge captured at all? | no | start KCS (capture on solve) |
| 5 | Duplicates/conflicts? | yes | merge to one source of truth, retire others |
| 6 | Can the next person follow it with zero help? | no | apply the quality checklist |

### 4 · Resolution Steps
Assign an **owner + review date** and update/retire stale content; fix **findability** (titles, keywords,
structure); match **artifact to audience**; institute **KCS** (capture on solve, link from ticket
closures); **merge duplicates** to a single source of truth; apply the **KB quality checklist** so every
article is complete + followable.

### 5 · Escalation Criteria
Escalate to the **knowledge owner / service-desk lead** for: standing up a KB lifecycle/KCS program,
KB-tool/search problems, and ownership/review-cadence policy. A chronically rotting KB is a **Problem**
(L32) to fix at the process level, not article-by-article. Sensitive content (internal-only) must not be
published to a user-facing KB (security, L29).

### 6 · Post-Incident Documentation
This lesson *is* documentation — the deliverables are the **playbook + quality checklist** + improved KB
articles; the meta-fix (lifecycle/KCS) is a continual-improvement action (L16) and possibly a Problem
record (L32).

---

## §6 — Ticket Simulation

> **Ticket ENT-28 / scenario (P3 meta):** *"Half our KB articles are out of date — users follow them and
> make things worse, and techs don't trust the KB so they ask each other instead. Fix our knowledge
> base."* You own the response.

**Triage:** a **KB-rot + no-lifecycle** problem (the §5 failure modes at once). Article-by-article fixes
won't hold — the **process** (ownership, review, KCS) is the real fix. This is a Problem (L32), not a
ticket.

**Worked resolution (fix the system, not just the symptoms):**
1. **Audit the KB:** inventory articles → flag **stale** (no recent review), **orphaned** (no owner),
   **duplicate/conflicting**, and **wrong-audience** ones. Quick triage: keep / update / merge / retire.
2. **Stop the harm first:** **retire or clearly flag** the actively-wrong articles immediately (a wrong
   article is worse than none — it breaks user trust and machines).
3. **Assign ownership + a review cadence:** every surviving article gets an **owner** and a
   **last-reviewed/next-review** date — the single change that prevents rot.
4. **Set the quality bar:** apply the **KB quality checklist** (task title, prereqs, exact numbered
   steps, success criteria, "still stuck?", owner/date) to the keepers; rewrite the close-but-incomplete
   ones.
5. **Institute KCS:** make capturing/updating a KB **part of resolving tickets** (link the KB in the
   closing note; "fix once, document once"), so the KB stays current as a byproduct of work (L16).
6. **Rebuild trust + measure:** announce the cleaned KB; track **deflection + article usage + "did this
   help?"** to prune/promote going forward.

**The professional note:**
```
SUMMARY: KB was rotting (stale/orphaned/duplicate articles → users misled, techs distrust it). Audited +
triaged all articles (keep/update/merge/retire); retired actively-wrong ones immediately; assigned owners
+ review cadence to keepers; applied a quality checklist; instituted KCS (capture/update on solve).
PROBLEM: no KB lifecycle/ownership → rot → wrong answers + low trust → high volume/low FCR.
ACTIONS: KB audit (flag stale/orphan/dup/wrong-audience); retired/flagged wrong articles; assigned
owner + last-/next-review to each keeper; rewrote to the quality checklist; linked KB in ticket closures
(KCS); set deflection/usage metrics.
RESULT: trustworthy, owned, current KB; knowledge captured as a byproduct of solving.
FOLLOW-UP (Problem/L32 + improvement/L16): quarterly review cadence; KCS adoption tracked; deflection +
"did this help?" metrics drive prune/promote. Sensitive content kept internal (not user-facing, L29).
```

---

## §7 — Service Desk / ITIL Perspective

- **Knowledge management is an ITIL practice** (L17) and the force multiplier behind **FCR/MTTR/
  deflection** (L16): the KB is how a desk scales without linearly adding people.
- **KCS (Knowledge-Centered Service)** is the operating model — capture/update knowledge **while
  resolving**, so the KB grows from real work and deflects future tickets (a virtuous loop).
- **Lifecycle (owner + review + retire)** is what separates a trusted KB from a liability — un-reviewed
  knowledge management actively harms (wrong answers).
- **Every other lesson feeds this:** runbooks, troubleshooting guides, KB articles, incident reports
  (L31), RCAs (L32) — documentation is the connective tissue of the whole service-desk practice.
- **Metric/risk angle:** deflection rate, FCR uplift, article usage/feedback, and "tribal knowledge"
  reduction (bus-factor) are the measures; stale content is a tracked risk.

---

## §8 — Practical Lab (build this yourself)

**Goal:** make documentation a deliberate, lifecycle-managed practice — and prove your KBs are followable.

### Lens C — Manual → Automation/Systematize → Why
- **Manual:** write articles ad-hoc, whenever someone remembers.
- **Systematized:** **templates** (don't start blank), a **KB index** with owners + review dates, a
  **quality checklist**, and **KCS** (capture-on-solve baked into the ticket workflow); usage data to
  prune/promote.
- **Why:** ad-hoc docs rot and go unfound; a systematized lifecycle keeps knowledge accurate, findable,
  and growing — turning documentation from a chore into a compounding asset (the FCR/deflection lever).

### Steps
1. **Audit your own KB:** review `docs/kb/INDEX.md` + articles — does each have an **owner +
   last-reviewed**? Flag any stale/incomplete.
2. **Write/improve to the standard:** take a real recurring issue (e.g. KB-0004 Wi-Fi or KB-0005 email —
   drafted inline earlier) and produce a polished, **followable** KB article from the template.
3. **Apply the quality checklist** (below) to it: task title? audience? prereqs? exact steps? success
   criteria? "still stuck?" owner/date?
4. **KCS drill:** take one of your worked tickets (ENT-…) and capture its fix as a KB — link it from the
   ticket's closing note (capture-on-solve).
5. **Findability:** confirm titles + keywords make it discoverable; link related articles.
6. **Write the documentation/KB playbook** (`docs/learning/playbooks/` or a runbook) + the **KB quality
   checklist** as reusable standards.

### Lens D — the raw artifact (the KB quality checklist)
```
   KB QUALITY CHECKLIST (an article isn't "done" until all are YES):
   [ ] Title is the USER'S GOAL ("How to connect to the VPN"), not a system name
   [ ] Audience stated (end user vs T1 tech) → language matches
   [ ] "Before you start" lists prerequisites
   [ ] Steps are numbered, EXACT, and say what SUCCESS looks like
   [ ] "Still not working?" → self-checks + how to contact the desk (what info to give)
   [ ] OWNER + LAST-REVIEWED date present (lifecycle)
   [ ] No sensitive/internal data in a user-facing article (security, L29)
   [ ] A non-expert could follow it with ZERO help from you  ← the real test
#   The last line is the whole standard. If the next person needs to ask you a question, it's not done.
```

---

## §9 — GitHub Artifact (the 6-artifact evidence package)

1. **Runbook/Playbook:** `docs/learning/playbooks/DOCUMENTATION-PLAYBOOK.md` — artifact→audience, the KB
   lifecycle, and KCS.
2. **Troubleshooting Guide:** `docs/troubleshooting/kb-not-helping.md` — the meta spine (rot/findability/
   audience/capture/duplicates).
3. **Ticket Notes:** `docs/tickets/ENT-28-kb-rot-fix.md` — the worked ENT-28 (KB-rot Problem).
4. **KB Article:** a newly polished, checklist-passing KB (e.g. finalize KB-0004 Wi-Fi) — the example
   deliverable.
5. **Incident Report:** N/A (this *is* the documentation lesson); the **KB quality checklist** is the
   centerpiece artifact.
6. **Portfolio Artifact:** §10 bullet + the KCS / lifecycle / quality-checklist talking points.
7. **Standard:** the **KB quality checklist** + a KB-index convention (owner + review dates).

---

## §10 — Portfolio Artifact

- **Resume bullet:** *"Built and maintained a knowledge base under a KCS model — authoring runbooks,
  troubleshooting guides, and end-user KB articles to a quality standard (owner + review cadence) that
  increased self-service deflection and first-contact resolution, and remediated a rotting KB by
  retiring/owning/refreshing content."*
- **Interview talking point:** documentation as the **force multiplier** (deflection + FCR), the
  **artifact→audience** match (runbook vs KB), **KCS** (capture-on-solve), and the **lifecycle**
  (owner/review/retire) that keeps a KB trustworthy — plus "a wrong article is worse than none."
- **Serves:** every role; especially IT Support, Junior SysAdmin, and a team-lead path.

---

## §11 — Certification Crossover Notes

- **ITIL 4 Foundation:** knowledge management practice (L17). **CompTIA A+ (Core 2):** documentation,
  knowledge bases, ticketing/operational procedures. Detail in `alignment/CERTIFICATION-MAPPING.md`.

---

## §12 — Support Notes (Lens E — Service & Security)

**🤝 Service:** documentation *is* service at scale — a clear self-service article respects the user's
time and a good runbook means consistent, quality help regardless of which tech they get. Write with
empathy for the reader (plain language, no unexplained jargon).

**🔒 Security:** the KB is a **data-classification surface** — never put **passwords, secrets, internal
IPs/architecture, or sensitive procedures** in a **user-facing** article (keep those in internal,
access-controlled docs); sanitize examples (placeholders — `navi.project.md` HR#1). Stale security
guidance is dangerous (e.g. an old "how to" that bypasses a current control). Documentation also supports
**incident response** (runbooks/RCAs, L31/L32) and **audit** — accurate records are a compliance asset.

---

## Quiz (Interview-Style, Graded)

**Q1.** What makes a KB article good? Name the elements and the single real test of quality.
> **Your answer:**

**Q2.** What's the difference between a runbook, a troubleshooting guide, and a KB article — and who's the
audience for each?
> **Your answer:**

**Q3.** Why is an out-of-date KB article worse than not having one?
> **Your answer:**

**Q4.** **Scenario:** the team's KB is full of stale, untrusted articles and people ask each other instead.
How do you fix it — and make sure it doesn't rot again?
> **Your answer:**

**Q5.** What is KCS (Knowledge-Centered Service) and why does "document it later" usually fail?
> **Your answer:**

*(Request the "Professional Answer" comparison under each before moving on.)*

---

## Reflection
*(After the quiz)* — What did you learn? · What confused you? · What would you do differently?

---

## Search Keywords For Further Understanding

**Core**
- `knowledge centered service KCS basics`
- `how to write a good KB article`
- `runbook vs knowledge base article`
- `knowledge base lifecycle review retire`
- `self-service deflection IT support`

**Tools**
- `documentation templates IT`
- `KB metrics deflection usage feedback`

**Going further**
- `security awareness for IT support` (L29) · `incident management` (L31) · `root cause analysis` (L32) ·
  `help-desk workflows` (L16) · `ITIL knowledge management` (L17)

**Service / Security (Lens E):**
- 🤝 `write KB for non-technical users`, `documentation as service at scale`
- 🔒 `no secrets in user-facing KB`, `data classification documentation`, `stale security guidance risk`

---

## Lesson Status
- [ ] §8 lab completed (KB audit + write to standard + KCS drill + playbook + quality checklist)
- [ ] 6-artifact evidence package committed (§9)
- [ ] Quiz answered + professional-answer comparisons (graded)
- [ ] Reflection + Search Keywords reviewed

When complete, run the Update Protocol, then move to **Lesson 29 — Security Awareness for IT Support**.

---

*Lesson 28 written by Navi · 2026-06-21 · full-depth. Sources to cite at study time: ITIL 4 knowledge
management, KCS (Consortium for Service Innovation), CompTIA A+ 220-1102 documentation procedures.*
