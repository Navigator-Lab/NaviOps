# Lesson 18 — Pure Practical: Network Troubleshooting

> **Companion to [`README.md`](./README.md).** Pure practice: 3 scenario tasks, guided → ticket-driven
> → on-call. **Lab:** the full topology (routers + hosts). **Rules:** work the OSI ladder bottom-up,
> diagnose before you fix, run ✅ **Verify** each task.

Each task: **Scenario · Objective · Given/constraints · Hints · ✅ Verify · Pitfalls · 🎯 Stretch.**

---

## Task 1 — Guided: the structured troubleshooting ladder (fluency)

**Scenario.** `NOC-181`. Build the muscle memory of a repeatable bottom-up method (L1→L7) you run on
every connectivity ticket.

**Objective.** Run the ladder on a *working* path and record the check + expected result at each layer.

**Given / constraints.** One command per layer; note pass criteria.

**Hints.**
1. L1/2: `ip link`, `ip neigh`. L3: `ping`, `ip route get`. L4: `nc -vz`. L7: `curl`/`dig`.
2. Each layer's pass gates the next.
3. Save it as a reusable checklist.

✅ **Verify.**
```bash
docker exec clab-h1 sh -c 'ip link show eth0 | grep -q UP && ping -c1 10.10.1.1 >/dev/null' && echo "LADDER PASSES ✅"
```

**Pitfalls.**
- Jumping to L7 first (top-down guessing).
- No documented method → inconsistent under pressure.
- Skipping L1/L2 assumptions.

🎯 **Stretch.** Turn the ladder into `scripts/net_diag.sh`-style output.

---

## Task 2 — Ticket-driven: unknown connectivity failure (diagnose → fix)

**Scenario.** `NOC-182` (P2). *"h1 can't reach a remote service."* Cause unknown. Run the ladder,
localize the break, fix it.

**Objective.** Find the failing layer with evidence and fix it — no random changes.

**Given / constraints.** A randomly-placed fault (pick one from LAB.md drills). Fix the specific layer.

**Hints.**
1. Bottom-up until a check fails — that's your layer.
2. Confirm with a second tool before changing.
3. Re-run the ladder after the fix.

✅ **Verify.**
```bash
docker exec clab-h1 ping -c3 10.10.2.10 | grep -q '0% packet loss' && echo "PATH RESTORED ✅"
```

**Pitfalls.**
- Fixing the symptom at the wrong layer.
- Not corroborating before acting.
- Declaring done without re-running the ladder.

🎯 **Stretch.** Time yourself; aim to localize within 5 minutes.

---

## Task 3 — On-call: intermittent, hard-to-reproduce fault (synthesis)

**Scenario.** `NOC-183` (P1, time-boxed). "Sometimes it fails." The hardest kind. Set up sustained
monitoring, capture the failure when it happens, and root-cause it.

**Objective.** Catch an intermittent fault with continuous probing + capture, identify the cause, and
write a note.

**Given / constraints.** Use `mtr`/looped ping + a rolling `tcpdump`. Evidence from an actual failure
event.

**Hints.**
1. Sustained `mtr -rw` + a ring-buffer capture (`tcpdump -C -W`) to catch the moment.
2. Correlate the failure timestamp with the capture/hop.
3. Root cause, not "it's flaky".

✅ **Verify.**
```bash
docker exec clab-h1 mtr -rwc20 10.10.2.10 | tail -3
test -f docs/learning/reports/NOC-183-intermittent.md && echo "REPORT ✅"
```

**Deliverable.** `docs/learning/reports/NOC-183-intermittent.md`: probe setup · captured event · root cause · fix.

**Pitfalls.**
- Spot checks that miss the intermittent event.
- No capture running when it fails → no evidence.
- Calling "flaky" a root cause.

🎯 **Stretch.** Script the probe to auto-save a capture window when loss is detected.

---

## Done?
- [ ] All ✅ Verify pass · [ ] localized by layer · [ ] intermittent-fault note written.
- [ ] **Guardrails:** lab only; no real `.pcap` committed. → [README Reflection](./README.md).
