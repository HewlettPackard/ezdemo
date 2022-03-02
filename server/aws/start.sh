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

## place the configuration files in place where cli expects them
[[ -d ~/.aws ]] || mkdir ~/.aws
[[ -f ~/.aws/config ]] || cp -f ./credentials ./config ~/.aws/
sed -i 's/"//g' ~/.aws/credentials ## somehow cli doesn't work with keys within quotes

REGION=$(grep "region" ./config | cut -d'=' -f2)
PROFILE=$(head -n1 credentials | tr -d '[' | tr -d ']')
ALL_INSTANCE_IDS=$(cat terraform.tfstate | jq '.resources[] | select (.type == "aws_instance") | .instances[].attributes.id' | sed 's/"//g')

aws --region $REGION --profile $PROFILE ec2 start-instances \
  --instance-ids $ALL_INSTANCE_IDS \
  --output table --no-cli-pager \
  --query "StoppingInstances[*].{ID:InstanceId,State:CurrentState.Name}"

while true; do
  RUNNING=$(aws --region ${REGION} --profile ${PROFILE} ec2 describe-instances --instance-ids ${ALL_INSTANCE_IDS} | jq '.Reservations[].Instances[] | select(.State.Name != "running") | .InstanceId')
  [[ "${RUNNING}" == "" ]] && echo " All instances are started" && break
  echo -n "."
  sleep 20
done

exit 0
