# `docs/detections/` — the detection library

The version-controlled home for detection content: Wazuh rules, **Sigma** rules, IOC lists, and
the ATT&CK coverage map. This is "detection-as-code" — every detection lesson and project adds
here, so the library *is* the portfolio's detection-engineering evidence.

| Path | Built in | What it is |
|---|---|---|
| `sigma/` | Lesson 27, 32–33 | portable Sigma detection rules (+ their Wazuh/Elastic conversions) |
| `attack-coverage.md` | Lesson 10, 32 | technique → rule → tested? → tuned? coverage map |
| `ioc-list.md` | Lesson 09, 12 | curated IOCs (host/network/file) + source + the Pyramid-of-Pain tier |

## The rule of this folder
A detection only counts when it is **tested** (fires on real lab telemetry, e.g. via
`wazuh-logtest` or `sigma convert` + a positive event) and **tuned** (its false positives are
analyzed). Untested rules are marked `DRAFT`. Every committed rule names the ATT&CK technique it
covers.

## Why Sigma (portability)
Sigma is the vendor-neutral detection format: write once, convert to Wazuh, Elastic, Splunk, etc.
It's how detection engineers share and version detections — and it keeps your skill portable
beyond Wazuh (Lesson 27).
