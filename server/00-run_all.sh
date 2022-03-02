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

if [[ "${1}" == "mac" && "$(uname -s)" != "Darwin" ]]
then
  echo "You should be running this on MacOS"
  exit 1
fi

set -euo pipefail

if [[ -f "${1}/run.log" ]]; then
  mv "${1}/run.log" "${1}/$(date +'%Y%m%d%H%M')-run.log"
fi

if [[ "${EZWEB:-}" == "true" ]]; then
  ./01-init.sh "${1}" | tee -a "${1}/run.log"
  ./02-apply.sh "${1}" | tee -a "${1}/run.log"
  ./03-install.sh "${1}" | tee -a "${1}/run.log"
  ./04-configure.sh "${1}" | tee -a "${1}/run.log"
else
  ./01-init.sh "${1}"
  ./02-apply.sh "${1}"
  ./03-install.sh "${1}"
  ./04-configure.sh "${1}"
fi

exit 0
