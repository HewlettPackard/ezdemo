#!/usr/bin/env bash
# =============================================================================
# Copyright 2022 Hewlett Packard Enterprise
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
# =============================================================================

set -euo pipefail

source ./outputs.sh "${1}"

ANSIBLE_INVENTORY="####
# Ansible Hosts File for HPE Container Platform Deployment
# created by Dirk Derichsweiler
# modified by Erdinc Kaya
#
# Important:
# use only ip addresses in this file
####
[controllers]
$(echo ${CTRL_PRV_IPS[@]:- } | sed 's/ /\n/g')
[gateway]
$(echo ${GATW_PRV_IPS[@]:- } | sed 's/ /\n/g')
[workers]
$(echo ${WRKR_PRV_IPS[@]:- } | sed 's/ /\n/g')
[gworkers]
$(echo ${GWRKR_PRV_IPS[@]:- } | sed 's/ /\n/g')
[ad_server]
${AD_PRV_IP}
[mapr]
$(echo ${MAPR_PRV_IPS[@]:- } | sed 's/ /\n/g')
[mapr:vars]
ansible_user=ubuntu
[all:vars]
ansible_connection=ssh
ansible_user=centos
install_file=${EPIC_FILENAME}
download_url=${EPIC_DL_URL}
admin_password=${ADMIN_PASSWORD}
gateway_pub_dns=$(echo ${GATW_PUB_DNS[0]:-})
ssh_prv_key=${SSH_PRV_KEY_PATH}
is_mlops=${IS_MLOPS}
is_mapr=${IS_MAPR}
is_ha=${IS_HA}
is_mapr_ha=${IS_MAPR_HA}
is_runtime=${IS_RUNTIME}
is_stable=${IS_STABLE}
install_ad=${INSTALL_AD}
ad_realm=${AD_REALM}
app_version=${APP_VERSION}
k8s_version=${K8S_VERSION}
project_id=${PROJECT_ID}

"

echo "${ANSIBLE_INVENTORY}" > ./ansible/inventory.ini
SSHOPT="-i generated/controller.prv_key -o ServerAliveInterval=30 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"
SSH_VIA_PROXY="${SSHOPT} -o ProxyCommand=\"ssh ${SSHOPT} -W %h:%p -q centos@${GATW_PUB_IPS[0]:-}\""
[[ -d ./ansible/group_vars/ ]] || mkdir ./ansible/group_vars
if [[ "${1}" == "mac" ]]; then
  echo "ansible_ssh_common_args: ${SSHOPT}" > ./ansible/group_vars/all.yml
else
  echo "ansible_ssh_common_args: ${SSH_VIA_PROXY}" > ./ansible/group_vars/all.yml
fi

### TODO: Move to ansible task
SSH_CONFIG="
Host *
  StrictHostKeyChecking no
Host hpecp_gateway
  Hostname $(echo ${GATW_PUB_DNS[0]:-})
  IdentityFile generated/controller.prv_key
  ServerAliveInterval 30
  User centos
Host 10.1.0.*
    Hostname %h
    ConnectionAttempts 3
    IdentityFile generated/controller.prv_key
    ProxyJump hpecp_gateway

"

[[ -d ~/.ssh ]] || mkdir ~/.ssh && chmod 700 ~/.ssh
[[ "${1}" == "mac" ]] || echo "${SSH_CONFIG}" > ~/.ssh/config ## TODO: move to ansible, delete on destroy

pushd ./generated/ > /dev/null
  if [[ $IS_RUNTIME == "true" ]]; then
    rm -rf "$(echo ${GATW_PUB_DNS[0]})"
    CTRL_DOMAINS="$(echo ${CTRL_PRV_DNS[@]} | sed 's/ /,/g'),$(echo ${CTRL_PRV_DNS%%.*})"
    CTRL_IPS="$(echo ${CTRL_PRV_IPS[@]} | sed 's/ /,/g')"
    ALL_DOMAINS="$(echo ${GATW_PUB_DNS[@]} | sed 's/ /,/g'),$(echo ${GATW_PRV_DNS} | sed 's/ /,/g'),${GATW_PUB_DNS%%.*},${GATW_PRV_DNS%%.*},${CTRL_DOMAINS},localhost"
    ALL_IPS="$(echo ${GATW_PUB_IPS[@]} | sed 's/ /,/g'),$(echo ${GATW_PRV_IPS[@]} | sed 's/ /,/g'),${CTRL_IPS},127.0.0.1"
    minica -domains "$(echo "$ALL_DOMAINS" | sed 's/,,/,/g')" -ip-addresses "$(echo "$ALL_IPS" | sed 's/,,/,/g')"
  fi
popd > /dev/null

exit 0
