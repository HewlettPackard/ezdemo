#!/usr/bin/env bash

set -euo pipefail

if ! echo "aws azure kvm vmware" | grep -w -q ${1}; then
   echo Usage: "${0} aws|azure|kvm|vmware"
   exit 1
fi

EPIC_STABLE_URL=$(jq -r '.epic_stable' ./system.settings)
EPIC_LATEST_URL=$(jq -r '.epic_latest' ./system.settings)
IS_RUNTIME=$(jq -r '.is_runtime' ./system.settings)
IS_STABLE=$(jq '.is_stable' ./system.settings)
K8S_VERSION=$(jq '.k8s_version' ./system.settings)
APP_VERSION=$(jq '.version' ./system.settings)
