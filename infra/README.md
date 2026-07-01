# NaviOps Lab — offline practice environment

Everything you need to *do* the lessons (not just read them). Built once, run anytime, **offline**.

## What's here
| Path | What it is |
|---|---|
| `lab/docker-compose.yml` | Two systemd-enabled Linux "servers" (`web`, `db`) on a real `172.28.0.0/24` network |
| `monitoring/docker-compose.yml` | NOC stack: Prometheus + node-exporter + Grafana + **Nagios** |
| `bootstrap.sh` | One command to pull / up / down / status the whole lab |
| `ansible/`, `terraform/` | Real config artifacts for Lessons 13/20/25 (install the tool, then apply) |

## Quick start
```bash
# ONE TIME (needs internet once) — cache every image locally:
./infra/bootstrap.sh pull

# From then on, fully offline:
./infra/bootstrap.sh up            # practice Linux servers
./infra/bootstrap.sh monitoring    # NOC dashboards
./infra/bootstrap.sh status        # URLs + what's running
./infra/bootstrap.sh down          # stop (keeps your work)
./infra/bootstrap.sh destroy       # wipe volumes for a clean re-run
```

## Access
- Practice nodes: `docker exec -it naviops-web bash` / `naviops-db`
- Grafana: http://localhost:3000 (`admin` / `naviops`)
- Prometheus: http://localhost:9090 (see `/targets`)
- Nagios: http://localhost:8081/nagios (`nagiosadmin` / `naviops`)

## How lessons use the lab (Gate Rule Step 4)
- **05 systemd/journald** → `systemctl`, `journalctl` inside `naviops-web`; verify with `scripts/service_check.sh`.
- **07 SSH/storage** → set up sshd, add users, practice mounts on the `/srv` volume; `scripts/disk_report.sh`.
- **08 networking/subnetting** → `ip`, `ss` across the `172.28.0.0/24` net; `scripts/net_diag.sh`.
- **09 firewalls** → `firewalld`/`iptables` on `naviops-web`; `scripts/firewall_audit.sh`.
- **10 hardening** → `scripts/security_audit.sh` against a node, then fix findings.
- **19/28 triage** → read Grafana/Nagios, feed logs to `scripts/alert_triage.sh`.
- **27 RHCSA** → `RHCSA-SERVICE-LABS.md` (NFS/Apache/BIND/SELinux) on the two nodes.

## Notes
- `web` and `db` run **privileged** (so in-container systemd works) — that's fine for a local lab, never
  for production. This is a teaching environment.
- No cloud, no spend, no secrets. Public-repo redaction discipline still applies to any screenshots.
- Ansible/Terraform aren't preinstalled; the lessons ship the real playbooks/`.tf` so you run them after
  `apt install ansible` / installing Terraform.
