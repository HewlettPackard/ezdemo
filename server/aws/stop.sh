#!/usr/bin/env bash

set -euo pipefail

## place the configuration files in place where cli expects them
[[ -d ~/.aws ]] || mkdir ~/.aws 
[[ -f ~/.aws/config ]] || cp -f ./credentials ./config ~/.aws/
sed -i 's/"//g' ~/.aws/credentials ## somehow cli doesn't work with keys within quotes

REGION=$(grep "region" ./config | cut -d'=' -f2)
PROFILE=$(head -n1 credentials | tr -d '[' | tr -d ']')
ALL_INSTANCE_IDS=$(cat terraform.tfstate | jq '.resources[] | select (.type == "aws_instance") | .instances[].attributes.id' | sed 's/"//g')

aws --region $REGION --profile $PROFILE ec2 stop-instances \
  --instance-ids $ALL_INSTANCE_IDS \
  --output table --no-cli-pager \
  --query "StoppingInstances[*].{ID:InstanceId,State:CurrentState.Name}"

while true; do
  RUNNING=$(aws --region ${REGION} --profile ${PROFILE} ec2 describe-instances --instance-ids ${ALL_INSTANCE_IDS} | jq '.Reservations[].Instances[] | select(.State.Name != "stopped") | .InstanceId')
  [[ "${RUNNING}" == "" ]] && echo " All instances are stopped" && break
  echo -n "."
  sleep 20
done

exit 0
