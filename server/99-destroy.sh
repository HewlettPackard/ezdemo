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

<<<<<<< HEAD
=======
<<<<<<< HEAD
>>>>>>> c94c4174d220e4dbda8614e6d389d996348ca6d2
# Tear down ssh port forwarding (if exist) for MapR MCS
source outputs.sh ${1}
ssh -S /tmp/MCS-socket -O exit centos@${GATW_PRV_DNS} || true

<<<<<<< HEAD
=======
=======
>>>>>>> 6dd04bfd97728f229064cbf03e734c072ada5136
>>>>>>> c94c4174d220e4dbda8614e6d389d996348ca6d2
rm -f generated/output.json
rm -f generated/ssh_host.sh
rm -f ansible/group_vars/all.yml
rm -f ansible/inventory.ini
rm -f "${1}/*run.log"
## Clean user environment
rm -f ~/.hpecp.conf
rm -f ~/.hpecp_tenant.conf
rm -f ~/.hpecp_admin.config

echo "Environment destroyed"
echo "SSH key-pair, certificates and cloud-init files are not removed!"

exit 0
