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

pushd "${1}" > /dev/null
  TF_IN_AUTOMATION=1 terraform destroy ${EZWEB_TF:-} \
    -parallelism 12 \
    -var-file=<(cat ./*.tfvars) \
    -auto-approve=true \

   if [[ -f "./destroy.sh" ]]; then
      "./destroy.sh"
   fi

  rm my.tfvars > /dev/null 2>&1 || true
popd > /dev/null

## Run cleaning playbook
ansible-playbook -i ansible/inventory.ini ansible/destroy.yml --extra-vars "target=${1}"

(ls -d generated/*/ | xargs rm -rf) 2> /dev/null || true # Deletes all folders under generated, better than deleting the generated folder all together

## Clean user environment # TODO: move to ansible task
[ ! -L ~/.hpecp.conf  ] && rm -f ~/.hpecp.conf || echo -n '' > ~/.hpecp.conf
[ ! -L ~/.kube/config  ] && rm -f ~/.kube/config || echo -n '' >  ~/.kube/config

rm -f generated/output.json
rm -f ansible/group_vars/all.yml
rm -f ansible/inventory.ini
(ls "${1}"/*run.log | xargs rm -f) 2> /dev/null || true

echo "Environment destroyed"
echo "SSH key-pair and CA certs are not removed!"

exit 0
