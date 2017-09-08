#!/usr/bin/env bash

set -eo pipefail
VAULT_NAME=cerberus_manual_vault
VAULT_ADDR=http://localhost:8200

docker run -d -p 8200:8200 --name $VAULT_NAME --rm vault:0.8.1
sleep 2 # wait for vault to startup

# Get the root token
ROOT_TOKEN=$(docker exec ${VAULT_NAME} cat /home/vault/.vault-token)

PERIODIC_TOKEN=$(docker exec -e VAULT_TOKEN=${ROOT_TOKEN} -e VAULT_ADDR=${VAULT_ADDR} ${VAULT_NAME} vault token-create -policy=default -format=json -period=600s | jq -r .auth.client_token)

echo "Root Token: $ROOT_TOKEN"
echo "Periodic Token: $PERIODIC_TOKEN"
