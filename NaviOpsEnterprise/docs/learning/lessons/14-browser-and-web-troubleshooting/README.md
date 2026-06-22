# Lesson 14 — Browser & Web Troubleshooting

**Status:** ✅ ready for self-study (full depth) · **Date written:** 2026-06-21
**Schema:** 12-section IT-Support (`docs/learning/CLAUDE_TEACHING_RULES.md`)
**Focus:** the browser is the modern desktop — almost every business app is a web app, so "the website
won't load / log me in / display right" is a constant ticket. Covers cache/cookies/extensions,
**certificate errors**, proxy, and **SSO/web-app login failures**, with a method that separates
"this site," "this browser/profile," and "the network."
**Primary artifact:** the browser troubleshooting guide + KB.

> **How to use this lesson:** read §1–§7, do §8 (use DevTools + the cache/cookie/extension drills),
> produce §9, take the quiz, reflect. Then Lesson 15.

---

## §1 — Concept (Theory)

### What it is
A browser (Chrome/Edge/Firefox) fetches web pages and runs web apps. To load `https://app.corp.example`
it must: **resolve the name** (DNS, L09), **connect securely** (TLS — validating the site's
**certificate**), possibly go through a **proxy**, then render **HTML/JS/cookies** and authenticate
(often via **SSO** to Entra/Workspace, L11/L12). It stores **cache** (copies of page assets),
**cookies** (your session/login state), saved **passwords**, and **extensions** (add-ons that can
modify pages). Each is a failure point.

### Why it matters for support
Most line-of-business tools are now web apps (M365, the ticketing system, HR, finance, SaaS). So a huge
share of "the app is broken" is really **browser** — stale cache, a bad cookie/session, a misbehaving
extension, a certificate warning, a proxy block, or an SSO loop. Knowing the browser stack turns "the
app's down" into "clear this, and it works."

### Three-Level Depth (Lens A)
- **Level 1 — User:** "the website won't load / won't log me in / looks broken / says 'not secure'."
- **Level 2 — Technician:** isolate — does it fail in an **incognito/private window** (rules out
  cache/cookies/extensions)? in a **different browser** (rules out one browser's profile)? on a
  **different machine/network** (rules out the device/network vs the site)? Then clear cache/cookies,
  disable extensions, or address the cert/proxy/SSO.
- **Level 3 — Engineer:** **TLS** validates the server cert against a trusted **CA chain** and the
  hostname + expiry (a "not secure"/`NET::ERR_CERT_*` error = expired/mismatched/untrusted cert or a
  missing internal **root CA**); **cookies** hold the auth **session** (a stale/corrupt cookie causes
  login loops); **SSO** redirects to the IdP (Entra) and back (a loop = clock skew, cookie block,
  third-party-cookie policy, or a Conditional Access denial, L11); a **proxy/PAC** can block or
  misroute requests; **extensions** inject scripts that can break a site. **DevTools** (the Network/
  Console tabs) shows the exact failing request/status. This is *why* incognito and "clear cookies"
  fix so much.

### Two Teaching Approaches (Lens B) — what loading a web app involves
**Approach 1 (technical):** a page load is a chain — DNS → TLS (cert) → (proxy) → HTTP request → cookies/
session → render/JS → (SSO auth). A failure at any link breaks the page; **incognito** disables the
profile-state links (cache/cookies/extensions) so a working incognito session proves the problem is
*local browser state*, not the site or network.

**Approach 2 (analogy):** opening a web app is **entering a members' club**. **DNS** is finding the
address; the **TLS certificate** is the club proving it's the *real* club (a forged/expired ID = the
"not secure" warning — don't go in); your **cookie** is the **wristband** showing you already paid
(checked in); an **extension** is a **gadget you brought** that might set off the metal detector
(breaking the page); **incognito** is **walking in as a brand-new guest with nothing in your pockets**.
**Where it breaks down:** unlike a club, a stale wristband (cookie) can put you in an endless "prove
who you are" loop (SSO) that only a fresh wristband (clear cookies) ends.

### Visual (ASCII) — the page-load chain & fixes
```
   URL ─▶ DNS(L09) ─▶ TLS/cert ─▶ (proxy) ─▶ HTTP ─▶ cookies/session ─▶ render/JS ─▶ SSO(Entra)
            │            │            │          │          │               │            │
        name fails    cert error   blocked    404/500   login loop /     extension    SSO loop /
        (→L09)        (expired/    (proxy/PAC) (server)  stale session    breaks page  CA denial(L11)
                       internal CA)                       → clear cookies  → disable ext

   ISOLATE FAST:  incognito (no cache/cookies/ext)  ·  different browser  ·  different machine/network
```

---

## §2 — Tools & Commands

| Task | How |
|---|---|
| Incognito/Private window | Ctrl+Shift+N (Chrome/Edge) / Ctrl+Shift+P (Firefox) |
| Clear cache & cookies | Ctrl+Shift+Del → pick range/site |
| Clear cookies for **one** site | site lock icon → Cookies/Site settings |
| Manage extensions | `chrome://extensions` / `edge://extensions` / `about:addons` |
| Inspect the failing request | **DevTools** (F12) → **Network** / **Console** tabs |
| View the certificate | lock icon → Certificate (issuer, validity, hostname) |
| Proxy settings | Windows Settings → Network → Proxy; check PAC URL |
| Reset / new browser profile | browser settings → Reset / new profile |
| Hard reload (bypass cache) | Ctrl+F5 / Shift+reload |

```text
# Tie-ins to earlier lessons:
nslookup app.corp.example        # name resolves? (L09)  → is it DNS, not the browser
ipconfig /flushdns               # stale DNS answer (L09)
# DevTools Network tab: look at the failing request's STATUS — 401/403 (auth), 404/500 (server),
#   (failed)/ERR_CERT_* (TLS), ERR_PROXY_* (proxy). The status routes your fix.
```

---

## §3 — Real-World Support Context & Use Cases

- **"The app is down" usually isn't:** when one user can't use a web app but others can, it's almost
  always **their browser state** (cache/cookies/extension) or **their machine/network** — incognito
  proves it in seconds.
- **Certificate errors:** an **expired** public cert (the site's fault — wait/escalate to site owner);
  a **name-mismatch** or **untrusted internal CA** (the device is missing the corporate **root CA** —
  push it via GPO/Intune, L19/L26). Teach users *not* to blindly click through real cert warnings.
- **SSO login loops:** stale cookies, blocked third-party cookies, clock skew, or a **Conditional
  Access** denial (L11) — clear cookies first, then check the IdP side.
- **Extensions** break enterprise apps surprisingly often (ad-blockers, script blockers) — disable to
  test.
- **Proxy/filtering:** "this site is blocked" may be a **web filter doing its job** (security), not a
  bug — recognize policy vs fault.
- **Exam framing:** A+ (Core 2) browser configuration/security, certificates, proxy; Network+ (DNS/
  TLS/proxy concepts).

---

## §4 — Demonstration (worked walkthrough)

> **Ticket INC-0511 (P2):** *"I can't log into our HR portal — it just keeps bouncing me back to the
> login page over and over. Everyone else seems fine. — Uma, LT-0470."* (an **SSO login loop**)

1. **Isolate with incognito:** open the portal in an **incognito** window.
   - **Works in incognito** → it's **local browser state** (cache/cookies/extension) → continue to fix
     her normal profile.
   - **Fails in incognito too** → it's the site/account/network → check DevTools + the IdP.
   (Here: works in incognito → it's her cookies.)
2. **Confirm it's the session cookie:** the loop = a **stale/corrupt SSO session cookie** — the app and
   IdP keep disagreeing about whether she's logged in.
3. **Fix:** clear **cookies for that site** (and the IdP/login domain), close all tabs, sign in fresh.
   (Clearing just that site is gentler than wiping everything.)
4. **If still looping in incognito:** check DevTools Network for the redirect chain and the failing
   status; verify it isn't a **Conditional Access** block (L11) or third-party-cookie policy.
5. **Verify:** Uma logs into the HR portal and stays logged in. Confirm.
6. **Document:** note it was an SSO cookie loop fixed by clearing site cookies; KB it (recurs).

The teaching point: **incognito is the fastest triage in the browser world** — it instantly tells you
*local state* vs *site/network*.

---

## §5 — Troubleshooting Workflow (the diagnostic spine)

**Problem class: a website/web app won't load, log in, or display correctly.**

### 1 · Symptoms
Won't load · "not secure"/certificate warning · login loop / can't sign in (SSO) · page looks broken/
half-rendered · "this site is blocked" · slow only in the browser · downloads fail.

### 2 · Possible Causes (most-likely first)
1. **Local browser state**: stale cache, corrupt cookie/session, bad **extension**.
2. **DNS/network** (L08/L09): name won't resolve / no connectivity (not really "the browser").
3. **Certificate**: expired/mismatch/untrusted (missing internal root CA).
4. **SSO/auth**: cookie loop, third-party-cookie block, Conditional Access denial (L11).
5. **Proxy/web filter**: blocked or misrouted (maybe intended).
6. **Server-side**: the site itself is down (5xx) — not your fix.

### 3 · Diagnostic Steps (ordered)
| # | Check | If… | …then |
|---|---|---|---|
| 1 | **Incognito** window | works | local state → clear cache/cookies / disable extensions |
| 2 | **Different browser** | works | first browser's profile → reset/new profile |
| 3 | **Different machine/network** | works elsewhere | the device/network, not the site |
| 4 | `nslookup`/`ping` the host (L09) | name/connect fails | it's DNS/network, not the browser |
| 5 | Certificate (lock icon) | expired/mismatch/untrusted | site owner / push internal root CA |
| 6 | DevTools Network status | 401/403 · 404/500 · ERR_CERT · ERR_PROXY | auth · server · TLS · proxy |
| 7 | Proxy / web-filter message | "blocked by policy" | it's a control — verify intent |

### 4 · Resolution Steps
Clear cache + cookies (whole or per-site); disable/remove the offending extension; reset or create a
new browser profile; fix DNS/network (L09); for cert errors escalate to the site owner (expired) or
push the **corporate root CA** (internal CA, via L19/L26); clear SSO cookies / address Conditional
Access (L11); for proxy/filter blocks confirm whether it's intended (security) before "fixing."

### 5 · Escalation Criteria
Escalate to the web-app/SSO admin, network/security team, or PKI/CA owner for: certificate issuance/
root-CA distribution, SSO/Conditional-Access changes (L11), web-filter/proxy policy, or a genuine
**server-side outage**. Attach: the incognito/other-browser/other-machine results, DevTools status +
the failing URL, the cert details. A web-filter block may be **security** working (L29) — don't bypass
without authorization.

### 6 · Post-Incident Documentation
Ticket note (isolation result + the layer + fix), KB ("web app won't load/log in — try this"), problem
ticket if many users hit the same cert/SSO/filter issue (L32).

---

## §6 — Ticket Simulation

> **Ticket ENT-14 / INC-0509 (P2):** *"Our internal timesheet site shows a big red 'Your connection is
> not private' warning and won't let me in. A couple of teammates see it too. — Vik, DESK-1230."*

**Triage:** a **certificate warning** on an **internal** site, hitting **multiple** users → likely a
**cert/CA** problem (expired internal cert, or the devices missing the corporate **root CA**), not one
user's browser. **P2** (blocks a business app for several people; potential wider scope).

**Worked resolution:**
1. **Read the exact error:** lock/Details → is it `NET::ERR_CERT_DATE_INVALID` (**expired**),
   `..._COMMON_NAME_INVALID` (**name mismatch**), or `..._AUTHORITY_INVALID` (**untrusted issuer** =
   missing internal root CA)?
2. **Inspect the certificate:** issuer, validity dates, the hostname it's issued for.
3. **Branch:**
   - **Expired internal cert** → the **site/server owner** must renew it; this is *not* a client fix —
     escalate with the cert details; warn users **not** to click through.
   - **Untrusted issuer (internal CA not trusted)** → the devices are missing the **corporate root CA**;
     it should be distributed via **GPO/Intune** (L19/L26) — escalate to the team that manages CA
     distribution; affected new/rebuilt machines need the root CA pushed.
4. **Scope it:** multiple users → confirm whether it's all of them (cert expired server-side) or only
   some (those missing the root CA) — that distinction routes the fix.
5. **Do-no-harm:** never coach users to bypass a real certificate warning (it could be a MITM/attack —
   L29); fix the cause.
6. **Verify + document** once renewed/trusted: the site loads cleanly.

**The professional ticket note:**
```
SUMMARY: Internal timesheet site threw a certificate "not private" error for several users. Diagnosed
as an EXPIRED internal server certificate (NET::ERR_CERT_DATE_INVALID). Escalated to the app/server
owner to renew; advised users NOT to bypass. Resolved on renewal.
SYMPTOM: "Your connection is not private" on https://timesheet.corp.example; multiple users.
DIAGNOSIS: cert Details → validity expired yesterday; issuer = corporate CA; affects all users → server
cert, not client trust.
CAUSE: expired server TLS certificate (renewal missed).
RESOLUTION: app/server owner renewed the certificate; users confirmed clean load. Did NOT instruct
bypass (security).
FOLLOW-UP: raised a Problem (L32) for cert-expiry monitoring/auto-renewal so it doesn't recur; KB on
"certificate warnings — what they mean / don't bypass" linked.
```

---

## §7 — Service Desk / ITIL Perspective

- **Category:** Web app / Browser. One user = **Incident** (P2/P3); a shared cert/SSO/filter issue =
  wider **Incident/Problem** (L32); an expired-cert outage on a key app can be a **Major Incident**
  (L31).
- **Incognito is your triage shortcut** — it instantly separates *local browser* from *site/network/
  account*, saving time on a high-volume category.
- **Certs and SSO are owned elsewhere:** you diagnose and route; PKI/CA, web-app, and identity teams
  fix issuance/policy. Your value is precise evidence (error code, cert details, scope).
- **Security overlap:** a web-filter "blocked" page and a certificate warning are often **controls
  working** (L29) — recognize intent before "fixing," and never coach bypassing a real cert error.
- **Metric angle:** browser tickets are high-FCR with the incognito method + a good KB; recurring cert/
  SSO issues are problem-management wins.

---

## §8 — Practical Lab (build this yourself)

**Goal:** master browser isolation and DevTools so "the app is broken" becomes a precise diagnosis.

### Lens C — Manual → Automation → Why
- **Manual:** clear cache/cookies, toggle extensions, read DevTools by hand.
- **Automated/standardized:** while browsers resist scripting their UI, the *method* is the automation —
  a fixed isolation sequence (incognito → other browser → other machine), plus managed-browser
  **policies** (GPO/Intune, L19/26) that pre-deploy the root CA, proxy/PAC, and allowed extensions so
  these tickets never happen.
- **Why:** consistency — every tech runs the same isolation; managing the browser centrally (root CA,
  homepage, extensions) eliminates whole ticket classes at scale.

### Steps
1. **Incognito drill:** find a site, break it by adding a bad cookie/extension, confirm it works in
   incognito — internalize the isolation logic.
2. **DevTools:** open F12 → Network, load a page, read request **statuses** (200/301/401/404/500) and a
   failing one; open Console for JS errors.
3. **Certificate read:** click the lock on any HTTPS site → view issuer/validity/hostname; recognize an
   untrusted vs expired vs mismatch scenario.
4. **Cache/cookie surgery:** clear cookies for **one** site (not everything) — the gentle fix.
5. **DNS tie-in:** `nslookup` a site that won't load to decide browser-vs-DNS (L09).
6. **Write the browser troubleshooting guide** (`docs/troubleshooting/browser-web.md`) + the KB.

### Lens D — the raw artifact (DevTools status / cert error routes the fix)
```
   DevTools ▸ Network:  POST /api/login   →  Status: 403 Forbidden        ← AUTH problem (SSO/permission), not "site down"
                        GET  /app.js       →  Status: (failed) net::ERR_CERT_AUTHORITY_INVALID
                                                                          ← device doesn't trust the issuer = missing internal ROOT CA (push via GPO/Intune)
#   The DevTools status code / cert error names the layer: 401/403=auth, 404/500=server, ERR_CERT=TLS,
#   ERR_PROXY=proxy. Read it before clearing things blindly.
```

---

## §9 — GitHub Artifact (the 6-artifact evidence package)

1. **Runbook:** `docs/runbooks/web-app-wont-load.md` — the incognito → other-browser → other-machine
   isolation ladder.
2. **Troubleshooting Guide:** `docs/troubleshooting/browser-web.md` — the full spine + a cert-error/
   DevTools-status reference.
3. **Ticket Notes:** `docs/tickets/ENT-14-cert-error.md` — the worked ENT-14.
4. **KB Article:** `docs/kb/` — "A website won't load or log you in — try this (and what a security
   warning means)" for end users.
5. **Incident Report:** the expired-cert outage as a mini incident report + the monitoring Problem
   (L32).
6. **Portfolio Artifact:** §10 bullet + the incognito-isolation / cert-error talking points.
7. **Reference (in lieu of a script):** the isolation ladder + DevTools-status table (browser UI isn't
   cleanly scriptable; the method *is* the artifact). Optionally a small `clear_browser_cache.ps1` for
   managed cache paths.

---

## §10 — Portfolio Artifact

- **Resume bullet:** *"Authored a browser/web-app troubleshooting guide built on an incognito-first
  isolation method and DevTools status/certificate reading, resolving SSO login loops, extension
  conflicts, and certificate errors — and routing PKI/SSO issues with precise evidence."*
- **Interview talking point:** **incognito as instant triage** (local state vs site/network), reading a
  **DevTools status** (401/403/404/500) and **cert errors** (expired vs untrusted root CA), and *never
  coaching a user to bypass a real cert warning*.
- **Serves:** Help Desk T1/T2, IT Support, Desktop Support.

---

## §11 — Certification Crossover Notes

- **CompTIA A+ (Core 2):** browser configuration & security, certificates, proxy settings — core.
- **Network+:** DNS/TLS/proxy concepts. **MS-900:** SSO/identity context (L11). Detail in
  `alignment/CERTIFICATION-MAPPING.md`.

---

## §12 — Support Notes (Lens E — Service & Security)

**🤝 Service:** users say "the app is broken" — the incognito test lets you quickly and credibly show
whether it's their browser or the service, which builds trust and avoids blaming the wrong thing.

**🔒 Security:** the browser is a major security boundary. **Never teach users to click through
certificate warnings** — a real one can mean an expired cert *or* a man-in-the-middle attack (L29). A
**"blocked by web filter"** page is usually a **control working** (don't bypass without authorization).
Malicious **extensions** can steal sessions/data — manage allowed extensions centrally (L19/26).
Saved-password hygiene, phishing pages that mimic SSO (check the URL!), and not entering corporate
credentials on look-alike sites all live here (L29).

---

## Quiz (Interview-Style, Graded)

**Q1.** A user says a web app is broken but colleagues are fine. What's the single fastest test to tell
whether it's their browser or the site, and why?
> **Your answer:**

**Q2.** What does an incognito window rule out when a site works in it but not in the normal window?
> **Your answer:**

**Q3.** A site shows "Your connection is not private." Give two different underlying causes and how the
fix differs.
> **Your answer:**

**Q4.** **Scenario:** a user is stuck in an endless login loop on an SSO web app; it works in incognito.
What's happening and what do you do?
> **Your answer:**

**Q5.** Why should you never just tell a user to "click through" a certificate warning?
> **Your answer:**

*(Request the "Professional Answer" comparison under each before moving on.)*

---

## Reflection
*(After the quiz)* — What did you learn? · What confused you? · What would you do differently?

---

## Search Keywords For Further Understanding

**Core**
- `browser incognito test cache cookies extensions`
- `NET::ERR_CERT certificate error meaning`
- `SSO login loop clear cookies`
- `chrome devtools network tab status codes`
- `internal root CA not trusted push GPO`

**Tools**
- `clear cookies for one site`
- `manage browser extensions enterprise policy`

**Going further**
- `ticketing systems fundamentals` (L15) · `microsoft 365 SSO/conditional access` (L11) ·
  `dns` (L09) · `security awareness phishing` (L29)

**Service / Security (Lens E):**
- 🤝 `incognito test prove browser vs site to user`
- 🔒 `never bypass certificate warning MITM`, `malicious browser extension`, `web filter control`

---

## Lesson Status
- [ ] §8 lab completed (incognito + DevTools + cert read + cache surgery + guide)
- [ ] 6-artifact evidence package committed (§9)
- [ ] Quiz answered + professional-answer comparisons (graded)
- [ ] Reflection + Search Keywords reviewed

When complete, run the Update Protocol, then move to **Lesson 15 — Ticketing Systems Fundamentals**.

---

*Lesson 14 written by Navi · 2026-06-21 · full-depth. Sources to cite at study time: CompTIA A+
220-1102 (browser/security), TLS certificate & SSO basics, browser DevTools docs.*
