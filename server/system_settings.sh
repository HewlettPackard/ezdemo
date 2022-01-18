#!/usr/bin/env bash

set -euo pipefail

EPIC_STABLE_URL=$(jq -r '.epic_stable' ./system.settings)
EPIC_LATEST_URL=$(jq -r '.epic_latest' ./system.settings)
IS_RUNTIME=$(jq -r '.is_runtime' ./system.settings)
IS_STABLE=$(jq '.is_stable' ./system.settings)
APP_VERSION=$(jq '.version' ./system.settings)
