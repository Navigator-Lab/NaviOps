---
name: ADR-P14-Adaptive-Improvement
status: Accepted
date: 2026-02-18
version: 18.0
description: Self-Correction & Pattern Recognition. Updates protocols when recurring failures expose gaps.
supersedes: ADR-P14 v17
---

# ADR-P14: Adaptive Improvement Protocol

<contract>
  <purpose>Learn from recurring failures/mis-routes and improve Navi's own protocols + memory.</purpose>
  <trigger>"this keeps happening", "update the agent", repeated mis-routes, post-mortems</trigger>
  <reads>ADR-P00 · the workflow (navi.md) · memory MEMORY.md</reads>
  <output>Protocol/memory updates (surgical) + a note of what changed and why</output>
</contract>

## Context

Updates the "Brain" (protocols + CLAUDE.md) when patterns of failure emerge. Prevents the same mistake from happening twice. Receives input from P10 (Debugger Discovery Bridge), P03 (VERIFY Discovery Bridge), and direct user feedback.

**Triggered by**: Navi.md Intent Routing — signals: "Pattern failed", "Keep making the same error", "Improve protocol", "Update agent", OR automatically by P10/P03 Discovery Bridge flags.

---

## Protocol Rules (Immutable)

### Step 0: Constitutional Anchor

```bash
view_file .agent/protocols/ADR-P00-Master-Rule.md
view_file CLAUDE.md
```

Output: "🔒 Adaptive Improvement Protocol v18 Loaded."

---

## FULL ADAPTIVE IMPROVEMENT ALGORITHM

### Phase 1: Pattern Identification

**Input sources** (check all before proceeding):

```bash
# Check recent discovery bridges from debugging sessions
ls -la docs/reports/DEBUG/              # Recent debug reports
ls -la docs/reports/VERIFY/             # Recent verification reports

# Read flagged discoveries
grep -rn "Pattern Updates\|ADR-P14" docs/reports/ --include="*.md" -l
```

**Pattern Classification**:

```markdown
## Pattern Identification

**Source**: [P10 Discovery / P03 Discovery / User Report / SP Retrospective]
**Pattern Type**:

- [ ] Recurring Bug (same error appears >2 times)
- [ ] Protocol Gap (protocol doesn't cover a real scenario)
- [ ] Anti-Pattern (agent keeps doing something wrong)
- [ ] Missing Check (something should be verified but isn't)
- [ ] Routing Error (Navi.md routed incorrectly)
- [ ] Hallucination (agent assumed something without checking)

**Description**: [Clear statement — "We keep doing X when we should do Y"]
**Frequency**: [How many times has this occurred]
**Impact**: [What broke because of this pattern]
**Evidence**:

- [Link or description of incident 1]
- [Link or description of incident 2]
```

---

### Phase 2: Root Cause of the Protocol Gap

Apply the same Hypothesis Engine from P10 to the protocol itself:

```markdown
## Protocol Gap Analysis

**Hypothesis A**: The protocol doesn't mention this scenario at all
**Evidence**: [Search protocol for the gap]
**Test**: `grep "[keyword]" .agent/protocols/ADR-PXX.md` → returns nothing

**Hypothesis B**: The protocol mentions it but doesn't enforce it clearly enough
**Evidence**: [The relevant section exists but is ambiguous]
**Test**: Read the section — would a new agent following it make the same mistake?

**Root Cause**: [A or B — with explanation]
```

---

### Phase 3: Protocol Update

**Read the target protocol first — never edit from memory**:

```bash
view_file .agent/protocols/ADR-P[XX]-[Name].md
```

**Determine update type**:

| Change Type            | Action                                             |
| ---------------------- | -------------------------------------------------- |
| New check needed       | Add a step or sub-step to the relevant phase       |
| Ambiguous instruction  | Rewrite the section to be explicit                 |
| Missing example        | Add a code example (Pseudo + Programmatic if code) |
| New routing scenario   | Update Navi.md Intent Matrix                       |
| Wrong default behavior | Add explicit rule with ✅/❌ examples              |

**Update Format**:

```markdown
### Proposed Update to ADR-P[XX]: [Protocol Name]

**Section**: [Exact section/step to update]
**Current Text**: [What it says now]
**Problem**: [Why this text allows the bad pattern]
**Proposed Text**: [New version]
**Why Better**: [How this prevents the pattern]

**Impact on Other Protocols**:
| Protocol | Does This Change Affect It? | Action Needed |
|---|---|---|
| P01 (SP) | [Yes/No] | [Update if yes] |
| P03 (VERIFY) | [Yes/No] | [Update if yes] |
```

---

### Phase 4: Verify the Fix

Before closing, confirm the new instruction actually prevents the bad pattern:

```markdown
## Verification of Protocol Update

**Test Case**: Simulate the scenario that caused the original failure
**With OLD protocol**: [Would agent still fail? Yes]
**With NEW protocol**: [Does new text prevent the failure? Yes/No]

**Edge Cases**:

- Does the new rule create any false positives? [Yes/No — explain]
- Does it conflict with any other rule? [Yes/No — check ADR-P00 axioms]

**Sign-off**: [Protocol update is safe to apply]
```

---

### Phase 5: CLAUDE.md & docs/ Update

After any protocol update, document the learning:

```bash
# Update CLAUDE.md with the pattern and fix
# Update docs/ if this is an architectural decision
```

**CLAUDE.md entry format**:

```markdown
## Agent Learning Log

### [Date] — Pattern: [Short name]

**What Failed**: [Description]
**Root Cause**: [Protocol gap or anti-pattern]
**Fix Applied**: [ADR-PXX updated — what changed]
**Prevention**: [What the new protocol does to prevent recurrence]
```

---

## Improvement Backlog Format

Track all pending improvements:

```markdown
## 📋 Improvement Backlog

| #   | Pattern                              | Source     | Protocol to Update | Priority    | Status  |
| --- | ------------------------------------ | ---------- | ------------------ | ----------- | ------- |
| 1   | Agent reads code from memory         | P10 Debug  | P04 Code Audit     | 🔴 Critical | Done    |
| 2   | Missing pagination on list endpoints | P03 VERIFY | P07 Quality        | 🟡 High     | Pending |
| 3   | No replay protection on webhooks     | P12 Review | P12 Reverse Edge   | 🔴 Critical | Pending |
```

---

## How P14 Supports Other Protocols

| Protocol           | P14 Support Role                                          |
| ------------------ | --------------------------------------------------------- |
| **P10 (Debugger)** | Discovery Bridge → feeds Phase 1 with debug patterns      |
| **P03 (VERIFY)**   | Discovery Bridge → feeds Phase 1 with verification gaps   |
| **Navi.md**        | Routing errors → Phase 3 updates Intent Matrix            |
| **All Protocols**  | Phase 3 updates → improvements to any protocol            |
| **CLAUDE.md**      | Phase 5 → agent learning log keeps memory of improvements |

---

## 6-Lens View of Adaptive Improvement

#### 👶 Junior

This protocol is like a developer writing in their notebook "I keep forgetting to check X before deploying." It makes that check automatic for next time.

#### 🎓 Senior

Implements a feedback loop between runtime failures and protocol definitions. Prevents regression of agent behavior. The Discovery Bridge pattern ensures learning is captured systematically, not ad-hoc.

#### 🏗️ Architect

Creates a self-improving system. Over time, the protocol library becomes more comprehensive and less ambiguous. CLAUDE.md acts as the institutional memory. The Improvement Backlog provides visibility into technical debt in the agent layer.

#### 🎯 Pattern

Implements the **Retrospective + Kaizen** pattern from software engineering. Each failure is an improvement opportunity, not just a bug to fix.

#### ⚖️ Trade-off

Cost: Protocol updates require reading, analysis, and careful editing — takes time. Benefit: Prevents the same mistake from occurring again. Net: Always worth it for patterns that repeat.

#### ⚠️ Risk

Risk of over-constraining protocols — if every edge case becomes a rule, protocols become rigid and unreadable. Mitigation: Only update for patterns that have occurred 2+ times or have critical impact.

📚 **Reference**: Kaizen continuous improvement methodology — https://www.lean.org/explore-lean/what-is-kaizen/

---

## Changelog

- **v18.0**: 5-phase algorithm formalized. Improvement Backlog format added. 6-Lens view added. How-Protocols-Support section added. CLAUDE.md update step added.
- **v17.0**: Initial ADR format. 3-step algorithm.