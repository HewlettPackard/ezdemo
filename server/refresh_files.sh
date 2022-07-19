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

USAGE="Usage: ${0} $(paste -s -d '|' providers)"

PROVIDERS=($(<providers))
if ! [ $# -gt 0 ] || ! (echo ${PROVIDERS[@]} | grep -w -q ${1}); then
  echo $USAGE
  exit 1
fi

set -euo pipefail

source ./outputs.sh "${1}"

pushd "${1}" > /dev/null
  [ -f "refresh.sh" ] && source ./refresh.sh || true
popd > /dev/null

# Configure AD settings for new AD installation (force AD installation on cloud) 
[[ "${1}" == "aws" || "${1}" == "azure" ]] && export INSTALL_AD=true
[[ "$INSTALL_AD" == "true" ]] && AD_CONF=$(<./etc/default_ad_conf.ini)

[[ "${1}" == "dc" ]] && while IFS='=' read var val
do
  if [[ $var == \[*] ]]
  then
    section=$var
  elif [[ $val ]]
  then
	  CUSTOM_INI="${CUSTOM_INI}
${var}=${val}"
  fi
done < ./dc/dc.ini


ANSIBLE_INVENTORY="####
[controllers]
$(echo ${CTRL_PRV_IPS[@]:- } | sed 's/ /\n/g')
[gateway]
$(echo ${GATW_PRV_IPS[@]:- } | sed 's/ /\n/g')
[workers]
$(echo ${WRKR_PRV_IPS[@]:- } | sed 's/ /\n/g')
[gworkers]
$(echo ${GWRKR_PRV_IPS[@]:- } | sed 's/ /\n/g')
[ad_server]
${AD_PRV_IP:-}
[mapr]
$(echo ${MAPR_PRV_IPS[@]:- } | sed 's/ /\n/g')
[mapr:vars]
ansible_user=rocky
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
app_version=${APP_VERSION}
k8s_version=${K8S_VERSION}
project_id=${PROJECT_ID}

### Customization
${AD_CONF:-}
${CUSTOM_INI:-}
"

echo "${ANSIBLE_INVENTORY}" > ./ansible/inventory.ini

# Set ansible for proxy ssh
SSHOPT="-i generated/controller.prv_key -o ServerAliveInterval=30 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"
SSH_VIA_PROXY="${SSHOPT} -o ProxyCommand=\"ssh ${SSHOPT} -W %h:%p -q centos@${GATW_PUB_IPS[0]:-}\""
[[ -d ./ansible/group_vars/ ]] || mkdir ./ansible/group_vars
if [[ "${1}" == "dc" ]]; then
  echo "ansible_ssh_common_args: ${SSHOPT}" > ./ansible/group_vars/all.yml
else
  echo "ansible_ssh_common_args: ${SSH_VIA_PROXY}" > ./ansible/group_vars/all.yml
fi

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
