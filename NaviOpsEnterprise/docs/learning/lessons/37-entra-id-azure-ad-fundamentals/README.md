# Lesson 37 — Entra ID (Azure AD) Fundamentals for IT Support

**Status:** 🟡 stub — scaffold only (author on demand) · **Date written:** 2026-06-28
**Schema:** 12-section IT-Support (`docs/learning/CLAUDE_TEACHING_RULES.md`)
**Intended study position:** after **L11** (M365) and **L18** (Active Directory) — the cloud-identity counterpart to on-prem AD. Appended as L37 to avoid renumbering existing lessons.
**Why this lesson exists (job signal):** Azure shows up for support/sysadmin roles *as identity* — **Entra ID** is where help-desk and junior-sysadmin tickets actually touch the cloud (MFA, sign-in failures, conditional access, hybrid sync). This is the platform's natural, cheapest Azure entry point and pairs with NaviOps L31 (Azure bridge).
**Focus:** Entra ID identity, **MFA / sign-in troubleshooting**, **Conditional Access**, RBAC roles, and **hybrid identity** (Entra Connect sync with on-prem AD).
**Primary artifact (TODO):** an Entra sign-in-failure runbook + `scripts/entra_signin_report.ps1` (Microsoft Graph PowerShell).

> **How to use this lesson:** read §1–§7, do §8 in a dev-tenant model, produce §9, take the quiz,
> reflect. Builds directly on L11 (M365) and L18 (AD).

---

## §1 — Concept (Theory)
> TODO — what Entra ID is (cloud identity/IdP), tenants, users/groups, **MFA**, **Conditional Access**, RBAC roles; how it differs from on-prem AD (no Kerberos/OU/GPO — it's token/OAuth/SAML).
> Lens A (User → Technician → Engineer): "I can't sign in" → reset MFA / check CA policy → token/OAuth flow + Entra Connect sync internals.
> Lens B (technical + analogy + ASCII): user → Entra ID (authn) → Conditional Access (authz/policy) → app.

## §2 — Tools & Commands
> TODO — Entra admin center (entra.microsoft.com); **Microsoft Graph PowerShell** (`Connect-MgGraph`, `Get-MgUser`, `Get-MgAuditLogSignIn`); sign-in logs; `Get-MgUserAuthenticationMethod`.

## §3 — Real-World Support Context & Use Cases
> TODO — MFA resets, blocked sign-ins, "impossible travel" CA blocks, license-vs-identity confusion, hybrid sync gaps, password write-back, guest/B2B access.

## §4 — Demonstration (worked walkthrough)
> TODO — walk a real sign-in failure: open sign-in logs → read the failure reason/CA policy → identify cause → resolve (reset MFA / exclude / unblock).

## §5 — Troubleshooting Workflow (the diagnostic spine — never skipped)
### 1 · Symptoms
> TODO — "can't sign in", MFA loop, "access blocked by your organization".
### 2 · Possible Causes (most-likely first)
> TODO — MFA not registered, Conditional Access block, disabled/locked account, expired license, sync error, stale token.
### 3 · Diagnostic Steps (ordered)
> TODO — sign-in logs → failure code → CA policy evaluated → account state → license → sync status.
### 4 · Resolution Steps
> TODO — re-register/reset MFA, adjust/exclude CA, enable account, assign license, force sync.
### 5 · Escalation Criteria
> TODO — tenant-wide CA/MFA outage, Entra Connect failure → escalate to identity/sysadmin team.
### 6 · Post-Incident Documentation
> TODO — the resolution note + KB update.

## §6 — Ticket Simulation
> TODO — a realistic ticket ("User MFA-locked after new phone") worked end-to-end with a professional resolution note. Redaction check (no real tenant/user data).

## §7 — Service Desk / ITIL Perspective
> TODO — identity tickets as incidents vs requests; access reviews as standard changes; least-privilege admin roles (PIM).

## §8 — Practical Lab (build this yourself)
> TODO — Lens C (GUI → PowerShell → at scale): reset one user's MFA in the portal → `entra_signin_report.ps1` via Graph → schedule a sign-in audit.
> Build: connect Graph PowerShell; pull last-N sign-ins for a user; flag failures/risky sign-ins; write a runbook. Lens D: the raw sign-in log record as the artifact.

## §9 — GitHub Artifact (the 6-artifact evidence package / Artifact Contract)
> TODO — script (`entra_signin_report.ps1`) + config/notes + ticket notes (§6) + runbook + incident report (from §8 drill) + portfolio artifact (§10). Redacted.

## §10 — Portfolio Artifact
> TODO — resume bullet + LinkedIn line + interview talking point ("triaged Entra ID sign-in failures via Graph PowerShell / Conditional Access").

## §11 — Certification Crossover Notes
> TODO — **MS-900** (M365 Fundamentals), **SC-900** (Security/Identity Fundamentals), **AZ-104** identity slice; pairs with NaviOps L31 (Azure bridge).

## §12 — Support Notes (Lens E — Service & Security)
> TODO — 🔒 `MFA fatigue / push bombing`, `consent phishing`, `legacy auth bypass`, `least-privilege admin (PIM)`, `conditional access as the control plane`, `break-glass accounts`.

---

## Quiz (Interview-Style, Graded)
> TODO — 5–8 questions (Entra ID vs on-prem AD; what Conditional Access does; MFA reset steps; hybrid identity/Entra Connect; where licensing fits).

## Reflection
> TODO — how cloud identity differs from the AD model in L18; what surprised you.

## Search Keywords For Further Understanding
> TODO — `entra id sign-in logs`, `conditional access policies`, `microsoft graph powershell`, `entra connect hybrid identity`, `reset mfa entra admin center`, `SC-900`.

---

## Lesson Status
- [ ] §8 lab completed (portal MFA reset + Graph sign-in report + runbook)
- [ ] 6-artifact evidence package committed (§9)
- [ ] Quiz answered + professional-answer comparisons (graded)
- [ ] Reflection + Search Keywords reviewed

---

*Lesson 37 scaffolded by Navi v28 · 2026-06-28 · stub — WebSearch sources to be gathered at authoring time (≥2 validating sources, e.g. learn.microsoft.com Entra).*
