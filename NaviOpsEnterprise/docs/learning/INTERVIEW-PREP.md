# Interview Prep — NaviOpsEnterprise

Interview questions for every target role, grouped the way interviews actually go: technical,
scenario-based, and behavioral. Each lesson's **Quiz** (§ after §8) drills these in depth with
graded "Professional Answer" comparisons — this file is the master bank and the strategy.

## How IT-support interviews actually run
1. **Phone screen** — basics + communication ("walk me through resetting a password securely").
2. **Technical** — troubleshooting method + breadth (Windows, M365, AD, networking).
3. **Scenario** — "a user says X; what do you do?" — they're testing your *method*, not trivia.
4. **Behavioral** — customer service, pressure, teamwork, learning.

**The meta-skill they're scoring: structured troubleshooting + clear communication.** Always think
out loud, use the diagnostic spine, and state when/why you'd escalate.

## Technical questions (by domain)

### Fundamentals / OS (L01–L04)
- Walk me through what happens from power-on to login on a Windows PC.
- What's the difference between RAM and disk? Why does a low-RAM machine feel slow?
- What do you check first on a PC that "won't turn on"?
- Where do you look for errors on a Windows machine? (Event Viewer, Reliability Monitor)

### Networking (L08–L09)
- A user has no internet. Walk me through your troubleshooting.
- What does `ipconfig /all` tell you? What's a default gateway? DNS server?
- Explain DNS to a five-year-old, then to me.
- DHCP vs static IP — when would you use each? What's a 169.254 address mean?
- `ping` works to the IP but not the name — what's wrong?

### Accounts, AD, GPO (L07, L18–L21)
- Difference between a local account and a domain account?
- NTFS permissions vs share permissions — which wins?
- What's an OU? What's a security group vs a distribution group?
- A GPO isn't applying to a user — how do you troubleshoot? (`gpresult /r`, LSDOU, scope, security
  filtering, replication, `gpupdate /force`)
- Walk me through resetting and unlocking an account *securely*.
- A user is locked out repeatedly — how do you find the source?

### M365 / email (L11, L13)
- A user isn't receiving email. Walk through it.
- What's an NDR? What does a 550 5.1.1 mean?
- OneDrive vs SharePoint — when do you use each?
- How do you check/assign a license in M365?
- Outlook won't open / keeps asking for a password — what do you try?

### Endpoints / software / printing (L10, L24–L26)
- "My computer is slow." How do you approach it?
- A printer shows "offline" — your steps?
- How do you deploy/uninstall software cleanly? What's `winget`/MSI?
- A Windows update failed — what do you do?

## Scenario questions (think out loud — use the spine)
- "The whole 3rd floor lost network at 9am." (scope! → P1? → incident → check switch/DHCP/uplink)
- "A VIP can't access a shared folder she had yesterday." (permissions/group change → check
  membership, ACL, mapped drive)
- "A user clicked a link and entered their password on a fake page." (security incident → reset,
  revoke sessions, check rules/forwarding, report — Lesson 29)
- "New hire starts Monday and nothing's set up." (onboarding runbook → AD, license, mailbox, device)
- "You have 12 tickets and a P1 just came in." (prioritization → impact×urgency, communicate)

**Scenario answer framework:** Clarify scope → state priority → diagnostic spine → resolution →
when you'd escalate and with what → how you'd document. Naming the framework impresses.

## Behavioral questions (use STAR: Situation, Task, Action, Result)
- Tell me about a time you helped a frustrated/non-technical user.
- A time you didn't know the answer — what did you do?
- A time you made a mistake — how did you handle it?
- How do you prioritize when everything's "urgent"?
- A time you had to learn something new fast.
- How do you handle a user who's angry at *you* for an outage you didn't cause?

For each, prep a real story (lab work counts: "I built X, hit problem Y, solved it by Z").

## Questions to ask them (shows seriousness)
- What does the ticket queue / volume look like day to day?
- What's the escalation structure (T1→T2→...)?
- What tools do you use (ITSM, RMM, M365/Google)?
- What does success look like in the first 90 days?
- Is there a path from help desk toward sysadmin/infra?

## The 24-hour-before checklist
- [ ] Re-read this file + the §Quiz of your weakest 3 lessons.
- [ ] Rehearse the diagnostic spine until it's automatic.
- [ ] Have 3 STAR stories ready (one about a mistake, one about a hard user, one about learning).
- [ ] Have your portfolio open and be ready to screen-share a runbook + a troubleshooting guide.
- [ ] Prepare your 3 questions for them.
