# Lesson 25 — Software Installation & Management

**Status:** ✅ ready for self-study (full depth) · **Date written:** 2026-06-21
**Schema:** 12-section IT-Support (`docs/learning/CLAUDE_TEACHING_RULES.md`)
**Focus:** installing, removing, and managing applications — **MSI/EXE/winget/Store**, **silent/managed
deployment** (Intune/SCCM/GPO), the **software catalog + request/approval** flow, license tracking, and
fixing install/uninstall/compat/activation failures. Turns "can I get X installed?" into a clean,
governed, scalable process.
**Primary artifact:** the software-request/deploy runbook + `scripts/software_inventory.ps1`.

> **How to use this lesson:** read §1–§7, do §8 (install/uninstall via winget + inventory), produce §9,
> take the quiz, reflect. Then Lesson 26.

---

## §1 — Concept (Theory)

### What it is
**Software management** is the lifecycle of applications on endpoints: **request → approve → install →
update → uninstall**, plus tracking **what's installed where** and **licensing**. Installs come as
**MSI** (the managed, silent-deployable Windows installer), **EXE** setups, **winget** (the built-in
Windows package manager), or the **Store**. In a managed org, apps are deployed at scale via **Intune**,
**SCCM/ConfigMgr**, or **GPO software install** — silently, consistently, from an approved **catalog** —
rather than each user installing things ad-hoc.

### Why it matters for support
"Please install X," "I can't install this," "the app won't activate," "uninstall this broken thing,"
"is this software allowed?" are constant tickets. Done well, software is a **catalog of approved apps**
(self-service where possible) + a **request/approval path** for the rest + **clean removal** + **license
tracking** — governed, secure, and scalable. Done poorly, it's malware risk, license non-compliance, and
endless one-off installs.

### Three-Level Depth (Lens A)
- **Level 1 — User:** "I need this program / it won't install / it says unlicensed / please remove this."
- **Level 2 — Technician:** install/uninstall cleanly (MSI/winget/Control Panel), use the **approved
  catalog**, route non-standard apps through **approval**, fix activation/compat, and check **licensing**.
- **Level 3 — Engineer:** apps are deployed **silently at scale** (MSI `/qn` + transforms, winget,
  Intune/SCCM/GPO packages) to **device/user groups**; install state lives in the registry (Uninstall
  keys) + `Get-Package`/`Win32_Product`; **per-user vs per-machine** installs differ; **app allow/block**
  is enforced (AppLocker/WDAC/Intune) for security; **licensing** is tracked for compliance and cost;
  failures trace to MSI exit codes/logs, dependencies, or compat (the **dependency/blast-radius** thinking
  of P05/P13). This is *why* "deploy from the catalog to a group" beats "install it by hand on each PC."

### Two Teaching Approaches (Lens B) — catalog + governed lifecycle
**Approach 1 (technical):** software should be a **managed catalog**: standard apps **packaged** (MSI/
winget/Intune) and **deployed to groups silently**; non-standard apps gated by **request + approval**
(cost/security/compat); installs/uninstalls **scripted and auditable**; **inventory** tracks what's where
for license compliance and security; **app control** blocks unapproved/risky software. The lifecycle is
governed, not ad-hoc.

**Approach 2 (analogy):** software management is a **company app store + procurement**. Standard apps are
on the **shelf (catalog)** — grab them (self-service); special requests go through **purchasing/approval**
(is it licensed? safe? compatible?); IT **stocks the shelves** (packages + deploys to teams), **tracks
inventory** (who has what — licensing), and **bans unsafe products** (app control). **Where it breaks
down:** unlike a store, a single user installing a random EXE from the web can introduce **malware or a
license violation** to the whole org — which is why governance + app control matter (the "just let me
install it" instinct is the risk).

### Visual (ASCII) — the governed software lifecycle
```
   REQUEST ─▶ in catalog? ──yes──▶ SELF-SERVICE / deploy from catalog (Intune/SCCM/winget) to a GROUP (silent)
                │ no
                ▼
            APPROVAL (cost · license · security/compat) ─▶ package ─▶ deploy ─▶ INVENTORY (who has it) ─▶ license track
                                                                         │
   UNINSTALL: clean removal (MSI /x, winget uninstall) ◀────────────────┘   APP CONTROL: block unapproved/risky apps
   failures: MSI exit code/log · dependency · per-user vs per-machine · compat · activation
```

---

## §2 — Tools & Commands

| Task | GUI | CLI / PowerShell |
|---|---|---|
| Install (package manager) | Store / Company Portal | `winget install <id>` |
| Install MSI silently | — | `msiexec /i app.msi /qn /l*v install.log` |
| Uninstall | Settings → Apps / Control Panel | `winget uninstall <id>` · `msiexec /x {GUID} /qn` |
| List installed apps | Settings → Apps | `Get-Package` · registry Uninstall keys · `winget list` |
| Managed deployment | Intune / SCCM / GPO software install | (admin consoles) |
| App allow/block | AppLocker / WDAC / Intune | (policy) |
| Search a package | — | `winget search <name>` |
| Upgrade all | — | `winget upgrade --all` |

```powershell
winget search "7zip"; winget install 7zip.7zip --silent        # find + silent install from the catalog
msiexec /i app.msi /qn /l*v C:\temp\app-install.log            # silent MSI + verbose log (read on failure)
Get-Package | Sort Name | Select Name, Version, ProviderName    # what's installed (inventory)
# Read installed apps from the registry (catches non-MSI too):
Get-ItemProperty 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*' |
  Select DisplayName, DisplayVersion, Publisher | Where DisplayName
```

> **Note:** software deployment to many endpoints is change-adjacent (**pilot first** — ties to L26) and
> **app installs are a security surface** (malware via untrusted installers — L29). Bulk
> deploy/uninstall = confirm scope; lab/pilot first.

---

## §3 — Real-World Support Context & Use Cases

- **Daily tickets:** "install <app>" (Service Request — catalog/self-service or approval, L17), "can't
  install" (rights/MSI error/dependency), "won't activate" (license — L11 for M365), "remove this"
  (clean uninstall), "is this allowed?" (app control/security).
- **Standard vs non-standard:** the **catalog** of approved apps (self-service/silent deploy) handles the
  80%; non-standard apps need **approval** (cost + license + security + compat).
- **Least privilege ties in (L07):** users shouldn't be local admins to install — managed deployment or
  an elevation process handles it (don't make everyone admin to dodge install tickets).
- **License compliance:** inventory + tracking avoids both **over-spend** (unused licenses) and
  **violations** (under-licensed) — an audit and cost concern.
- **Onboarding (L20):** a new hire's role determines their app set — deploy by **group** so it's automatic.
- **Exam framing:** A+ (Core 2 — software install/configure/troubleshoot, app deployment), MD-102 (app
  management/Intune).

---

## §4 — Demonstration (worked walkthrough)

> **Ticket REQ-0501 (P4, Service Request):** *"Please install 7-Zip on my laptop. — Uma, LT-0470."*

1. **Classify:** a Service Request (L17). Is 7-Zip in the **approved catalog**? (Yes — a standard utility.)
2. **Standard path:** since it's approved + packaged, **self-service** (Company Portal) or push from the
   catalog — ideally Uma doesn't even need a ticket for catalog apps. For a one-off, deploy silently:
   `winget install 7zip.7zip --silent` (remotely/via the management tool — no local admin needed for the
   user).
3. **Verify:** `winget list` / `Get-Package` shows 7-Zip installed; Uma can open it.
4. **Contrast — non-standard:** if she'd asked for a **non-catalog** app, route to **approval** (cost/
   license/security/compat) *before* installing — don't install unvetted software (L29).
5. **Document + improve:** note the install; if catalog apps keep generating tickets, push them to
   **self-service** (deflection — L16).

The teaching point: **catalog apps = self-service/silent deploy (often no ticket needed); non-catalog =
approval first.** Governance + automation turn install requests from a manual grind into a self-service
catalog.

---

## §5 — Troubleshooting Workflow (the diagnostic spine)

**Problem class: software install / uninstall / activation / compatibility failures.**

### 1 · Symptoms
"Can't install" (error/blocked) · install hangs/fails · "needs admin" · won't uninstall / uninstall
fails · app crashes after install (L24) · "unlicensed"/won't activate · "this app is blocked" · wrong
version / conflict.

### 2 · Possible Causes (most-likely first)
1. **Permissions** — user lacks rights / needs managed deploy (don't just make them admin, L07).
2. **MSI/installer error** — bad package, exit code, missing **dependency**.
3. **App control block** — AppLocker/WDAC/Intune blocking unapproved software (maybe intended, L29).
4. **Licensing/activation** — no/expired license (M365 → L11; other apps → license server/key).
5. **Conflict/compat** — older version present, OS incompatibility, leftover from a bad uninstall.
6. **Disk/space or pending reboot** (L06/L26) — install can't complete.

### 3 · Diagnostic Steps (ordered)
| # | Check | If… | …then |
|---|---|---|---|
| 1 | In catalog? rights? | catalog + rights gap | deploy via mgmt tool (not user-admin) |
| 2 | MSI/winget exit code + `/l*v` log | error/dependency | read the log; install dependency |
| 3 | App control message ("blocked by policy") | blocked | approval/allow (or it's intended, L29) |
| 4 | License/activation state | unlicensed | assign license/key (M365 → L11) |
| 5 | Existing/old version present | conflict | clean uninstall (incl. leftovers) first |
| 6 | Disk space / pending reboot | low/pending | free space (L06) / reboot (L26) |

### 4 · Resolution Steps
Deploy via the management tool / approved path (avoid standing local admin, L07); read the MSI verbose
log + install dependencies; route blocked apps through **approval/allow** (or explain the control, L29);
fix licensing/activation (L11 for M365); **clean-uninstall** conflicts/leftovers before reinstalling;
free disk / reboot to clear pending state. For catalog apps, push to **self-service**.

### 5 · Escalation Criteria
Escalate to the app-packaging/endpoint-management team or the app vendor for: packaging a new app for
deployment, **app-control policy** changes, license **procurement**, stubborn MSI failures, and
fleet-wide deploys (pilot first — L26). Non-standard software needs **approval** (security/license).
**Unapproved/suspicious installers** → security (L29). Attach: the install log/exit code, the app + version,
what you tried.

### 6 · Post-Incident Documentation
Ticket note (app + version + method + outcome), inventory/license records updated (L27), KB (KB-0008
"request & install software"), catalog/self-service improvement (L16), Problem if a package fails fleet-
wide (L32).

---

## §6 — Ticket Simulation

> **Ticket ENT-25 / REQ-0502 (P3, Service Request):** *"I need a PDF-editing app called 'FreePDFPro' I
> found online to edit a contract — can you install it? It's urgent. — Vik, DESK-1230."*

**Triage:** a **non-standard, internet-sourced** app → this is **approval + security**, not a quick
install. Urgency is real, but installing unvetted software is exactly the risk governance prevents (L29).
Service Request → but gated.

**Worked resolution (governed, security-aware):**
1. **Don't just install it:** an unknown "free" tool from the web is a **malware/license risk** (L29) —
   the governance path exists for this.
2. **Understand the need:** Vik needs to **edit a PDF/contract**. Is there an **approved catalog app**
   that already does this (e.g. the org's standard PDF editor / Acrobat)? → If yes, offer that **now**
   (solves the urgent need *safely*, no approval delay).
3. **If no catalog option fits → approval path:** submit the non-standard request for **review** —
   security (is FreePDFPro safe/reputable?), **licensing** (is "free" really licensed for business use?),
   and **compat** — *before* any install. Set Vik's expectation on the approval timeline.
4. **Never bypass app control:** if it's blocked by policy, that's the control working (L29) — don't
   disable it to "help."
5. **Resolve the urgency safely:** give Vik the **approved** PDF tool for the contract today; the
   non-standard request proceeds (or is declined) through approval.
6. **Document:** the request, the safe alternative provided, and the approval routing.

**The professional ticket note:**
```
SUMMARY: Vik requested an internet-sourced "FreePDFPro" to edit a contract urgently. Did NOT install
unvetted software; met the urgent need with the approved catalog PDF editor today, and routed FreePDFPro
through security/license approval as a non-standard request.
REQUEST: edit a PDF/contract urgently (asked for a specific non-catalog "free" app).
ASSESSMENT: unknown internet installer = malware + license risk (L29); governance/approval applies.
ACTIONS: identified the real need (PDF editing) → provided the APPROVED catalog PDF editor immediately
(urgent need solved safely); submitted FreePDFPro for security + license + compat review (non-standard).
RESULT: contract editable today with vetted software; no unvetted install; approval pending for the
requested app.
FOLLOW-UP: if FreePDFPro is rejected, communicate the approved alternative; KB-0008 (how to request
software) shared; catalog reviewed for PDF-editing coverage.
```

---

## §7 — Service Desk / ITIL Perspective

- **Install requests = Service Requests** (catalog/self-service = standard, pre-approved; non-standard =
  request + **approval**). Clean removal/conflict = Incident.
- **The catalog + self-service is the deflection/standardization win** (L16/L17): standard apps need no
  ticket; only exceptions reach a human — huge volume reduction.
- **App deployment is change-adjacent** (L26): pushing software to many endpoints is **piloted** (a ring)
  with rollback — a bad package can break the fleet.
- **License management** is a cost + compliance responsibility (inventory → L27): avoid both over-spend
  and violations.
- **Security gate:** non-standard/internet software needs review; **app control** + least privilege (L07)
  + no standing admin are the controls (L29). The desk fulfills within governance.

---

## §8 — Practical Lab (build this yourself)

**Goal:** install/uninstall cleanly and silently, inventory installed software, and recognize the
governed path.

### Lens C — Manual → Automation → Why
- **Manual:** click through a setup.exe / Control Panel uninstall.
- **Automated:** `winget`/`msiexec /qn` for **silent** install/uninstall; `software_inventory.ps1` reports
  installed apps + versions (and flags unapproved/unknown publishers) locally or **fleet-wide**.
- **Why:** silent + scripted = consistent, no-touch deployment (the catalog model); inventory is essential
  for **license compliance** and **security** (spotting unapproved/risky software across the fleet) — you
  can't manage what you can't see.

### Steps
1. **Silent install:** `winget search` then `winget install <id> --silent` for a benign utility; verify
   with `winget list`/`Get-Package`.
2. **MSI + log:** install an MSI with `/qn /l*v log.txt`; read the log; note the **exit code** on success/
   failure.
3. **Clean uninstall:** `winget uninstall`/`msiexec /x`; confirm it's gone from the registry Uninstall
   keys (no leftovers).
4. **Inventory:** read installed apps from `Get-Package` **and** the registry Uninstall keys (catches
   non-MSI); compare to a notional approved list.
5. **Governance awareness:** map the **catalog → self-service** vs **non-standard → approval** paths;
   note where app control (AppLocker/Intune) fits.
6. **Write `scripts/software_inventory.ps1`** (installed apps + versions + publisher, flag unknown/
   unapproved) and the software-request/deploy runbook.

### Lens D — the raw artifact (inventory surfaces the risk)
```
> .\software_inventory.ps1   (excerpt)
   DisplayName        Version   Publisher              Flag
   -----------        -------   ---------              ----
   7-Zip              23.01     Igor Pavlov            OK (approved catalog)
   Acrobat Reader     2024.x    Adobe                  OK
   FreePDFPro         1.0       (unknown)              ⚠ unapproved + unknown publisher → review (L29)
   GotoMyPC           ...       (remote tool)          ⚠ unsanctioned remote-access tool → security review
#   Inventory is both a LICENSE tool and a SECURITY tool — it surfaces unapproved/unknown-publisher and
#   risky (remote-access) software across the fleet so you can remediate. "What's installed where" is the
#   foundation of both compliance and endpoint security.
```

---

## §9 — GitHub Artifact (the 6-artifact evidence package)

1. **Runbook:** `docs/runbooks/software-request-deploy.md` — catalog/self-service vs approval; silent
   install/uninstall.
2. **Troubleshooting Guide:** `docs/troubleshooting/software-install.md` — the full spine (rights/MSI/
   app-control/license/conflict).
3. **Ticket Notes:** `docs/tickets/ENT-25-nonstandard-app-request.md` — the worked ENT-25.
4. **KB Article:** `docs/kb/` — KB-0008 "Request & install software" (catalog + how to request
   non-standard) for end users.
5. **Incident Report:** an unapproved-software/malware-via-installer event or a failed fleet package as an
   incident/problem (L29/L32).
6. **Portfolio Artifact:** §10 bullet + the catalog/governance + inventory-as-security talking points.
7. **Script:** `scripts/software_inventory.ps1` (`Invoke-ScriptAnalyzer`-clean; flags unapproved apps).

---

## §10 — Portfolio Artifact

- **Resume bullet:** *"Managed application lifecycle (winget/MSI silent deploy, catalog + request/approval
  governance, clean uninstall) and built a PowerShell software-inventory script that surfaces unapproved/
  unknown-publisher software fleet-wide for license-compliance and security remediation."*
- **Interview talking point:** the **governed software lifecycle** (catalog/self-service vs approval),
  **silent deployment** (winget/`msiexec /qn`) without standing local admin (L07), and **inventory as both
  a license and a security tool** — plus why you don't just install an internet "free" app.
- **Serves:** Desktop Support, IT Support Specialist, Junior SysAdmin.

---

## §11 — Certification Crossover Notes

- **CompTIA A+ (Core 2):** software install/configure/troubleshoot, deployment methods. **MD-102:** app
  management & deployment (Intune). Detail in `alignment/CERTIFICATION-MAPPING.md`.

---

## §12 — Support Notes (Lens E — Service & Security)

**🤝 Service:** users want their app *now* — meet the real need fast (often via an approved equivalent)
while honoring governance; self-service catalogs make the common case instant. Explain approval timelines
honestly for non-standard asks.

**🔒 Security:** software is a primary **malware vector** — never install **unvetted internet installers**
(L29); enforce **app control** (AppLocker/WDAC/Intune) + **least privilege** (no standing local admin so
users can't install arbitrary software, L07); use the **inventory** to hunt unapproved/risky software
(remote-access tools, unknown publishers — NaviOpsSec); keep apps **patched** (vulnerable apps are exploit
targets — L26); and verify installer **integrity** (official source/signature). Bulk deploy is
change-controlled (pilot — L26) so a bad/over-privileged package doesn't hit the fleet.

---

## Quiz (Interview-Style, Graded)

**Q1.** What's the difference between deploying a catalog app and handling a non-standard software request?
> **Your answer:**

**Q2.** How do you install software silently, and why does that matter for managed deployment?
> **Your answer:**

**Q3.** A user can't install an app and it says they need admin rights. What's the right fix — and what's
the wrong one?
> **Your answer:**

**Q4.** **Scenario:** a user urgently wants a "free" PDF tool they found online installed on their work
laptop. What do you do?
> **Your answer:**

**Q5.** Why is a software inventory a security tool, not just a license tool?
> **Your answer:**

*(Request the "Professional Answer" comparison under each before moving on.)*

---

## Reflection
*(After the quiz)* — What did you learn? · What confused you? · What would you do differently?

---

## Search Keywords For Further Understanding

**Core**
- `winget install uninstall silent`
- `msiexec /qn /l*v silent install log`
- `software deployment intune sccm gpo`
- `applocker wdac application control`
- `software inventory installed programs powershell`

**Tools**
- `Get-Package registry uninstall keys`
- `company portal self-service catalog`

**Going further**
- `patch management` (L26) · `asset management` (L27) · `endpoint troubleshooting` (L24) ·
  `user accounts/least privilege` (L07) · `security awareness` (L29)

**Service / Security (Lens E):**
- 🤝 `self-service software catalog deflection`, `approved alternative fast`
- 🔒 `no unvetted installers malware`, `application control least privilege`, `inventory unapproved software` (→ NaviOpsSec)

---

## Lesson Status
- [ ] §8 lab completed (silent install/uninstall + MSI log + inventory + software_inventory.ps1 + runbook)
- [ ] 6-artifact evidence package committed (§9)
- [ ] Quiz answered + professional-answer comparisons (graded)
- [ ] Reflection + Search Keywords reviewed

When complete, run the Update Protocol, then move to **Lesson 26 — Patch Management**.

---

*Lesson 25 written by Navi · 2026-06-21 · full-depth. Sources to cite at study time: CompTIA A+ 220-1102
(software/deployment), Microsoft winget/Intune app-deployment docs.*
