#!/usr/bin/env bash
set -euo pipefail

CID=$(docker ps -f "status=running" -f "ancestor=erdincka/ezdemo" -q)
# CID=$(docker ps -f "status=running" --format "{{ .ID }}")

(
  set -x
  docker cp "${CID}:/root/.kube/config" ~/.kube/"${CID}"_admin.config 
  docker cp "${CID}:/root/.hpecp.conf" ~/"${CID}".hpecp.conf
  docker cp "${CID}:/root/.hpecp_tenant.conf" ~/"${CID}".hpecp_tenant.conf || true
  docker cp "${CID}:/app/server/generated/minica.pem" ~/"${CID}".minica.pem || true
)

exit 0
