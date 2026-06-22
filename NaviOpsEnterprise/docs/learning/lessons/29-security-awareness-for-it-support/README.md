# Lesson 29 — Security Awareness for IT Support

**Status:** ✅ ready for self-study (full depth) · **Date written:** 2026-06-21
**Schema:** 12-section IT-Support (`docs/learning/CLAUDE_TEACHING_RULES.md`)
**Focus:** the security responsibilities a support tech carries every day — **identity verification**,
recognizing **phishing / social engineering / MFA fatigue / pretexting**, **least privilege**, **data
handling**, and **what to do when a user is compromised**. The desk is a top attack target; this lesson
consolidates the 🔒 thread that's run through every lesson into a coherent defensive posture and the
**bridge to NaviOpsSec**.
**Primary artifact:** the security-awareness KB + the "suspected compromise" incident runbook.

> **How to use this lesson:** read §1–§7, do §8 (run identity-verification + phishing-triage + a
> compromise drill), produce §9, take the quiz, reflect. Then Lesson 30.

---

## §1 — Concept (Theory)

### What it is
**Security awareness for IT support** is the set of defensive practices a help-desk/IT tech must apply
because **the support desk is a primary attack target and a privileged access point**. It covers:
**verifying identity** before any account action (the front line — L21), recognizing **social
engineering** (phishing, vishing, pretexting, **MFA fatigue**, impersonating users *or* IT), enforcing
**least privilege** (L07/L18/L25), handling **data** safely (L06/L23/L27/L28), and **responding to a
suspected compromise** (recognize → contain → escalate, feeding incident management L31 and the security
team / **NaviOpsSec**).

### Why it matters for support
Attackers don't always hack systems — they **call the help desk** and *ask*. The biggest breaches of
recent years (MGM, Okta-targeted, etc.) started with **social engineering of support** — a convincing
caller getting a reset, an MFA re-registration, or access. The tech who verifies identity, spots the
manipulation, and escalates a compromise is a **human firewall**; the one who "just helps quickly" under
pressure is the breach. Every lesson's 🔒 note has been building to this: security is **part of the
support job**, not a separate team's problem.

### Three-Level Depth (Lens A)
- **Level 1 — User:** "I got a weird email / a call from IT / a flood of approve prompts" — they need to
  recognize and report.
- **Level 2 — Technician:** **verify identity** before acting (L21); recognize phishing/pretexting/MFA
  fatigue; apply **least privilege**; handle data per classification; and when something's off, **don't
  proceed — verify/escalate**.
- **Level 3 — Engineer/Defender:** the desk sits in the **attack chain** — social engineering →
  credential/MFA capture → account takeover → lateral movement/data theft; defenses are **identity
  verification (out-of-band)**, **MFA + phishing-resistant factors**, **least privilege / no standing
  admin**, **conditional access** (L11), monitoring for **impossible travel / mass-forward rules /
  MFA-bombing** (L13/L11), and a **fast containment** response (disable + **revoke sessions**, L20).
  This is *why* the desk's procedures (verify, least privilege, escalate) are security **controls**, and
  where NaviOpsSec takes over (detection/IR depth).

### Two Teaching Approaches (Lens B) — the human firewall
**Approach 1 (technical):** the support desk is an **identity + access control point** in the org's
security model. Its controls are procedural: **verify identity out-of-band** before credential/access
changes; resist **social-engineering** patterns (urgency + authority + plausibility); enforce **least
privilege**; classify/handle **data**; and execute **fast containment** (disable + revoke sessions) on
suspected compromise, escalating to security. Skipping these = a control failure = a breach vector.

**Approach 2 (analogy):** the help-desk tech is the **building's security guard at the front desk**. A
polished stranger in a suit says "I'm the new CEO, I lost my badge, let me in — I'm late for the board!"
A bad guard, eager to help and intimidated by authority, opens the door. A good guard **calmly verifies**
(calls the real office, checks the record) regardless of the pressure — because **urgency + authority is
the con, not a reason to skip the check**. The guard also notices when something's *off* (a tailgater, a
propped door) and **raises the alarm** (escalates). **Where it breaks down:** unlike a physical guard, the
attacker is often remote and the "door" is a password reset or MFA re-registration — invisible, instant,
and high-impact — so the *procedure* (verify, don't rush) is the only defense.

### Visual (ASCII) — the attack chain & where the desk defends
```
   SOCIAL ENGINEERING ─▶ CREDENTIAL/MFA CAPTURE ─▶ ACCOUNT TAKEOVER ─▶ LATERAL MOVEMENT / DATA THEFT
   (phish/vish/pretext,     (reset, MFA re-reg,        (mailbox rules,      (shares, more accounts)
    MFA fatigue, "I'm the    captured code)             impossible travel)
    CEO, hurry!")
        │  DESK DEFENDS HERE ↓ (the controls this lesson teaches)
   VERIFY IDENTITY (out-of-band) · spot the manipulation · LEAST PRIVILEGE · data handling ·
   on suspicion → CONTAIN (disable + REVOKE sessions, L20) + ESCALATE to security (→ NaviOpsSec / L31)
```

---

## §2 — Tools & Commands

Security awareness is largely procedure + recognition; the "tools" are the checks + the containment
actions (drawn from earlier lessons):

| Task | How / where |
|---|---|
| **Identity verification** | out-of-band per policy (call-back to number on file, manager, verified portal) — L21 |
| Spot phishing | check sender/URL, hover links, urgency+authority cues; report button | L13/L14 |
| Check for compromise (mailbox) | `Get-InboxRule` / external **forwarding**; impossible-travel sign-ins (Entra) | L13/L11 |
| **Contain a compromised account** | `Disable-ADAccount` + **`Revoke-MgUserSignInSession`** + reset | L20/L21 |
| Least privilege | no standing local/Domain admin; group-based access | L07/L18/L25 |
| App/data control | AppLocker/WDAC; DLP; data classification | L25/L28 |
| Report/escalate | the security incident process → security team / NaviOpsSec | L31 |

```powershell
# Compromise check (mailbox takeover indicators — L13):
Get-InboxRule -Mailbox jdoe@corp.example | Where {$_.ForwardTo -or $_.DeleteMessage}   # hidden forward/delete rule
Get-Mailbox jdoe@corp.example | Select ForwardingSmtpAddress                            # external auto-forward
# Containment (suspected account takeover — L20):
Disable-ADAccount jdoe ; Revoke-MgUserSignInSession -UserId jdoe@corp.example           # disable + kill live sessions
```

> **This lesson is defensive (Blue Team).** Attack *recognition* only — never perform social engineering or
> offensive actions. Deep detection/IR is **NaviOpsSec**. Containment ops are danger zones (L20) — confirm
> + coordinate with security.

---

## §3 — Real-World Support Context & Use Cases

- **The reset/unlock desk is the #1 social-engineering target** (L21): attackers impersonate **users**
  (to get into an account) *and* **IT** (to get a user to hand over a code / install remote access). Verify
  identity, every time, under any pressure.
- **MFA fatigue / MFA bombing** (L11): a flood of approve prompts hoping the user taps "yes" — teach users
  to **deny + report**, never approve an unexpected prompt.
- **Phishing** (L13/L14): the top initial-access vector — recognize it, report it, and treat a user who
  **clicked + entered credentials** as a **compromise** (INC-0701: reset + revoke sessions + check rules).
- **Compromised-mailbox indicators** (L13): rogue **inbox rules** / **external forwarding** = account
  takeover → contain + escalate, don't quietly delete the rule.
- **Least privilege everywhere** (L07/L18/L25): no standing admin, group-based access, vetted software —
  these limit blast radius when something does go wrong.
- **Physical + data** (L02/L06/L27): lost/stolen devices, unknown USBs, secure disposal, not exposing
  data — all desk responsibilities.
- **Exam framing:** A+ (Core 2 — social engineering, security best practices, malware), MS-900 (security/
  compliance), and the on-ramp to **NaviOpsSec** (SOC/detection/IR).

---

## §4 — Demonstration (worked walkthrough)

**Watch me handle a social-engineering attempt at the desk.**

> Phone call: *"Hi, this is Mark from the executive team — I'm traveling, locked out, and I have an
> investor call in 5 minutes. I need you to reset my password and the MFA right now, my assistant will
> confirm. This is urgent!!"*

1. **Recognize the pattern, not just the request:** **urgency + authority + plausibility + pressure to
   skip process** = the textbook social-engineering profile (L21). The red flags *are* the signal.
2. **Stay calm + polite, but do NOT skip verification:** "Absolutely, I can help — I just need to verify
   your identity first per our security policy." (Politeness ≠ compliance; the policy protects everyone.)
3. **Verify out-of-band, not via the caller:** call-back to the **number on file** / manager confirmation
   / verified channel — **not** "my assistant will confirm" (the attacker controls that). An exec gets the
   **same** verification (authority is a cue to verify *harder*, not less).
4. **If verification fails or is refused:** **do not reset/re-register MFA.** That's the attack. Decline
   politely, offer the proper verified path, and **report** the attempt (it may be an active attack on
   that exec's account).
5. **If it's genuinely the exec (verified):** proceed via the secure reset (L21) — verification doesn't
   slow a *real* user much, and it stops the fake one cold.
6. **Document + report:** log the attempt; if it was an impersonation attempt, escalate to security
   (NaviOpsSec) — others may be getting the same call.

The teaching point: **urgency + authority is the con.** The professional move is to **verify out-of-band
regardless of pressure** — that single discipline is the human firewall.

---

## §5 — Troubleshooting Workflow (the diagnostic spine)

**Problem class: security events at the desk — phishing, social engineering, suspected compromise.**

### 1 · Symptoms
User clicked a phishing link / entered credentials · suspicious email ("is this phishing?") · flood of
unexpected **MFA prompts** · a **reset/access request that can't be verified** · odd account behavior
(mass emails sent, rules appeared, impossible-travel sign-in) · lost/stolen device · unknown USB / ransom
note (L23).

### 2 · Possible Causes (most-likely first)
1. **Phishing / credential capture** (user entered password on a fake page).
2. **Social-engineering attempt** (caller impersonating user or IT).
3. **MFA fatigue/bombing** (attacker has the password, spamming approvals).
4. **Account takeover** (rogue inbox rule / external forward / impossible travel — L13/L11).
5. **Malware** (L24 — slow + odd processes; ransomware = mass file changes, L23).
6. **Lost/stolen device / data exposure** (L02/L06/L27).

### 3 · Diagnostic Steps (ordered)
| # | Check | If… | …then |
|---|---|---|---|
| 1 | **Verify identity** (any account request) | unverifiable | do NOT proceed → escalate/report (L21) |
| 2 | Did the user enter credentials on a phishing page? | yes | treat as **compromise** → contain (step 4) |
| 3 | Unexpected MFA prompts? | yes | user **denies**; password likely known → reset + investigate |
| 4 | Mailbox rules / external forward / sign-in logs | rogue rule/forward/impossible travel | **account takeover** → contain |
| 5 | Malware/ransomware signs (L24/L23) | yes | **isolate** device + escalate |
| 6 | Lost/stolen device | yes | remote wipe/lock + report (L27/L30) |

### 4 · Resolution Steps (recognize → contain → escalate)
For a **suspected compromise**: **contain fast** — `Disable-ADAccount` + **`Revoke-MgUserSignInSession`**
(disable ≠ revoke, L20) + reset password; **remove rogue rules/forwards** (after preserving evidence);
**isolate** an infected device (disconnect network) — then **escalate to the security team / NaviOpsSec**
and open a **security incident** (L31). For an **attempt** (no compromise yet): decline the unverified
request, **report** it. **Preserve evidence** (don't wipe/delete before security reviews) and educate the
user (without blame).

### 5 · Escalation Criteria
**Escalate to security / NaviOpsSec (and major-incident, L31) for ANY:** confirmed/suspected account
takeover, credential-phishing victim, ransomware, data breach/loss, or a targeted social-engineering
campaign. The desk's job is **recognize → contain → escalate**, not full investigation (that's SOC/IR —
**NaviOpsSec**). Never handle a real compromise alone or quietly. Preserve evidence; coordinate
containment (danger zones, L20/L24).

### 6 · Post-Incident Documentation
Security-incident record (timeline, indicators, containment actions — feeds L31/L32 RCA), report the
phishing/social-eng attempt (others may be targeted), update the security-awareness KB, and feed lessons
into user training. Sensitive details handled per data classification (L28).

---

## §6 — Ticket Simulation

> **Ticket ENT-29 / INC-0701 (P1, security):** *"I think I messed up — I got an email that looked like IT
> saying my mailbox was full, I clicked the link and entered my password, and now my coworkers say I'm
> sending them spam. — Nia, LT-0495."*

**Triage:** a user **entered credentials on a phishing page** + **mailbox now sending spam** = **active
account takeover** → **P1 security incident**. The job: **contain immediately, preserve evidence,
escalate** — recognize → contain → escalate.

**Worked resolution (contain fast, do-no-harm to evidence):**
1. **Treat it as a compromise (not a "spam" ticket):** credentials entered + spam sent from her account =
   the attacker is **in**. Time matters.
2. **Contain immediately (L20/L21):** **reset Nia's password** and **`Revoke-MgUserSignInSession`** (kill
   the attacker's live session — disabling/reset alone may not — L20); re-secure MFA (the attacker may
   have registered their own method — check + remove it).
3. **Find what the attacker did (takeover indicators, L13):** `Get-InboxRule` / forwarding → look for a
   **rogue auto-forward/auto-delete rule** (used to hide replies / exfiltrate); check sign-in logs for
   **impossible travel**. **Preserve** this evidence (note it) before removing — security/IR will want it.
4. **Stop the spread:** the spam to coworkers may be phishing *them* → warn recipients / have the email
   pulled (and watch for further victims — this can cascade).
5. **Escalate to security / NaviOpsSec + declare the incident (L31):** this is beyond desk scope —
   investigation, scoping (did they reach data/other accounts?), and IR belong to the security team.
   The desk did the critical first 10 minutes (contain).
6. **Support Nia without blame:** she **reported it** — that's exactly right; reinforce, don't shame
   (blame makes the next victim hide it). Educate on spotting the phish.
7. **Document:** full timeline + indicators + containment actions for the IR/RCA (L31/L32).

**The professional incident note (excerpt):**
```
SUMMARY: Nia entered credentials on a phishing page → account takeover (spam sent from her mailbox).
CONTAINED: reset password + REVOKED sessions + removed attacker MFA method; found + preserved a rogue
external auto-forward rule; warned spam recipients. Escalated to security/NaviOpsSec as a P1 security
incident.
SYMPTOM: user phished (credentials entered) + mailbox sending spam = active takeover.
CONTAINMENT (first 10 min, the desk's job): Set-ADAccountPassword reset + Revoke-MgUserSignInSession
(killed live session); checked/removed attacker-registered MFA; identified rogue auto-forward rule
(PRESERVED as evidence, then removed); pulled/warned on the spam to coworkers.
INDICATORS: external forwarding rule to <attacker>@…; impossible-travel sign-in (foreign IP).
ESCALATION: P1 security incident → security team/NaviOpsSec for scoping + IR (did they reach data/other
accounts/shares?). Declared per L31.
FOLLOW-UP: IR/RCA (L31/L32); phishing reported + recipients warned; user supported (no blame) + educated;
review whether MFA was phishing-resistant. NaviOpsSec owns the investigation depth.
```

---

## §7 — Service Desk / ITIL Perspective

- **Security incidents are incidents (L31)** with a security flavor — often **P1/major** — and follow
  recognize → contain → escalate; the desk does the **critical first containment**, security/IR
  (**NaviOpsSec**) does the investigation.
- **The desk's procedures ARE security controls:** identity verification (L21), least privilege (L07/18/
  25), data handling (L28/L27), vetted software (L25) — security isn't a separate team's job, it's woven
  into every desk action (this lesson made the 🔒 thread explicit).
- **Speed + evidence balance:** **contain fast** (revoke sessions) but **preserve evidence** (don't wipe/
  delete before IR) — the do-no-harm tension, security edition.
- **No-blame culture is a security control:** users who fear blame **hide** incidents (the worst outcome);
  praising reporting (like Nia) surfaces incidents fast — a service *and* security win.
- **The bridge to NaviOpsSec:** this lesson is the on-ramp — detection engineering, SIEM, threat hunting,
  and full IR are the **NaviOpsSec** platform; here you learn the desk's defensive role + when to hand off.

---

## §8 — Practical Lab (build this yourself)

**Goal:** drill the three core desk security skills — identity verification, phishing/social-eng
recognition, and compromise containment.

### Lens C — Manual → Automation/Process → Why
- **Manual:** verify/recognize/respond ad-hoc.
- **Systematized:** a **verification script** (the questions/out-of-band steps to follow — L21), a
  **phishing-report** button + triage flow, and a **containment runbook** (disable + revoke + check
  rules) so the high-pressure moment follows a checklist, not improvisation; org-wide, **MFA + least
  privilege + conditional access** (L11) reduce the attack surface.
- **Why:** security decisions happen under pressure (an angry "exec," a panicking phished user) — a
  **pre-decided procedure** prevents the rushed mistake that becomes a breach. Containment as a runbook =
  fast, correct first response.

### Steps
1. **Identity-verification drill:** write/practice the out-of-band verification procedure (L21); role-play
   the "urgent exec" social-eng call and *decline-then-verify*.
2. **Phishing triage:** examine sample phishing (sender, URL hover, urgency/authority cues — L13/L14);
   build a "is this phishing?" quick-check + the report path.
3. **MFA-fatigue awareness:** know the "deny + report unexpected prompts" guidance (L11) — teachable to
   users.
4. **Compromise containment drill:** practice (lab) the contain sequence — reset + **revoke sessions**
   (L20) + check `Get-InboxRule`/forwarding (L13) + isolate device (L24) — then escalate.
5. **No-blame + report:** draft the user-facing "you did the right thing by reporting" message + the
   security-awareness KB.
6. **Write the "suspected compromise" runbook** + the **security-awareness KB** (phishing, MFA, identity-
   verification, lost device) for end users.

### Lens D — the raw artifact (the takeover fingerprint)
```
   Get-InboxRule -Mailbox nia@corp.example   (excerpt)
     Name: ".. "            ForwardTo: attacker@evilmail.example   DeleteMessage: True   ← rogue rule:
                                                                                            auto-forward + auto-delete
   Entra sign-in log:  nia  09:02 from 10.10.x (office)  /  09:07 from 203.0.113.x (foreign IP)  ← impossible travel
#   A hidden auto-forward+delete inbox rule and an impossible-travel sign-in are the classic ACCOUNT
#   TAKEOVER fingerprints. PRESERVE them (evidence for IR/NaviOpsSec), then contain. Don't just delete the
#   rule and close the ticket — that hides an active breach.
```

---

## §9 — GitHub Artifact (the 6-artifact evidence package)

1. **Runbook:** `docs/runbooks/suspected-compromise.md` — recognize → contain (disable+revoke+rules) →
   escalate.
2. **Troubleshooting Guide:** `docs/troubleshooting/security-events.md` — the full spine (phishing/social-
   eng/MFA/takeover/malware/lost device).
3. **Ticket Notes:** `docs/tickets/ENT-29-account-takeover.md` — the worked ENT-29 (INC-0701).
4. **KB Article:** `docs/kb/` — "Spot & report phishing / what to do if you clicked / MFA prompts you
   didn't request" (end-user security awareness).
5. **Incident Report:** the account-takeover as a **security incident report** (feeds L31/L32 + NaviOpsSec).
6. **Portfolio Artifact:** §10 bullet + the verify-under-pressure + recognize→contain→escalate talking
   points.
7. **Standard:** the identity-verification procedure + the containment checklist.

---

## §10 — Portfolio Artifact

- **Resume bullet:** *"Acted as the security front line at the service desk — enforcing out-of-band
  identity verification, recognizing phishing/social-engineering/MFA-fatigue, and executing first-response
  containment (disable + session revoke + rogue-rule preservation) on an account-takeover incident before
  escalating to the security team."*
- **Interview talking point:** **"urgency + authority is the con"** (verify out-of-band regardless of
  pressure — the MGM/Okta lesson), the **account-takeover fingerprints** (rogue forward rule + impossible
  travel), and **recognize → contain → escalate** (disable + **revoke sessions**, preserve evidence,
  no-blame). Bridges to NaviOpsSec.
- **Serves:** every role; the security spine of Help Desk → IT Support → and the on-ramp to SOC/NaviOpsSec.

---

## §11 — Certification Crossover Notes

- **CompTIA A+ (Core 2):** social engineering, security best practices, malware removal, incident
  response basics. **MS-900:** security/compliance/identity. **Security+ / SOC path:** this is the
  on-ramp — depth in **NaviOpsSec**. Detail in `alignment/CERTIFICATION-MAPPING.md`.

---

## §12 — Support Notes (Lens E — Service & Security)

**🤝 Service:** security and service align here — **no-blame** support (praising users who report, like
Nia) is *both* good service and the best security control (fear → hidden incidents). Verifying identity
politely-but-firmly protects the user themselves. Educate without condescension.

**🔒 Security:** this lesson **is** the 🔒 thread, consolidated — the desk is a **privileged access point
and top target**, so its everyday procedures (verify, least privilege, data handling) are **security
controls**, and its first-response (recognize → contain → escalate) is the difference between a near-miss
and a breach. **Verify out-of-band under pressure; deny+report unexpected MFA; contain by disabling +
revoking sessions; preserve evidence; escalate to security/NaviOpsSec.** The desk holds the line until
the SOC takes over.

---

## Quiz (Interview-Style, Graded)

**Q1.** Why is the IT help desk a top target for attackers, and what's the single most important control
the desk applies?
> **Your answer:**

**Q2.** A caller claims to be a stressed executive demanding an urgent password + MFA reset. What do you
do, and why is the urgency itself a red flag?
> **Your answer:**

**Q3.** A user says they get constant unexpected MFA approval prompts. What's happening and what's your
advice + action?
> **Your answer:**

**Q4.** **Scenario:** a user clicked a phishing link, entered their password, and their account is now
sending spam. What do you do, in order — and who do you involve?
> **Your answer:**

**Q5.** You find a hidden inbox rule auto-forwarding a user's mail externally. Why don't you just delete
it and close the ticket?
> **Your answer:**

*(Request the "Professional Answer" comparison under each before moving on.)*

---

## Reflection
*(After the quiz)* — What did you learn? · What confused you? · What would you do differently?

---

## Search Keywords For Further Understanding

**Core**
- `help desk social engineering attack MGM Okta`
- `identity verification before password reset`
- `MFA fatigue MFA bombing defense`
- `account takeover indicators inbox rule impossible travel`
- `phishing recognition report user`

**Tools**
- `Revoke-MgUserSignInSession contain account`
- `Get-InboxRule forwarding compromise`

**Going further**
- `backup and recovery / ransomware` (L30) · `incident management` (L31) · `password resets` (L21) ·
  `email compromise` (L13) · **NaviOpsSec** (SOC / detection / incident response — the deep dive)

**Service / Security (Lens E):**
- 🤝 `no-blame security reporting culture`, `polite firm identity verification`
- 🔒 `recognize contain escalate`, `verify out-of-band under pressure`, `preserve evidence before remediate` (→ NaviOpsSec)

---

## Lesson Status
- [ ] §8 lab completed (verification drill + phishing triage + containment drill + runbook + KB)
- [ ] 6-artifact evidence package committed (§9)
- [ ] Quiz answered + professional-answer comparisons (graded)
- [ ] Reflection + Search Keywords reviewed

When complete, run the Update Protocol, then move to **Lesson 30 — Backup & Recovery Fundamentals**.

---

*Lesson 29 written by Navi · 2026-06-21 · full-depth. Sources to cite at study time: CompTIA A+ 220-1102
(social engineering/security), CISA phishing guidance, real help-desk social-eng breaches; deep dive →
NaviOpsSec.*
