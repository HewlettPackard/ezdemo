#!/usr/bin/env bash

VOLUMES=()
CONFIG_FILES=("aws_config.json" "azure_config.json" "vmware_config.json" "kvm_config.json")
for file in "${CONFIG_FILES[@]}"
do
  target="${file%_*}"
  # [[ -f "./${file}" ]] && VOLUMES="--mount=type=bind,source="$(pwd)"/${file},target=/app/server/${target}/config.json ${VOLUMES}"
  [[ -f "./${file}" ]] && VOLUMES+=("$(pwd)/${file}:/app/server/${target}/config.json:rw")
done

# echo "${VOLUMES[*]}"
printf -v joined ' -v %s' "${VOLUMES[@]}"
# echo "${joined}"
## run at the background with web service exposed at 4000
docker run -d -p 4000:4000 -p 8443:8443 ${joined} erdincka/ezdemo:latest

exit 0
