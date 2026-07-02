# Lesson 12 — Pure Practical: Indicators of Compromise (IoCs)

> **Companion to [`README.md`](./README.md).** Pure practice: 3 scenario tasks, guided → ticket-driven
> → on-call. **Lab:** `siem-victim` + Wazuh. **Rules:** evidence before verdict, run ✅ **Verify** each.

Each task: **Scenario · Objective · Given/constraints · Hints · ✅ Verify · Pitfalls · 🎯 Stretch.**

---

## Task 1 — Guided: extract IoCs from an event (fluency)

**Scenario.** `SOC-121`. Pull the atomic + behavioral indicators from a lab compromise so they can be
hunted/shared.

**Objective.** A structured IoC set (IPs, hashes, filenames, user, process) from one event.

**Given / constraints.** Use a lab event (rogue process/file). Classify each IoC type.

**Hints.**
1. Atomic: IP, hash (`sha256sum`), filename, port. Computed/behavioral: process tree, persistence.
2. `find -newer`, `ps`, `ss`, hashing.
3. Record type + value + where seen.

✅ **Verify.**
```bash
test -f docs/learning/reports/SOC-121-iocs.md && grep -qiE 'hash|ip|process' docs/learning/reports/SOC-121-iocs.md && echo "IOCS EXTRACTED ✅"
```

**Pitfalls.**
- Only atomic IoCs (behavioral ones are more durable).
- No context (where/when seen).
- IoCs that are too generic (a common IP/port) → false positives.

🎯 **Stretch.** Rank IoCs by fidelity (a hash beats a shared IP).

---

## Task 2 — Ticket-driven: hunt an IoC across the estate (diagnose)

**Scenario.** `SOC-122` (P2). *"Is this IoC present anywhere else?"* Sweep for it and report scope.

**Objective.** Confirm presence/absence of an IoC across available sources, with evidence.

**Given / constraints.** Use the IoC from T1. Search logs + host. Evidence for the verdict.

**Hints.**
1. Search central logs + the host (hash/filename/IP).
2. Present → scope it; absent → show what you searched.
3. Report + recommended detection.

✅ **Verify.**
```bash
test -f docs/learning/reports/SOC-122-ioc-hunt.md && grep -qiE 'found|not found' docs/learning/reports/SOC-122-ioc-hunt.md && echo "HUNT ✅"
```

**Deliverable.** `docs/learning/reports/SOC-122-ioc-hunt.md`: IoC · sources searched · findings · detection.

**Pitfalls.**
- "Not found" without listing what/where you searched.
- Hunting only atomic IoCs (miss the behavior).
- Low-fidelity IoC → false-positive storm.

🎯 **Stretch.** Convert the IoC into a Wazuh/Sigma detection so it auto-flags next time.

---

## Task 3 — On-call: produce an IoC package for the incident (synthesis)

**Scenario.** `SOC-123` (P1, time-boxed). Wrap up an incident with a shareable IoC package + detections,
respecting TLP.

**Objective.** A complete, TLP-marked IoC package (atomic + behavioral) with fidelity + detections.

**Given / constraints.** Sanitized/lab IoCs only. TLP marked. Include detections.

**Hints.**
1. Collate all IoCs from the incident; dedup; assign fidelity.
2. TLP marking + handling note.
3. Include the detection rules that catch them.

✅ **Verify.**
```bash
grep -qiE 'tlp' docs/learning/reports/SOC-123-ioc-package.md && echo "TLP-MARKED PACKAGE ✅"
```

**Deliverable.** `docs/learning/reports/SOC-123-ioc-package.md`: IoCs (type/fidelity) · TLP · detections · sharing guidance.

**Pitfalls.**
- Sharing IoCs without TLP (mishandling).
- Committing real/sensitive IoCs (guardrail).
- Package with no detections (not actionable).

🎯 **Stretch.** Export in a machine-readable format (CSV/STIX-like) for a feed.

---

## Done?
- [ ] All ✅ Verify pass · [ ] behavioral + atomic IoCs · [ ] TLP-marked package with detections.
- [ ] **Guardrails:** sanitized IoCs only; TLP respected. → [README Reflection](./README.md).
