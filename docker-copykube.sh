#!/usr/bin/env bash
set -euo pipefail

# CID=$(docker ps -f "status=running" -f "ancestor=erdincka/ezdemo" --format "{{ .ID }}")
CID=$(docker ps -f "status=running" --format "{{ .ID }}")
docker cp "${CID}:/root/.hpecp_admin.config" ~/.kube/"${CID}"_admin.config 

exit 0
