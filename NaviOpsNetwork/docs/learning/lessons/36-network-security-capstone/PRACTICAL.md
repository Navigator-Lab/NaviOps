# Lesson 36 — Pure Practical: Network Security Capstone

> **Companion to [`README.md`](./README.md).** Already hands-on; this adds 3 end-to-end secure-network
> drills combining segmentation, firewalls, VPN, and detection. **Lab:** full topology + firewalls.
> **Rules:** type it, diagnose before you fix, run ✅ **Verify** each task.

Each task: **Scenario · Objective · Given/constraints · Hints · ✅ Verify · Pitfalls · 🎯 Stretch.**

---

## Task 1 — Guided: build a defense-in-depth network (fluency)

**Scenario.** `NOC-361`. Deliver a segmented network: zones, default-deny between them, an encrypted
tunnel for admin, and logging.

**Objective.** Zones enforced (only intended flows), a WireGuard admin path, and denied-flow logging.

**Given / constraints.** Default-deny inter-zone; VPN for admin; log drops.

**Hints.**
1. Firewall zones + established/allowed flows (L28/L15).
2. WireGuard for the admin path (L29).
3. Log denied packets for later review.

✅ **Verify.**
```bash
docker exec clab-h1 nc -vz 10.10.2.10 <allowed> 2>&1 | grep -qi succeeded && \
docker exec clab-h1 nc -vz 10.10.2.10 <denied> 2>&1 | grep -qiE 'refused|timed out' && echo "SEGMENTATION ✅"
```

**Pitfalls.**
- Allow-all defaults.
- Admin over cleartext instead of the tunnel.
- No logging on denies.

🎯 **Stretch.** Add egress filtering + a jump-host pattern.

---

## Task 2 — Ticket-driven: security control gap (diagnose → fix)

**Scenario.** `NOC-362` (P2). An audit finds a gap (a leaking flow, cleartext admin, or an exposed
service). Diagnose and close it without breaking legitimate access.

**Objective.** Close the specific gap, keep legit flows, verify — diagnose first.

**Given / constraints.** Recreate one gap. Fix minimally.

**Hints.**
1. Identify the gap (capture the leak / find the exposed port).
2. Tighten the control; keep admin/legit access.
3. Verify closed + legit intact.

✅ **Verify.**
```bash
docker exec clab-h1 nc -vz 10.10.2.10 <gap-port> 2>&1 | grep -qiE 'refused|timed out' && echo "GAP CLOSED ✅"
```

**Pitfalls.**
- Closing the gap and breaking admin access.
- No verification of both sides.
- Fixing symptom, not the control.

🎯 **Stretch.** Add a detection so the gap-attempt alerts next time.

---

## Task 3 — On-call: active intrusion scenario (synthesis)

**Scenario.** `NOC-363` (P1, time-boxed). Recon → exploitation attempt across zones. Detect, contain,
scope, and write an IR report with IoCs and control improvements.

**Objective.** Detect the activity, contain the source, scope impact, and document with MITRE-style
mapping + control fixes.

**Given / constraints.** Simulate scan + a lateral attempt. Preserve evidence; contain by rule.

**Hints.**
1. Detect the recon (L28) + the lateral attempt (cross-zone flow).
2. Contain (scoped block), capture IoCs, scope which zones touched.
3. Report + control improvements (segmentation/logging/detection).

✅ **Verify.**
```bash
test -f docs/learning/reports/NOC-363-intrusion.md && grep -qi 'ioc\|containment' docs/learning/reports/NOC-363-intrusion.md && echo "IR REPORT ✅"
```

**Deliverable.** `docs/learning/reports/NOC-363-intrusion.md`: timeline · IoCs · containment · scope · control improvements.

**Pitfalls.**
- Containing loudly and tipping the attacker before scoping.
- No evidence captured.
- No control improvement → recurs.

🎯 **Stretch.** Turn each detection gap into a monitoring rule.

---

## Done?
- [ ] All ✅ Verify pass · [ ] segmentation enforced · [ ] IR report with IoCs + control fixes.
- [ ] **Guardrails:** lab only; fake IoCs; no VPN keys committed. → [README Reflection](./README.md).
