#!/usr/bin/env bash

CID=$(docker ps -f "status=running" -f "ancestor=erdincka/ezdemo" --format "{{ .ID }}")
if [ "${CID}" != "" ]; then 
  docker stop "${CID}" || true 
  docker rm "${CID}" || true 
fi 
exit 0
