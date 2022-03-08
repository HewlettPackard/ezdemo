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
export K8SCLUSTER="dfcluster"
export NB_CLUSTER_NAME=nb
export MLFLOW_CLUSTER_NAME=mlflow
export TRAINING_CLUSTER_NAME=trainingengineinstance
export AD_USER_NAME=ad_user1
export AD_USER_PASS=pass123

# PROFILE=tenant HPECP_CONFIG_FILE=~/.hpecp_tenant.conf hpecp tenant k8skubeconfig

export AD_USER_ID=$(hpecp user list --query "[?label.name=='$AD_USER_NAME'] | [0] | [_links.self.href]" --output text | cut -d '/' -f 5 | sed '/^$/d')
export AD_USER_SECRET_HASH=$(python3 -c "import hashlib; print(hashlib.md5('$AD_USER_ID-$AD_USER_NAME'.encode('utf-8')).hexdigest())")
export AD_USER_KC_SECRET="hpecp-kc-secret-$AD_USER_SECRET_HASH"

# ${KUBEATNS} get secret $AD_USER_KC_SECRET
# if [[ \$? == 0 ]]; then
#   echo "Secret $AD_USER_KC_SECRET exists - removing"

## remove if exist
${KUBEATNS} delete secret $AD_USER_KC_SECRET || true

# fi
# set -e

export AD_USER_KUBECONFIG="$(PROFILE=tenant HPECP_CONFIG_FILE=~/.hpecp_tenant.conf hpecp tenant k8skubeconfig | base64 -w 0)"
export DATA_BASE64=$(base64 -w 0 <<END
{
  "data": {
    "config": "$AD_USER_KUBECONFIG"
  },
  "kind": "Secret",
  "apiVersion": "v1",
  "metadata": {
    "labels": {
      "kubedirector.hpe.com/username": "$AD_USER_NAME",
      "kubedirector.hpe.com/userid": "$AD_USER_ID",
      "kubedirector.hpe.com/secretType": "kubeconfig"
    },
    "namespace": "${TENANT_NS}",
    "name": "$AD_USER_KC_SECRET"
  }
}
END
)

CLUSTER_ID=$(hpecp k8scluster list -o text | grep ${K8SCLUSTER} | cut -d' ' -f1)
PROFILE=tenant HPECP_CONFIG_FILE=~/.hpecp_tenant.conf hpecp httpclient post $CLUSTER_ID/kubectl <(echo -n '{"data":"'$DATA_BASE64'","op":"create"}')

###
### Training Cluster
###

echo "Launching Training Cluster"
cat <<EOF_YAML | ${KUBEATNS} apply -f -
apiVersion: "kubedirector.hpe.com/v1beta1"
kind: "KubeDirectorCluster"
metadata:
  name: "${TRAINING_CLUSTER_NAME}"
  namespace: "${TENANT_NS}"
  labels:
    description: ""
spec:
  app: "training-engine"
  namingScheme: "CrNameRole"
  appCatalog: "local"
  connections:
    secrets:
      - ${AD_USER_KC_SECRET}
      - hpecp-ext-auth-secret
  roles:
    -
      id: "LoadBalancer"
      members: 1
      resources:
        requests:
          cpu: "2"
          memory: "4Gi"
          nvidia.com/gpu: "0"
        limits:
          cpu: "2"
          memory: "4Gi"
          nvidia.com/gpu: "0"
      #Note: "if the application is based on hadoop3 e.g. using StreamCapabilities interface, then change the below dtap label to 'hadoop3', otherwise for most applications use the default 'hadoop2'"
      podLabels:
        hpecp.hpe.com/dtap: "hadoop2"
    -
      id: "RESTServer"
      members: 1
      resources:
        requests:
          cpu: "2"
          memory: "4Gi"
          nvidia.com/gpu: "0"
        limits:
          cpu: "2"
          memory: "4Gi"
          nvidia.com/gpu: "0"
      #Note: "if the application is based on hadoop3 e.g. using StreamCapabilities interface, then change the below dtap label to 'hadoop3', otherwise for most applications use the default 'hadoop2'"
      podLabels:
        hpecp.hpe.com/dtap: "hadoop2"
EOF_YAML

date
echo "Waiting for Training to have state==configured"

COUNTER=0
while [ $COUNTER -lt 30 ];
do
  STATE=$(${KUBEATNS} get kubedirectorcluster $TRAINING_CLUSTER_NAME -o 'jsonpath={.status.state}')
  echo STATE=$STATE
  [[ $STATE == "configured" ]] && break
  sleep 1m
  let COUNTER=COUNTER+1
done
date

###
### Jupyter Notebook
###

export AD_USER_ID=$AD_USER_ID

echo "Launching Jupyter Notebook as '$AD_USER_NAME' user ($AD_USER_ID)"
cat <<EOF_YAML | ${KUBEATNS} apply -f -
apiVersion: "kubedirector.hpe.com/v1beta1"
kind: "KubeDirectorCluster"
metadata:
  name: "$NB_CLUSTER_NAME"
  namespace: "$TENANT_NS"
  labels:
    "kubedirector.hpe.com/createdBy": "$AD_USER_ID"
spec:
  app: "jupyter-notebook"
  namingScheme: "CrNameRole"
  appCatalog: "local"
  connections:
    clusters:
      - $MLFLOW_CLUSTER_NAME
      - $TRAINING_CLUSTER_NAME
    secrets:
      - hpecp-sc-secret-gitea-ad-user1-nb
      - hpecp-ext-auth-secret
      - mlflow-sc
      - $AD_USER_KC_SECRET
  roles:
    -
      id: "controller"
      members: 1
      serviceAccountName: "ecp-tenant-member-sa"
      resources:
        requests:
          cpu: "2"
          memory: "4Gi"
          nvidia.com/gpu: "0"
        limits:
          cpu: "2"
          memory: "4Gi"
          nvidia.com/gpu: "0"
      storage:
        # size: "20Gi"
        # storageClassName: "dfdemo"
      #Note: "if the application is based on hadoop3 e.g. using StreamCapabilities interface, then change the below dtap label to 'hadoop3', otherwise for most applications use the default 'hadoop2'"
      podLabels:
        hpecp.hpe.com/dtap: "hadoop2"
EOF_YAML

# ./bin/ssh_rdp_linux_server.sh rm -rf static/
# ./bin/ssh_rdp_linux_server.sh mkdir static/

# for FILE in $(ls -1 static/*)
# do
#   cat $FILE | ./bin/ssh_rdp_linux_server.sh "cat > $FILE"
# done


date
echo "Waiting for Notebook to have state==configured"

COUNTER=0
while [ $COUNTER -lt 180 ];
do
  STATE=$(${KUBEATNS} get kubedirectorcluster $NB_CLUSTER_NAME -o 'jsonpath={.status.state}')
  echo STATE=$STATE
  [[ $STATE == "configured" ]] && break
  sleep 1m
  let COUNTER=COUNTER+1
done
date

###########
# Retrieve the notebook pod
###########

POD=$(${KUBEATNS} get pod -l kubedirector.hpe.com/kdcluster=$NB_CLUSTER_NAME -o 'jsonpath={.items..metadata.name}')

echo TENANT_NS=$TENANT_NS
echo POD=$POD

###########
## Setup notebook service-account-token
###########

HPECP_VERSION=$(hpecp config get --query 'objects.[bds_global_version]' --output text)

if [[ "$HPECP_VERSION" == *"5.4"*  ]]; then

  set -x

  SECRET_NAME=$(${KUBEATNS} get secret --field-selector type=kubernetes.io/service-account-token | grep '\-sa\-' | cut -f 1 -d' ')
  echo SECRET_NAME=$SECRET_NAME

  # Extract and decode
  # ${KUBEATNS} get secret $SECRET_NAME -o yaml | grep " token:" | awk '{print $2}' | base64 -d > token

  # FIXME

  # Put the token file in your nb pod
  # kubectl --kubeconfig <(hpecp k8scluster --id $CLUSTER_ID admin-kube-config) \
  #   cp token -c app \$POD:/var/run/secrets/kubernetes.io/serviceaccount/token -n $TENANT_NS

fi

###########
# create home folders
###########

TENANT_USER=ad_user1

echo "Login to notebook to create home folders for ${TENANT_USER}"

${KUBEATNS} exec -c app $POD -- sudo su - ${TENANT_USER}

echo "Copying example files to notebook pods"

# for FILE in \$(ls -1 ./static/*)
# do
#   BASEFILE=\$(basename \$FILE)
#   kubectl --kubeconfig <(hpecp k8scluster --id $CLUSTER_ID admin-kube-config) \
#     cp --container app \$FILE $TENANT_NS/\$POD:/home/\${TENANT_USER}/\${BASEFILE}

#   kubectl --kubeconfig <(hpecp k8scluster --id $CLUSTER_ID admin-kube-config) \
#     exec -c app -n $TENANT_NS \$POD -- chown ad_user1:domain\\ users /home/\${TENANT_USER}/\${BASEFILE}

#   if [[ "\${BASEFILE##*.}" == ".sh" ]]; then
#     kubectl --kubeconfig <(hpecp k8scluster --id $CLUSTER_ID admin-kube-config) \
#       exec -c app -n $TENANT_NS \$POD -- chmod +x /home/\${TENANT_USER}/\${BASEFILE}
#   fi
# done

echo "Adding pytest and nbval python libraries for testing"

${KUBEATNS} exec -c app $POD -- sudo -E -u ${TENANT_USER} /opt/miniconda/bin/pip3 install --user --quiet --no-warn-script-location pytest nbval

echo "Setup HPECP CLI as admin user"

${KUBEATNS} cp --container app ~/.hpecp_tenant.conf $TENANT_NS/$POD:/home/${TENANT_USER}/.hpecp.conf

${KUBEATNS} exec -c app $POD -- chown ad_user1:root /home/${TENANT_USER}/.hpecp.conf

${KUBEATNS} exec -c app $POD -- chmod 600 /home/${TENANT_USER}/.hpecp.conf

${KUBEATNS} exec -c app $POD -- sudo -E -u ${TENANT_USER} /opt/miniconda/bin/pip3 install --user --quiet --no-warn-script-location hpecp
