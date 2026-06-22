# Lesson 09 — Threat Intelligence Fundamentals

**Status:** ✅ ready for self-study (full depth) · **Date written:** 2026-06-20
**Schema:** 12-section SOC (`docs/learning/CLAUDE_TEACHING_RULES.md`)
**Focus:** IOC vs IOA vs TTP, the **Pyramid of Pain**, intel types (strategic/operational/
tactical), feeds (MISP/OTX/abuse.ch), and **enrichment** — turning external knowledge into
detection + faster triage.
**Primary artifact:** `docs/detections/ioc-list.md` (a curated IOC list) + `scripts/ioc_sweep.sh` (tie-in).

> **How to use this lesson:** read §1–§7, do §8 (build an IOC list + enrich an alert), produce §9,
> quiz, reflect. Then Lesson 10.

---

## §1 — Concept (Scientific Theory)

### What it is
**Threat intelligence (TI)** is evidence-based knowledge about threats — who's attacking, with what
tools and techniques, and what indicators they leave — used to **detect**, **prioritize**, and
**enrich**. Key distinctions:
- **IOC (Indicator of Compromise):** an artifact that says an attack *happened* — an IP, domain,
  hash, file path, URL.
- **IOA (Indicator of Attack):** behavior that says an attack is *happening* — e.g. a process
  spawning a shell that connects out (more durable than an IOC).
- **TTP (Tactics, Techniques, Procedures):** *how* the adversary operates (ATT&CK) — the hardest
  thing for them to change.

### Why it exists
A SOC can't discover every threat first-hand. TI lets you benefit from what others have already
seen: block a known-bad IP before it hits you, recognize a malware hash instantly, and prioritize
the threats actually targeting your sector. It turns triage from "is this bad?" into "this IP is on
3 feeds as a brute-force source — TP, escalate."

### The Pyramid of Pain (the key model)
How much it *hurts the attacker* when you detect/block each indicator type:
```
            ▲  TTPs              ← hardest to change (changing how they operate = "tough!")
            │  Tools
            │  Network/Host artifacts
            │  Domain names
            │  IP addresses
            │  Hash values       ← trivial to change (recompile = new hash)  "trivial"
```
Detecting by **hash/IP** is easy but the attacker swaps them instantly; detecting by **TTP** is
hard to build but devastating — they'd have to change *how they work*. This is *why* the platform
pushes you toward behavioral detection (Lessons 21, 25, 26).

### Three-Level Depth (Lens A)
- **Level 1 — Beginner:** TI is a "wanted poster" list of known-bad things (IPs, hashes) plus
  knowledge of how criminals operate.
- **Level 2 — Analyst/SOC:** you **enrich** alerts with TI (look up the IP/hash/domain reputation),
  **match** logs against IOC feeds, and **prioritize** by what's targeting you. Feeds: MISP, AlienVault
  OTX, abuse.ch (URLhaus/ThreatFox), the CISA advisories.
- **Level 3 — Adversary/Kernel:** IOCs decay fast (the Pyramid); durable detection keys on TTPs +
  IOAs. TI is consumed as structured data (**STIX/TAXII**) and operationalized into SIEM watchlists
  and Sigma rules. Strategic intel informs *which* TTPs to cover (Lesson 10).

### Two Teaching Approaches (Lens B) — IOC vs TTP
**Approach 1 (technical):** IOCs are point-in-time atomic indicators (high precision, low
longevity); TTPs are behavioral patterns (lower precision per-event, high longevity). A mature SOC
uses IOCs for fast wins and TTPs for resilient coverage.

**Approach 2 (analogy):** catching a burglar by their **getaway car's plate** (IOC) works until
they steal a new car; catching them by their **method** — always entering through bathroom windows
at 2am (TTP) — works across cars. **Where it breaks down:** method-detection has more false
positives (lots of people open bathroom windows) — so you combine both.

---

## §2 — Linux Investigation Commands

```bash
# match logs against an IOC list (the core operationalization)
grep -F -f docs/detections/ioc-ips.txt /var/log/auth.log     # any known-bad IP in our logs?
# extract candidate IOCs from evidence
grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' /var/log/auth.log | sort -u   # all IPs seen
sha256sum /tmp/suspect.bin                                    # hash a suspect file (→ lookup)
# enrich (lab/approved only — these reach third parties; honor no-auto-send)
# whois <ip> ; dig -x <ip> ; (VirusTotal/OTX/ThreatFox lookups via their web UI/API w/ key)
```
| Linux | SIEM equivalent |
|---|---|
| `grep -f ioc-list` | Wazuh **CDB list** / watchlist match |
| hash lookup | SIEM threat-intel integration / VT enrichment |
| IP extraction | automated IOC extraction → watchlist |

> **No-auto-send (Hard Rule #6):** external lookups (VirusTotal, OTX) send your data to third
> parties — only with approval, and never submit sensitive samples/IPs from a real environment.

---

## §3 — Real-World Threat Context & Use Cases

- **Enrichment in triage:** the single biggest TI win — an IP/hash/domain reputation lookup turns a
  maybe into a decision in seconds.
- **Proactive blocking:** import a feed of known-bad IPs/domains into the firewall/SIEM watchlist.
- **Sector targeting:** strategic intel ("ransomware group X is hitting healthcare") tells you which
  TTPs to prioritize.
- **IOC decay:** a stale IOC list is noise; TI must be fresh and scoped (Pyramid of Pain).
- **Exam framing:** IOC/IOA/TTP, the Pyramid of Pain, intel types, and STIX/TAXII appear on
  CySA+/Security+/BTL1.

---

## §4 — Detection

- **IOC matching** = watchlist detection: maintain `docs/detections/ioc-list.md` (IP/domain/hash +
  source + confidence + Pyramid tier), match logs/flows against it (Wazuh CDB list).
- **Decay management:** every IOC has a source + date; expire stale ones (avoid false positives).
- **Climb the Pyramid:** prefer TTP/IOA detections (Lessons 21, 25) for durable coverage; use IOCs
  for cheap, high-precision wins.
- **Enrichment-as-detection:** an alert auto-enriched with "this IP is known-bad, confidence high"
  is effectively a higher-fidelity detection.

---

## §5 — Investigation & Triage

TI is the **enrichment** step of triage (`soc/alert-triage.md`): given an alert's indicators, look
them up (reputation, prior sightings, associated campaign) to decide TP/FP and severity. Record the
source + confidence in the case (facts vs assessment — "OTX lists this IP, confidence 80%" is a
fact; "likely the same actor" is assessment).

---

## §6 — SOC Perspective

A SOC runs a TI function (even if it's one analyst + free feeds): curate watchlists, enrich alerts,
and brief the team on active threats. TI feeds the priorities and the daily "what's targeting us"
picture. Maturity shows in *climbing the Pyramid* — moving detections from hash/IP toward TTP.

---

## §7 — Incident-Response Perspective

In IR, you **extract** IOCs (Phase 2) from the incident and **contribute** them back (to the
watchlist, and the team's TI) so the next occurrence is caught instantly (Phase 6). The IOCs you
extract are the pivot points for scoping (`ioc_sweep.sh` across hosts).

---

## §8 — Practical Lab (build this yourself)

**Goal:** build a curated IOC list and use it to enrich + sweep.

### Lens C — Manual → Automated → Why
- **Manual:** look up one suspect IP/hash by hand.
- **Automated:** `scripts/ioc_sweep.sh` greps a host's logs (and lists hosts) against your IOC file
  — one command to answer "is any known-bad indicator present here?"
- **Why:** during an incident you sweep *fast*; production auto-matches every event against
  watchlists in the SIEM.

### Steps
1. Build `docs/detections/ioc-list.md`: a small table of (indicator, type, source, confidence,
   Pyramid tier, date). Use safe public examples (e.g. abuse.ch ThreatFox samples) or your own lab
   "attacker" IP from earlier drills.
2. Create `scripts/ioc_sweep.sh`: `grep -F -f <ioc-ips> <logs>` + extract-seen-IPs; print any match.
   `bash -n` + `shellcheck` clean.
3. Take an earlier drill's "attacker IP", add it to the list, and run `ioc_sweep.sh` — confirm it
   flags the matching log lines.
4. Practice enrichment (approved/lab): document how you'd look up an IP's reputation and what you'd
   record (source + confidence), honoring the no-auto-send rule.
5. Note which of your indicators are low on the Pyramid (and thus decay fast).

### Lens D — the raw artifact
```
$ grep -F -f docs/detections/ioc-ips.txt /var/log/auth.log
Jun 20 02:14 web01 sshd: Accepted password for svc_app from 203.0.113.50  ← IOC hit = high-priority
# A single grep turns "240 failed logins" into "and the source is a KNOWN brute-force IP" → TP.
```

---

## §9 — GitHub Artifact (the 6-artifact evidence package)

1. **Script:** `scripts/ioc_sweep.sh` (committed, `shellcheck`-clean).
2. **Detection rule/config:** `docs/detections/ioc-list.md` (the watchlist) + a Wazuh CDB-list note.
3. **Runbook:** `docs/runbooks/runbook-ioc-match.md` — "when an IOC matches, do X."
4. **Playbook:** `docs/playbooks/enrichment-play.md` (lookup → record source/confidence → decide).
5. **Incident report + notes:** an alert enriched with TI (IOC match flipped it to TP) + notes.
6. **SOC ticket:** `SOC-09` (Task: "IOC list + sweep + enrichment") → Closed.

---

## §10 — Portfolio Artifact

- **Resume bullet:** "Curated a threat-intel IOC watchlist (typed, sourced, Pyramid-of-Pain ranked)
  and built an IOC-sweep tool to enrich alerts and scope incidents across hosts."
- **Interview talking point:** explain the Pyramid of Pain and *why* TTP detection beats IOC
  detection — a clear seniority signal.
- **Serves:** SOC T1 → Detection Engineer (Stages 2–4).

---

## §11 — Certification Crossover Notes

- **Security+:** threat intel (2.x). **CySA+:** threat intelligence (major domain). **SC-200:**
  threat intelligence in Defender/Sentinel. **BTL1:** threat intel. Detail:
  `alignment/CERTIFICATION-MAPPING.md`.

---

## §12 — Security Notes (Lens E — Attacker & Defender)

**🔴 Attacker:** rotate IOCs constantly (new IPs/domains/hashes) to evade indicator-based detection
— exactly why they sit at the bottom of the Pyramid. Sophisticated actors reuse infra sparingly.

**🔵 Defender:** consume fresh TI, match watchlists, but **climb the Pyramid** toward TTP/IOA
detection that survives IOC rotation. Contribute your own IOCs back. Pair TI enrichment with
behavioral detection for both speed and durability.

---

## Quiz (Interview-Style, Graded)

**Q1.** Distinguish IOC, IOA, and TTP with an example of each for an SSH brute-force intrusion.
> **Your answer:**

**Q2.** Explain the Pyramid of Pain. Why is detecting by hash "trivial" for the attacker to defeat,
and detecting by TTP "tough"?
> **Your answer:**

**Q3.** How do you use threat intel during alert triage, and what do you record in the case?
> **Your answer:**

**Q4.** **Scenario:** an alert shows a login from an IP your feed lists as a known brute-force
source (confidence 90%). How does that change your triage, and what's the caveat about IOC age?
> **Your answer:**

**Q5.** What's the risk of an external reputation lookup, and how do you handle it responsibly?
> **Your answer:**

*(Request the "Professional Answer" comparison under each before moving on.)*

---

## Reflection
*(After the quiz)* — What did you learn? · What confused you? · What would you do differently?

---

## Search Keywords For Further Understanding

**Core**
- `ioc ioa ttp difference`
- `pyramid of pain threat intelligence`
- `threat intelligence types strategic operational tactical`
- `stix taxii misp otx feeds`
- `ioc enrichment alert triage`

**Tools**
- `wazuh cdb list ioc matching`
- `abuse.ch threatfox urlhaus`

**Going further**
- `mitre att&ck` (L10) · `indicators of compromise` (L12) · `threat hunting` (L25)

**Red / Blue (Lens E):**
- 🔴 `ioc rotation evasion`, `infrastructure churn`
- 🔵 `threat intel watchlist`, `climb pyramid of pain ttp detection`, `ioc decay management`

---

## Lesson Status
- [ ] §8 lab completed (IOC list + sweep + enrichment)
- [ ] 6-artifact evidence package committed (§9)
- [ ] Quiz answered + professional-answer comparisons (graded)
- [ ] Reflection + Search Keywords reviewed

When complete, run the Update Protocol, then move to **Lesson 10 — MITRE ATT&CK Framework**.

---

*Lesson 09 written by Navi · 2026-06-20 · full-depth. Sources to cite at study time: David
Bianco's Pyramid of Pain, MITRE ATT&CK, MISP/OTX/abuse.ch docs, CySA+ threat-intel domain.*
