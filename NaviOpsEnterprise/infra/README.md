# infra/ — Lab Build Definitions (NaviOpsEnterprise)

The lab environment the AD/Server/endpoint lessons (Module F onward) practice against. **Build
notes only** — no secrets, no real tenant data, no real IPs (`navi.project.md` HR#1). Everything
uses `corp.example`, RFC 1918, and placeholder identities from `docs/learning/LEARNING_STATE.md`.

> **Danger zones apply:** AD write ops, GPO links, M365/Entra changes, and offboarding are all
> destructive — practice **only** in this lab, never a live domain/tenant (`navi.project.md`).

## The lab at a glance

```
   ┌──────────────────────── corp.example (lab AD forest/domain: CORP) ────────────────────────┐
   │                                                                                            │
   │   DC01  (Windows Server)  ── AD DS + DNS + DHCP   10.10.0.10  (the domain controller)      │
   │   FS01  (Windows Server)  ── File services + shares (\\FS01\…)  10.10.0.20                  │
   │   CLIENT01 (Windows 10/11) ── domain-joined test endpoint      DHCP                        │
   │   (optional) WS-LINUX     ── Ubuntu, for L05 Linux-for-support  DHCP                        │
   │                                                                                            │
   │   Network: 10.10.0.0/24   gateway 10.10.0.1   DNS 10.10.0.10 (DC)   DHCP scope 10.10.0.100-200 │
   └────────────────────────────────────────────────────────────────────────────────────────────┘

   M365 / Entra: a Microsoft 365 *developer/dev tenant* (corp.onmicrosoft.com — MODEL only),
   for L11/L13/L20/L21 cloud-identity practice. Never a production tenant.
```

## Build options (pick what you have)
- **Local hypervisor:** Hyper-V / VirtualBox / VMware on a workstation — 2–3 VMs (DC01, FS01,
  CLIENT01) on an internal/NAT network `10.10.0.0/24`.
- **Cloud lab:** a small Windows Server VM as DC01 + a client (mind cost; stop when idle — no
  auto-spend, P00).
- **M365 side:** a free **Microsoft 365 Developer Program** dev tenant (sample users) — treat as a
  model; apply the redaction convention.

## DC01 — Domain Controller (Lessons 18, 19)
- Install **Windows Server**; set static IP `10.10.0.10`; rename to `DC01`.
- Promote to a domain controller: new forest **`corp.example`** (NetBIOS `CORP`).
- Add roles: **AD DS** (done by promotion), **DNS** (auto with DC), **DHCP** (scope
  `10.10.0.100–10.10.0.200`, gateway `10.10.0.1`, DNS `10.10.0.10`).
- Create the **OU structure** (L18): `OU=Corp` → `Departments` (Sales, Finance, IT…), `Users`,
  `Groups`, `Computers`, `ServiceAccounts`.
- Seed placeholder users/groups (`jdoe`, `asmith`, `Finance`, `Projects`…) — see LEARNING_STATE.

## FS01 — File Server (Lessons 22, 23)
- Windows Server; static `10.10.0.20`; domain-join to `corp.example`.
- Create shares (`\\FS01\Finance`, `\\FS01\Projects`) with **share + NTFS** permissions granted by
  **group** (L07/L23); enable Access-Based Enumeration.

## CLIENT01 — Test endpoint
- Windows 10/11; domain-join to `corp.example`; log in as a placeholder user to test logon, GPO
  (`gpresult`), drive maps, and the endpoint lessons (L24).

## Scripts that target this lab (`/scripts`)
Built across Module F+: `aduc_query.ps1`, `reset_password.ps1`, `unlock_account.ps1`,
`new_user_onboard.ps1`, `offboard_user.ps1`, plus the earlier triage scripts. All use `-WhatIf`
defaults for write operations and target the **lab** domain only.

## Safety checklist (every lab session)
- [ ] Confirm you're targeting **DC01/corp.example (lab)**, not a production domain.
- [ ] Write ops (`Set-ADUser`, `Remove-ADUser`, GPO links) run with `-WhatIf` first.
- [ ] No real names/emails/IPs/keys committed — sanitize before saving any output to the repo.
- [ ] Snapshots before risky changes (GPO links, schema-ish ops) so you can roll back.
