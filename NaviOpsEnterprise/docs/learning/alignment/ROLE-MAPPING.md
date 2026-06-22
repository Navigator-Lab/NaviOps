# Role Mapping — NaviOpsEnterprise

Which lessons prepare you for which role, what each role actually does, and where it sits on the
career ladder. Pair with [`CERTIFICATION-MAPPING.md`](CERTIFICATION-MAPPING.md) and
[`../SYSADMIN-PATH.md`](../SYSADMIN-PATH.md).

## The ladder this platform climbs

```
Help Desk T1 ─▶ Help Desk T2 ─▶ IT Support Specialist ─▶ Desktop Support ─▶ Junior SysAdmin ─▶ Infrastructure Support Eng.
   L01–L17          L13–L21            L18–L27               L22–L24            L18–L33              L22–L36
```

## Role-by-role

### Help Desk Tier 1
- **What you do:** first contact. Take the call/ticket, verify identity, resolve the common stuff
  (password reset, unlock, printer, basic connectivity, app questions), and escalate the rest with
  clean notes. Measured on FCR, response time, CSAT.
- **Core lessons:** 01, 04, 07, 08, 10, 11, 13, 14, **15, 16, 17**, 21.
- **Proof you can do it:** worked password-reset/unlock/printer tickets, a clean queue workflow,
  KB articles, identity-verification discipline.

### Help Desk Tier 2
- **What you do:** the escalations T1 couldn't crack — deeper Windows/M365/AD issues, profile
  corruption, mail flow, GPO not applying. You're the bridge to the sysadmin team.
- **Core lessons:** 13, 18, 19, 20, 21, 23, 24, plus everything in T1.
- **Proof:** troubleshooting guides with real diagnostic spines, AD/GPO fixes, an RCA.

### IT Support Specialist
- **What you do:** own end-user IT for a site/team — devices, accounts, software, access, small
  projects. Broader and more autonomous than help desk.
- **Core lessons:** 18, 20, 22, 23, 25, 26, 27, 28, 30.
- **Proof:** onboarding/offboarding runbook + script, software/asset management, documentation set.

### Desktop Support Technician
- **What you do:** hands-on with hardware and endpoints — imaging, deployments, repairs, peripheral
  and conference-room support, deskside visits.
- **Core lessons:** 02, 04, 06, 07, 10, 24, 25, 26, 27.
- **Proof:** hardware troubleshooting guide, endpoint triage runbook, software/patch deployment.

### Junior System Administrator
- **What you do:** keep the servers, directory, and services healthy — AD, GPO, file shares,
  patching, backups, server roles, incidents. The first "infrastructure" role.
- **Core lessons:** 18, 19, 20, 22, 23, 26, 30, 31, 32, and **capstone 36**.
- **Proof:** server health runbook, GPO + share builds, backup/restore test, incident report + RCA.

### Infrastructure Support Engineer
- **What you do:** support the core infrastructure — directory services, identity, file/print,
  patching at scale, monitoring hooks, vendor/major-incident coordination. The bridge into NaviOps
  (Linux/SysAdmin) and NaviOpsNetwork (NOC).
- **Core lessons:** 22, 23, 26, 27, 30, 31, 32, 33, all three capstones.
- **Proof:** the full capstone portfolio + a major-incident writeup.

## Role → lesson matrix (primary ✓ / supporting ·)

| Lesson | T1 | T2 | IT Support | Desktop | Jr SysAdmin | Infra |
|---|:--:|:--:|:--:|:--:|:--:|:--:|
| 01 IT Fundamentals | ✓ | · | · | · | · | · |
| 02 Hardware | · | · | · | ✓ | · | · |
| 03 OS Fundamentals | ✓ | · | · | · | · | · |
| 04 Windows | ✓ | ✓ | · | ✓ | · | · |
| 05 Linux for support | · | · | ✓ | · | ✓ | ✓ |
| 06 Filesystems/storage | · | · | · | ✓ | ✓ | · |
| 07 Accounts/permissions | ✓ | ✓ | ✓ | ✓ | ✓ | · |
| 08 Networking | ✓ | ✓ | · | · | · | ✓ |
| 09 DNS/DHCP | · | ✓ | ✓ | · | ✓ | ✓ |
| 10 Printers | ✓ | · | · | ✓ | · | · |
| 11 M365 | ✓ | ✓ | ✓ | · | · | · |
| 12 Google Workspace | ✓ | ✓ | ✓ | · | · | · |
| 13 Email | ✓ | ✓ | ✓ | · | · | · |
| 14 Browser/web | ✓ | · | · | · | · | · |
| 15 Ticketing | ✓ | ✓ | · | · | · | · |
| 16 Help-desk workflows | ✓ | ✓ | · | · | · | · |
| 17 ITIL | ✓ | ✓ | ✓ | · | · | ✓ |
| 18 Active Directory | · | ✓ | ✓ | · | ✓ | ✓ |
| 19 Group Policy | · | ✓ | ✓ | · | ✓ | ✓ |
| 20 Provisioning | · | ✓ | ✓ | · | ✓ | ✓ |
| 21 Password resets | ✓ | ✓ | ✓ | · | ✓ | · |
| 22 Windows Server | · | · | ✓ | · | ✓ | ✓ |
| 23 File shares | · | ✓ | ✓ | ✓ | ✓ | ✓ |
| 24 Endpoint troubleshooting | · | ✓ | ✓ | ✓ | · | · |
| 25 Software mgmt | · | · | ✓ | ✓ | ✓ | · |
| 26 Patch mgmt | · | · | ✓ | ✓ | ✓ | ✓ |
| 27 Asset mgmt | · | · | ✓ | ✓ | ✓ | ✓ |
| 28 Documentation/KB | ✓ | ✓ | ✓ | · | ✓ | ✓ |
| 29 Security awareness | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| 30 Backup/recovery | · | · | ✓ | · | ✓ | ✓ |
| 31 Incident mgmt | · | ✓ | ✓ | · | ✓ | ✓ |
| 32 RCA | · | ✓ | ✓ | · | ✓ | ✓ |
| 33 Jira SM | ✓ | ✓ | ✓ | · | ✓ | ✓ |
| 34 Service-desk capstone | ✓ | ✓ | · | · | · | · |
| 35 IT-support capstone | · | · | ✓ | ✓ | · | · |
| 36 Jr-sysadmin capstone | · | · | · | · | ✓ | ✓ |
