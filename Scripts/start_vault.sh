#!/usr/bin/env bash

set -eo pipefail
VAULT_NAME=cerberus_manual_vault
docker run -d -p 8200:8200 --name $VAULT_NAME --rm vault:0.8.1
sleep 2
ROOT_TOKEN=$(docker exec ${VAULT_NAME} cat /home/vault/.vault-token)
LIMITED_TOKEN=$(docker exec -e VAULT_TOKEN=${ROOT_TOKEN} ${VAULT_NAME} vault token-create -address=http://localhost:8200 -policy=default -format=json | jq -r .auth.client_token)

echo "Root Token: $ROOT_TOKEN"
echo "Limited Token: $LIMITED_TOKEN"
