# Portfolio Guide — NaviOpsEnterprise

How to turn the artifacts you produce in every lesson into a portfolio that gets you interviews.
The portfolio is a **byproduct of the work**, not a separate project — if you follow the 6-artifact
contract (`CLAUDE_TEACHING_RULES.md` §9), you're already building it.

## What hiring managers for IT support actually want to see
They are not looking for a CS degree. They want evidence you can: **take a ticket, troubleshoot
methodically, fix it without breaking anything, and write it down.** Your portfolio proves exactly
that.

## The portfolio = this repo
Your public GitHub repo *is* the portfolio. Its structure already maps to what employers value:

| Folder | What it proves |
|---|---|
| `docs/runbooks/` | You can write repeatable procedures |
| `docs/troubleshooting/` | You troubleshoot methodically (the diagnostic spine) |
| `docs/kb/` | You can write for end users (communication) |
| `docs/tickets/` | You can work and document real tickets |
| `docs/templates/` | You bring process, not chaos |
| `scripts/` | You can automate (PowerShell/Bash) — above-baseline |
| `docs/learning/capstones/` | You can run a whole service desk / support env / sysadmin op |

## The five portfolio centerpieces (build these deliberately)
1. **An onboarding/offboarding runbook + script** (Lesson 20) — the single most relatable IT
   process; shows you understand AD + M365 + lifecycle.
2. **A troubleshooting guide with a real diagnostic spine** (e.g. "no internet", "printer offline",
   "slow PC") — shows method, not luck.
3. **A polished KB article** (e.g. VPN access) — shows you can communicate to non-technical users.
4. **An incident report + RCA** (Lessons 31, 32) — shows you can handle pressure and prevent
   recurrence. This is what separates senior candidates.
5. **A capstone metrics report** (Lesson 34) — shows you understand the *business* of support
   (FCR, MTTR, SLA, CSAT).

## Turning a lesson into a portfolio entry
Each lesson's §10 gives you a **resume bullet** and a **talking point**. Collect them:
- Per lesson → §10 in the lesson README.
- Per milestone → `lessons/<milestone>/PORTFOLIO.md` (the roll-up).
- Top-level → your resume + LinkedIn (see [`LINKEDIN-GUIDE.md`](LINKEDIN-GUIDE.md)).

### Resume bullet formula
> **Action verb + what + how (tool) + outcome/metric.**
> *"Built a scripted user-onboarding process (PowerShell + AD + M365) that provisions a new hire's
> account, groups, license, mailbox, and device from a single CSV, cutting onboarding from 45 to 10
> minutes."*

Even though it's lab/simulated, this is **true** (you built it) and **demonstrable** (it's in the
repo). The honesty rule: claim only what's in the repo, and label simulated work as a lab/personal
project. (See the resume-claims rule the operator follows across all platforms.)

## Presentation checklist
- [ ] `README.md` explains what the repo is and the AI-disclosure (already done).
- [ ] Each artifact is self-contained and sanitized (no real data — `navi.project.md` Hard Rule #1).
- [ ] Commit history reflects steady, real work (commit per lesson/artifact).
- [ ] A pinned "start here" path: ROADMAP → a flagship runbook → a capstone.
- [ ] Your resume/LinkedIn link to specific files, not just the repo root.

## What NOT to do
- Don't dump AI-generated walls of text and call it a portfolio — write the artifacts in your own
  voice; the lesson teaches you so you *can*.
- Don't claim production experience you don't have — "lab/personal project" is respected; lying is
  disqualifying.
- Don't commit real employer/tenant/user data — ever.
