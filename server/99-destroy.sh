#!/usr/bin/env bash

set -euo pipefail

if ! echo "aws azure kvm vmware" | grep -w -q ${1}; then
   echo Usage: "${0} aws|azure|kvm|vmware"
   exit 1
fi

pushd "${1}" > /dev/null
  TF_IN_AUTOMATION=1 terraform destroy \
    -no-color \
    -parallelism 12 \
    -var-file=<(cat ./*.tfvars) \
    -auto-approve=true \
    # -var="client_cidr_block=$(curl -s http://ipinfo.io/ip)/32"
    
popd > /dev/null

# Tear down ssh port forwarding (if exist) for MapR MCS
source outputs.sh ${1}
ssh -S /tmp/MCS-socket -O exit centos@${GATW_PRV_DNS} || true

rm -rf generated/"${GATW_PUB_DNS}"
rm -f generated/output.json
rm -f ansible/group_vars/all.yml
rm -f ansible/inventory.ini
rm -f "${1}/*run.log"
## Clean user environment
rm -f ~/.hpecp.conf
rm -f ~/.hpecp_tenant.conf
rm -f ~/.hpecp_admin.config
rm -f ~/.kube/*_admin.config

echo "Environment destroyed"
echo "SSH key-pair, CA certs and cloud-init files are not removed!"

exit 0
