#!/usr/bin/env bash

set -exo pipefail

VAULT_NAME=$(docker run -d --rm vault:0.8.1)
finish () {
  docker stop $VAULT_NAME
}
trap finish EXIT
sleep 2 # wait for vault to startup

CONFIGURE_SCRIPT="${BASH_SOURCE%/*}/configure_fixture_vault.sh"
eval $(docker exec -i $VAULT_NAME /bin/sh - < "$CONFIGURE_SCRIPT") # Execute output

docker build -t cerberus-test ./

set +e
docker run --rm --link $VAULT_NAME:localhost -e ROOT_TOKEN -e PERIODIC_TOKEN -e ACCESSIBLE_SECRET_PATH cerberus-test \
  || {  set +x; echo -e "\033[0;31mTests exited with non-zero exit code\033[0m"; tput bel; exit 1; };

