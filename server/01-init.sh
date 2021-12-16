#!/usr/bin/env bash

set -euo pipefail

if ! echo "aws azure kvm vmware" | grep -w -q ${1}; then
   echo Usage: "${0} aws|azure|kvm|vmware"
   exit 1
fi

[[ -d "./generated" ]] || mkdir generated

if [[ ! -f  "./generated/controller.prv_key" ]]; then
   ssh-keygen -m pem -t rsa -N "" -f "./generated/controller.prv_key"
   mv "./generated/controller.prv_key.pub" "./generated/controller.pub_key"
   chmod 600 "./generated/controller.prv_key"
fi

if [[ ! -f  "./generated/ca-key.pem" ]]; then
   openssl genrsa -out "./generated/ca-key.pem" 2048
   openssl req -x509 \
      -new -nodes \
      -key "./generated/ca-key.pem" \
      -subj "/C=US/ST=CA/O=MyOrg, Inc./CN=mydomain.com" \
      -sha256 -days 1024 \
      -out "./generated/ca-cert.pem"
fi

SSH_PUB_KEY=$(cat ./generated/controller.pub_key)
SSH_PRV_KEY=$(cat ./generated/controller.prv_key)
SSH_PRV_KEY_B64=$(base64 ./generated/controller.prv_key)

if [[ ! -f "./generated/cloud-init.yaml" ]]; then
   CLOUD_INIT=$(eval "cat <<EOF
$(<./etc/cloud-init.yaml-template)
EOF
" 2> /dev/null)

   echo "$CLOUD_INIT" > ./generated/cloud-init.yaml
fi

if [[ ! -f "./generated/cloud-init-ad-server.yaml" ]]; then
   AD_POSIX_CLASSES=$(base64 ./files/ad_set_posix_classes.ldif)
   AD_USER_SETUP=$(base64 ./files/ad_user_setup.sh)
   LDIF_MODIFY=$(base64 ./files/ldif_modify.sh)
   RUN_AD=$(base64 ./files/run_ad.sh)
  
   CLOUD_INIT=$(eval "cat <<EOF
$(<./etc/cloud-init-ad-server.yaml-template)
EOF
" 2> /dev/null)

   echo "$CLOUD_INIT" > ./generated/cloud-init-ad-server.yaml
fi

pushd "${1}" > /dev/null
   TF_IN_AUTOMATION=1 terraform init -no-color
   ### Init hook-up for individual targets (aws, vmware etc)
   if [[ -f "./init.sh" ]]; then
      "./init.sh"
   fi
popd > /dev/null

echo "Stage 1 complete"
# ./02-apply.sh "${1}"

exit 0
