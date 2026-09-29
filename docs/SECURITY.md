# Security

## Files that must remain private

Do not publish:

```text
Ansible/secrets/secrets.yml
Ansible/.vault_pass
Ansible/buffer/tls.key
/opt/vault/init.file
Tofu/terraform.tfstate
Tofu/terraform.tfstate.backup
Tofu/.terraform/
```

The Vault initialization output can contain root/recovery/unseal material depending on the seal configuration and must be handled as a high-value secret.

## Azure auto-unseal secrets

The intended private Azure variables are:

- `tenant_id`
- `client_id`
- `client_secret`
- `vault_name`
- `key_name`

Only the example schema belongs in the public repository. Actual values should live in an Ansible Vault-encrypted file or another approved secret-management mechanism.

## TLS private key

The delivered lab distributes the same `tls.key` to all Vault nodes. This simplifies the portfolio lab, but the key must never be committed or left in an Ansible controller buffer inside the public repository.

## Keepalived authentication

The current Keepalived templates contain a static VRRP authentication value. Treat it as a lab placeholder and replace it for non-lab use.

## OpenTofu state

State can contain infrastructure details and possibly sensitive outputs. Public repositories should ignore state and use a remote/state backend appropriate to the environment.

## Source-control recommendations

At minimum, ignore:

```gitignore
Ansible/.vault_pass
Ansible/secrets/secrets.yml
Ansible/buffer/
Tofu/.terraform/
Tofu/*.tfstate
Tofu/*.tfstate.*
```

Do not commit credentials even if the repository is private unless the credential-storage design explicitly permits it.
