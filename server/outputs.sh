#!/usr/bin/env bash

set -euo pipefail

if ! echo "aws azure kvm vmware" | grep -w -q ${1}; then
   echo Usage: "${0} aws|azure|kvm|vmware"
   exit 1
fi

OUTPUT_JSON=$(cat "generated/output.json")

###############################################################################
# Set variables from terraform output
###############################################################################

# Ensure python is able to parse the OUTPUT_JSON file
python3 - <<____HERE
import json,sys,subprocess
try:
   with open('generated/output.json') as f:
      json.load(f)
except: 
   print(80 * '*')
   print("ERROR: Can't parse: 'generated/output.json'")
   print(80 * '*')
   sys.exit(1)
____HERE

###############################################################################
# Set variables from terraform output
###############################################################################
SSH_PUB_KEY_PATH="generated/controller.pub_key"
SSH_PRV_KEY_PATH="generated/controller.prv_key"
CTRL_PRV_IPS=$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (*obj["controller_private_ips"]["value"], sep=" ")') 
#echo "CTRL_PRV_IPS=${CTRL_PRV_IPS}"
CTRL_PRV_DNS=$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (*obj["controller_private_dns"]["value"], sep=" ")') 
#echo "CTRL_PRV_DNS=${CTRL_PRV_DNS}"

GATW_PRV_IPS=$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (*obj["gateway_private_ips"]["value"], sep=" ")')
#echo "GATW_PRV_IPS=${GATW_PRV_IPS}"
GATW_PUB_IPS=$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (*obj["gateway_public_ips"]["value"], sep=" ")')
#echo "GATW_PUB_IPS=${GATW_PUB_IPS}"
GATW_PRV_DNS=$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (*obj["gateway_private_dns"]["value"], sep=" ")')
#echo "GATW_PRV_DNS=${GATW_PRV_DNS}"
GATW_PUB_DNS=$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (*obj["gateway_public_dns"]["value"], sep=" ")')
#echo "GATW_PUB_DNS=${GATW_PUB_DNS}"
# GATW_PUB_HOST=$(echo $GATW_PUB_DNS | cut -d"." -f1)
# GATW_PRV_HOST=$(echo $GATW_PRV_DNS | cut -d"." -f1)

#### WORKERS
WORKER_COUNT=$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (obj["worker_count"]["value"], sep=" ")') 
WRKR_PRV_IPS=$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (*obj["workers_private_ip"]["value"], sep=" ")') 
#echo "WRKR_PRV_IPS=${WRKR_PRV_IPS}"
#read -r -a WRKR_PRV_IPS <<< "$WRKR_PRV_IPS"

#### GPU WORKERS
GWORKER_COUNT=$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (obj["gworker_count"]["value"], sep=" ")')
GWRKR_PRV_IPS=$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (*obj["gworkers_private_ip"]["value"], sep=" ")')
#echo "GWRKR_PRV_IPS=${GWRKR_PRV_IPS}"

#### MAPR NODES
MAPR_COUNT=$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (obj["mapr_count"]["value"], sep=" ")')
MAPR_PRV_IPS=$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (*obj["mapr_private_ips"]["value"], sep=" ")')
#echo "MAPR_PRV_IPS=${MAPR_PRV_IPS}"
#read -r -a WRKR_PRV_IPS <<< "$WRKR_PRV_IPS"

AD_PRV_IP=$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (obj["ad_server_private_ip"]["value"])')
#echo "AD_PRV_IP=${AD_PRV_IP}"

### SYSTEM SETTINGS
source ./system_settings.sh 
EPIC_DL_URL=${EPIC_STABLE_URL}
[[ "${IS_STABLE}" == "false" ]] && export EPIC_DL_URL=${EPIC_LATEST_URL}

### USER SETTINGS
source ./user_settings.sh "${1}"

# echo "${EPIC_DL_URL}"
EPIC_FILENAME="$(echo ${EPIC_DL_URL##*/})"
# echo ${EPIC_FILENAME}
EPIC_OPTIONS="--skipeula --default-password ${ADMIN_PASSWORD}"

ANSIBLE_CMD="ansible-playbook"
if [ ${IS_VERBOSE} ]; then
  ANSIBLE_CMD="${ANSIBLE_CMD} -v"
fi
