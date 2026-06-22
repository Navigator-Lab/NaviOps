# SOC Operations Modules

The day-to-day operating discipline of a Security Operations Center — the security analog of
NaviOpsNetwork's `noc/` modules. Lessons reference these from §6 (SOC Perspective); the
SOC-Operations project (Lesson 34) exercises all of them together.

| Module | What it covers |
|---|---|
| [alert-triage.md](alert-triage.md) | the alert lifecycle, TP/FP, severity, the triage decision tree, alert fatigue |
| [escalation-matrix.md](escalation-matrix.md) | T1 → T2 → T3/IR, when and how to escalate, who owns what |
| [case-management.md](case-management.md) | the `SOC-NN` ticket lifecycle, documentation discipline, case hygiene |
| [shift-handover.md](shift-handover.md) | the handover note, what the next shift must know, continuity |
| [soc-metrics-sla.md](soc-metrics-sla.md) | MTTD/MTTR, alert volume, dwell time, SLA, dashboards |
| [soc-scenarios.md](soc-scenarios.md) | the 8 canonical SOC scenarios each lesson's §7 maps to |

> All of these assume the **Linux-first + Wazuh** workflow from the lessons. The modules are the
> *process*; the lessons are the *technique*.
