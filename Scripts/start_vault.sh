#!/usr/bin/env bash

set -eo pipefail
VAULT_NAME=cerberus_manual_vault

# Stop the vault if it's running.
set +e; docker stop $VAULT_NAME &> /dev/null && docker container wait $VAULT_NAME > /dev/null; set -e

docker run -d -t -p 8200:8200 --name $VAULT_NAME --rm vault:0.8.2 > /dev/null
sleep 2 # wait for vault to startup
CONFIGURE_SCRIPT="${BASH_SOURCE%/*}/configure_fixture_vault.sh"
docker exec -i $VAULT_NAME /bin/sh - < $CONFIGURE_SCRIPT
