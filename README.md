# Cerberus

A Vault client in Swift (for Linux, obviously).

## Status
1. Connects to a running Vault
  - no support for custom TLS
1. Get Vault sealed and health status
1. Set Vault token
1. Retrieve info about the current token.

## Roadmap
1. Retrieve secret given unwrapped token (get generic secret)
2. Renew secret (get new generic secret)
3. Renew token (extend lease)
4. Get a token from an unwrapped `secret_id` and `role_id` (AppRole auth).
5. Unwrap a wrapped token/secret.

### Postgres Secrets
### RabbitMQ Secrets

## Running the tests
> Required: Docker and `jq`.

Run `./Scripts/test.sh`.
The integration tests will spin up a Vault instance in one container, grab the credentials, and run the tests in another Linux container given the credentials.
