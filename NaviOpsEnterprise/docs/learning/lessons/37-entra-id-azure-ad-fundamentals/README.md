# Lesson 37 — Entra ID (Azure AD) Fundamentals for IT Support

**Status:** ✅ ready for self-study (full depth) · **Date written:** 2026-06-28
**Schema:** 12-section IT-Support (`docs/learning/CLAUDE_TEACHING_RULES.md`)
**Focus:** **Entra ID** (formerly Azure AD) — the cloud identity where help-desk and junior-sysadmin
tickets actually touch Azure: **sign-in failures**, **MFA resets**, **Conditional Access**, **RBAC
roles**, and **hybrid identity** (Entra Connect sync with on-prem AD). The diagnostic spine here is
the **sign-in log**.
**Primary artifact:** an Entra sign-in-failure runbook + `scripts/entra_signin_report.ps1`
(Microsoft Graph PowerShell).

> **How to use this lesson:** read §1–§7, do §8 in a dev-tenant model, produce §9, take the quiz,
> reflect. Builds on **L11 (M365)** and **L18 (Active Directory)** — Entra ID is the cloud
> counterpart to the on-prem AD you already learned. Pairs with **NaviOps L31 (Azure bridge)** for
> the infrastructure side.

---

## §1 — Concept (Theory)

### What it is
**Entra ID** is Microsoft's **cloud identity provider (IdP)** — the directory that authenticates
users into Microsoft 365, Azure, and thousands of SaaS apps. A **Tenant** is your organization's
directory; it holds **users**, **groups**, **app registrations**, and the policies that govern how
people sign in (**MFA**, **Conditional Access**). Authorization for Azure *resources* is **Azure
RBAC** (separate — see L31); Entra ID is primarily about **who you are** and **how you prove it**.

### Why it matters for support
A huge share of modern tickets are *identity* tickets: "I can't sign in," "MFA stopped working,"
"it says my access is blocked." Per [Microsoft's sign-in troubleshooting guide](https://learn.microsoft.com/en-us/entra/identity/monitoring-health/howto-troubleshoot-sign-in-errors),
the **sign-in logs** are the fastest way to stop guessing — they show success/failure, the
**Conditional Access** decision, the authentication method, the client app, and a correlation ID.
Reading them *is* the core skill of this lesson.

### How it differs from on-prem AD (L18)
| On-prem AD (L18) | Entra ID (cloud) |
|---|---|
| Kerberos / NTLM, domain join | OAuth 2.0 / OIDC / SAML tokens |
| OUs + Group Policy (GPO) | Groups + **Conditional Access** policies |
| `Get-ADUser` | `Get-MgUser` (Graph PowerShell) |
| On your network | Internet-facing IdP, MFA front and center |

Many orgs run **hybrid**: on-prem AD is synced *up* to Entra ID by **Entra Connect**, so the same
user exists in both — a frequent source of "synced wrong / not synced" tickets.

### Lens A — Three-Level Depth (User → Technician → Engineer)
- **L1 User:** "I can't sign in / approve the MFA prompt."
- **L2 Technician:** open **Sign-in logs**, read the **failure reason** + **Conditional Access**
  tab, then act — reset MFA, unblock, or assign a license.
- **L3 Engineer (Lens D):** the underlying mechanism is a **token** flow — Entra issues an
  OAuth/OIDC token after authn + policy evaluation; the **sign-in log entry** (with its
  **correlation ID**) is the artifact that records exactly which policy/condition decided the
  outcome. In hybrid, **Entra Connect** sync state determines whether the object is even correct.

### Lens B — Two Teaching Approaches (Technical + Analogy + Visual)
- **Analogy:** Entra ID is the **building's front-desk security**. The **password** is your ID
  badge; **MFA** is the second guard who calls your phone to confirm it's really you; **Conditional
  Access** is the rule sheet ("contractors can't enter after 6pm or from outside the city"). The
  **sign-in log** is the front-desk visitor register — every attempt, allowed or denied, with the
  reason.
- **ASCII:**
```
 user ─password─> [ Entra ID authn ] ─MFA?─> [ Conditional Access policy ] ─allow─> token ─> app (M365/Azure/SaaS)
                         │                            │
                     sign-in log  <───── records reason/CA decision ─────┘  (your diagnostic spine)
```

---

## §2 — Tools & Commands
**Portal:** Entra admin center (`entra.microsoft.com`) → **Identity > Users**; **Monitoring &
health > Sign-in logs**; **Protection > Conditional Access** (+ the **What If** tool).

**Microsoft Graph PowerShell** (the scriptable path):
```powershell
Connect-MgGraph -Scopes "User.Read.All","AuditLog.Read.All","UserAuthenticationMethod.ReadWrite.All"

Get-MgUser -UserId user@contoso.com -Property DisplayName,AccountEnabled,UserPrincipalName
Get-MgUserAuthenticationMethod -UserId user@contoso.com          # what MFA methods are registered
# Recent sign-ins for a user (the diagnostic spine, scriptable):
Get-MgAuditLogSignIn -Filter "userPrincipalName eq 'user@contoso.com'" -Top 20 |
  Select-Object createdDateTime, @{n='status';e={$_.status.errorCode}}, appDisplayName, conditionalAccessStatus
```
Per [Microsoft's Graph reporting cmdlets](https://learn.microsoft.com/en-us/entra/identity/monitoring-health/reference-powershell-reporting),
sign-in data is available via Graph PowerShell. **MFA reset** ("require re-register MFA") deletes
the user's registered phone/Authenticator/OATH methods so they set up fresh on next sign-in
([Microsoft Learn](https://learn.microsoft.com/en-us/entra/identity/authentication/howto-mfa-userdevicesettings)).
You typically need **Authentication Administrator** (or Privileged Auth Admin / Global Admin) to
reset another user's MFA.

---

## §3 — Real-World Support Context & Use Cases
1. **MFA reset** — user got a new phone; the old Authenticator registration is dead → require
   re-register MFA.
2. **Blocked sign-in** — Conditional Access blocks an "impossible travel" or untrusted-location
   attempt; legitimate user is stuck → read the CA tab, use **What If**, exclude/adjust if valid.
3. **License vs identity confusion** — account is fine but the user has no mailbox/app → it's a
   *licensing* gap (L11), not an identity one.
4. **Hybrid sync gap** — a change made on-prem (L18) hasn't reached Entra → check Entra Connect
   sync status / force a sync.

---

## §4 — Demonstration (worked walkthrough)
*Ticket: "Sarah can't sign in to Outlook on the web — says access is blocked."*
1. Entra admin center → **Sign-in logs** → filter to `sarah@contoso.com`, last 24h.
2. Open the failed event → **Status** shows `Failure`, error `53003` (blocked by Conditional
   Access).
3. Click the **Conditional Access** tab → policy *"Block legacy / require compliant device"*
   evaluated **Failure** — Sarah is on a personal, non-compliant laptop.
4. Run **What If** for Sarah + that app + her location to confirm which policy fires.
5. Resolution: either she uses a compliant device, or (if policy allows) IT grants a scoped
   exception — **document why**.

---

## §5 — Troubleshooting Workflow (the diagnostic spine — never skipped)

### 1 · Symptoms
"Can't sign in," MFA prompt loops, "Access blocked by your organization," repeated re-auth.

### 2 · Possible Causes (most-likely first)
1. Wrong password / **"Error validating credentials"** (most common —
   [Microsoft Learn](https://learn.microsoft.com/en-us/entra/identity/monitoring-health/howto-troubleshoot-sign-in-errors)).
2. **MFA** not registered / new phone / broken Authenticator.
3. **Conditional Access** block (location/device/risk).
4. Account **disabled / locked**.
5. **License** missing (looks like "no access" but is licensing).
6. **Hybrid sync** error (object stale/missing in Entra).

### 3 · Diagnostic Steps (ordered)
**Sign-in logs first, always.** Find the event → read the **failure reason / error code** → open
the **Conditional Access** tab to see which policy decided → use **What If** to simulate → check
account state → check license → check sync. (Per
[Microsoft CA troubleshooting](https://learn.microsoft.com/en-us/entra/identity/conditional-access/troubleshoot-conditional-access),
**What If** is the single most useful identity-access debugging tool.)

### 4 · Resolution Steps
Reset/re-register **MFA**; adjust or scope a **CA exclusion** (with justification); **enable** the
account; **assign** the license; **force** an Entra Connect sync.

### 5 · Escalation Criteria
Tenant-wide CA/MFA outage, an **Entra Connect** failure, or a suspected **account compromise**
(impossible-travel + MFA changes) → escalate to the identity/sysadmin team and treat as a security
incident.

### 6 · Post-Incident Documentation
Record the error code, the deciding CA policy, the fix, and **why** any exception was granted →
update the KB.

---

## §6 — Ticket Simulation
> **Ticket TS-4471 — "MFA stopped working after I got a new phone, now I'm locked out."**
> **Priority:** High (user fully blocked) · **Channel:** phone

**Worked resolution (professional note):**
> Verified caller identity per policy (manager callback + employee ID — **not** via the broken
> account). Sign-in logs showed error `500121` (auth failed at MFA — no usable method). Confirmed
> old device deregistered. Action: **required re-registration of MFA** (cleared stale
> Authenticator/phone methods) and had the user enroll the Authenticator app on the new phone
> during the call. Test sign-in succeeded. Advised enabling a **backup method** (second factor).
> Closed; KB-Entra-MFA-Reset linked. **Redaction:** no real UPN/phone/employee-ID in the public
> artifact.

---

## §7 — Service Desk / ITIL Perspective
Identity tickets split into **incidents** (user blocked now — restore service fast) vs **requests**
(new access — fulfil via a controlled process). Access changes are **standard changes** governed by
**access reviews**. Admin identity itself follows **least privilege** — use **Privileged Identity
Management (PIM)** for just-in-time elevation rather than standing Global Admin. Verify identity
**out-of-band** before resetting MFA (the reset itself is a social-engineering target, §12).

---

## §8 — Practical Lab (build this yourself)

### Lens C — GUI → PowerShell → at scale
- **GUI:** in a dev tenant, reset one user's MFA in the Entra admin center and read their sign-in
  logs.
- **PowerShell:** `entra_signin_report.ps1` via Graph — pull last-N sign-ins for a user, flag
  failures/risky sign-ins, output a clean report.
- **At scale:** schedule the report as a daily sign-in audit.

### Steps
1. Set up a **dev tenant** model (Microsoft 365 Developer program) or use sandbox data.
2. `Connect-MgGraph` with the read scopes in §2.
3. Write `entra_signin_report.ps1`: for a given UPN, `Get-MgAuditLogSignIn` last 20, project
   `time / errorCode / app / CA status`, write a markdown report, highlight any `Failure`.
4. In the GUI, trigger a failure (block via a test CA policy) → confirm your script surfaces it.
5. Reset MFA for a test user; document the runbook steps.
6. **Redaction:** scrub real UPNs/IDs from the committed report.

### Lens D — the raw artifact
The **sign-in log record** (with `correlationId`, `errorCode`, and the `conditionalAccess`
decision) is the ground truth — every resolution traces back to one log entry.

---

## §9 — GitHub Artifact (the 6-artifact evidence package / Artifact Contract)
1. **Script** — `scripts/entra_signin_report.ps1` (read-scoped Graph, redacted output).
2. **Runbook** — "Entra sign-in failure triage" (the §5 spine as a checklist).
3. **Troubleshooting guide** — error-code → cause → fix table (from §5).
4. **Ticket notes** — TS-4471 (§6) with the professional resolution note.
5. **Incident report** — the §8 drill (induced CA block → detected → resolved), redacted.
6. **Portfolio artifact** — the résumé bullet + LinkedIn line + talking point (§10).

---

## §10 — Portfolio Artifact
- **Résumé bullet:** "Triaged Microsoft Entra ID sign-in failures using sign-in logs + Graph
  PowerShell; resolved MFA and Conditional Access blocks and authored the triage runbook."
- **LinkedIn line:** "Hands-on with Entra ID identity support — MFA resets, Conditional Access
  troubleshooting, and Graph PowerShell reporting."
- **Interview talking point:** walk a blocked sign-in from log → error code → CA tab → What If →
  fix, and explain verifying identity out-of-band before an MFA reset.

---

## §11 — Certification Crossover Notes
- **MS-900** (Microsoft 365 Fundamentals) — Entra ID identity basics.
- **SC-900** (Security, Compliance & Identity Fundamentals) — Conditional Access, MFA, Zero Trust.
- **AZ-104** — the Entra identity slice (users/groups/RBAC).
- Pairs with **NaviOps L31** (Azure bridge) for the infrastructure-RBAC side.

---

## §12 — Support Notes (Lens E — Service & Security)
> Frameworks: [MITRE ATT&CK](https://attack.mitre.org/) · [Entra CA troubleshooting (Microsoft Learn)](https://learn.microsoft.com/en-us/entra/identity/conditional-access/troubleshoot-conditional-access).

- 🔒 **MFA fatigue / push-bombing** — attacker spams approval prompts hoping the user taps "approve";
  defense: number-matching, and *never* approve an unexpected prompt.
- 🔒 **Help-desk social engineering** — attackers call posing as a user to get **MFA reset**;
  defense: strict **out-of-band identity verification** before any reset.
- 🔒 **Consent phishing / legacy-auth bypass** — block legacy auth; review app consents.
- 🛡️ **Least privilege** — **PIM** for admin roles, **break-glass** accounts excluded from CA, and
  **alert** on impossible-travel + MFA-method changes (compromise signal).

---

## Quiz (Interview-Style, Graded)

**Q1.** What is **Entra ID**, and how does it differ from the on-prem **Active Directory** in L18
(name two concrete differences)?

> **Your answer:**

**Q2.** A user reports "access blocked." What's your **first** step, and what specifically do you
read in that artifact?

> **Your answer:**

**Q3.** What does a **Conditional Access** policy do, and what tool simulates whether one will fire
for a given user/app/location?

> **Your answer:**

**Q4.** Walk through resetting MFA for a user who got a new phone — and what must you do *before*
the reset?

> **Your answer:**

**Q5.** What is **hybrid identity / Entra Connect**, and how can it cause a "the change I made
isn't showing up" ticket?

> **Your answer:**

**Q6.** Describe an **MFA-fatigue** attack and two defenses. Why is the help desk itself a target?

> **Your answer:**

---

## Reflection
- How does cloud identity differ from the AD model you learned in L18?
- What surprised you about how much the **sign-in log** tells you?
- Where does *licensing* masquerade as an *identity* problem?

## Search Keywords For Further Understanding
- `entra id sign-in logs error codes`
- `conditional access what if tool`
- `reset mfa entra admin center require re-register`
- `microsoft graph powershell get-mgauditlogsignin`
- `entra connect hybrid identity sync`
- `SC-900 conditional access`
- 🔒 `mfa fatigue push bombing defense` · `help desk social engineering mfa reset`

---

## Lesson Status
- [ ] §8 lab completed (portal MFA reset + Graph sign-in report + runbook)
- [ ] 6-artifact evidence package committed (§9)
- [ ] Quiz answered + professional-answer comparisons (graded)
- [ ] Reflection + Search Keywords reviewed

When complete, run the Update Protocol. Pairs with **NaviOps L31 (Azure bridge)** for the
infrastructure/RBAC side of Azure.

---

*Lesson 37 written by Navi v28 · 2026-06-28 · WebSearch sources:
[Troubleshoot Entra sign-in errors (Microsoft Learn)](https://learn.microsoft.com/en-us/entra/identity/monitoring-health/howto-troubleshoot-sign-in-errors),
[Troubleshoot sign-in with Conditional Access + What If (Microsoft Learn)](https://learn.microsoft.com/en-us/entra/identity/conditional-access/troubleshoot-conditional-access),
[Manage MFA authentication methods (Microsoft Learn)](https://learn.microsoft.com/en-us/entra/identity/authentication/howto-mfa-userdevicesettings),
[Graph PowerShell reporting cmdlets (Microsoft Learn)](https://learn.microsoft.com/en-us/entra/identity/monitoring-health/reference-powershell-reporting),
[12 common Entra ID issues & fixes (AdminDroid)](https://blog.admindroid.com/12-common-microsoft-entra-id-issues-fixes-for-admins/)*
