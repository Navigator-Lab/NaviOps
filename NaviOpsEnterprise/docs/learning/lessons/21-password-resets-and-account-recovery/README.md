# Lesson 21 — Password Resets & Account Recovery

**Status:** ✅ ready for self-study (full depth) · **Date written:** 2026-06-21
**Schema:** 12-section IT-Support (`docs/learning/CLAUDE_TEACHING_RULES.md`)
**Focus:** the single highest-volume ticket in all of IT — **password resets, account unlocks, and
recovery** — done **securely** (identity verification first), plus finding the **root cause of repeated
lockouts** and enabling **self-service (SSPR)** to deflect the volume. This is the lesson where service
and security meet most directly.
**Primary artifacts:** `scripts/reset_password.ps1` + `scripts/unlock_account.ps1` + the
reset/lockout runbook. **Lab:** DC01 + M365 dev-tenant (`infra/`).

> **How to use this lesson:** read §1–§7, do §8 (reset/unlock in the lab + hunt a lockout source),
> produce §9, take the quiz, reflect. Then Lesson 22 (Module G).

---

## §1 — Concept (Theory)

### What it is
A **password reset** sets a new credential for a user who's forgotten theirs or whose password expired
(L01). An **account unlock** clears the **lockout** state that AD/Entra applies after too many bad
attempts (a security feature). **Account recovery** is the broader process of restoring a user's access
safely — which always starts with **verifying it's really them** (or an authorized requester). In
cloud/hybrid, **SSPR** (Self-Service Password Reset) and **Self-Service Unlock** let users do this
themselves with MFA, deflecting the bulk of these tickets.

### Why it matters for support
Password/lockout tickets are perennially the **#1 volume** at every help desk — and the **#1 social-
engineering target**: attackers call posing as a user (or as IT) to capture a reset. So this lesson is
where **throughput** (do it fast, enable self-service) and **security** (verify identity, least
privilege, recognize pretexting) collide. Doing it well — and finding *why* an account keeps locking
(root cause, not just unlock-again) — is core competence.

### Three-Level Depth (Lens A)
- **Level 1 — User:** "I forgot my password / I'm locked out / nothing works."
- **Level 2 — Technician:** **verify identity first**, then reset (`Set-ADAccountPassword`/SSPR) or
  unlock (`Unlock-ADAccount`); for repeats, **find the lockout source** rather than unlocking forever.
- **Level 3 — Engineer:** AD lockout is governed by **account-lockout policy** (threshold/duration/
  reset-counter, set via GPO/Default Domain Policy — L19); the **PDC emulator** is authoritative for
  lockouts and logs **Event ID 4740**; the **caller/source** of bad attempts is found via security
  logs / `LockoutStatus`/`Get-ADUser -Properties LockedOut,badPwdCount` and 4740's caller-computer
  field; the usual root cause is a **stale cached credential** (phone mail app, mapped drive, saved
  Wi-Fi, a service using the account, an RDP/scheduled task). In hybrid, **SSPR write-back** syncs a
  cloud reset to on-prem AD. This is *why* "unlock again" never ends until you kill the stale credential.

### Two Teaching Approaches (Lens B) — reset vs unlock vs the lockout loop
**Approach 1 (technical):** a **reset** changes the secret; an **unlock** clears the lockout flag set by
the lockout policy after N bad attempts. They're independent: an account can be locked with a known-good
password (a stale device keeps trying the *old* one), or forgotten without being locked. Repeated
lockouts are a **feedback loop** — a process somewhere keeps submitting the old credential — broken only
by finding and fixing that source (Event 4740 → caller computer).

**Approach 2 (analogy):** the account is a **safe**. A **reset** = changing the combination; an
**unlock** = the safe auto-locked after too many wrong tries and you're clearing that timeout. The
maddening case: a **forgotten note in someone's pocket has the OLD combination** and they keep trying it
(a phone still configured with the old password), re-locking the safe minutes after you clear it — until
you **find and update that note** (the stale cached credential). **Where it breaks down:** unlike a
physical safe, the "person trying the old combination" is usually an *automated* device the user forgot
about — so you trace it from the **logs (Event 4740 caller)**, not by asking the user.

### Visual (ASCII) — verify → act, and the lockout loop
```
   TICKET ─▶ VERIFY IDENTITY (out-of-band / policy)  ← NON-NEGOTIABLE (social-eng target, L29)
              │
              ├─ forgot pw / expired ─▶ RESET (Set-ADAccountPassword / SSPR) + ChangeAtLogon
              └─ locked out ─────────▶ UNLOCK (Unlock-ADAccount)  ── but if it RE-LOCKS:
                                          │
   LOCKOUT LOOP:  stale OLD credential on a device keeps trying ──▶ AD locks account (policy threshold)
                  find source: Event ID 4740 (PDC) → caller computer ; common: phone mail, mapped drive,
                  saved Wi-Fi, a service/scheduled task ──▶ UPDATE the stale credential ──▶ loop ends
   DEFLECT: enable SSPR / self-service unlock (MFA) so users self-serve the common case
```

---

## §2 — Tools & Commands

| Task | GUI | PowerShell |
|---|---|---|
| Reset password (AD) | ADUC → Reset Password | `Set-ADAccountPassword` / `Set-ADUser -ChangePasswordAtLogon` |
| Unlock account (AD) | ADUC → Unlock | `Unlock-ADAccount` |
| Find all locked accounts | — | `Search-ADAccount -LockedOut` |
| Lockout state / bad-pwd count | ADUC → Account | `Get-ADUser jdoe -Properties LockedOut,badPwdCount,LastBadPasswordAttempt` |
| Lockout source | Event Viewer (Security) on PDC | **Event ID 4740** (caller computer) / Microsoft `LockoutStatus`/ALTools |
| Reset (Entra/M365) | M365 admin / Entra → Reset password | `Reset-MgUserAuthenticationMethodPassword` (Graph) |
| Self-service | enable **SSPR** (Entra) | aka.ms/sspr (user-facing) |

```powershell
# Verify identity FIRST (out-of-band), then:
Unlock-ADAccount -Identity jdoe                                   # clear the lockout
Set-ADAccountPassword -Identity jdoe -Reset -NewPassword (Read-Host -AsSecureString) ; `
  Set-ADUser jdoe -ChangePasswordAtLogon $true                   # reset + force change at next logon
Search-ADAccount -LockedOut | Select Name,LastLogonDate          # who's locked right now
Get-ADUser jdoe -Properties LockedOut,badPwdCount,LastBadPasswordAttempt | fl
# Lockout source: read Security Event ID 4740 on the PDC emulator (caller computer name)
```

> **Danger zone** (`navi.project.md`): resets/unlocks change credentials — **verify identity first**,
> deliver new passwords **securely** (never plain-text email/chat — L29), **lab/authorized only**, and
> confirm the exact target (resetting the wrong account locks out the wrong person).

---

## §3 — Real-World Support Context & Use Cases

- **#1 volume ticket** everywhere — and the best **FCR + deflection** target (SSPR). Speed *and*
  security both matter.
- **#1 social-engineering vector:** the attacker's classic move is to call the desk *as* a user (or
  *as* IT) to get a reset/unlock or capture a code (MFA fatigue/help-desk pretexting — the MGM/Okta-style
  attacks). **Identity verification is the control** (L29).
- **Repeated lockouts** are a root-cause hunt, not an unlock-loop: the source is almost always a **stale
  cached credential** (phone mail app, mapped drive, saved Wi-Fi, a **service account** running with the
  user's old password, an RDP session, a scheduled task) — found via **Event 4740**.
- **SSPR/self-service unlock** (with MFA) deflects the bulk of tickets — the strategic fix.
- **Hybrid:** know whether to reset in **AD** or **Entra** and whether **SSPR write-back** is in play
  (L11/L18) so the reset reaches both.
- **Exam framing:** MS-900/MD-102 (identity, SSPR, MFA), A+ (account management, security/social
  engineering), ITIL (request fulfillment).

---

## §4 — Demonstration (worked walkthrough)

> **Ticket INC-0101 (P3):** *"I forgot my password and can't log in. — jdoe."* Channel: phone.

1. **Verify identity FIRST** (the non-negotiable step): use the org's method — a **call-back to the
   number on file**, manager confirmation, security questions, or an in-person/verified-session check.
   *Never reset on an unverified request*, no matter how urgent or senior the caller claims to be (L29).
2. **Determine the state:** forgotten (reset needed) vs also locked (`Get-ADUser -Properties LockedOut`)
   — reset and unlock are independent.
3. **Reset securely:** `Set-ADAccountPassword -Reset` to a **strong temp password**, `Set-ADUser
   -ChangePasswordAtLogon $true` so jdoe sets her own at next logon.
4. **Deliver the temp password securely:** read it over the **verified** phone call or use a secure
   channel — **never** plain-text email/chat/sticky note (L29).
5. **Guide + verify:** jdoe signs in, sets a new compliant password (KB-0001/KB-0101), confirms access.
6. **Prevent re-lockout:** remind her to update the password on **all devices** (phone mail, mapped
   drives, Wi-Fi) so a stale cached copy doesn't lock her (the loop). Point her at **SSPR** for next
   time.
7. **Document:** verified-how, reset, change-at-logon, self-service pointer.

The teaching point: **verify identity → reset/unlock → secure handoff → prevent the loop → deflect to
SSPR.** Verification is step zero, every time.

---

## §5 — Troubleshooting Workflow (the diagnostic spine)

**Problem class: can't sign in — password/lockout/recovery (incl. repeated lockouts).**

### 1 · Symptoms
"Forgot password" · "account locked" · locks again minutes after unlock · "password works on web but
locks my desktop" · MFA can't be completed (L11) · expired password with no way to change (L01).

### 2 · Possible Causes (most-likely first)
1. **Forgotten / expired** password (simple reset — L01).
2. **Lockout** from too many bad tries (unlock).
3. **Stale cached credential** re-locking (the loop) — phone/mapped drive/Wi-Fi/service/scheduled task.
4. **MFA** issue (new phone / not registered — L11) masquerading as "can't sign in".
5. **Account disabled** (offboarded/suspended — L20), not actually a password issue.
6. **Hybrid mismatch** — reset on the wrong side / not synced (L11/L18).

### 3 · Diagnostic Steps (ordered)
| # | Check | If… | …then |
|---|---|---|---|
| 0 | **Verify identity** (out-of-band) | unverifiable | do NOT reset — escalate/deny (L29) |
| 1 | `Get-ADUser -Properties LockedOut,Enabled,PasswordExpired` | which state | reset / unlock / (disabled→L20) |
| 2 | Re-locks after unlock? | yes | hunt the **source** (step 3) |
| 3 | Event ID **4740** on PDC (caller computer) | a device/service | update that stale credential |
| 4 | Is it actually MFA? (L11) | yes | re-register MFA, not password |
| 5 | Hybrid: reset on correct side + synced? | no | reset on authoritative side (L11/L18) |

### 4 · Resolution Steps
Verify → **unlock** (`Unlock-ADAccount`) and/or **reset** (`Set-ADAccountPassword -Reset` +
ChangeAtLogon) → deliver securely → for repeats, **trace Event 4740** to the caller computer/service and
**update the stale credential** (re-add phone mail, fix the service-account password, remap drives,
forget/rejoin Wi-Fi, fix the scheduled task) → enable/point to **SSPR** to deflect future tickets.

### 5 · Escalation Criteria
Escalate to a senior admin / **security** for: **service-account** password changes (can break apps —
coordinate, L18), suspected **account compromise** or a social-engineering attempt (don't reset — treat
as a security incident, L29), SSPR/MFA policy changes, lockout-policy (GPO) tuning, and hybrid
write-back issues. An **unverifiable** caller requesting a reset → deny + report (L29). Attach: account
state, 4740 source, what you tried.

### 6 · Post-Incident Documentation
Ticket note (verified-how, reset/unlock, **root cause** of any loop with the 4740 source), KB (KB-0001/
KB-0002 + SSPR enrollment), security escalation if compromise/social-eng suspected, Problem (L32) if a
service account / device pattern locks many.

---

## §6 — Ticket Simulation

> **Ticket ENT-21 / INC-0102 (P2):** *"My account keeps locking — you unlock it and ten minutes later
> I'm locked out again. This is the fourth time today! — rkhan, LT-0469."*

**Triage:** **repeated** lockouts right after unlock = a **stale cached credential** loop — unlocking
again is treating the symptom. The fix is **finding the source**. Single user, repeatedly blocked → **P2**
+ a root-cause hunt (Problem-adjacent, L32).

**Worked resolution (root cause, not symptom):**
1. **Verify identity** (it's a recurring user, still verify per policy — L29).
2. **Stop the symptom temporarily:** `Unlock-ADAccount rkhan` so he can work while you investigate.
3. **Find the source — Event ID 4740:** on the **PDC emulator**, read Security **4740** events for
   rkhan → the **Caller Computer Name** points at the offender (e.g. his **phone** `RKHAN-IPHONE`, a
   **mapped drive** to FS01, or a **scheduled task/service**).
   - Corroborate with `Get-ADUser rkhan -Properties LastBadPasswordAttempt,badPwdCount`.
4. **Kill the stale credential at the source:** if it's the **phone mail app** → remove + re-add the
   account with the new password; if a **mapped drive** → reconnect with current creds / clear
   Credential Manager (L13); if **saved Wi-Fi** → forget + rejoin; if a **service/scheduled task** using
   his account → update its stored password (or move it to a proper service account — escalate, L18).
5. **Verify the loop is broken:** unlock once more, confirm `badPwdCount` stops climbing and no new 4740
   appears.
6. **Prevent + deflect:** ensure all his devices have the current password; enable **SSPR**; document the
   source so it doesn't recur.

**The professional ticket note:**
```
SUMMARY: rkhan's repeated lockouts (4×/day) were caused by his iPhone mail app still using his OLD
password (stale cached credential). Traced via Security Event 4740 (caller: RKHAN-IPHONE); re-added the
mail account with the current password. Lockout loop stopped. Enabled SSPR.
SYMPTOM: account re-locks ~10 min after each unlock; 4 lockouts today.
VERIFIED: identity per policy.
DIAGNOSIS: Event ID 4740 on PDC → caller computer = RKHAN-IPHONE; badPwdCount climbing from that source
(stale cached old password after his recent reset).
CAUSE (root, not symptom): old password cached in the phone's mail app kept submitting → AD lockout
threshold hit repeatedly.
RESOLUTION: unlocked; removed + re-added the mail account on the phone with current password; confirmed
badPwdCount stable + no new 4740. Enabled/SSPR-pointed for self-service.
FOLLOW-UP: KB-0002 (account unlock — update saved passwords) reinforced; if pattern repeats across
users post-reset → Problem (L32) on "remind users to update phone mail after a reset".
```

---

## §7 — Service Desk / ITIL Perspective

- **Category:** Account/Access. Single = **Incident**; repeated lockouts with a shared cause (e.g. a
  service account) = a **Problem** (L32); SSPR rollout = an **improvement/Change** (L16/L26).
- **The #1 FCR + deflection lever:** resets/unlocks are textbook FCR, and **SSPR** deflects the whole
  category — the single biggest volume reduction a desk can make (L16).
- **Security gate is mandatory:** identity verification before reset/unlock is a **policy control**, not
  a courtesy — skipping it under pressure is exactly the attacker's play (L29). Urgency + authority
  ("I'm the CEO, reset it now") is a **verify harder** signal, not a rush signal.
- **Root-cause over repeat-unlock:** mature desks trace 4740 and fix the source — repeatedly unlocking
  the same account is a missed problem record.
- **Metric angle:** password/lockout volume is a headline metric; SSPR adoption + lockout-source fixes
  visibly cut it.

---

## §8 — Practical Lab (build this yourself)

**Goal:** reset/unlock securely, trace a lockout to its source, and script the safe procedure — in the
lab.

### Lens C — Manual → Automation → Why
- **Manual:** ADUC reset/unlock click-by-click.
- **Automated:** `reset_password.ps1` (verify-prompt → reset → ChangeAtLogon → secure-handoff note) and
  `unlock_account.ps1` (unlock + optionally report the 4740 source) — consistent, auditable, fast.
- **Why:** the highest-volume ticket benefits most from a consistent, logged procedure; scripting the
  4740 lookup turns "unlock again" into "find and fix the source." (SSPR is the ultimate automation —
  the user self-serves.)

### Steps
1. **Lab:** in `corp.example`, use placeholder users (jdoe, rkhan).
2. **Reset drill:** `Set-ADAccountPassword -Reset` + `Set-ADUser -ChangePasswordAtLogon $true`; log in as
   the user to confirm the change-at-logon prompt.
3. **Lockout drill:** deliberately fail logon past the threshold (lab) → `Search-ADAccount -LockedOut`
   shows it → `Unlock-ADAccount`.
4. **Source hunt:** generate bad attempts from a second machine, then read **Event ID 4740** on the PDC
   → identify the **caller computer** (the core skill). Corroborate with `badPwdCount`/
   `LastBadPasswordAttempt`.
5. **SSPR awareness:** in the M365 dev tenant, see how SSPR/self-service unlock is enabled and what the
   user experience (aka.ms/sspr) looks like.
6. **Write `scripts/reset_password.ps1` + `scripts/unlock_account.ps1`** (verify-prompt, secure handoff,
   4740 reporting) and the reset/lockout runbook.

### Lens D — the raw artifact (Event 4740 names the lockout source)
```
   Security Log (on the PDC emulator) — Event ID 4740: "A user account was locked out."
       Account Name:   rkhan
       Caller Computer Name:  RKHAN-IPHONE        ← THE SOURCE — a stale cached password on his phone
#   Unlocking treats the symptom; Event 4740's "Caller Computer Name" tells you WHAT keeps locking the
#   account. Fix that source (re-add mail with the new pw) and the loop ends. This one field is the
#   difference between unlocking forever and actually solving it.
```

---

## §9 — GitHub Artifact (the 6-artifact evidence package)

1. **Runbook:** `docs/runbooks/password-reset-unlock.md` — verify → reset/unlock → secure handoff →
   4740 source hunt → SSPR.
2. **Troubleshooting Guide:** `docs/troubleshooting/lockouts-and-resets.md` — the full spine (incl. the
   repeated-lockout source trace).
3. **Ticket Notes:** `docs/tickets/ENT-21-repeated-lockout.md` — the worked ENT-21.
4. **KB Article:** `docs/kb/` — KB-0001 (reset) + KB-0002 (unlock) reinforced + an SSPR enrollment guide.
5. **Incident Report:** a service-account-driven mass lockout (or a thwarted social-engineering reset
   attempt) as an incident (L31/L29).
6. **Portfolio Artifact:** §10 bullet + the verify-first + Event-4740-source talking points.
7. **Scripts:** `scripts/reset_password.ps1` + `scripts/unlock_account.ps1` (`Invoke-ScriptAnalyzer`-
   clean; verify-prompt; lab-targeted).

---

## §10 — Portfolio Artifact

- **Resume bullet:** *"Automated secure password resets and account unlocks (PowerShell + AD) with
  mandatory identity verification and forced change-at-logon, traced repeated lockouts to their source via
  Security Event 4740, and drove down ticket volume by enabling self-service password reset (SSPR/MFA)."*
- **Interview talking point:** **verify identity first** (the social-engineering control, L29),
  **reset vs unlock** as independent actions, and tracing **repeated lockouts via Event ID 4740** to a
  stale cached credential — plus **SSPR** as the deflection strategy.
- **Serves:** Help Desk T1/T2, IT Support, Junior SysAdmin.

---

## §11 — Certification Crossover Notes

- **MS-900 / MD-102:** identity, SSPR, MFA, account management. **A+ (Core 2):** account management +
  social-engineering awareness. **ITIL:** request fulfillment + problem (repeated lockouts). Detail in
  `alignment/CERTIFICATION-MAPPING.md`.

---

## §12 — Support Notes (Lens E — Service & Security)

**🤝 Service:** this is the most-repeated user interaction — be fast, friendly, and *teach the prevention*
(update saved passwords; use SSPR) so the user isn't back tomorrow. A locked-out user is stressed; calm +
quick + a secure handoff is the experience.

**🔒 Security:** **this lesson is the front line of help-desk security.** The reset/unlock desk is the
top **social-engineering target** (attackers impersonate users *and* IT — MGM/Okta-class breaches started
exactly here). **Identity verification before any credential action is non-negotiable**; urgency +
authority pressure is a *verify-harder* cue, not a reason to rush. Deliver passwords **securely** (never
plain text), use **least privilege** (you don't need Domain Admin to reset a standard user — delegated
rights), enforce strong/SSPR-with-MFA, and treat an **unverifiable** or suspicious request as a security
incident to **report**, not fulfill (L29). Repeated lockouts can also indicate a **brute-force attack**
(not just a stale phone) — if the 4740 source is unknown/external, escalate to security (NaviOpsSec).

---

## Quiz (Interview-Style, Graded)

**Q1.** What is the very first thing you do on any password-reset request, and why is it non-negotiable?
> **Your answer:**

**Q2.** What's the difference between resetting a password and unlocking an account? Can one be needed
without the other?
> **Your answer:**

**Q3.** An account keeps locking minutes after you unlock it. What's the usual cause, and what's the one
log/event that tells you the source?
> **Your answer:**

**Q4.** **Scenario:** a caller is adamant they're the new VP, very angry, demanding an immediate reset,
and can't complete identity verification. What do you do?
> **Your answer:**

**Q5.** How would you reduce the overall volume of password/lockout tickets at a help desk?
> **Your answer:**

*(Request the "Professional Answer" comparison under each before moving on.)*

---

## Reflection
*(After the quiz)* — What did you learn? · What confused you? · What would you do differently?

---

## Search Keywords For Further Understanding

**Core**
- `active directory account lockout event 4740 source`
- `Set-ADAccountPassword Unlock-ADAccount PowerShell`
- `repeated account lockout stale cached credential`
- `self service password reset SSPR MFA`
- `help desk identity verification before reset`

**Tools**
- `Search-ADAccount -LockedOut badPwdCount`
- `Microsoft Account Lockout tools LockoutStatus`

**Going further**
- `windows server fundamentals` (L22) · `active directory` (L18) · `provisioning/deprovisioning` (L20) ·
  `microsoft 365 MFA` (L11) · `security awareness` (L29)

**Service / Security (Lens E):**
- 🤝 `calm fast secure reset experience`, `teach lockout prevention SSPR`
- 🔒 `help desk social engineering reset attack` (MGM/Okta), `verify identity under pressure`,
  `service account lockout brute force` (→ NaviOpsSec)

---

## Lesson Status
- [ ] §8 lab completed (reset + unlock drills + Event 4740 source hunt + SSPR + scripts)
- [ ] 6-artifact evidence package committed (§9)
- [ ] Quiz answered + professional-answer comparisons (graded)
- [ ] Reflection + Search Keywords reviewed

When complete, run the Update Protocol, then move to **Lesson 22 — Windows Server Fundamentals**
(Module G).

---

*Lesson 21 written by Navi · 2026-06-21 · full-depth. Sources to cite at study time: Microsoft AD
account-lockout + Event 4740 docs, Entra SSPR, `ActiveDirectory` PowerShell; social-engineering context
→ NaviOpsSec.*
