#!/usr/bin/env bash

yarn build
tag=$(date "+%Y%m%d%H%M")
docker build -t erdincka/ezdemo:"${tag}" -t erdincka/ezdemo:latest --platform amd64 .

exit 0
