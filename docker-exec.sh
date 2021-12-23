#!/usr/bin/env bash
set -euo pipefail

CID=$(docker ps -f "status=running" -f "ancestor=erdincka/ezdemo" -q)
docker exec -it "${CID}" /bin/bash

exit 0
