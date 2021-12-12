#!/usr/bin/env bash

set -euo pipefail

KUBEATNS="${1}"

cat <<EOF_YAML | ${KUBEATNS} apply -f -
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: gitea
  labels:
    app: gitea
spec:
  replicas: 1
  selector:
    matchLabels:
      app: gitea
  template:
    metadata:
      labels:
        app: gitea
    spec:
      containers:
      - name: gitea
        image: gitea/gitea:1.14.2
        ports:
        - containerPort: 3000
          name: gitea
        - containerPort: 22
          name: git-ssh
        volumeMounts:
        - mountPath: /data
          name: git-data
        resources:
            limits:
                cpu:      2
                memory:   4Gi
      volumes:
      - name: git-data
        persistentVolumeClaim:
          claimName: gitea-pvc

---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: gitea-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
      
---
kind: Service
apiVersion: v1
metadata:
  name: gitea-service
  labels:
    hpecp.hpe.com/hpecp-internal-gateway: "true"
spec:
  selector:
    app: gitea
  ports:
  - name: http
    port: 3000
  - name: ssh
    port: 22
  type: NodePort

EOF_YAML

while [[ $(${KUBEATNS} get pods -l app=gitea -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do 
  echo "waiting for pod" && sleep 1
done

POD=$(${KUBEATNS} get pods -l app=gitea --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
echo POD=$POD
# while [[ ${KUBEATNS} \
#   get pods $POD -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do echo "waiting for pod" && sleep 1; done

EXTERNAL_URL=$(${KUBEATNS} get service gitea-service \
  -o 'jsonpath={..annotations.hpecp-internal-gateway/3000}')
# echo EXTERNAL_URL=$EXTERNAL_URL
  
EXTERNAL_URL_ESC=$(echo "http://$EXTERNAL_URL" | python3 -c "import urllib.parse;print (urllib.parse.quote(input()))")
# perl -MURI::Escape -wlne 'print uri_escape $_')
# echo EXTERNAL_URL_ESC=$EXTERNAL_URL_ESC

EXTERNAL_HOSTNAME=$(echo $EXTERNAL_URL | cut -d ':' -f 1)
# echo EXTERNAL_HOSTNAME=$EXTERNAL_HOSTNAME

URL_DATA="db_type=SQLite3&db_host=localhost%3A3306&db_user=root&db_passwd=&db_name=gitea&ssl_mode=disable&db_schema=&charset=utf8&db_path=%2Fdata%2Fgitea%2Fgitea.db&app_name=Gitea%3A+Git+with+a+cup+of+tea&repo_root_path=%2Fdata%2Fgit%2Frepositories&lfs_root_path=%2Fdata%2Fgit%2Flfs&run_user=git&domain=$EXTERNAL_HOSTNAME&ssh_port=22&http_port=3000&app_url=$EXTERNAL_URL_ESC&log_root_path=%2Fdata%2Fgitea%2Flog&smtp_host=&smtp_from=&smtp_user=&smtp_passwd=&enable_federated_avatar=on&no_reply_address=&password_algorithm=pbkdf2&admin_name=&admin_passwd=&admin_confirm_passwd=&admin_email="
# echo URL_DATA=$URL_DATA
echo "stage 2"

${KUBEATNS} exec $POD -- \
  curl -s -d $URL_DATA http://localhost:3000

${KUBEATNS} exec $POD -- \
  su git -c 'gitea admin user create --username "administrator" --password "admin123" --email "admin@samdom.example.com" --admin --must-change-password=false' || true

${KUBEATNS} exec $POD -- \
  su git -c 'gitea admin user create --username "ad_admin1" --password "pass123" --email "ad_admin1@samdom.example.com" --must-change-password=false' || true

${KUBEATNS} exec $POD -- \
  su git -c 'gitea admin user create --username "ad_user1" --password "pass123" --email "ad_user1@samdom.example.com" --must-change-password=false' || true

${KUBEATNS} exec $POD -- \
  su git -c 'rm -rf /tmp/gatekeeper-library'
  
${KUBEATNS} exec $POD -- \
  su git -c 'gitea dump-repo --git_service github --clone_addr https://github.com/riteshja/gatekeeper-library --units issues,labels --repo_dir /tmp/gatekeeper-library'

# WORKAROUND FOR: [F] Failed to restore repository: open /tmp/gatekeeper-library/topic.yml: no such file or directory
${KUBEATNS} exec $POD -- \
  su git -c 'touch /tmp/gatekeeper-library/topic.yml'

${KUBEATNS} exec $POD -- \
  su git -c 'gitea restore-repo --repo_dir /tmp/gatekeeper-library --owner_name administrator --units issues,labels --repo_name gatekeeper-library' || true

###### ad_user1 repo
${KUBEATNS} exec $POD -- \
  su git -c 'rm -rf /tmp/jupyter-demo'

${KUBEATNS} exec $POD -- \
  su git -c 'gitea dump-repo --git_service github --clone_addr https://github.com/snowch/jupyter-demo --units issues,labels --repo_dir /tmp/jupyter-demo'

# WORKAROUND FOR: [F] Failed to restore repository: open /tmp/gatekeeper-library/topic.yml: no such file or directory
${KUBEATNS} exec $POD -- \
  su git -c 'touch /tmp/jupyter-demo/topic.yml'

${KUBEATNS} exec $POD -- \
  su git -c 'gitea restore-repo --repo_dir /tmp/jupyter-demo --owner_name ad_user1 --units issues,labels --repo_name jupyter-demo' || true

cat <<EOF_YAML | ${KUBEATNS} apply -f -
---
apiVersion: v1
stringData:
  authType: password #either of token or password. If token is selected, fill "token" field with token, otherwise "password" with password
  #token: my-github-token # fill this if authType is chosen as "token"
  password: $(echo -n pass123 | base64) # fill this if authType is chosen as "password" - base64 encoded
  branch: master  
  email: ad_user1@samdom.example.com
  repoURL: http://$EXTERNAL_URL/ad_user1/jupyter-demo.git  
  type: github   #either of "bitbucket" or "github"
  username: ad_user1 
  #proxyHostname: web-proxy.hpe.net #optional 
  #proxyPort: "8080" #optional 
  #proxyProtocol: http #http or https (optional)
kind: Secret
metadata:
  name: hpecp-sc-secret-gitea-ad-user1-nb
  labels:
    kubedirector.hpe.com/secretType: source-control
type: Opaque
EOF_YAML
