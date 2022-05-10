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

pushd .. >> /dev/null 2>&1  
. ./user_settings.sh ## since we are not parsing my.tfvars
popd >> /dev/null 2>&1  

### TODO: these should be in user settings
VM_NETWORK=$(grep vm_network dc.ini | cut -d= -f2)
TEMPLATE_USER=$(grep template_user dc.ini | cut -d= -f2)
TEMPLATE_KEYFILE=$(grep template_keyfile dc.ini | cut -d= -f2)
MAPR_TEMPLATE_USER=$(grep mapr_template_user dc.ini | cut -d= -f2)
MAPR_TEMPLATE_KEYFILE=$(grep mapr_template_keyfile dc.ini | cut -d= -f2)

ansible --extra-vars "project_id=${PROJECT_ID} is_runtime=${IS_RUNTIME} is_mlops=${IS_MLOPS} is_ha=${IS_HA} \
  is_mapr=${IS_MAPR} is_mapr_ha=${IS_MAPR_HA} vm_network=${VM_NETWORK} \
  template_user=${TEMPLATE_USER} template_ssh_private_key_file_path=${TEMPLATE_KEYFILE} \
  mapr_template_user=${MAPR_TEMPLATE_USER} mapr_template_ssh_private_key_file_path=${MAPR_TEMPLATE_KEYFILE}" \
  localhost -m ansible.builtin.template -a "src=hosts-common.j2 dest=hosts-common.ini"
cat hosts-common.ini dc.ini > ./hosts.ini

exit 0
