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
MLFLOW_CLUSTER_NAME=${2}
MLFLOW_ADMIN_PASSWORD=${3}

# echo Waiting for Notebook to have state==configured
COUNTER=0
while [ $COUNTER -lt 30 ];
do
  STATE=$(${KUBEATNS} get kubedirectorcluster $MLFLOW_CLUSTER_NAME -o 'jsonpath={.status.state}')
  echo STATE=$STATE
  [[ $STATE == "configured" ]] && break
  sleep 1m
  let COUNTER=COUNTER+1
done

if [[ $STATE != "configured" ]];
then
  echo "State is not configured after 30 minutes. Raising an error."
  exit 1
fi

## Minio get host/port

HOST=$(${KUBEATNS} get service -l kubedirector.hpe.com/kdcluster=$MLFLOW_CLUSTER_NAME \
-o jsonpath={.items[0].metadata.annotations.'hpecp-internal-gateway/9000'})

echo $HOST

## Minio create bucket

# export PYTHONPATH=~/.local/lib/python3.8/site-packages/
export PYTHONWARNINGS="ignore:Unverified HTTPS request"

pip3 install minio --user --quiet
pip3 install requests --user --quiet
python3 - <<PYTHON_EOF
from minio import Minio
from minio.error import S3Error
import urllib3
import sys
httpClient = urllib3.PoolManager(cert_reqs = 'CERT_NONE')
client = Minio(
  "$HOST",
  access_key="admin",
  secret_key="${MLFLOW_ADMIN_PASSWORD}",
  secure=True,
  http_client = httpClient
)
found = client.bucket_exists("mlflow")
if not found:
  client.make_bucket("mlflow")
  print("Created bucket 'mflow'")
else:
  print("Bucket 'mlflow' already exists")
PYTHON_EOF
