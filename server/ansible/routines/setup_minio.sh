## Minio wait-for mlflow

set -euo pipefail

KUBEATNS=${1}
MLFLOW_CLUSTER_NAME=${2}

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

HOST_AND_PORT=$(${KUBEATNS} get service -l kubedirector.hpe.com/kdcluster=$MLFLOW_CLUSTER_NAME \
-o jsonpath={.items[0].metadata.annotations.'hpecp-internal-gateway/9000'})

echo $HOST_AND_PORT

## Minio create bucket

export PYTHONPATH=$PYTHONPATH:~/.local/lib/python3.6/site-packages/
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
  secret_key="admin123",
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
