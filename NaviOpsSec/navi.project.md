# navi.project.md — NaviOpsSec

> Navi loads this right after project detection as its **Project Law**. Navi's core
> (`.agent/`) stays project-agnostic; everything specific to *NaviOpsSec* (the Security
> Operations / Blue-Team platform being built and the learning journey behind it) lives here.
>
> Sibling projects:
> - **NaviOps** (`/home/sys-ctl/NaviOps`) — the Linux/DevOps/SysAdmin platform.
> - **NaviOpsNetwork** (`/home/sys-ctl/NaviOpsNetwork`) — the Networking/NOC platform.
>
> Same philosophy, same documentation system, same quality bar. NaviOpsSec is the **third
> platform** and the bridge's destination: it turns a Linux SysAdmin + NOC Technician into a
> **Security Analyst → SOC Analyst (T1/T2) → Security Operations Engineer / Incident Responder
> / Junior Detection Engineer**. This is a **Blue-Team / Security-Operations** platform — *not*
> a hacking or penetration-testing course.

## Identity
- **name**: NaviOpsSec
- **one-liner**: A project-based, operations-focused **Security Operations (Blue Team)**
  learning platform built in public on the Navi framework, taking the operator from
  Linux/NOC foundations to **Security Analyst / SOC Analyst T1–T2 / Security Operations
  Engineer / Incident Responder / Junior Detection Engineer**.
- **stack**: Bash · Linux log analysis & auditing (`journalctl`, `grep`, `awk`, `sed`, `auditd`)
  · syslog/rsyslog · **Wazuh (SIEM/XDR — first-class citizen)** · MITRE ATT&CK · Cyber Kill
  Chain · IOCs/threat intel · Sigma detection rules · detection engineering · alert triage &
  investigation · incident response (NIST SP 800-61) · packet/network forensics (`tcpdump`,
  `tshark`, `ss`, `ip`) · report writing. `.agent/` is the Navi core, copied unmodified from
  the sibling platforms.

## Commands
- **install**: _(none global — added per lesson as tools/stacks are introduced: `auditd`,
  `rsyslog`, the Wazuh manager + agent, `suricata`, `aide`, `sigma-cli`, `jq`)_
- **test**: _(none yet — add `scripts/` checks per lesson: `bash -n`, `shellcheck`; validate
  detection rules with the tool's own checker, e.g. `wazuh-logtest`, `sigma convert`)_
- **run / dev**: open Claude Code here → `/navi <request>`
- **build**: _(n/a until the first Wazuh stack / lab under `infra/`)_
- **lint / typecheck**: `shellcheck scripts/*.sh` (once scripts exist)

## Layout
- **entrypoint**: `.agent/workflows/navi.md` (Navi v28 core, copied from the sibling platforms)
- **pedagogy layer**: `docs/learning/` — `PROJECT_MISSION.md` (constitution),
  `CLAUDE_TEACHING_RULES.md` (the canonical **12-section SOC lesson schema** + Integration
  Lenses — single source of truth), `ROADMAP.md` (35-lesson map + analyst career stages),
  `LEARNING_STATE.md` (living progress tracker), `JOB_MILESTONES.md` (application waves),
  `alignment/` (Security+/CySA+/SC-200/BTL1 + role mappings), `capstones/`, `soc/` (SOC
  operations modules), `workflows/` (the 6-phase IR workflow + templates),
  `threat-hunting-drills.md`, `prompts/` (bootstrap archive),
  `lessons/NN-topic/README.md` (one per completed lesson, schema output)
- **memory + reports**: `docs/` (STATUS/CHANGELOG/TODO/DECISIONS/DEFERRED + `docs/reports/`)
- **platform code**: `infra/` (Wazuh manager/agent configs, detection rules, lab targets),
  `scripts/` (Bash investigation/detection automation), `docs/runbooks/` (incident reports),
  `docs/playbooks/` (detection & response playbooks), `docs/templates/` (report/evidence
  templates), `docs/detections/` (Sigma/Wazuh rule library), `docs/dashboards/`
- **config / env**: real secrets never committed — see Hard Rules below

## Hard Rules ("Schema Lock") — what Navi must never violate here
1. **Public-repo discipline (this repo ships to GitHub as a portfolio piece).** No real public
   IPs, internal hostnames/asset names, employer log data, usernames/credentials, API keys,
   Wazuh cluster keys/agent keys, SIEM URLs, or raw captures/log excerpts containing real PII
   are ever committed. Use RFC 1918 / RFC 5737 ranges, `host01.lab.example`, and the
   placeholders in `LEARNING_STATE.md`. All sample alerts/logs are **lab-generated or
   sanitized**.
2. **Blue-Team framing, lab-only offense.** This is a Security-Operations platform. Any attack
   *generation* used to produce telemetry (failed logins, brute force, port scans, web-attack
   requests, simulated persistence) is **benign and executed only against self-owned lab
   targets** for the purpose of detecting it. Never against a third party. Authorization
   context is always: educational, the operator's own lab.
3. **Lesson schema is canonical in ONE file**: `docs/learning/CLAUDE_TEACHING_RULES.md`
   (the 12-section SOC schema + Lenses). Every lesson follows it; other docs link to it.
4. **Every lesson produces real operational evidence** — the **6-artifact contract**: a
   detection/investigation **script**, a **detection rule/config** (Wazuh/Sigma/auditd), a
   **runbook**, a **playbook**, an **incident report + investigation notes**, and a **SOC-NN
   ticket** — into `scripts/`, `infra/`, `docs/runbooks/`, `docs/playbooks/`. No disconnected
   toy exercises.
5. **`docs/learning/LEARNING_STATE.md` is updated after every lesson/milestone** — a fresh
   session resumes teaching from it with zero re-explanation.
6. **No auto-spend / no auto-send** (P00, inherited): never run a scan/attack against a host
   the operator doesn't own, send data to a third party, `git push`, or spin up paid cloud
   resources without the human explicitly approving that specific command.

## Danger Zones (confirm before touching)
- **Attack simulation** (`nmap`, `hydra`/`ncrack`, web-attack generators, persistence/priv-esc
  simulation) — only against self-owned lab targets, benign payloads, never real malware.
  Authorization context required and stated in the lesson.
- **auditd / log pipeline changes** on a live host — can flood disk or drop events; test in lab.
- **Wazuh active response** (auto-block, kill-process, firewall-drop) — can lock you out or take
  down a service; enable only in lab, with console fallback.
- **Packet capture** (`tcpdump`/`tshark`) — captures may contain credentials and PII; redact,
  never commit raw captures from a real network.
- **Firewall containment** (`nftables`/`iptables`/`firewalld` drop rules) on a live machine —
  can cut off a remote host. Confirm + have console fallback.
- **Editing `.agent/`** (Navi core) — keep in sync with the sibling platforms; project-specific
  content belongs in `docs/learning/` or this file, not `.agent/`.

## Notes
- **MENTOR (P11) teaching depth in NaviOpsSec**: when MENTOR answers a command question (e.g.
  "what does `auditctl -w` do", "is `grep 'Failed password' /var/log/auth.log` best practice"),
  it composes this project's teaching schema as its depth — the **12-section SOC lesson schema**
  (`CLAUDE_TEACHING_RULES.md`) + **Integration Lenses** (Two-Approach explanation, Bash
  automation, Detection lens, Investigation lens, Attacker/Defender). So command mentoring
  matches the lesson pedagogy.
- A fresh session resumes from `docs/STATUS.md` (project/code state) **and**
  `docs/learning/LEARNING_STATE.md` (pedagogy/progress state) — read both first.
- **Linux-first detection & investigation**: every concept is taught from the Linux CLI first
  (`journalctl`, `grep`, `awk`, `sed`, `find`, `auditd`, `ss`, `tcpdump`), then mapped to the
  SIEM (Wazuh query / rule, Sigma). The operator must be able to investigate an incident
  directly on the box *and* in the SIEM — that's the platform's signature.
- **Wazuh is a first-class citizen**: installation, agents, decoders/rules, alerts, dashboards,
  active response, FIM, and incident investigation are taught in depth (Lessons 13–16, 24, and
  the projects 31–35).
- **The bridge**: NaviOps (Linux) + NaviOpsNetwork (networking/NOC) + NaviOpsSec (security ops)
  form one career path — NOC Technician → Linux Support → Junior SysAdmin → Security Analyst →
  Security Operations Engineer. See `docs/learning/alignment/ROLE-MAPPING.md`.
- Origin of this project: built per the operator's `1.md` spec to extend the NaviOps /
  NaviOpsNetwork standards into a Blue-Team Security-Operations academy.
