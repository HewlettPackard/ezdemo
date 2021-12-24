#!/usr/bin/env bash

set -euo pipefail

# update credentials & tags from config file

SUBSCRIPTION=$(jq '.az_subscription' ./config.json)
TENANT=$(jq '.az_tenant' ./config.json)
APPID=$(jq '.az_appId' ./config.json)
PASSWORD=$(jq '.az_password' ./config.json)
USER_ID=$(jq '.user' ./config.json)
ADMIN_PASSWORD=$(jq '.admin_password' ./config.json)
PROJECT_ID=$(jq '.project_id' ./config.json)
IS_MLOPS=$(jq -r '.is_mlops // false' ./config.json)
IS_MAPR=$(jq -r '.is_mapr // false' ./config.json)

cat > ./my.tfvars <<EOF
subscription_id = ${SUBSCRIPTION}
client_id = ${APPID}
client_secret = ${PASSWORD}
tenant_id = ${TENANT}
user = ${USER_ID}
project_id = ${PROJECT_ID}
is_mlops = ${IS_MLOPS}
is_mapr = ${IS_MAPR}
admin_password = ${ADMIN_PASSWORD}
EOF

exit 0
