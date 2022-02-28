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

source ./system_settings.sh ### These settings coming from system, not the user

pushd "${1}" > /dev/null
   TF_IN_AUTOMATION=1 terraform refresh ${EZWEB_TF:-} \
      -parallelism 10 \
      -auto-approve=true \
      -var-file=<(cat ./*.tfvars) \
      -var="is_runtime=${IS_RUNTIME}"
   # Save output
   TF_IN_AUTOMATION=1 terraform output -json > ../generated/output.json
popd > /dev/null

./variables.sh "${1}"

ANSIBLE_SSH_RETRIES=5 ${ANSIBLE_CMD} -f 10 \
  -i ./ansible/inventory.ini \
  ./ansible/refresh.yml

echo "Refresh complete"

exit 0
