# Lesson 13 — Email Troubleshooting

**Status:** ✅ ready for self-study (full depth) · **Date written:** 2026-06-21
**Schema:** 12-section IT-Support (`docs/learning/CLAUDE_TEACHING_RULES.md`)
**Focus:** the email tickets that never stop — **can't send/receive, Outlook won't connect, keeps
asking for a password, bounce-backs (NDRs), mailbox full, junk/spam, calendar issues** — plus the
mail-flow mental model (sender → MX/DNS → recipient) that makes NDRs readable and "is it us or them?"
answerable.
**Primary artifact:** the email troubleshooting guide + `scripts/mailbox_report.ps1`.

> **How to use this lesson:** read §1–§7, do §8 (read an NDR + an Outlook connectivity check), produce
> §9, take the quiz, reflect. Then Lesson 14.

---

## §1 — Concept (Theory)

### What it is
Email moves from a sender's client → their mail server → across the internet to the recipient's mail
server (found via the recipient domain's **MX DNS record**, L09) → the recipient's mailbox → their
client. On the corporate side it's **Exchange Online** (M365, L11) or **Gmail** (Workspace, L12). The
**client** (Outlook, the web app, a phone) connects to the mailbox to send/receive. Failures happen at
the **client**, the **mailbox/account**, **mail flow/DNS**, or the **other side**.

### Why it matters for support
Email is the lifeblood of business and one of the highest-volume, highest-anxiety ticket categories.
"I'm not getting email," "Outlook keeps asking for my password," "my message bounced," "my mailbox is
full" — each maps to a specific layer. Reading an **NDR** (the bounce message) is a superpower: it
usually tells you exactly what's wrong and *which side* failed.

### Three-Level Depth (Lens A)
- **Level 1 — User:** "email isn't working" / "it won't send" / "I got a weird bounce-back."
- **Level 2 — Technician:** isolate the layer — client (Outlook profile/cache/credentials), mailbox
  (full? account/license OK?), or delivery (NDR code, recipient address, spam filter) — then fix that
  layer.
- **Level 3 — Engineer:** delivery is decided by the recipient domain's **MX record** (L09) and
  authenticated by **SPF/DKIM/DMARC** (anti-spoofing — why legit mail lands in junk or gets rejected);
  **NDR codes** (e.g. `550 5.1.1` recipient doesn't exist, `550 5.7.x` policy/spam reject, `452 4.2.2`
  quota) pinpoint the cause and side; Outlook stores the mailbox in an **OST** cache + an **Outlook
  profile** (a corrupt profile/OST causes "won't connect"/"asking for password"); **modern auth/MFA**
  (L11) explains repeated credential prompts. This is *why* the NDR code and the profile rebuild are
  the two key moves.

### Two Teaching Approaches (Lens B) — mail flow & the NDR
**Approach 1 (technical):** sending mail = looking up the recipient domain's MX (DNS), connecting to
that server, and being accepted or rejected; the receiving server applies authentication (SPF/DKIM/
DMARC) and spam policy. A bounce (**NDR**) is the receiving (or sending) server reporting *why* it
refused — the numeric code tells you the reason and which side.

**Approach 2 (analogy):** email is the **postal system**. The **MX record** is the recipient's
**registered mailing address**; **SPF/DKIM/DMARC** are the **return-address verification + tamper seal**
the post office uses to reject forgeries (spoofing); an **NDR** is the **"Return to Sender" stamp with a
reason** ("no such person" = 550 5.1.1, "mailbox full" = quota, "refused by recipient" = policy/spam).
**Where it breaks down:** unlike paper mail, delivery is instant and a single misconfigured "seal"
(SPF) can silently divert legitimate mail to junk — so "I sent it, they didn't get it" needs the NDR or
message trace, not assumptions.

### Visual (ASCII) — mail flow & where it breaks
```
   SENDER client ─▶ sender server ─▶ [DNS: recipient MX?] ─▶ recipient server ─(SPF/DKIM/DMARC + spam)─▶ mailbox ─▶ recipient client
        │                │                  │                       │                                      │            │
   profile/OST/      auth/quota         no MX/typo'd          550 5.1.1 (no user)                       full=quota   profile/
   credentials       (won't send)        domain              550 5.7.x (policy/spam)                    452 4.2.2    cache/rules
   ("asking for pw")                                          → READ THE NDR CODE                                     (junk/rules)
```

---

## §2 — Tools & Commands

| Task | GUI | PowerShell / admin |
|---|---|---|
| Mailbox properties / quota | Exchange admin center (EAC) | `Get-Mailbox` · `Get-MailboxStatistics` |
| Trace a message's path | EAC → Mail flow → **Message trace** | `Get-MessageTrace` / `Get-MessageTraceDetail` |
| Recipient MX (delivery target) | — | `Resolve-DnsName <domain> -Type MX` (L09) |
| Outlook connectivity | Outlook → File → Account Settings; **Test E-mail AutoConfiguration** | — |
| Rebuild Outlook profile | Control Panel → Mail → Show Profiles | (new profile) |
| Inbox rules / forwarding (compromise!) | Outlook rules; EAC | `Get-InboxRule` · `Get-Mailbox \| select ForwardingSmtpAddress` |
| Junk/quarantine | Defender/EAC quarantine | `Get-QuarantineMessage` |

```powershell
Connect-ExchangeOnline
Get-Mailbox jdoe@corp.example | Select DisplayName, ProhibitSendQuota, ProhibitSendReceiveQuota
Get-MailboxStatistics jdoe@corp.example | Select TotalItemSize, ItemCount      # is it full?
Get-MessageTrace -RecipientAddress jdoe@corp.example -StartDate (Get-Date).AddDays(-1) -EndDate (Get-Date)
Resolve-DnsName partner.example -Type MX                                       # where their mail should go
Get-InboxRule -Mailbox jdoe@corp.example                                       # hidden malicious rule? (L29)
```

---

## §3 — Real-World Support Context & Use Cases

- **Top-volume, high-anxiety.** Email down *feels* like work has stopped — speed + clear comms matter.
- **NDR-reading is the skill:** `550 5.1.1` = recipient address wrong/doesn't exist (sender typo or
  the recipient left); `550 5.7.x` = blocked by policy/spam (auth/SPF/reputation); `452/4.2.2` quota =
  recipient mailbox full. The code tells you the fix and the side.
- **"Outlook keeps asking for my password"** = stale cached credentials / modern-auth / a corrupt
  profile — a daily classic.
- **Mailbox full** blocks send/receive — archive/cleanup or quota increase.
- **Junk/quarantine:** legit mail in junk (sender SPF/DMARC or rules) vs phishing in the inbox (L29).
- **Auto-forwarding to an external address** is both a support item *and a top compromise indicator*
  (L29) — always check it on "weird email" tickets.
- **Exam framing:** MS-900 (Exchange Online), Network+ (DNS/MX), A+ (email client config).

---

## §4 — Demonstration (worked walkthrough)

> **Ticket INC-0404 (P3):** *"I emailed a client and got a bounce-back I don't understand. — Sara,
> LT-0460."* (She forwards the NDR.)

1. **Read the NDR — the code is the answer:** it says
   `550 5.1.1 ... recipient address rejected: user unknown`.
2. **Interpret:** `5.1.1` = the **recipient address doesn't exist** on their server — a **sender-side
   addressing** problem (typo) *or* the recipient genuinely left their company.
3. **Verify the address:** check what Sara typed vs the correct address (autocomplete often re-uses a
   stale/typo'd entry — a frequent culprit). `Resolve-DnsName clientco.example -Type MX` confirms their
   mail server is reachable (so it's the *address*, not the *domain*).
4. **Resolve:** correct the recipient address; clear Outlook's **autocomplete** entry for the bad one so
   it doesn't recur; resend.
5. **If the user truly left their company:** advise Sara to get the new contact — not an IT fix, but a
   clear, helpful answer.
6. **Document:** note it was a recipient-address NDR (5.1.1), fixed by correcting the address + clearing
   autocomplete.

The teaching point: **read the NDR code first** — it routes you to the exact cause and side, saving a
blind investigation.

---

## §5 — Troubleshooting Workflow (the diagnostic spine)

**Problem class: email send/receive, connection, delivery, or mailbox issues.**

### 1 · Symptoms
Not receiving · can't send · "Outlook trying to connect"/disconnected · repeated password prompts ·
NDR/bounce-back · mailbox full · legit mail in junk · calendar not updating · sent-as wrong name.

### 2 · Possible Causes (most-likely first)
1. **Client**: corrupt Outlook profile/OST, stale cached credentials, offline mode.
2. **Account/mailbox**: disabled/unlicensed (L11), **mailbox full** (quota).
3. **Delivery**: wrong recipient address / NDR code; recipient-side reject.
4. **Filtering**: caught in junk/quarantine (SPF/DKIM/DMARC, rules).
5. **Mail-flow/DNS**: MX/record/connector issue (wider → admin).
6. **Service health**: Exchange Online/Gmail outage (L11 — check first if many users).

### 3 · Diagnostic Steps (ordered)
| # | Check | If… | …then |
|---|---|---|---|
| 1 | Scope + service health | many users / outage | Microsoft/Google-side → comms (L31) |
| 2 | Web mail (OWA/Gmail web) works? | yes → client-side | rebuild Outlook profile/OST |
| 3 | The **NDR code** (for bounces) | 5.1.1 / 5.7.x / 4.2.2 | address / policy-spam / quota |
| 4 | Mailbox quota (`Get-MailboxStatistics`) | full | archive/cleanup or raise quota |
| 5 | **Message trace** (EAC) | shows where it stopped | act on that hop |
| 6 | Junk/quarantine + **inbox rules/forwarding** | found / suspicious rule | release / **security (L29)** |
| 7 | License/account enabled (L11) | missing | assign/enable |

### 4 · Resolution Steps
Rebuild the Outlook **profile**/clear the OST + re-auth (modern auth/MFA, L11); free mailbox space or
raise quota; correct the recipient address + clear autocomplete; release from quarantine / fix the rule
or filter; escalate mail-flow/MX/connector problems to the admin; if an **external auto-forward** or
rogue rule is found → treat as a **security incident** (L29), don't just delete it quietly.

### 5 · Escalation Criteria
Escalate to the Exchange/mail admin (or Microsoft/Google support) for: mail-flow/connector/MX changes,
tenant-wide delivery problems, quarantine/transport-rule policy, and **suspected compromise** (rogue
forwarding/rules, mass-sent spam → security, L29). Attach: the **full NDR**, a **message trace**,
mailbox stats, scope. Mail-flow/transport-rule changes are a **change** (L17) with org-wide blast
radius.

### 6 · Post-Incident Documentation
Ticket note (layer + NDR code + fix), KB (KB-0005 Outlook self-help), security escalation for
compromise indicators, problem/RCA for mail-flow outages (L31/L32).

---

## §6 — Ticket Simulation

> **Ticket ENT-13 / INC-0403 (P2):** *"Outlook keeps popping up asking for my password over and over,
> and I can't send or receive. The web version works fine though. — Tomás, LT-0461."*

**Triage:** **web mail works** → the **mailbox/account is fine**; the problem is **client-side**
(Outlook). Repeated password prompts → stale cached credentials / corrupt profile / modern-auth hiccup.
Blocked in his main client → **P2**.

**Worked resolution:**
1. **Confirm the split:** OWA (web) sends/receives fine → isolates to the **Outlook desktop client**.
2. **Clear cached credentials:** Windows **Credential Manager** → remove stale Office/Outlook entries
   (old password cached → endless prompts). Restart Outlook → re-auth with MFA (L11).
3. **If prompts persist:** rebuild the **Outlook profile** (Control Panel → Mail → new profile) so a
   corrupt profile/OST is recreated clean; let it re-sync from the mailbox (no data loss — it's a
   cache).
4. **Verify:** Outlook connects, sends/receives, no repeated prompts. Confirm with Tomás.
5. **Root cause:** usually a recent **password change** (L21) not updated in the cached client, or a
   corrupted profile — note which, and that web mail being fine proved it was the client.

**The professional ticket note:**
```
SUMMARY: Outlook desktop prompting for password repeatedly + not syncing while OWA worked → client-side
(stale cached credential + profile). Cleared Credential Manager entries and rebuilt the Outlook profile;
client reconnected and syncs. No mailbox data affected.
SYMPTOM: endless password prompts in Outlook desktop; can't send/receive; web (OWA) works.
DIAGNOSIS: OWA OK → account/mailbox healthy → isolate to client. Credential Manager held a stale Office
credential (post password change).
CAUSE: cached old credential + corrupt Outlook profile after a recent password reset.
RESOLUTION: removed stale Credential Manager entries; rebuilt Outlook profile; re-authenticated (MFA);
verified send/receive.
FOLLOW-UP: reminded Tomás that a password change (L21/KB-0101) requires re-auth on all clients; KB-0005
linked. No compromise indicators (no rogue rules/forwarding).
```

---

## §7 — Service Desk / ITIL Perspective

- **Category:** Email/M365. Client/mailbox = **Incident**; mail-flow/connector change = **Change**
  (L17); tenant outage = **Major Incident** (L31).
- **The OWA test is your triage shortcut:** "does web mail work?" instantly splits **client-side** from
  **mailbox/service-side** — do it early.
- **Security overlap:** "weird email" tickets are where compromises surface — **always check inbox
  rules + external forwarding**; a rogue auto-forward is a P1 security incident (L29), not a P3 email
  quirk.
- **Priority:** email-down is high-anxiety; judge true impact (one user's client vs org mail flow).
- **Metric angle:** NDR literacy + the OWA test drive high FCR; a good Outlook self-help KB (KB-0005)
  deflects volume.

---

## §8 — Practical Lab (build this yourself)

**Goal:** read NDRs, run a message trace, and report mailbox health — against a **dev tenant model**.

### Lens C — Manual → Automation → Why
- **Manual:** open EAC, check a mailbox's quota, click through a message trace.
- **Automated:** `mailbox_report.ps1` reports quota/size/usage (and flags mailboxes near full) and dumps
  any **forwarding/inbox rules** for a quick compromise check — across many mailboxes.
- **Why:** "is the mailbox full / is there a rogue forward?" recurs; a script answers it instantly and
  proactively flags near-full mailboxes before they ticket, and surfaces compromise indicators (L29).

### Steps
1. **Read NDR codes:** memorize `5.1.1` (no recipient), `5.7.x` (policy/spam), `4.2.2`/quota (full);
   practice on sample bounces.
2. **OWA test:** confirm the "web works → client problem" triage on a test account.
3. **Message trace (lab):** send a test message and trace it in EAC — see each hop and the final status.
4. **Mailbox stats:** `Get-MailboxStatistics` for size/quota; map to the "mailbox full" ticket.
5. **Compromise check:** `Get-InboxRule` + forwarding address — know what a malicious rule looks like
   (L29).
6. **Write `scripts/mailbox_report.ps1`** (quota/usage + near-full flag + forwarding/rules dump) and the
   email troubleshooting guide.

### Lens D — the raw artifact (the NDR tells you everything)
```
   Remote Server returned '550 5.1.1 <jdoe@clientco.example>: Recipient address rejected: User unknown'
   ── 5.1.1 ──▶ the recipient address doesn't exist on their server (typo, or they left)
                → SENDER-side fix: correct the address + clear autocomplete; NOT a mailbox/server problem

   Remote Server returned '452 4.2.2 The email account that you tried to reach is over quota'
   ── 4.2.2 ──▶ RECIPIENT mailbox is full → their side (advise/forward); your user did nothing wrong
#   The numeric code names the cause AND the side. Read it first — it replaces a blind investigation.
```

---

## §9 — GitHub Artifact (the 6-artifact evidence package)

1. **Runbook:** `docs/runbooks/outlook-wont-connect.md` — OWA test → credentials → profile rebuild.
2. **Troubleshooting Guide:** `docs/troubleshooting/email.md` — the full spine + an **NDR-code table**.
3. **Ticket Notes:** `docs/tickets/ENT-13-outlook-password-prompt.md` — the worked ENT-13.
4. **KB Article:** `docs/kb/` — KB-0005 "Email/Outlook troubleshooting" (web test, password prompts,
   junk, mailbox full) for end users.
5. **Incident Report:** a mail-flow outage **or** a compromised-mailbox (rogue forward) incident
   (template; the latter feeds L29).
6. **Portfolio Artifact:** §10 bullet + the NDR-code / OWA-test talking points.
7. **Script:** `scripts/mailbox_report.ps1` (Exchange Online; `Invoke-ScriptAnalyzer`-clean).

---

## §10 — Portfolio Artifact

- **Resume bullet:** *"Built an Exchange Online mailbox-health PowerShell report (quota + forwarding/
  rule audit) and an email troubleshooting guide with an NDR-code reference, resolving Outlook
  connectivity and delivery incidents and surfacing mailbox-compromise indicators."*
- **Interview talking point:** **read the NDR code** (5.1.1 vs 5.7.x vs quota → cause + side), the
  **OWA test** to split client vs mailbox, and **always check forwarding/inbox rules** on weird-email
  tickets (compromise).
- **Serves:** Help Desk T1/T2, IT Support Specialist.

---

## §11 — Certification Crossover Notes

- **MS-900:** Exchange Online / M365 mail. **Network+:** DNS/MX and mail-flow concepts. **A+ (Core
  2):** email client configuration & troubleshooting. Detail in `alignment/CERTIFICATION-MAPPING.md`.

---

## §12 — Support Notes (Lens E — Service & Security)

**🤝 Service:** email-down feels catastrophic — reassure (the web version + the mailbox are usually
fine), give a clear ETA, and the OWA test lets you honestly say whether it's their client or a service.

**🔒 Security:** email is the #1 attack vector — this lesson is half security. **Phishing** lands here
(L29); a **rogue inbox rule** (auto-delete/auto-forward to hide an attacker's activity) or **external
auto-forwarding** is a classic **account-compromise** indicator — check it on every suspicious-email
ticket and escalate as a security incident, don't quietly delete. Never read/relay a user's password;
SPF/DKIM/DMARC and quarantine are controls protecting the org — releasing from quarantine should be
deliberate (it might be real phishing).

---

## Quiz (Interview-Style, Graded)

**Q1.** A user's email bounces with `550 5.1.1`. What does that mean and whose problem is it?
> **Your answer:**

**Q2.** Outlook desktop keeps asking for a password and won't sync, but webmail works. What does that
tell you, and what do you do?
> **Your answer:**

**Q3.** A user "isn't getting some emails." What tool shows you exactly where a message went, and where
do you also look for legit mail that vanished?
> **Your answer:**

**Q4.** **Scenario:** a user reports odd behavior and you find an inbox rule auto-forwarding all mail to
an external Gmail address. What is this, and what do you do?
> **Your answer:**

**Q5.** A user can't send and gets a quota/over-limit message. What's the cause and your options?
> **Your answer:**

*(Request the "Professional Answer" comparison under each before moving on.)*

---

## Reflection
*(After the quiz)* — What did you learn? · What confused you? · What would you do differently?

---

## Search Keywords For Further Understanding

**Core**
- `email NDR bounce codes 550 5.1.1 5.7.1 explained`
- `outlook keeps asking for password fix credential manager`
- `rebuild outlook profile ost`
- `exchange online message trace`
- `mailbox full quota prohibitsend`

**Tools**
- `Get-MessageTrace Get-MailboxStatistics`
- `Get-InboxRule forwarding compromise check`

**Going further**
- `browser and web troubleshooting` (L14) · `microsoft 365 fundamentals` (L11) ·
  `dns MX records` (L09) · `security awareness phishing` (L29)

**Service / Security (Lens E):**
- 🤝 `OWA test reassure user email`, `email-down expectation setting`
- 🔒 `malicious inbox rule auto-forward compromise`, `SPF DKIM DMARC`, `quarantine release caution`

---

## Lesson Status
- [ ] §8 lab completed (NDR reading + message trace + mailbox_report.ps1 + guide)
- [ ] 6-artifact evidence package committed (§9)
- [ ] Quiz answered + professional-answer comparisons (graded)
- [ ] Reflection + Search Keywords reviewed

When complete, run the Update Protocol, then move to **Lesson 14 — Browser & Web Troubleshooting**.

---

*Lesson 13 written by Navi · 2026-06-21 · full-depth. Sources to cite at study time: MS-900 / Exchange
Online docs, NDR/DSN code references, SPF/DKIM/DMARC basics.*
