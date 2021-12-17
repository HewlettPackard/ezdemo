#!/usr/bin/env bash
set -euo pipefail

# CID=$(docker ps -f "status=running" -f "ancestor=erdincka/ezdemo" --format "{{ .ID }}")
CID=$(docker ps -f "status=running" --format "{{ .ID }}")
docker cp "${CID}:/root/.hpecp_admin.config" ~/.kube/"${CID}"_admin.config 
docker cp "${CID}:/root/.hpecp.conf" ~/"${CID}".hpecp.conf
docker cp "${CID}:/root/.hpecp_tenant.conf" ~/"${CID}".hpecp_tenant.conf || true
docker cp "${CID}:/app/server/generated/minica.pem" ~/"${CID}".minica.pem || true

exit 0
