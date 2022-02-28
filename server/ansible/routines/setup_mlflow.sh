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

KUBEATNS=${1}
MLFLOW_ADMIN_PASSWORD=$(echo ${2} | base64)

export MLFLOW_CLUSTER_NAME=mlflow

###
### MLFLOW Secret
###
cat <<EOF_YAML | ${KUBEATNS} apply -f -
apiVersion: v1
data:
  MLFLOW_ARTIFACT_ROOT: czM6Ly9tbGZsb3c= #s3://mlflow
  AWS_ACCESS_KEY_ID: YWRtaW4= #admin
  AWS_SECRET_ACCESS_KEY: ${MLFLOW_ADMIN_PASSWORD}
kind: Secret
metadata:
  name: mlflow-sc
  labels:
    kubedirector.hpe.com/secretType: mlflow
type: Opaque
EOF_YAML

###
### MLFLOW Cluster
###

echo "Launching MLFLOW Cluster"
cat <<EOF_YAML | ${KUBEATNS} apply -f -
apiVersion: "kubedirector.hpe.com/v1beta1"
kind: "KubeDirectorCluster"
metadata:
  name: "$MLFLOW_CLUSTER_NAME"
  namespace: "${KUBEATNS##* }"
  labels:
    description: "mlflow"
spec:
  app: "mlflow"
  namingScheme: "CrNameRole"
  appCatalog: "local"
  connections:
    secrets:
      - mlflow-sc
  roles:
    -
      id: "controller"
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
      storage:
        size: "20Gi"
        storageClassName: "dfdemo"

      #Note: "if the application is based on hadoop3 e.g. using StreamCapabilities interface, then change the below dtap label to 'hadoop3', otherwise for most applications use the default 'hadoop2'"
      podLabels:
        hpecp.hpe.com/dtap: "hadoop2"
EOF_YAML

COUNTER=0
while [ $COUNTER -lt 30 ];
do
  STATE=$(${KUBEATNS} get kubedirectorcluster $MLFLOW_CLUSTER_NAME -o 'jsonpath={.status.state}')
  echo STATE=$STATE
  [[ $STATE == "configured" ]] && break
  sleep 60
  let COUNTER=COUNTER+1
done

### Following line is used as input for next run (though they could be hardcoded as we use mlflow as cluster name)
echo "${MLFLOW_CLUSTER_NAME}"
