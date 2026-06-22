# SysAdmin Path — NaviOpsEnterprise

The route from a help-desk seat to **Junior System Administrator** and beyond, and how this
platform feeds the three sibling platforms. Pair with
[`alignment/ROLE-MAPPING.md`](alignment/ROLE-MAPPING.md).

## The arc

```
Help Desk T1/T2 ─▶ IT Support / Desktop ─▶ Junior SysAdmin ─▶ Infrastructure / Sr SysAdmin
                                              │
                       ┌──────────────────────┼───────────────────────┐
                       ▼                      ▼                       ▼
                  NaviOps (Linux)    NaviOpsNetwork (NOC)     NaviOpsSec (SOC)
```

NaviOpsEnterprise gets you hired and to Junior SysAdmin. The siblings take you deeper into Linux,
networking, and security.

## What a Junior SysAdmin actually does
- Owns **Active Directory** (users, groups, OUs, GPO) — Lessons 18–21.
- Owns **Windows Server** roles and health — Lesson 22.
- Owns **file/print services and permissions** — Lessons 10, 23.
- Runs **patching and software at scale** — Lessons 25, 26.
- Runs **backups and restores** and proves they work — Lesson 30.
- Handles **incidents and writes RCAs** — Lessons 31, 32.
- Lives in the **ITSM tool** and reports on it — Lessons 15, 17, 33.
- Increasingly **scripts** everything (PowerShell) — across all lessons.

## Skill milestones (gate yourself)

| Milestone | You can… | Proven by |
|---|---|---|
| **M1 — Floor-ready** (after L01–L17) | Work a queue, resolve the common 80%, escalate cleanly | Capstone 34 |
| **M2 — Identity-capable** (after L18–L21) | Create/manage AD users & groups, fix GPO, onboard/offboard, reset securely | `new_user_onboard.ps1` + GPO troubleshooting guide |
| **M3 — Endpoint/server-capable** (after L22–L27) | Stand up a share, patch a ring, manage software/assets, triage a server | Capstone 35 |
| **M4 — Operations-capable** (after L28–L33) | Run an incident, write an RCA, drive a KB, manage backups | Capstone 36 |
| **M5 — SysAdmin** | All of the above, scripted and documented, in a real/simulated environment | Full capstone portfolio |

## The PowerShell ramp
PowerShell is the junior-sysadmin force multiplier. Build it lesson by lesson:
- **Read** the directory: `Get-ADUser`, `Get-ADGroupMember`, `Get-ADComputer` (L18)
- **Change** safely: `Set-ADUser`, `Set-ADAccountPassword`, `Unlock-ADAccount` (L21)
- **Bulk**: pipelines, `Import-Csv | ForEach-Object` for onboarding (L20)
- **Cloud**: `ExchangeOnlineManagement`, `Microsoft.Graph` (L11, L13)
- **Report**: `Export-Csv`, scheduled reports (L27, L33)
- **Discipline**: `-WhatIf`/`-Confirm` before any write; `Invoke-ScriptAnalyzer` on every script.

## When to branch into a sibling platform
- **You like the OS/server layer** → **NaviOps** (Linux/SysAdmin/DevOps).
- **You like connectivity/"is it the network?"** → **NaviOpsNetwork** (NOC).
- **You like the logs, the alerts, the "who did this?"** → **NaviOpsSec** (SOC/Blue Team).

All four share the Navi framework, the 12-section schema, and the artifact-driven portfolio — so
the habits transfer directly.
