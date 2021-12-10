#!/usr/bin/env bash
CID=$(docker ps -f "status=running" -f "ancestor=erdincka/ezdemo" --format "{{ .ID }}")
docker exec -it "${CID}" /bin/bash

exit 0
