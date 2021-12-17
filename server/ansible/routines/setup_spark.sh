#!/usr/bin/env bash

set -euo pipefail

export KUBEATNS=${1}
export TENANT_NS=${KUBEATNS##* }
export HIVECLUSTERNAME=hivems
# export NB_CLUSTER_NAME=nb
# export MLFLOW_CLUSTER_NAME=mlflow
# export TRAINING_CLUSTER_NAME=trainingengineinstance
export AD_USER_NAME=ad_user1
export AD_USER_PASS=pass123

# PROFILE=tenant HPECP_CONFIG_FILE=~/.hpecp_tenant.conf hpecp tenant k8skubeconfig

export AD_USER_ID=$(hpecp user list --query "[?label.name=='$AD_USER_NAME'] | [0] | [_links.self.href]" --output text | cut -d '/' -f 5 | sed '/^$/d')
export AD_USER_SECRET_HASH=$(python3 -c "import hashlib; print(hashlib.md5('$AD_USER_ID-$AD_USER_NAME'.encode('utf-8')).hexdigest())")
export AD_USER_KC_SECRET="hpecp-kc-secret-$AD_USER_SECRET_HASH"


###
### Hive Metastore
###
cat <<EOF_YAML | ${KUBEATNS} apply -f -
---
apiVersion: "v1"
kind: "ConfigMap"
metadata: 
  name: "${HIVECLUSTERNAME}"
  namespace: "${TENANT_NS}"
  labels: 
    kubedirector.hpe.com/cmType: "hivemetastore238"
data: 
  mysqlDB: "false"
  mysql_host: ""
  mysql_user: ""
  #Note: "Provide mysql_password as Base64-encoded value in Yaml."
  mysql_password: ""
  airgap: ""
  baserepository: ""
  imagename: ""
  tag: ""
  imagepullsecretname: ""
---
apiVersion: "kubedirector.hpe.com/v1beta1"
kind: "KubeDirectorCluster"
metadata: 
  name: "${HIVECLUSTERNAME}"
  namespace: "${TENANT_NS}"
  labels: 
    description: ""
spec: 
  app: "hivemetastore238"
  namingScheme: "CrNameRole"
  appCatalog: "local"
  connections: 
    secrets: 
      - ${AD_USER_KC_SECRET}
    configmaps: 
      - "${HIVECLUSTERNAME}"
  roles: 
    - 
      id: "hivemetastore"
      members: 1
      serviceAccountName: "ecp-tenant-member-sa"
      resources: 
        requests: 
          cpu: "2"
          memory: "8Gi"
          nvidia.com/gpu: "0"
        limits: 
          cpu: "2"
          memory: "8Gi"
          nvidia.com/gpu: "0"
      #Note: "if the application is based on hadoop3 e.g. using StreamCapabilities interface, then change the below dtap label to 'hadoop3', otherwise for most applications use the default 'hadoop2'"
      #podLabels: 
        #hpecp.hpe.com/dtap: "hadoop2"
EOF_YAML

date
echo "Waiting for Hive Metastore to have state==configured"
  
COUNTER=0
while [ $COUNTER -lt 30 ]; 
do
  STATE=$(${KUBEATNS} get kubedirectorcluster $HIVECLUSTERNAME -o 'jsonpath={.status.state}')
  echo STATE=$STATE
  [[ $STATE == "configured" ]] && break
  sleep 1m
  let COUNTER=COUNTER+1 
done
date

