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

export KUBEATNS=${1}
export TENANT_NS=${KUBEATNS##* }
export HIVECLUSTERNAME=hivems
export SPARKHSCLUSTERNAME=sparkhs
export LIVYCLUSTERNAME=livy
export AD_USER_NAME=ad_user1 ### TODO: should come from user settings
export AD_USER_PASS=pass123

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
  sleep 60
  let COUNTER=COUNTER+1
done
date


###
### Spark History Server
###
cat <<EOF_YAML | ${KUBEATNS} apply -f -
---
apiVersion: "v1"
kind: "ConfigMap"
metadata:
  name: "${SPARKHSCLUSTERNAME}"
  namespace: "${TENANT_NS}"
  labels:
    kubedirector.hpe.com/cmType: "sparkhs312"
data:
  eventlogstorage: "true"
  kind: "pvc"
  pvcName: ""
  pvcStoragePath: "/mnt/hs-logs"
  storageSize: "10Gi"
  s3path: ""
  s3Endpoint: ""
  s3AccessKey: ""
  s3SecretKey: ""
  airgap: ""
  baserepository: ""
  imagename: ""
  tag: ""
  imagepullsecretname: ""
---
apiVersion: "kubedirector.hpe.com/v1beta1"
kind: "KubeDirectorCluster"
metadata:
  name: "${SPARKHSCLUSTERNAME}"
  namespace: "${TENANT_NS}"
  labels:
    description: "SparkHS"
spec:
  app: "sparkhs312"
  namingScheme: "CrNameRole"
  appCatalog: "local"
  connections:
    secrets:
      - ${AD_USER_KC_SECRET}
    configmaps:
      - ${SPARKHSCLUSTERNAME}
  roles:
    -
      id: "sparkhs312"
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
echo "Waiting for Spark History Server to have state==configured"

COUNTER=0
while [ $COUNTER -lt 30 ];
do
  STATE=$(${KUBEATNS} get kubedirectorcluster $SPARKHSCLUSTERNAME -o 'jsonpath={.status.state}')
  echo STATE=$STATE
  [[ $STATE == "configured" ]] && break
  sleep 60
  let COUNTER=COUNTER+1
done
date


# ###
# ### Livy Server
# ###
cat <<EOF_YAML | ${KUBEATNS} apply -f -
---
apiVersion: "v1"
kind: "ConfigMap"
metadata:
  name: "${LIVYCLUSTERNAME}"
  namespace: "${TENANT_NS}"
  labels:
    kubedirector.hpe.com/cmType: "livy070"
data:
  hivesitesource: ""
  sessionrecovery: "false"
  kind: ""
  pvcName: ""
  sparkhs: "true"
  integrate: "true"
  s_pvcname: "spark-hs-pvc"
  eventsdir: "file:///var/log/sparkhs-eventlog-storage"
  airgap: ""
  baserepository: ""
  imagename: ""
  tag: ""
  imagepullsecretname: ""
---
apiVersion: "kubedirector.hpe.com/v1beta1"
kind: "KubeDirectorCluster"
metadata:
  name: "${LIVYCLUSTERNAME}"
  namespace: "${TENANT_NS}"
  labels:
    description: "LivyServer"
spec:
  app: "livy070"
  namingScheme: "CrNameRole"
  appCatalog: "local"
  connections:
    secrets:
      - ${AD_USER_KC_SECRET}
    configmaps:
      - ${LIVYCLUSTERNAME}
  roles:
    -
      id: "livy"
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
echo "Waiting for Livy Server to have state==configured"

COUNTER=0
while [ $COUNTER -lt 30 ];
do
  STATE=$(${KUBEATNS} get kubedirectorcluster $LIVYCLUSTERNAME -o 'jsonpath={.status.state}')
  echo STATE=$STATE
  [[ $STATE == "configured" ]] && break
  sleep 60
  let COUNTER=COUNTER+1
done
date
