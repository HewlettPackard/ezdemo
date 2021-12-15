#!/usr/bin/env bash

set -euo pipefail

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

# PROJECT_DIR=$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (obj["project_dir"]["value"])')
# [ "$PROJECT_DIR" ] || ( echo "ERROR: PROJECT_DIR is empty" && exit 1 )

# ADDITIONAL_CLIENT_IP_LIST=$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (*obj["additional_client_ip_list"]["value"])')
#echo ADDITIONAL_CLIENT_IP_LIST="${ADDITIONAL_CLIENT_IP_LIST}"

# LOG_FILE="${PROJECT_DIR}"/generated/bluedata_install_output.txt

# CLIENT_CIDR_BLOCK=$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (obj["client_cidr_block"]["value"])')
# [ "$CLIENT_CIDR_BLOCK" ] || ( echo "ERROR: CLIENT_CIDR_BLOCK is empty" && exit 1 )

# USER_TAG=$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (obj["user"]["value"])')
# [ "$USER_TAG" ] || ( echo "ERROR: USER_TAG is empty" && exit 1 )

# USER=$USER_TAG
ADMIN_PASS=admin123

# PROJECT_ID=$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (obj["project_id"]["value"])')
# [ "PROJECT_ID" ] || ( echo "ERROR: PROJECT_ID is empty" && exit 1 )

SSH_PUB_KEY_PATH="generated/controller.pub_key"
SSH_PRV_KEY_PATH="generated/controller.prv_key"

CTRL_PRV_IPS=$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (*obj["controller_private_ips"]["value"][0], sep=" ")') 
CTRL_PRV_DNS=$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (*obj["controller_private_dns"]["value"][0], sep=" ")') 
# CTRL_PRV_HOST=$(echo $CTRL_PRV_DNS | cut -d"." -f1)

GATW_PRV_IPS=$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (*obj["gateway_private_ips"]["value"][0], sep=" ")')
GATW_PUB_IPS=$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (*obj["gateway_public_ips"]["value"][0], sep=" ")')
GATW_PRV_DNS=$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (*obj["gateway_private_dns"]["value"][0], sep=" ")')
### getting only the first dns name for gateway
GATW_PUB_DNS=$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (obj["gateway_public_dns"]["value"])')
# GATW_PUB_HOST=$(echo $GATW_PUB_DNS | cut -d"." -f1)
# GATW_PRV_HOST=$(echo $GATW_PRV_DNS | cut -d"." -f1)

#### WORKERS
WORKER_COUNT=$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (obj["worker_count"]["value"], sep=" ")') 
WRKR_PRV_IPS=$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (*obj["workers_private_ip"]["value"][0], sep=" ")') 
#read -r -a WRKR_PRV_IPS <<< "$WRKR_PRV_IPS"

#### MAPR NODES
MAPR_COUNT=$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (obj["mapr_count"]["value"], sep=" ")') 
MAPR_PRV_IPS=$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (*obj["mapr_private_ips"]["value"][0], sep=" ")') 
#read -r -a WRKR_PRV_IPS <<< "$WRKR_PRV_IPS"

AD_PRV_IP=$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (obj["ad_server_private_ip"]["value"])')

### SYSTEM SETTINGS
source ./settings.sh 
# EPIC_DL_URL="$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (obj["epic_dl_url"]["value"])')"
# echo "${EPIC_DL_URL}"
EPIC_FILENAME="$(echo ${EPIC_DL_URL##*/})"
# echo ${EPIC_FILENAME}
EPIC_OPTIONS="--skipeula --default-password ${ADMIN_PASS}"

### USER SETTINGS
IS_VERBOSE=$(jq '.is_verbose // false' "${1}"/config.json)
IS_MLOPS=$(jq '.is_mlops // false' "${1}"/config.json)

ANSIBLE_CMD="ansible-playbook"
if [ ${IS_VERBOSE} ]; then
  ANSIBLE_CMD="${ANSIBLE_CMD} -v"
fi
