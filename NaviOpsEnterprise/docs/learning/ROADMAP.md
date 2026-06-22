# NaviOpsEnterprise — Roadmap (36 lessons → IT-Support-ready)

The full curriculum, the skills each lesson builds, the 6-artifact evidence it produces, and the
role each one serves. The lesson schema (how each is taught) is authoritative in
[`CLAUDE_TEACHING_RULES.md`](CLAUDE_TEACHING_RULES.md). Progress is tracked live in
[`LEARNING_STATE.md`](LEARNING_STATE.md).

> **Career arc:** Help Desk Tier 1 → Help Desk Tier 2 → IT Support Specialist → Desktop Support
> Technician → Junior System Administrator → Infrastructure Support Engineer. The roadmap front-
> loads the skills that get you hired into a queue (1–17), then deepens into Windows Server / AD /
> M365 administration (18–27), operations discipline (28–33), and three capstones (34–36).

## Module map

| Module | Lessons | Focus | Primary role served |
|---|---|---|---|
| **A · IT & Hardware Foundations** | 01–03 | IT fundamentals, computer hardware, operating-systems fundamentals | Help Desk T1 |
| **B · The Two Desktops** | 04–07 | Windows fundamentals, Linux fundamentals for support, filesystems & storage, user accounts & permissions | Help Desk T1 / Desktop Support |
| **C · Networking & Connectivity** | 08–09 | Networking fundamentals, DNS/DHCP & connectivity | Help Desk T1/T2 |
| **D · Peripherals & End-User Apps** | 10–14 | Printers & peripherals, M365 fundamentals, Google Workspace admin, email troubleshooting, browser/web troubleshooting | Desktop Support / IT Support |
| **E · The Service Desk** | 15–17 | Ticketing systems, help-desk workflows, ITIL fundamentals | Help Desk T1/T2 |
| **F · Identity & Directory** | 18–21 | Active Directory, Group Policy, user provisioning/deprovisioning, password resets & account recovery | IT Support / Junior SysAdmin |
| **G · Windows Server & Endpoints** | 22–27 | Windows Server, file shares & permissions, endpoint troubleshooting, software install/mgmt, patch mgmt, asset mgmt | Junior SysAdmin / Infra Support |
| **H · Operations Discipline** | 28–33 | Documentation/KB, security awareness, backup & recovery, incident management, RCA, Jira Service Management | IT Support → Junior SysAdmin |
| **I · Capstones** | 34–36 | Service-desk capstone, IT-support capstone, junior-sysadmin capstone | Hireable portfolio |

## Lesson-by-lesson

### Module A — IT & Hardware Foundations
| # | Lesson | You will be able to… | Key artifact |
|---|---|---|---|
| 01 | IT Fundamentals | Speak the language of IT support; map the support tiers; take a ticket end-to-end | Runbook: "anatomy of a ticket" |
| 02 | Computer Hardware | Identify components, diagnose a no-boot/no-display, do safe hardware swaps | Troubleshooting guide: hardware failure |
| 03 | Operating-Systems Fundamentals | Explain how an OS works (processes, memory, boot); compare Windows/macOS/Linux for support | KB: "which OS am I supporting" |

### Module B — The Two Desktops
| # | Lesson | You will be able to… | Key artifact |
|---|---|---|---|
| 04 | Windows Fundamentals | Navigate Windows for support: Settings, Control Panel, Task Manager, Event Viewer, Services, Reliability Monitor | Runbook: Windows triage |
| 05 | Linux Fundamentals for Support | Survive on a Linux box: shell, files, permissions, `systemctl`, logs — enough to support it | Script: `linux_triage.sh` |
| 06 | Filesystems & Storage | NTFS/FAT/exFAT, disk management, free up space, recover a full/failing disk | Script: `disk_cleanup.ps1` |
| 07 | User Accounts & Permissions | Local vs domain accounts, NTFS vs share permissions, UAC, least privilege | Troubleshooting: "access denied" |

### Module C — Networking & Connectivity
| # | Lesson | You will be able to… | Key artifact |
|---|---|---|---|
| 08 | Networking Fundamentals | IP/subnet/gateway/DNS, the OSI mental model, `ipconfig`/`ping`/`tracert`, Wi-Fi vs wired | Runbook: "no internet" triage |
| 09 | DNS, DHCP & Connectivity | How a name resolves, how a lease is granted; fix DNS and DHCP failures | Script: `check_dns.ps1` |

### Module D — Peripherals & End-User Apps
| # | Lesson | You will be able to… | Key artifact |
|---|---|---|---|
| 10 | Printers & Peripherals | Install/share printers, fix "printer offline"/spooler/driver issues, support docks & displays | Runbook: printer offline |
| 11 | Microsoft 365 Fundamentals | Licensing, the admin center, Outlook/Teams/OneDrive/SharePoint support, common requests | KB: M365 self-service |
| 12 | Google Workspace Administration | Admin console, users/groups/OUs, Gmail/Drive support, the M365↔Workspace map | Runbook: Workspace user mgmt |
| 13 | Email Troubleshooting | Mail flow, NDRs, Outlook profile/OST issues, quota, send/receive failures | Troubleshooting: email |
| 14 | Browser & Web Troubleshooting | Cache/cookies/extensions, certificate errors, proxy, SSO/web-app login failures | KB: browser fixes |

### Module E — The Service Desk
| # | Lesson | You will be able to… | Key artifact |
|---|---|---|---|
| 15 | Ticketing Systems Fundamentals | Work a queue in Jira SM / ServiceNow / Zendesk concepts; states, fields, priority | Templates: ticket note |
| 16 | Help-Desk Workflows | Intake → triage → resolve → escalate → close; FCR; warm handoffs; shift handover | Playbook: HELPDESK |
| 17 | ITIL Fundamentals | Incident vs request vs problem vs change; SLAs; the value chain | Runbook: incident vs request |

### Module F — Identity & Directory
| # | Lesson | You will be able to… | Key artifact |
|---|---|---|---|
| 18 | Active Directory Fundamentals | Domains, OUs, users, groups, the logon flow; ADUC + PowerShell | Script: `aduc_query.ps1` |
| 19 | Group Policy Fundamentals | How GPO processes, link/scope/precedence, `gpresult`/`gpupdate`, common policies | Troubleshooting: GPO not applying |
| 20 | User Provisioning & Deprovisioning | Onboard/offboard end-to-end (AD + M365 + groups + mailbox + device) | Script: `new_user_onboard.ps1` |
| 21 | Password Resets & Account Recovery | Reset/unlock securely with identity verification; SSPR; lockout root cause | Script: `reset_password.ps1` |

### Module G — Windows Server & Endpoints
| # | Lesson | You will be able to… | Key artifact |
|---|---|---|---|
| 22 | Windows Server Fundamentals | Server roles, Server Manager, services, Event/Performance monitoring, remote admin | Runbook: server health check |
| 23 | File Shares & Permissions | Build a share, share vs NTFS, ABE, mapped drives, fix access issues | Troubleshooting: share access |
| 24 | Endpoint Troubleshooting | Slow PC, boot issues, profile corruption, blue screens, performance triage | Runbook: slow computer |
| 25 | Software Installation & Management | Install/uninstall, MSI/winget, app deployment, license/compat issues | Script: `software_inventory.ps1` |
| 26 | Patch Management | Windows Update/WSUS/Intune, rings, reboot mgmt, failed-update fixes | Runbook: patch deployment |
| 27 | Asset Management | Inventory, lifecycle, CMDB basics, asset tags, stock/loaner process | Template: asset register |

### Module H — Operations Discipline
| # | Lesson | You will be able to… | Key artifact |
|---|---|---|---|
| 28 | Documentation & Knowledge Bases | Write runbooks/KB that the next tech can actually use; KB lifecycle | Playbook: documentation |
| 29 | Security Awareness for IT Support | Verify identity, spot phishing/MFA-fatigue/pretexting, least privilege, data handling | KB: support security |
| 30 | Backup & Recovery Fundamentals | Backup types, the 3-2-1 rule, restore tests, OneDrive/Known-Folder recovery | Runbook: file recovery |
| 31 | Incident Management | Run a major incident: declare, comms, bridge, roles, timeline, resolve | Template: incident report |
| 32 | Root Cause Analysis | 5 Whys / fishbone, evidence, write an RCA that prevents recurrence | Template: RCA |
| 33 | Jira Service Management | Queues, SLAs, automation, request types, reporting — the real ITSM tool | Runbook: JSM workflow |

### Module I — Capstones
| # | Lesson | The project | Deliverable |
|---|---|---|---|
| 34 | Service Desk Capstone | Run a simulated service desk: handle 50 tickets, document resolutions, create KBs, escalate, produce a metrics report | `capstones/34-…` portfolio package |
| 35 | IT Support Capstone | Manage an IT-support environment: users, permissions, devices, software, documentation, incidents | `capstones/35-…` portfolio package |
| 36 | Junior SysAdmin Capstone | Operate as a junior sysadmin: provision systems, manage accounts, handle incidents, run backups, write reports | `capstones/36-…` portfolio package |

## What "done" looks like for a lesson
A lesson is complete when its `lessons/NN-…/README.md` covers all 12 sections, the **6-artifact
evidence package** is committed (runbook, troubleshooting guide, ticket notes, KB article,
incident report, portfolio artifact — plus a script where automatable), the **quiz** is answered
to a professional standard, and `LEARNING_STATE.md` is updated. See the Artifact Contract in
[`CLAUDE_TEACHING_RULES.md`](CLAUDE_TEACHING_RULES.md) §9.
