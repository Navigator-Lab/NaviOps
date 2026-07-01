#!/usr/bin/env bash
#
# NaviOpsNetwork lab bootstrap — routing topology + NOC monitoring, offline after one pull.
#
#   ./infra/bootstrap.sh pull         # one-time image fetch (internet once)
#   ./infra/bootstrap.sh up           # r1, r2, h1, h2 (the routing topology)
#   ./infra/bootstrap.sh monitoring   # Prometheus + blackbox + Grafana
#   ./infra/bootstrap.sh all | status | down | destroy

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; readonly SCRIPT_DIR
readonly TOPO_DIR="${SCRIPT_DIR}/topologies"
readonly MON_DIR="${SCRIPT_DIR}/monitoring"

if docker compose version >/dev/null 2>&1; then DC=(docker compose)
elif command -v docker-compose >/dev/null 2>&1; then DC=(docker-compose)
else echo "Install Docker first." >&2; exit 1; fi

usage() { grep -E '^#( |$)' "$0" | sed 's/^# \{0,1\}//'; }
topo() { ( cd "$TOPO_DIR" && "${DC[@]}" "$@"; ); }
mon()  { ( cd "$MON_DIR"  && "${DC[@]}" "$@"; ); }

status() {
	echo "== Topology =="; topo ps 2>/dev/null || true
	echo; echo "== Monitoring =="; mon ps 2>/dev/null || true
	cat <<-'URLS'

	Next: docker exec -it clab-r1 vtysh   (configure OSPF)   ·   docker exec -it clab-h1 bash (test)
	Grafana http://localhost:3001 (admin/naviops) · Prometheus http://localhost:9091 · blackbox :9115
	Lab guide: infra/LAB.md
	URLS
}

case "${1:-status}" in
	pull)       topo pull; mon pull ;;
	up)         topo up -d; echo "Topology up. See infra/LAB.md for the OSPF exercise." ;;
	monitoring) mon up -d; echo "Monitoring up: Grafana :3001 Prometheus :9091" ;;
	all)        topo up -d; mon up -d; status ;;
	status)     status ;;
	down)       topo down; mon down; echo "Stopped (volumes kept)." ;;
	destroy)    topo down -v; mon down -v; echo "Stopped + volumes removed." ;;
	-h|--help)  usage ;;
	*)          echo "Unknown: $1" >&2; usage; exit 1 ;;
esac
