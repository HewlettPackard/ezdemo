#!/usr/bin/env bash

set -euo pipefail

VMS=("ct" "ad" "gw" "w1" "w2" "df")
CPUS=(16 2 4 16 16 8)
MEMS=(32 4 8 32 32 32)
DISKS=(500 0 0 500 500 500)

# reset ips for newly created set
# echo -n "" > hosts.out

for num in {1..5}; do
  id=num-1
  ### Don't disturb running VM
  is_running=$(ps -ef | grep qemu | grep "file=${VMS[id]}-disk1.img" | wc -l | tr -d ' ') || true
  if [[ "${is_running}" != 0 ]]; then
    echo "Skipping ${VMS[id]}..."
  else
    ./centos-x64.sh "${VMS[id]}" "${CPUS[id]}" "${MEMS[id]}" "${DISKS[id]}" &
    sleep 30 # before firing up the next one
  fi 
done
wait 

echo "Waiting services to start (2m)"
sleep 120

### Global vars
CTRL_PRV_IP=$(grep "${VMS[0]}" hosts.out | cut -d',' -f2)
AD_PRV_IP=$(grep "${VMS[1]}" hosts.out | cut -d',' -f2)
GATW_PRV_IP=$(grep "${VMS[2]}" hosts.out | cut -d',' -f2)
GATW_PUB_IP=${GATW_PRV_IP}
WRKR_IPS=($(grep "${VMS[3]}" hosts.out | cut -d',' -f2) $(grep "${VMS[4]}" hosts.out | cut -d',' -f2))
# echo "${WRKR_IPS[@]}"
K8S_IPS=$(echo ${WRKR_IPS[@]} | sed 's/ /\n/g' )
# echo "${K8S_IPS[@]}"
MAPR_IP=$(grep df hosts.out | cut -d',' -f2)
MLOPS_IPS=""
PICASSO_IPS=""
SSH_PRV_KEY_PATH="${HOME}/.ssh/id_rsa"
EPIC_DL_URL="${HOME}/Downloads/hpe-cp-rhel-release-5.4-32.bin"
# EPIC_DL_URL="${HOME}/Downloads/hpe-cp-rhel-release-5.3.6-3060.bin"
EPIC_FILENAME="hpe-cp-rhel-release-5.4-32.bin"
# EPIC_FILENAME="hpe-cp-rhel-release-5.3.6-3060.bin"
ADMIN_PASSWORD=${ADMIN_PASSWORD}
GATW_PUB_DNS=${GATW_PRV_IP}
IS_MLOPS=false


ANSIBLE_INVENTORY="####
# Ansible Hosts File for HPE Container Platform Deployment
# created by Dirk Derichsweiler
# modified by Erdinc Kaya
#
# Important:
# use only ip addresses in this file
####
[controllers]
${CTRL_PRV_IP}
[gateway]
${GATW_PRV_IP}
[k8s]
${K8S_IPS}
[picasso]
${PICASSO_IPS}
[mlops]
${MLOPS_IPS}
[ad_server]
${AD_PRV_IP}
[mapr]
${MAPR_IP}
[all:vars]
ansible_connection=ssh
ansible_user=${USER}
install_file=${EPIC_FILENAME}
download_url=${EPIC_DL_URL}
admin_password=${ADMIN_PASSWORD}
gateway_pub_dns=${GATW_PUB_DNS}
ssh_prv_key=${SSH_PRV_KEY_PATH}
is_mlops=${IS_MLOPS}"
echo "${ANSIBLE_INVENTORY}" > ./ansible/inventory.ini
# sed "s/GATEWAY_IP/${GATW_PUB_IP}/g" ./ansible/group_vars.yml-template > ./ansible/group_vars/all.yml

### Init
if [[ ! -f  "ca-key.pem" ]]; then
   openssl genrsa -out "ca-key.pem" 2048
   openssl req -x509 \
      -new -nodes \
      -key "ca-key.pem" \
      -subj "/C=US/ST=CA/O=MyOrg, Inc./CN=mydomain.com" \
      -sha256 -days 1024 \
      -out "ca-cert.pem"
fi

ANSIBLE_CMD="ansible-playbook -v"

${ANSIBLE_CMD} -f 10 \
  -i ./ansible/inventory.ini \
  ./ansible/install.yml | tee "run.log"

exit 0
