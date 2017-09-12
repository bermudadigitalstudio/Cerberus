# Cerberus

A Vault client in Swift (for Linux, obviously).

## Status
1. Connects to a running Vault
1. Get Vault sealed and health status
1. Set Vault token
1. Retrieve info about the current token.
1. Retrieve secret given unwrapped token (get generic secret)
1. Renew token (extend lease)
1. Get a token from an unwrapped `secret_id` and `role_id` (AppRole auth).
1. Automatic periodic token renewal

## Roadmap
1. Unwrapping secrets
1. Custom TLS support

### Postgres Secrets
TBD

### RabbitMQ Secrets
TBD

## Running the tests
> Required: Docker

Run `./Scripts/test.sh`.
The integration tests will spin up a Vault instance in one container, grab the credentials, and run the tests in another Linux container given the credentials.

## Development

`./Scripts/start_vault.sh` will spin up a Vault instance, expose it locally at port 8200 and configure it to the same state as used in integration tests. You can pass the variables printed to the unit tests, whether they are run in Xcode or on the command line.
