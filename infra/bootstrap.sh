#!/usr/bin/env bash
#
# infra/bootstrap.sh — one command to run the NaviOps offline lab.
#
# Choice: a single wrapper over the two compose stacks (lab + monitoring) so the learner never has to
# remember compose paths. Works offline once images are pulled (see `pull`).
#
#   ./infra/bootstrap.sh pull         # one-time: fetch all images (needs internet ONCE)
#   ./infra/bootstrap.sh up           # start the practice Linux servers
#   ./infra/bootstrap.sh monitoring   # start the NOC monitoring stack (Prometheus/Grafana/Nagios)
#   ./infra/bootstrap.sh all          # both
#   ./infra/bootstrap.sh status       # what's running + access URLs
#   ./infra/bootstrap.sh down         # stop everything (keeps data volumes)
#   ./infra/bootstrap.sh destroy      # stop + delete data volumes (fresh start)

# 1. Safety headers
set -euo pipefail
IFS=$'\n\t'

# 2. Constants
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
readonly LAB_DIR="${SCRIPT_DIR}/lab"
readonly MON_DIR="${SCRIPT_DIR}/monitoring"

# 3. Pick the compose command available on this machine (v2 plugin or v1 binary).
if docker compose version >/dev/null 2>&1; then
	DC=(docker compose)
elif command -v docker-compose >/dev/null 2>&1; then
	DC=(docker-compose)
else
	echo "ERROR: neither 'docker compose' nor 'docker-compose' found. Install Docker first." >&2
	exit 1
fi

# 4. Helpers
usage() { grep -E '^#( |$)' "$0" | sed 's/^# \{0,1\}//'; }

lab()  { ( cd "$LAB_DIR" && "${DC[@]}" "$@"; ); }
mon()  { ( cd "$MON_DIR" && "${DC[@]}" "$@"; ); }

status() {
	echo "== Practice servers (infra/lab) =="
	lab ps 2>/dev/null || true
	echo
	echo "== Monitoring stack (infra/monitoring) =="
	mon ps 2>/dev/null || true
	cat <<-'URLS'

	Access:
	  Practice web node : docker exec -it naviops-web bash   (ssh -p 2210 root@localhost once set up)
	  Practice db  node : docker exec -it naviops-db  bash
	  Grafana           : http://localhost:3000   (admin / naviops)
	  Prometheus        : http://localhost:9090
	  Nagios            : http://localhost:8081/nagios   (nagiosadmin / naviops)
	URLS
}

# 5. Command router
main() {
	local cmd="${1:-status}"
	case "$cmd" in
		pull)       lab pull; mon pull ;;
		up)         lab up -d; echo "Practice servers up. Run './infra/bootstrap.sh status'." ;;
		monitoring) mon up -d; echo "Monitoring up: Grafana :3000  Prometheus :9090  Nagios :8081/nagios" ;;
		all)        lab up -d; mon up -d; status ;;
		status)     status ;;
		down)       lab down; mon down; echo "Stopped (data volumes kept)." ;;
		destroy)    lab down -v; mon down -v; echo "Stopped and volumes removed (fresh start)." ;;
		-h|--help|help) usage ;;
		*)          echo "Unknown command: $cmd" >&2; usage; exit 1 ;;
	esac
}

main "$@"
