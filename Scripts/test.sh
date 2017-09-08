#!/usr/bin/env bash

set -exo pipefail
docker build -t cerberus-test ./

VAULT_NAME=$(docker run -d --rm vault:0.8.1)
finish () {
  docker stop $VAULT_NAME
}
trap finish EXIT
sleep 2;

export ROOT_TOKEN=$(docker exec ${VAULT_NAME} cat /home/vault/.vault-token)

export PERIODIC_TOKEN=$(docker exec -e VAULT_TOKEN=${ROOT_TOKEN} -e VAULT_ADDR=${VAULT_ADDR} ${VAULT_NAME} vault token-create -policy=default -format=json -period=600s | jq -r .auth.client_token)

set +e
docker run --rm --link $VAULT_NAME:localhost -e ROOT_TOKEN -e PERIODIC_TOKEN cerberus-test \
  || {  set +x; echo -e "\033[0;31mTests exited with non-zero exit code\033[0m"; tput bel; exit 1; };

