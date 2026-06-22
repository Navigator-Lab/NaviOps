# LEARNING_STATE — NaviOpsEnterprise

> **Read this first** (with `docs/STATUS.md`). A fresh session resumes teaching from here with
> zero re-explanation. Updated after every lesson/milestone (`CLAUDE_TEACHING_RULES.md` Update
> Protocol).

## Where we are

- **Phase:** ✅ **v1 COMPLETE** — all 36 lessons + 3 capstones authored full-depth.
- **Current lesson:** none pending — the operator now *studies/executes* lessons 01→36 in order.
- **Lessons complete:** 01–36 authored full-depth (see table below).
- **Lab state:** lab build notes written (`infra/README.md` — DC01/FS01 + M365 dev-tenant model);
  learner builds the AD/server lab from Lesson 18 onward.

## Lesson progress

| # | Lesson | Status |
|---|---|---|
| 01 | IT Fundamentals | ✅ authored — ready for self-study |
| 02 | Computer Hardware | ✅ authored — ready for self-study |
| 03 | Operating-Systems Fundamentals | ✅ authored — ready for self-study |
| 04 | Windows Fundamentals | ✅ authored — ready for self-study |
| 05 | Linux Fundamentals for Support | ✅ authored — ready for self-study |
| 06 | Filesystems & Storage | ✅ authored — ready for self-study |
| 07 | User Accounts & Permissions | ✅ authored — ready for self-study |
| 08 | Networking Fundamentals | ✅ authored — ready for self-study |
| 09 | DNS, DHCP & Connectivity | ✅ authored — ready for self-study |
| 10 | Printers & Peripherals | ✅ authored — ready for self-study |
| 11 | Microsoft 365 Fundamentals | ✅ authored — ready for self-study |
| 12 | Google Workspace Administration | ✅ authored — ready for self-study |
| 13 | Email Troubleshooting | ✅ authored — ready for self-study |
| 14 | Browser & Web Troubleshooting | ✅ authored — ready for self-study |
| 15 | Ticketing Systems Fundamentals | ✅ authored — ready for self-study |
| 16 | Help-Desk Workflows | ✅ authored — ready for self-study |
| 17 | ITIL Fundamentals | ✅ authored — ready for self-study |
| 18 | Active Directory Fundamentals | ✅ authored — ready for self-study |
| 19 | Group Policy Fundamentals | ✅ authored — ready for self-study |
| 20 | User Provisioning & Deprovisioning | ✅ authored — ready for self-study |
| 21 | Password Resets & Account Recovery | ✅ authored — ready for self-study |
| 22 | Windows Server Fundamentals | ✅ authored — ready for self-study |
| 23 | File Shares & Permissions | ✅ authored — ready for self-study |
| 24 | Endpoint Troubleshooting | ✅ authored — ready for self-study |
| 25 | Software Installation & Management | ✅ authored — ready for self-study |
| 26 | Patch Management | ✅ authored — ready for self-study |
| 27 | Asset Management | ✅ authored — ready for self-study |
| 28 | Documentation & Knowledge Bases | ✅ authored — ready for self-study |
| 29 | Security Awareness for IT Support | ✅ authored — ready for self-study |
| 30 | Backup & Recovery Fundamentals | ✅ authored — ready for self-study |
| 31 | Incident Management | ✅ authored — ready for self-study |
| 32 | Root Cause Analysis | ✅ authored — ready for self-study |
| 33 | Jira Service Management | ✅ authored — ready for self-study |
| 34 | Service Desk Capstone | ✅ authored — ready to execute |
| 35 | IT Support Capstone | ✅ authored — ready to execute |
| 36 | Junior SysAdmin Capstone | ✅ authored — ready to execute |

## Skills acquired
_(updated as lessons complete — skill → lesson it was proven in)_

- Ticket lifecycle & support-tier model → L01
- Hardware diagnosis (no-power/no-display, external-monitor test, SMART) → L02
- OS internals & Event-ID reading; boot-stage isolation → L03
- Windows management surfaces (Services/Event Viewer/profiles); temp-profile fix → L04
- Linux literacy (systemctl/journalctl/rwx); Windows↔Linux map → L05
- Storage stack (NTFS/exFAT, disk-full cascade, RAW/do-no-harm recovery) → L06
- Identity & permissions (auth vs authz, share-vs-NTFS, least privilege, stale token) → L07
- Network reachability ladder (localize → bottom-up); major-incident scope → L08
- DHCP/DNS fingerprints (169.254 vs resolver-vs-record) → L09
- Print pipeline (spooler wedge reset, offline quirk, DHCP reservation) → L10
- M365 model (identity→license→permission; MFA re-registration; service health) → L11
- Google Workspace (Admin console/OUs/Shared drives; Workspace↔M365 map) → L12
- Email (NDR codes 5.1.1/5.7.x/4.2.2; OWA-test; rogue inbox-rule check) → L13
- Browser (incognito isolation; DevTools status; cert errors; never bypass) → L14
- Ticketing (one model→three tools; public-vs-internal notes; duplicate storm) → L15
- Run-a-queue (triage by priority+SLA; FCR; warm handoff; shift handover; metrics) → L16
- ITIL (incident/request/problem/change; SLAs; one situation→four records) → L17
- Active Directory (domain/OU/object/group; read account attrs vs membership vs OU) → L18
- Group Policy (LSDOU; four "did it apply" gates; gpresult; backup/rollback) → L19
- Provisioning/deprovisioning (group-based onboard; staged offboard: disable≠revoke; data transfer) → L20
- Password reset/unlock (verify-first; reset vs unlock; Event 4740 lockout source; SSPR) → L21
- Windows Server (roles; remote admin RDP/PS-remoting/RSAT; server-down triage; DC disk-full MI) → L22
- File shares (build-by-group/least-priv/ABE; share-vs-NTFS; open-can't-save; share audit) → L23
- Endpoint troubleshooting (measure the bottleneck; fix-vs-reimage; remote support; data-first) → L24
- Software mgmt (catalog/self-service vs approval; silent deploy; inventory-as-security) → L25
- Patch mgmt (deployment rings; failed-update fix; roll back bad patch; change enablement) → L26
- Asset mgmt (discovery-fed CMDB source of truth; lifecycle; secure disposal; underpins all) → L27
- Documentation/KB (artifact→audience; KCS capture-on-solve; lifecycle; quality checklist) → L28
- Security awareness (verify out-of-band; recognize→contain→escalate; account-takeover signs) → L29
- Backup/recovery (3-2-1 + offline/immutable; RPO/RTO; test restores; ransomware recovery) → L30
- Incident mgmt (declare; IC role; restore-first; comms cadence; timeline; major incident) → L31
- RCA/problem mgmt (5 Whys/fishbone; blameless; corrective+preventive; verify the fix) → L32
- Jira Service Mgmt (queues/JQL; SLAs+pause; automation enforces workflow; deflection; reporting) → L33
- Capstones (run a desk · own an IT env · operate infra safely + report) → L34/L35/L36 (integrative)

## Redaction & lab convention (public-repo discipline)

All examples use **placeholders only** — never real data:

| Thing | Placeholder |
|---|---|
| Domain | `corp.example` / AD: `CORP` |
| Users | `jdoe@corp.example` (Jane Doe), `asmith@corp.example`, `svc_app@corp.example` |
| Hostnames | `LT-0427` (laptop), `DESK-1102`, `DC01`, `FS01` (file server), `PRT-FLOOR2` (printer) |
| IPs | RFC 1918 only: `10.10.x.x`, `192.168.x.x`; gateway `10.10.0.1`, DNS `10.10.0.10` |
| Tenant | `corp.onmicrosoft.com` (model only — no real tenant ID) |
| Ticket IDs | `INC-0001…` (incidents), `REQ-0001…` (requests), `ENT-NN` per-lesson ticket |

## How to resume
1. Read `docs/STATUS.md` (project/code state) + this file (pedagogy state).
2. Next action = the first ⏳ lesson, or the operator's `/navi` request.
3. After any lesson, run the Update Protocol in `CLAUDE_TEACHING_RULES.md`.
