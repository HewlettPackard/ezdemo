#!/usr/bin/env bash

# command -v az || curl -L https://aka.ms/InstallAzureCli | bash

SUBSCRIPTION_ID=`az account list --query "[].{sub:id}" -o tsv`

[[ -f azure.json ]] || {
  az login
  az account set --subscription="${SUBSCRIPTION_ID}"
  az ad sp create-for-rbac --role="Contributor" --scopes="/subscriptions/${SUBSCRIPTION_ID}" -o json | jq --arg subscription ${SUBSCRIPTION_ID} '. + {subscription: $subscription}'
}
