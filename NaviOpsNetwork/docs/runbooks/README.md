# docs/runbooks/ — incident reports & operational runbooks

One report per troubleshooting drill / NOC scenario / real incident. This is the highest-value
portfolio evidence (the #1 NOC skill: documenting an incident end-to-end).

## Standard incident-report format

```markdown
# Incident <NN> — <short title>
- Severity: Sev<N>   Status: Resolved   Ticket: NAVI-<NN>   Commit: <sha>
- Detected: <time/alert>   Resolved: <time>   Duration / MTTR: <mins>

## Symptom
<what was observed / which alert fired / scope + impact>

## Diagnosis (bottom-up)
<commands run + redacted output; the layer where it failed>

## Root cause (RCA)
<the WHY, not the symptom — 5 Whys / fault-domain isolation, see noc/rca.md>

## Fix
<exact change that restored service>

## Verification
<commands proving service restored>

## Prevention
<action item + owner so it can't recur; detection gap to close>
```

## Planned reports (one per drill, `troubleshooting-drills.md`)
- `incident-dns-outage.md` (L13) · `incident-dhcp-failure.md` (L12) ·
  `incident-high-latency.md` (L18) · `incident-packet-loss.md` (L18) ·
  `incident-iface-down.md` (L01/L17) · `incident-routing.md` (L07) ·
  `incident-vlan-misconfig.md` (L09) · `incident-firewall-block.md` (L15)
- `troubleshooting-method.md` (L18) · `incident-template.md` (L26) ·
  capstone reports (L34–36).

**Redaction check on every report** — lab/RFC-1918 ranges + sanitized output only.
