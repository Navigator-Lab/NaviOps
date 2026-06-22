# Report & Evidence Templates

The reusable document templates every lesson's §9 and the IR workflow draw on. Copy a template
into `docs/runbooks/` (per incident) and fill it in — sanitized. These are what a real SOC/IR
team uses, scaled to a portfolio.

| Template | Use |
|---|---|
| [incident-report.md](incident-report.md) | the full technical incident write-up (the headline portfolio artifact) |
| [investigation-notes.md](investigation-notes.md) | working notes during an investigation (facts vs assessment) |
| [executive-summary.md](executive-summary.md) | the non-technical leadership summary |
| [rca.md](rca.md) | root-cause analysis (the "why it happened") |
| [evidence-package.md](evidence-package.md) | the collected-evidence index (chain of custody) |
| [lessons-learned.md](lessons-learned.md) | post-incident review + the new detection to add |

**Redaction:** every template is filled with lab/sanitized values only — see the redaction
convention in `docs/learning/LEARNING_STATE.md`. Real IPs/hostnames/creds/PII never get committed.
