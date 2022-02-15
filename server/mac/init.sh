#!/usr/bin/env bash

set -euo pipefail

ADMIN_PASSWORD=$(jq '.admin_password' ./config.json)
IS_MLOPS=$(jq -r '.is_mlops // false' ./config.json)
IS_MAPR=$(jq -r '.is_mapr // false' ./config.json)

cat > ./my.tfvars <<EOF
is_mlops = ${IS_MLOPS}
is_mapr = ${IS_MAPR}
admin_password = ${ADMIN_PASSWORD}
EOF

exit 0
