#!/usr/bin/env bash

set -eo pipefail

VAULT_NAME=cerberus_manual_vault
docker stop $VAULT_NAME
