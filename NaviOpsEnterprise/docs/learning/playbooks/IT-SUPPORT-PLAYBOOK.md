# IT Support Playbook — NaviOpsEnterprise

The operating manual for the **IT Support Specialist / Desktop Support** role — broader and more
autonomous than the front-line desk. Where the [Help Desk playbook](HELPDESK-PLAYBOOK.md) is about
working a queue, this is about **owning end-user IT** for a team or site: devices, accounts,
access, software, and the small projects in between tickets.

## What changes at this level
- You **own outcomes**, not just tickets. "The new hire starts Monday" is yours end-to-end.
- You touch **AD, M365, file shares, and endpoints with write access** — so the danger zones in
  `navi.project.md` are now *your* responsibility. Confirm scope, target the right object, log it.
- You're the **escalation target** for T1, and the **escalator** to sysadmin/infra and vendors.
- You think in **standard processes**, not one-offs: onboarding, offboarding, imaging, software
  catalog, patch rings, asset lifecycle.

## The core processes you own

### 1 · Onboarding (new user) — Lesson 20
A repeatable checklist, ideally scripted (`scripts/new_user_onboard.ps1`):
- [ ] AD account created in the correct OU, naming standard, manager/title set
- [ ] Group memberships per role (least privilege)
- [ ] M365 license assigned; mailbox provisioned
- [ ] Home/share access; mapped drives
- [ ] Device assigned, imaged, asset-tagged, recorded
- [ ] MFA enrolled; temp password delivered securely; welcome/first-login doc sent
- [ ] Ticket documented + handed to the user's manager

### 2 · Offboarding (leaver) — Lesson 20
Staged and reversible-where-possible (`scripts/offboard_user.ps1`):
- [ ] Disable account + revoke sessions (don't delete day one)
- [ ] Block sign-in / reset password
- [ ] Convert/forward mailbox per policy; preserve data per retention
- [ ] Reclaim license, devices, access; update asset register
- [ ] Document; schedule deletion per policy

### 3 · Device lifecycle — Lessons 06, 24, 25, 26, 27
Provision → image → deploy → support → patch → refresh → retire/wipe. Every device has an asset
record and an owner.

### 4 · Access management — Lessons 07, 18, 23
Grant by **group**, not by individual ACL. Least privilege. Time-box elevated access. Every grant
is traceable to a request + approval.

### 5 · Software management — Lesson 25
A **catalog** of approved/standard apps (self-service where possible), a request+approval path for
the rest, license tracking, and a clean uninstall/upgrade story.

## Decision guides

**Repair vs replace (hardware):** if labor + parts > ~50% of replacement, or the device is past
refresh age, replace and recover data. Always recover data first.

**Fix in place vs reimage (software/OS):** time-box in-place troubleshooting (~30–45 min for a
single endpoint). If profile/OS corruption is suspected and data is backed up (OneDrive/Known
Folder Move), reimage — it's faster and cleaner than chasing a ghost.

**Do it manually vs script it:** if you'll do it more than ~3 times, or it must be identical every
time (onboarding!), script it. Consistency and auditability beat clicking.

## Working with the rest of IT
- **T1 hands you** tickets — give feedback so they resolve more themselves; feed the KB.
- **You hand sysadmin/infra** the server/directory/infra-level problems (with a package).
- **You hand vendors** hardware RMAs and product bugs (with logs + repro).
- **You feed problem management** (Lesson 32) when the same incident keeps recurring.

## Change discipline (intro — Lesson 17, 26)
Anything that affects more than one user goes through change awareness: what, why, blast radius,
rollback, pilot first (a ring), and a maintenance window. A patch that bricks the fleet is a
career event; a piloted patch is a Tuesday.

## Documentation you maintain
- **Runbooks** for every recurring task (`docs/runbooks/`)
- **Troubleshooting guides** for every recurring problem (`docs/troubleshooting/`)
- **KB articles** for anything users can self-serve (`docs/kb/`)
- **The asset register** (Lesson 27) and access records
- **Incident reports + RCAs** for anything that hurt (Lessons 31, 32)
