#!/usr/bin/env bash
#
# NaviOpsSec SIEM lab bootstrap — Wazuh single-node + victim target.
# HEAVY: needs ~4GB free RAM. Offline after the one-time image pull.
#
#   ./infra/bootstrap.sh sysctl   # set vm.max_map_count (needs sudo, one-time per boot)
#   ./infra/bootstrap.sh pull     # fetch images (internet once)
#   ./infra/bootstrap.sh certs    # generate SSL certs (one-time)
#   ./infra/bootstrap.sh up       # start the SIEM  (Dashboard https://localhost:8443)
#   ./infra/bootstrap.sh status | down | destroy

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; readonly SCRIPT_DIR
readonly LAB_DIR="${SCRIPT_DIR}/lab"

if docker compose version >/dev/null 2>&1; then DC=(docker compose)
elif command -v docker-compose >/dev/null 2>&1; then DC=(docker-compose)
else echo "Install Docker first." >&2; exit 1; fi

usage() { grep -E '^#( |$)' "$0" | sed 's/^# \{0,1\}//'; }
lab() { ( cd "$LAB_DIR" && "${DC[@]}" "$@"; ); }

case "${1:-status}" in
	sysctl)
		echo "Setting vm.max_map_count=262144 (required by the indexer)..."
		sudo sysctl -w vm.max_map_count=262144 ;;
	pull)   lab pull; ( cd "$LAB_DIR" && "${DC[@]}" -f generate-certs.yml pull; ) ;;
	certs)
		echo "Generating SSL certs into lab/config/wazuh_indexer_ssl_certs/ ..."
		( cd "$LAB_DIR" && "${DC[@]}" -f generate-certs.yml run --rm generator; )
		echo "Done. Now: ./infra/bootstrap.sh up" ;;
	up)
		if [[ ! -d "$LAB_DIR/config/wazuh_indexer_ssl_certs" ]]; then
			echo "No certs yet — run './infra/bootstrap.sh certs' first." >&2; exit 1
		fi
		lab up -d
		echo "SIEM starting (give the indexer ~1-2 min). Dashboard: https://localhost:8443 (admin/SecretPassword)." ;;
	status) lab ps 2>/dev/null || true ;;
	down)   lab down; echo "Stopped (volumes kept)." ;;
	destroy) lab down -v; echo "Stopped + volumes removed." ;;
	-h|--help) usage ;;
	*) echo "Unknown: $1" >&2; usage; exit 1 ;;
esac
