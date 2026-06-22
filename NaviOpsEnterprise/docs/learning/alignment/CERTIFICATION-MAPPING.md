# Certification Mapping — NaviOpsEnterprise

How the 36 lessons map to the certifications IT-support employers actually ask for. The platform
is **not** a brain-dump — it builds the operational skill, and the cert objectives fall out of it.
Use this to study for the exam *and* to know what to claim on a resume. Pair with
[`ROLE-MAPPING.md`](ROLE-MAPPING.md).

## Target certifications

| Cert | Why it matters here | Best-fit role |
|---|---|---|
| **CompTIA A+ (220-1101 / 220-1102)** | The baseline help-desk/desktop ticket. Hardware, OS, networking basics, troubleshooting method, operational procedures. | Help Desk T1, Desktop Support |
| **CompTIA Network+ (N10-009)** | Connectivity, DNS/DHCP, IP, common network troubleshooting — the "is it the network?" skill. | Help Desk T2, IT Support |
| **Microsoft 365 Fundamentals (MS-900)** | M365 services, licensing, identity (Entra), admin centers. | Help Desk, IT Support |
| **Microsoft Endpoint Administrator (MD-102)** | Windows endpoint deployment, identity, apps, compliance, Intune. | Desktop Support, Jr SysAdmin |
| **ITIL 4 Foundation** | Service management vocabulary employers expect: incident/request/problem/change, SLAs, the value chain. | All service-desk roles |

## A+ coverage (220-1101 Core 1 + 220-1102 Core 2)

| A+ domain | Lessons |
|---|---|
| Mobile/laptop hardware, components | 02 |
| Networking (ports, protocols, IP, tools) | 08, 09 |
| Hardware troubleshooting | 02, 24 |
| Operating systems (Windows install/config, command line) | 03, 04, 05, 06 |
| Security (auth, social engineering, best practices) | 07, 29 |
| Software troubleshooting | 13, 14, 24, 25 |
| Operational procedures (tickets, documentation, change, backup, safety) | 01, 15, 16, 17, 26, 27, 28, 30, 31 |
| Printers & peripherals | 10 |

## Network+ coverage (N10-009)

| Network+ area | Lessons |
|---|---|
| Networking fundamentals (OSI, IP, subnets) | 08 |
| Network implementations / services (DNS, DHCP) | 09 |
| Network troubleshooting & tools (`ipconfig`/`ping`/`tracert`/`nslookup`) | 08, 09 |
| Connectivity issues (wired/wireless) | 08, 10 |

## MS-900 coverage (Microsoft 365 Fundamentals)

| MS-900 area | Lessons |
|---|---|
| Cloud concepts / M365 services (Exchange, Teams, SharePoint, OneDrive) | 11 |
| Microsoft 365 apps & collaboration | 11, 13 |
| Security, compliance, identity (Entra ID) basics | 11, 29 |
| Licensing, pricing, support, admin centers | 11 |
| (Cross-platform contrast) Google Workspace admin | 12 |

## MD-102 coverage (Endpoint Administrator)

| MD-102 area | Lessons |
|---|---|
| Deploy Windows client | 04, 25 |
| Manage identity & compliance | 07, 18, 20, 29 |
| Manage, maintain & protect devices | 24, 26, 27, 30 |
| Manage applications | 25 |

## ITIL 4 Foundation coverage

| ITIL concept | Lessons |
|---|---|
| Service management, value, the four dimensions | 17 |
| Incident management | 17, 31 |
| Service request management | 15, 16, 20 |
| Problem management & RCA | 32 |
| Change enablement (intro) | 17, 26 |
| The service desk practice | 15, 16, 33 |
| SLAs & continual improvement (metrics) | 16, 17, 33, 34 |

## Per-lesson quick reference

| # | Lesson | A+ | Net+ | MS-900 | MD-102 | ITIL |
|---|---|:--:|:--:|:--:|:--:|:--:|
| 01 | IT Fundamentals | ✓ | · | · | · | ✓ |
| 02 | Hardware | ✓ | · | · | · | · |
| 03 | OS Fundamentals | ✓ | · | · | · | · |
| 04 | Windows | ✓ | · | · | ✓ | · |
| 05 | Linux for support | ✓ | · | · | · | · |
| 06 | Filesystems/storage | ✓ | · | · | · | · |
| 07 | Accounts/permissions | ✓ | · | ✓ | ✓ | · |
| 08 | Networking | ✓ | ✓ | · | · | · |
| 09 | DNS/DHCP | ✓ | ✓ | · | · | · |
| 10 | Printers | ✓ | · | · | · | · |
| 11 | M365 | · | · | ✓ | ✓ | · |
| 12 | Google Workspace | · | · | ✓ | · | · |
| 13 | Email | ✓ | · | ✓ | · | · |
| 14 | Browser/web | ✓ | · | · | · | · |
| 15 | Ticketing | ✓ | · | · | · | ✓ |
| 16 | Help-desk workflows | ✓ | · | · | · | ✓ |
| 17 | ITIL | · | · | · | · | ✓ |
| 18 | Active Directory | · | · | ✓ | ✓ | · |
| 19 | Group Policy | · | · | · | ✓ | · |
| 20 | Provisioning | · | · | ✓ | ✓ | ✓ |
| 21 | Password resets | ✓ | · | ✓ | ✓ | ✓ |
| 22 | Windows Server | · | · | · | · | · |
| 23 | File shares | ✓ | · | · | ✓ | · |
| 24 | Endpoint troubleshooting | ✓ | · | · | ✓ | · |
| 25 | Software mgmt | ✓ | · | · | ✓ | · |
| 26 | Patch mgmt | ✓ | · | · | ✓ | ✓ |
| 27 | Asset mgmt | ✓ | · | · | ✓ | · |
| 28 | Documentation/KB | ✓ | · | · | · | ✓ |
| 29 | Security awareness | ✓ | · | ✓ | ✓ | · |
| 30 | Backup/recovery | ✓ | · | · | ✓ | · |
| 31 | Incident mgmt | ✓ | · | · | · | ✓ |
| 32 | RCA | · | · | · | · | ✓ |
| 33 | Jira SM | · | · | · | · | ✓ |
| 34–36 | Capstones | ✓ | ✓ | ✓ | ✓ | ✓ |

> "✓" = the lesson meaningfully advances that exam's objectives; "·" = little/none. Detailed
> objective-by-objective mapping is added to each lesson's §11 as lessons are authored.
