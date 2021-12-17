#!/usr/bin/env bash

set -euo pipefail

# update credentials & tags from config file
ACCESS_KEY=$(jq '.aws_access_key' ./config.json)
SECRET=$(jq '.aws_secret_key' ./config.json)
USER_ID=$(jq '.user' ./config.json)
ADMIN_PASS=$(jq '.admin_pass' ./config.json)
PROJECT_ID=$(jq '.project_id' ./config.json)
IS_MLOPS=$(jq -r '.is_mlops // false' ./config.json)

cat > ./credentials <<EOF
[default]
aws_access_key_id=${ACCESS_KEY}
aws_secret_access_key=${SECRET}
EOF

cat > ./my.tfvars <<EOF
user = ${USER_ID}
project_id = ${PROJECT_ID}
is_mlops = ${IS_MLOPS}
admin_pass = ${ADMIN_PASS}
EOF

exit 0
