# Lesson 37 — Python for Network Automation

**Status:** 🟡 stub — scaffold only (author on demand) · **Date written:** 2026-06-28
**Schema:** 12-section (`docs/learning/CLAUDE_TEACHING_RULES.md`)
**Intended study position:** after **L18** (network troubleshooting) / before the capstones (**L34–36**) — a track extension. Appended as L37 to avoid renumbering existing lessons.
**Why this lesson exists (job signal):** Python automation is now a **baseline** network-engineer expectation (~1 in 5 postings explicitly; the clearest signal of how the role is evolving past pure BGP/CLI). This is the gap in the NaviOpsNetwork track.
**Focus:** automating device + monitoring tasks with Python — `netmiko`/`paramiko` for SSH, `Nornir` for scale, parsing/validation, and the bridge to cloud (`boto3`).
**Primary artifact (TODO):** a Python script that connects to N devices (or mock/EVE-NG), pulls config/state, parses it, and flags drift — committed with sample output.

> **How to use this lesson:** read §1–§7, build the automation in §8. Builds on Linux networking
> (L17) and troubleshooting (L18). Python here doubles as cloud scripting (boto3) for the bridge.

---

## §1 — Concept (Scientific Theory)
> TODO — why automate (consistency, scale, drift detection); imperative SSH-scraping vs API/structured data; idempotence.
> Lens A (Beginner → NetOps → Wire): one-off script → reusable inventory-driven runbook → how SSH/transport + structured telemetry actually move.
> Lens B (technical + analogy + ASCII): script ↔ inventory ↔ devices ↔ parsed result.

## §2 — Linux Networking Commands / Tooling
> TODO — `python3 -m venv`, `pip install netmiko nornir paramiko`; `ssh`, `ncclient`; running from a Linux jump host; `requests`/`boto3` for cloud APIs.

## §3 — Real-World Use Cases
> TODO — bulk config push, compliance/drift audits, scheduled state collection feeding monitoring, ticket-driven changes, AWS VPC/route automation with boto3.

## §4 — Troubleshooting Section
> TODO — auth/timeouts, paramiko host-key issues, prompt/parse mismatches, partial failures across a device list, rate limits.
> (Includes a redaction check — no real device IPs/creds.)

## §5 — Common Mistakes
> TODO — no error handling on a fleet loop, hardcoded creds, no dry-run, scraping text instead of using structured output, no idempotence.

## §6 — NOC Perspective
> TODO — automation as force-multiplier on the NOC floor; guardrails (change windows, approvals, blast radius) before you let a script touch prod.

## §7 — Incident-Response Perspective
> TODO — automated evidence collection during an incident; fast "show me state across all devices"; rollback scripts.

## §8 — Practical Lab (build this yourself)
> TODO — Lens C (Manual → Automated → Why): SSH by hand to 3 devices → `netmiko`/`Nornir` inventory loop → why inventory-driven scales.
> Build: venv + inventory file; connect to mock/EVE-NG/lab devices; pull `show` output; parse; detect config drift; print a report. Optional Lens D: a `tcpdump`/pcap of the SSH/API session.

## §9 — GitHub Artifact (the evidence 5-tuple / Artifact Contract)
> TODO — script + inventory (redacted) + sample run output + a NET-NN ticket + an incident/drill note.

## §10 — Portfolio Artifact
> TODO — resume bullet + LinkedIn line + interview talking point ("automated config-drift detection across N devices in Python").

## §11 — RHCSA Crossover Notes
> TODO — venvs, cron-scheduling the collector, SSH keys, file permissions on the creds/inventory, systemd timer to run it.

## §12 — Security Notes (Lens E — Attacker & Defender)
- 🔴 TODO — `stolen automation credentials`, `over-privileged service account`, `supply-chain pip typosquat`, `MITRE ATT&CK T1119 automated collection`.
- 🔵 TODO — `secrets in vault/env not code`, `least-privilege device accounts`, `pin/verify pip deps`, `audit-log automation actions`, `read-only by default`.

---

## Quiz (Interview-Style, Graded)
> TODO — 5–8 questions (netmiko vs Nornir vs ncclient; why structured > scraped; how to keep creds out of code; idempotence; boto3 auth).

## Reflection
> TODO — what automating revealed about your manual workflow; next script to write.

## Search Keywords For Further Understanding
> TODO — `netmiko tutorial`, `nornir automation framework`, `python network automation`, `boto3 ec2 example`, `napalm getters`, `paramiko host keys`.

---

## Lesson Status
- [ ] §8 lab completed (inventory-driven script + drift report)
- [ ] §4 drill done
- [ ] Evidence committed (§9)
- [ ] Quiz answered + professional-answer comparisons (graded)
- [ ] Reflection + Search Keywords reviewed

---

*Lesson 37 scaffolded by Navi v28 · 2026-06-28 · stub — WebSearch sources to be gathered at authoring time (≥2 validating sources, e.g. netmiko/Nornir docs + a network-automation guide).*
