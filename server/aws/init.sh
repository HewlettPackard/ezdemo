#!/usr/bin/env bash

set -euo pipefail

# update credentials & tags from config file
ACCESS_KEY=$(jq '.aws_access_key' ./config.json)
SECRET=$(jq '.aws_secret_key' ./config.json)
USER_ID=$(jq '.user' ./config.json)
PROJECT_ID=$(jq '.project_id' ./config.json)
ADMIN_PASSWORD=$(jq '.admin_password' ./config.json)
IS_MLOPS=$(jq -r '.is_mlops // false' ./config.json)
IS_MAPR=$(jq -r '.is_mapr // false' ./config.json)
IS_GPU=$(jq -r '.is_gpu // false' ./config.json)

cat > ./credentials <<EOF
[default]
aws_access_key_id=${ACCESS_KEY}
aws_secret_access_key=${SECRET}
EOF

cat > ./my.tfvars <<EOF
user = ${USER_ID}
project_id = ${PROJECT_ID}
is_mlops = ${IS_MLOPS}
is_mapr = ${IS_MAPR}
admin_password = ${ADMIN_PASSWORD}
EOF

if [[ "${IS_GPU}" == "true" ]]; then 
  echo "gworker_count = 1" >> ./my.tfvars 
fi

exit 0
