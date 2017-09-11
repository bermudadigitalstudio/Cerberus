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

# Periodic token that can read the secret
PERIODIC_TOKEN=$(vault token-create -policy=$POLICY_NAME -period=86400 | grep "token " | sed 's/token[[:space:]]*//')

# Create an approle backend
ROLE_NAME=integration-tests

vault auth-enable approle > /dev/null
vault write auth/approle/role/$ROLE_NAME policies=$POLICY_NAME > /dev/null
ROLE_ID=$(vault read -field=role_id auth/approle/role/$ROLE_NAME/role-id)
SECRET_ID=$(vault write -f -field=secret_id auth/approle/role/$ROLE_NAME/secret-id)

# Enable auditing with no hashing so we can debug the tests
vault audit-enable file file_path=stdout log_raw=true > /dev/null
printf "export ROOT_TOKEN=$VAULT_TOKEN PERIODIC_TOKEN=$PERIODIC_TOKEN ACCESSIBLE_SECRET_PATH=$ACCESSIBLE_SECRET_PATH ROLE_ID=$ROLE_ID SECRET_ID=$SECRET_ID\n"

