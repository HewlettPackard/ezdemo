#!/usr/bin/env bash

set -euo pipefail

# update credentials & tags from config file

SUBSCRIPTION=$(jq '.az_subscription' ./config.json)
TENANT=$(jq '.az_tenant' ./config.json)
APPID=$(jq '.az_appId' ./config.json)
PASSWORD=$(jq '.az_password' ./config.json)
USER_ID=$(jq 'if .user == "" then "unknown user" else .user end' ./config.json)
PROJECT_ID=$(jq 'if .project_id == "" then "unnamed" else .project_id end' ./config.json)
ADMIN_PASSWORD=$(jq '.admin_password' ./config.json)
IS_MLOPS=$(jq -r '.is_mlops // false' ./config.json)
IS_MAPR=$(jq -r '.is_mapr // false' ./config.json)
IS_GPU=$(jq -r '.is_gpu // false' ./config.json)
REGION=$(jq -r '.region' ./config.json)

cat > ./my.tfvars <<EOF
subscription_id = ${SUBSCRIPTION}
client_id = ${APPID}
client_secret = ${PASSWORD}
tenant_id = ${TENANT}
user = ${USER_ID}
project_id = ${PROJECT_ID// /_}
is_mlops = ${IS_MLOPS}
is_mapr = ${IS_MAPR}
admin_password = ${ADMIN_PASSWORD}
EOF

if [[ "${IS_GPU}" == "true" ]]; then 
  echo "gworker_count = 1" >> ./my.tfvars 
fi
if [[ "${REGION}" != "" ]]; then
  echo "setting region to $REGION"
  echo "region = \"${REGION}\"" >> ./my.tfvars
fi

exit 0
