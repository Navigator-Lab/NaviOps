# Lesson 36 — Network-Security Capstone

**Status:** ✅ ready for self-study (full depth) · **Date written:** 2026-06-20
**Schema:** 12-section (`docs/learning/CLAUDE_TEACHING_RULES.md`)
**Focus:** detect + respond to recon/brute-force/exfil with IDS + SIEM, full IR write-up — the
Security-Analyst (networking) capstone.
**Primary artifact:** the attack runbook + detection evidence + IR report (full plan:
[`capstones/36-network-security-capstone.md`](../../capstones/36-network-security-capstone.md)).
**Difficulty:** **full red/blue** — you play both attacker and defender (lab-only, self-owned).

> **How to use this lesson:** the security-track destination — you generate (lab) attack telemetry
> and detect + respond to it. The detailed plan is in
> `docs/learning/capstones/36-network-security-capstone.md`. Prereqs: Lessons 15, 19–20, 28 + the
> Lens E thread. **All activity against self-owned lab targets only** (`navi.project.md` danger
> zone; authorization context: educational, your own lab).

---

## §1 — Concept (Scientific Theory)

The Network-Security Capstone integrates the **Lens E thread** of the entire curriculum into one
end-to-end exercise: you stage a benign, lab-only intrusion chain (recon → brute force → C2-ish
beacon → exfil simulation), then **detect** each stage with an IDS (Suricata) + SIEM (Wazuh) +
detection scripts, **triage** the alerts (TP/FP + severity + MITRE ATT&CK), and **respond** via the
IR lifecycle (detect → contain → eradicate → recover → report, Lesson 26). It proves the SOC /
Security-Analyst (networking track) skill set — the security destination of the platform.

Playing **both sides** makes Lens E real: you finally *see*, from the attacker's keyboard, exactly
what the defenses you've built in every lesson are catching.

---

## §2 — Linux Networking Commands (red + blue)
```bash
# RED (lab-only, self-owned targets) — generate the telemetry
nmap -sS -p- 10.0.0.0/24            # recon scan (T1046)
hydra/ncrack ... ssh://<lab-host>   # brute force a deliberately weak lab cred (T1110)
# (benign) periodic outbound to a lab "C2" + a marked dummy-file exfil (T1071/T1041)
# BLUE — detect + respond
suricata -i eth0 -c .../suricata.yaml ; tail -f /var/log/suricata/fast.log
port_scan_detect.sh <if> ; grep "Failed password" /var/log/auth.log | awk ... | sort | uniq -c
# Wazuh dashboard / /var/ossec/logs/alerts/ ; correlate
nft add rule inet filter input ip saddr <attacker> drop   # CONTAIN (L15)
capture_triage.sh <if> "<bpf>"     # preserve evidence (L20)
```

---

## §3 — Real-World Use Cases
This is the SOC Tier-1 reality: an alert fires, you triage (TP/FP, severity, ATT&CK), and respond.
Producing the attack→detection→triage→IR artifacts is exactly what a Security-Analyst (networking)
interview wants to see — and the strongest differentiator built by the Lens E thread.

---

## §4 — Troubleshooting / Triage Section
Each detection is triaged with the discipline from Lesson 28: alert → true/false positive →
severity → scope → MITRE ATT&CK ID → action (escalate/contain or close+tune). False positives are
*tuned* (the core SOC skill), not ignored. The triage table is the deliverable.

---

## §5 — Common Mistakes
The security-capstone failures: scanning/attacking something you don't own (never — lab only);
detection with no response plan; not preserving evidence before containment; no ATT&CK mapping;
chasing the alert without confirming TP/FP; missing the egress/exfil stage (watch outbound, Lessons
15/16). The capstone rubric (plan) checks each.

---

## §6 — NOC Perspective
This is the **NOC→SOC bridge** made concrete (the NOSC role, `ROADMAP.md`). The detection scripts
are NOC-runnable; the SIEM is the security analog of the monitoring stack (Lessons 22–23); the
triage discipline is the same alert-handling loop (`noc/alert-handling.md`) with a security lens.
A NOC that can do this is a strong SOC candidate.

---

## §7 — Incident-Response Perspective
This lesson is **applied IR** (Lesson 26) for a security incident: detect (IDS/SIEM/script) →
triage (TP/FP + ATT&CK) → **contain** (block the source, isolate the host, Lesson 15) → **preserve
evidence** (off-box logs L25, captures L20) → **eradicate → recover → report** (mapped to ATT&CK).
The full-lifecycle IR report is the centerpiece artifact.

---

## §8 — Practical Lab (the capstone itself)
Follow [`capstones/36-network-security-capstone.md`](../../capstones/36-network-security-capstone.md):
stand up Suricata + Wazuh + your detection scripts; stage the 4-stage benign attack chain against
self-owned lab targets; detect, triage, and run IR end-to-end for each stage; document everything
mapped to MITRE ATT&CK.

**Lens C (automation):** your detection scripts (`port_scan_detect.sh`, failed-login counter) +
Suricata/Wazuh rules = automated detection; a containment one-liner (nftables block) = automated
response. **Lens D:** every detection reduces to earlier primitives (scan=TCP flags L03, brute
force=auth logs L25, C2/exfil=flow/egress L15/16) — detection is applied networking.

---

## §9 — GitHub Artifact (evidence 5-tuple)
1. **Script:** `scripts/port_scan_detect.sh` + a brute-force/failed-login detector (shellcheck-clean).
2. **Config:** Suricata rules + Wazuh rules (lab) in `infra/configs/`.
3. **Drill:** the full staged attack detected + contained (sanitized indicators).
4. **NAVI ticket:** `NAVI-36` master Incident referencing the staged-attack tickets.
5. **Incident reports:** `sec-capstone-attack.md` + `sec-capstone-detection.md` + a full-lifecycle
   IR report (RCA + containment proof + recovery), all sanitized. Plus the milestone **`PORTFOLIO.md`**.

---

## §10 — Portfolio Artifact
- **Resume bullet:** "Built and detected a staged network intrusion (recon→brute-force→C2→exfil) in
  a lab: deployed Suricata IDS + Wazuh SIEM, wrote detection scripts, triaged alerts mapped to MITRE
  ATT&CK, and ran the incident-response lifecycle (contain→eradicate→recover→report) end-to-end."
- **Interview talking point:** the attacker→defender story for each ATT&CK stage and the IR
  lifecycle — the strongest SOC / Security-Analyst (networking) portfolio piece, and the payoff of
  the whole Lens E thread.
- **Serves:** SOC Analyst / Security Analyst (networking, Stage 5); the security destination.

---

## §11 — RHCSA Crossover Notes
Host-side controls overlap with RHCSA hardening: SSH hardening, **firewalld** (containment), fail2ban,
and **auditd**/log review on RHEL. The sibling NaviOps platform covers Linux hardening + Wazuh in
depth; this capstone is the network-detection + IR lens on the same skills.

---

## §12 — Security Notes (Lens E — Attacker & Defender) — the whole lesson
This lesson *is* Lens E, fully realized. **🔴 Red:** the early kill chain — recon `T1046`, brute
force `T1110`, C2 `T1071`/`T1571`, exfil `T1041`/`T1048` — plus evasion (low-and-slow, encrypted
C2, disabling logging `T1562`). **🔵 Blue:** detect each stage (IDS/SIEM/scripts), tune to beat both
false positives and low-and-slow, correlate, map to ATT&CK, and respond via IR with evidence
preservation and containment. **Authorization is mandatory:** lab/self-owned targets only, benign
payloads (no real malware), sanitized artifacts — this is the ethical, legal way to build the skill.

---

## Quiz (Interview-Style — defend your investigation)
**Q1.** For each attack stage, what detection caught it and what's the ATT&CK technique?
> **Your answer:**

**Q2.** Walk through your IR response to the confirmed intrusion (detect→contain→eradicate→recover→report).
> **Your answer:**

**Q3.** How did you distinguish a true positive from a false positive, and how did you tune a noisy rule?
> **Your answer:**

**Q4.** **Scenario:** Your SIEM shows a host beaconing to one external IP every 60s. Triage it: what
do you suspect, what's the technique, and what do you do?
> **Your answer:**

**Q5.** Why is evidence preservation before containment essential, and what attacker technique
threatens it?
> **Your answer:**

*(Request the "Professional Answer" comparison under each — graded to close the curriculum.)*

---

## Reflection
*(After completion)* — What surprised you playing attacker? · Which detection was hardest? · What
detection/prevention would you add?

---

## Search Keywords For Further Understanding
- `network intrusion detection suricata`
- `wazuh siem incident response`
- `mitre attack kill chain mapping`
- `port scan brute force exfil detection`
- 🔴 `recon T1046, brute force T1110, c2 T1071, exfil T1041 T1048, evasion T1562`
- 🔵 `suricata wazuh detection rules, alert triage tuning, incident response containment`

---

## Lesson Status
- [ ] Staged attack chain built + each stage detected (lab-only)
- [ ] Triage table (TP/FP + severity + ATT&CK) complete
- [ ] Full IR report (contain→eradicate→recover→report) committed (§9, sanitized)
- [ ] `PORTFOLIO.md` written (§10)
- [ ] Quiz (investigation defense) answered + professional-answer comparisons + reflection

**This is the final lesson.** When complete, run the Update Protocol and produce the **final
Portfolio Summary** rolling up all milestones — the platform is complete; you're ready to apply
(`JOB_MILESTONES.md`).

---

*Lesson 36 written by Navi · 2026-06-20 · full-depth. Detailed plan:
[`capstones/36-network-security-capstone.md`](../../capstones/36-network-security-capstone.md).
Sources: MITRE ATT&CK, Suricata & Wazuh docs, NIST SP 800-61.*
