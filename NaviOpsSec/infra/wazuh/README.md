# `infra/wazuh/` — the SIEM stack (Wazuh)

The Wazuh manager/agent configs and custom detection content the platform builds. **Sanitized
only** — no real agent keys, cluster keys, IPs, or hostnames (`navi.project.md` Hard Rule #1).

| File | Built in | What it is |
|---|---|---|
| `ossec.conf` (sample) | Lesson 14 | manager/agent config — log collection, modules (sanitized) |
| `local_rules.xml` | Lesson 15, 32 | custom detection rules (failed-login/brute-force/persistence…) |
| `local_decoders.xml` | Lesson 15 | custom decoders for non-standard log formats |
| `fim.conf` (syscheck) | Lesson 24 | file-integrity-monitoring config for critical paths |
| `active-response.conf` | Lesson 29, 32 | lab-only auto-response (firewall-drop on brute force) |

## Standing up the lab (Lesson 14)
Single-node lab: Wazuh manager + indexer + dashboard on one VM, agent(s) on the lab target(s).
The live stack is the **operator's** job on their own VMs — these files are the
version-controlled, sanitized configuration that drives it.

## Testing rules
```bash
# feed a sample log line through decoders+rules without waiting for a real event
/var/ossec/bin/wazuh-logtest
```

> Active response is a **Danger Zone** — auto-block/kill can lock you out or drop a service.
> Lab-only, with console fallback.
