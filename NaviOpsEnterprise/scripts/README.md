# scripts/ — what you produce here

**This folder starts empty on purpose — you build it lesson by lesson.** It holds the real support
automation (PowerShell, plus Bash where relevant) you write as each lesson's §9 deliverable. Every script
is a portfolio artifact.

## Standards
- **PowerShell:** use **`-WhatIf`/`-Confirm`** for any write/destructive action; keep it
  `Invoke-ScriptAnalyzer`-clean. **Bash:** `shellcheck`-clean, `bash -n` syntax-checked.
- **Lab/authorized targets only** — never run write operations against a live domain/tenant
  (`navi.project.md` danger zones).
- **Sanitized** — no real names/emails/IPs/keys; use placeholders (`corp.example`, RFC 1918).

## What each lesson asks you to build (its §8/§9)
| From | Script |
|---|---|
| L02 | `hardware_inventory.ps1` |
| L03 | `os_triage.ps1` |
| L04 | `windows_triage.ps1` |
| L05 | `linux_triage.sh` |
| L06 | `disk_cleanup.ps1` |
| L07 | `whoami_access.ps1` |
| L08 | `net_triage.ps1` |
| L09 | `check_dns.ps1` |
| L10 | `spooler_reset.ps1` |
| L11 | `m365_user_report.ps1` (Microsoft Graph) |
| L13 | `mailbox_report.ps1` (Exchange Online) |
| L18 | `aduc_query.ps1` |
| L19 | `gpresult_collect.ps1` (+ GPO backup/restore helper) |
| L20 | `new_user_onboard.ps1` + `offboard_user.ps1` (portfolio centerpiece) |
| L21 | `reset_password.ps1` + `unlock_account.ps1` |
| L22 | `server_health.ps1` (remote, multi-server) |
| L23 | `share_audit.ps1` |
| L24 | `endpoint_triage.ps1` (local/remote) |
| L25 | `software_inventory.ps1` |
| L26 | `patch_status.ps1` |
| L27 | `asset_collect.ps1` |

> See each lesson's **§2** (the commands) and **§8/§9** (build + the artifact). These are *your* scripts —
> writing them is the skill the platform builds.
