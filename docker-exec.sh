#!/usr/bin/env bash
set -euo pipefail

CID=$(docker ps -f "status=running" --format "{{ .ID }}")
docker exec -it "${CID}" /bin/bash

exit 0
