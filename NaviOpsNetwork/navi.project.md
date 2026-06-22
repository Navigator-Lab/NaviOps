# navi.project.md — NaviOpsNetwork

> Navi loads this right after project detection as its **Project Law**. Navi's core
> (`.agent/`) stays project-agnostic; everything specific to *NaviOpsNetwork* (the
> networking/NOC platform being built and the learning journey behind it) lives here.
>
> Sibling project: **NaviOps** (`/home/sys-ctl/NaviOps`) — the Linux/DevOps platform this
> one is modeled on. Same philosophy, same documentation system, same quality bar, a
> **networking + NOC + network-security** curriculum instead of a Linux-SysAdmin one.

## Identity
- **name**: NaviOpsNetwork
- **one-liner**: A project-based, operations-focused Networking learning platform built in
  public on the Navi framework, taking the operator from beginner to **NOC Technician /
  Network Operations Engineer / Linux Network Admin / Junior Network Engineer**, with a
  Security-Analyst (networking track) on-ramp.
- **stack**: Bash · Linux networking (`ip`, `ss`, `tcpdump`, `nftables`) · CompTIA Network+ ·
  CCNA · DNS/DHCP/NAT · routing & switching (VLAN/STP/EtherChannel) · monitoring
  (Prometheus/Grafana, Zabbix, SNMP, syslog) · packet analysis (Wireshark/tshark/tcpdump) ·
  network security & detection (nmap, Suricata/IDS, Wazuh/SIEM). `.agent/` is the Navi core,
  copied unmodified from `Navigator-Lab/Navi`.

## Commands
- **install**: _(none yet — added per lesson as tools are introduced: `iproute2`, `tcpdump`,
  `tshark`, `bind-utils`/`dnsutils`, `nmap`, `mtr`, `snmp`, `net-snmp-utils`)_
- **test**: _(none yet — add `scripts/` checks per lesson, e.g. `bash -n`, `shellcheck`)_
- **run / dev**: open Claude Code here → `/navi <request>`
- **build**: _(n/a until first lab topology / monitoring stack under `infra/`)_
- **lint / typecheck**: `shellcheck scripts/*.sh` (once scripts exist)

## Layout
- **entrypoint**: `.agent/workflows/navi.md` (Navi v28 core, copied from `Navigator-Lab/Navi`)
- **pedagogy layer**: `docs/learning/` — `PROJECT_MISSION.md` (constitution),
  `CLAUDE_TEACHING_RULES.md` (the canonical **12-section lesson schema** + Integration
  Lenses — single source of truth), `ROADMAP.md` (36-lesson map + NOC-first career stages),
  `LEARNING_STATE.md` (living progress tracker), `JOB_MILESTONES.md` (application waves),
  `alignment/` (CCNA / Network+ / NOC matrices), `capstones/`, `noc/` (NOC ops modules),
  `troubleshooting-drills.md`, `prompts/` (bootstrap archive),
  `lessons/NN-topic/README.md` (one per completed lesson, schema output)
- **memory + reports**: `docs/` (STATUS/CHANGELOG/TODO/DECISIONS/DEFERRED + `docs/reports/`)
- **platform code**: `infra/` (lab topologies, monitoring stacks, device/service configs),
  `scripts/` (Bash network automation), `docs/runbooks/` (incident reports),
  `docs/networking/` (cheatsheets), `docs/diagrams/` (ASCII/architecture), `docs/dashboards/`
- **config / env**: real secrets never committed — see Hard Rules below

## Hard Rules ("Schema Lock") — what Navi must never violate here
1. **Public-repo discipline (this repo ships to GitHub as a portfolio piece).** No real
   public IPs, router/switch management IPs, hostnames, ISP/circuit IDs, employer topology,
   SNMP community strings, device credentials, VPN PSKs, or `.pcap` files containing real
   capture data are ever committed. Lab/RFC-1918 ranges and documentation ranges only
   (`10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16`, `203.0.113.0/24` per RFC 5737);
   placeholders `<PUBLIC_IP>`, `<MGMT_IP>`, `<COMMUNITY_STRING>`, `<PSK>`. See
   `LEARNING_STATE.md` for the redaction convention.
2. **Lesson schema is canonical in ONE file**: `docs/learning/CLAUDE_TEACHING_RULES.md`
   (the 12-section schema + Lenses). Every lesson follows it. Other docs
   (`PROJECT_MISSION.md`, `ROADMAP.md`) link to it, never restate it.
3. **Every lesson produces real operational evidence** — a script + config/topology + a
   troubleshooting drill + a NAVI ticket + (when a failure/IR is involved) an incident
   report — into `scripts/`, `infra/`, `docs/runbooks/`. No disconnected toy exercises.
4. **`docs/learning/LEARNING_STATE.md` is updated after every lesson/milestone** — a fresh
   session resumes teaching from it with zero re-explanation.
5. **No auto-spend / no auto-send** (P00, inherited): never run a scan against a host you
   don't own, send live traffic to third-party infrastructure, `git push`, or spin up paid
   cloud network resources (AWS VPC/NAT GW/ELB) without the human explicitly approving that
   specific command.

## Danger Zones (confirm before touching)
- **Active scanning / recon** (`nmap`, `masscan`, brute-force tooling) — only against
  lab hosts/ranges the operator owns. Never a third party. Authorization context required.
- **Packet capture** (`tcpdump`/`tshark`/Wireshark) — captures may contain credentials and
  PII; redact and never commit raw `.pcap` from a real network.
- **Firewall / routing changes** (`nftables`/`iptables`, `ip route`, VLAN/STP changes) on a
  live machine — can cut you off from a remote host. Confirm + have console fallback.
- **Cloud networking** (AWS VPC/IGW/NAT GW/ELB/Route 53) — billing-affecting; human-approved
  only, redact account IDs/IPs before any doc or screenshot is committed.
- **Editing `.agent/`** (Navi core) — keep in sync with upstream `Navigator-Lab/Navi`;
  project-specific content belongs in `docs/learning/` or this file, not `.agent/`.

## Notes
- **MENTOR (P11) teaching depth in NaviOpsNetwork**: when MENTOR answers a command question
  (e.g. "what does `dig +trace` do", "is `tcpdump -nn` best practice"), it composes this
  project's teaching schema as its depth — the **12-section lesson schema**
  (`CLAUDE_TEACHING_RULES.md`) + **Integration Lenses** (Two-Approach explanation, Bash
  automation, NOC perspective, Incident-Response perspective, Attacker/Defender). So command
  mentoring matches the lesson pedagogy. The generic protocol stays in `.agent/`; this
  binding is the project-specific overlay.
- A fresh session resumes from `docs/STATUS.md` (project/code state) **and**
  `docs/learning/LEARNING_STATE.md` (pedagogy/progress state) — read both first.
- **Linux-first networking**: every protocol is taught from the Linux CLI first (`ip`, `ss`,
  `dig`, `tcpdump`, `nmap`, `curl`, `nc`, `socat`, `mtr`), then mapped to Cisco/CCNA syntax —
  not the other way around. This is the platform's signature and its differentiator.
- **RHCSA crossover**: networking lessons that overlap RHCSA objectives (NetworkManager,
  `nmcli`, firewalld, hostname/DNS resolution, `ss`/`ip`) carry an RHCSA crossover note,
  so this platform doubles as RHCSA-networking prep alongside the sibling NaviOps RHCSA track.
- Origin of this project: modeled on NaviOps (`/home/sys-ctl/NaviOps`) per the operator's
  request to build a second, networking-dedicated platform on the same standards.
