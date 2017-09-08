#!/usr/bin/env bash

set -eo pipefail
VAULT_NAME=cerberus_manual_vault
export VAULT_ADDR=http://localhost:8200

# Stop the vault if it's running.
set +e; docker stop $VAULT_NAME > /dev/null; set -e

docker run -d -p 8200:8200 --name $VAULT_NAME --rm vault:0.8.1 > /dev/null
sleep 2 # wait for vault to startup

# Get the root token
ROOT_TOKEN=$(docker exec ${VAULT_NAME} cat /home/vault/.vault-token)
export VAULT_TOKEN=$ROOT_TOKEN

# Write a secret
ACCESSIBLE_SECRET_PATH=cerberus/something/something-policy/my_special_secret # defined in `narrow_policy.hcl`
vault write secret/$ACCESSIBLE_SECRET_PATH secret="this is a very secret thing but it is the only thing you can read" > /dev/null

# Configure a policy
# Create a Vault policy allowing the periodic token to read just this one secret

POLICY_NAME=narrow-policy-cerberus-test
POLICY_FILE="${BASH_SOURCE%/*}/narrow_policy.hcl"
vault policy-write $POLICY_NAME $POLICY_FILE > /dev/null
PERIODIC_TOKEN=$(vault token-create -policy=$POLICY_NAME -format=json -period=86400 | jq -r .auth.client_token)

echo "Root Token: $ROOT_TOKEN"
echo "Periodic Token: $PERIODIC_TOKEN"
echo "Secret with key 'secret' stored at path: $ACCESSIBLE_SECRET_PATH"
