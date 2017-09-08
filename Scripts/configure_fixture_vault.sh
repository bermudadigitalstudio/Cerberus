#!/usr/bin/env sh
# Run this script inside a running vault container to configure it for tests

export VAULT_ADDR=http://localhost:8200
export VAULT_TOKEN=$(cat /home/vault/.vault-token)

ACCESSIBLE_SECRET_PATH=cerberus/something/something-policy/my_special_secret # defined in `narrow_policy.hcl`
POLICY_NAME=narrow-policy-cerberus-test

vault policy-write $POLICY_NAME - > /dev/null <<EOF
path "secret/cerberus/something/something-policy/my_special_secret" {
  capabilities = ["read"]
}
EOF

vault write secret/$ACCESSIBLE_SECRET_PATH secret="this is a very secret thing but it is the only thing you can read" > /dev/null

PERIODIC_TOKEN=$(vault token-create -policy=$POLICY_NAME -period=86400 | grep "token " | sed 's/token[[:space:]]*//')
printf "export ROOT_TOKEN=$VAULT_TOKEN PERIODIC_TOKEN=$PERIODIC_TOKEN ACCESSIBLE_SECRET_PATH=$ACCESSIBLE_SECRET_PATH\n"

