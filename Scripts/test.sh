#!/usr/bin/env bash

set -exo pipefail
VAULT_NAME=cerberus_test_vault
finish () {
  docker stop $VAULT_NAME
}
trap finish EXIT

export VAULT_ADDR=http://localhost:8201

# Stop the vault if it's running.
set +e; docker stop $VAULT_NAME > /dev/null; set -e

docker run -d -p 8201:8200 --name $VAULT_NAME --rm vault:0.8.1 > /dev/null
sleep 2 # wait for vault to startup

# Get the root token
export ROOT_TOKEN=$(docker exec ${VAULT_NAME} cat /home/vault/.vault-token)
export VAULT_TOKEN=$ROOT_TOKEN

# Write a secret
export ACCESSIBLE_SECRET_PATH=cerberus/something/something-policy/my_special_secret # defined in `narrow_policy.hcl`
vault write secret/$ACCESSIBLE_SECRET_PATH secret="this is a very secret thing but it is the only thing you can read" > /dev/null

# Configure a policy
# Create a Vault policy allowing the periodic token to read just this one secret

POLICY_NAME=narrow-policy-cerberus-test
POLICY_FILE="${BASH_SOURCE%/*}/narrow_policy.hcl"
vault policy-write $POLICY_NAME $POLICY_FILE > /dev/null
export PERIODIC_TOKEN=$(vault token-create -policy=$POLICY_NAME -format=json -period=86400 | jq -r .auth.client_token)

docker build -t cerberus-test ./

set +e
docker run --rm --link $VAULT_NAME:localhost -e ROOT_TOKEN -e PERIODIC_TOKEN -e ACCESSIBLE_SECRET_PATH cerberus-test \
  || {  set +x; echo -e "\033[0;31mTests exited with non-zero exit code\033[0m"; tput bel; exit 1; };

