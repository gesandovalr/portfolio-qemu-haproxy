# Azure Key Vault Auto-Unseal

## Status in this repository

Azure Key Vault auto-unseal is a **prepared extension**, not an active feature in the delivered templates.

The `vault_install` role already loads a private file:

```yaml
include_vars: "secrets/secrets.yml"
```

The intended private structure is:

```yaml
secret:
  tenant_id: "00000000-0000-0000-0000-000000000000"
  client_id: "00000000-0000-0000-0000-000000000000"
  client_secret: "REPLACE_WITH_PRIVATE_VALUE"
  vault_name: "azure-keyvault"
  key_name: "azure-keyvault"
```

`secrets.yml` must remain private and is intentionally not included in the public project package.

## Intended Vault stanza

To activate Azure Key Vault auto-unseal using those private Ansible variables, the Vault HCL templates would need a seal stanza equivalent to:

```hcl
seal "azurekeyvault" {
  tenant_id     = "{{ secret.tenant_id }}"
  client_id     = "{{ secret.client_id }}"
  client_secret = "{{ secret.client_secret }}"
  vault_name    = "{{ secret.vault_name }}"
  key_name      = "{{ secret.key_name }}"
}
```

This stanza is **not present** in the current `kvnode01_vault_hcl.j2`, `kvnode02_vault_hcl.j2`, or `kvnode03_vault_hcl.j2` files.

## HashiCorp behavior

HashiCorp Vault supports Azure Key Vault as an auto-unseal mechanism. The Azure seal can be configured in the HCL file or by environment variables. Required values include the Azure tenant, client credentials (unless using an Azure managed identity), Key Vault name, and key name.

Official reference:

- https://developer.hashicorp.com/vault/docs/configuration/seal/azurekeyvault
- https://developer.hashicorp.com/vault/tutorials/auto-unseal/autounseal-azure-keyvault

## Initialization difference

With cloud/KMS auto-unseal enabled before first initialization, Vault produces recovery keys rather than standard Shamir unseal keys. The current role runs `vault operator init` without special flags; Vault chooses the appropriate initialization behavior based on the configured seal.

Official reference:

- https://developer.hashicorp.com/vault/docs/commands/operator/init
- https://developer.hashicorp.com/vault/docs/concepts/seal

## Important migration warning

Do not add or remove a seal stanza casually on an already initialized Vault cluster. Changing an existing cluster from Shamir to auto-unseal is a seal migration operation and should be preceded by a Raft snapshot and a documented migration procedure.

## Credential handling

For this local QEMU/KVM lab, Azure service-principal credentials would have to be supplied securely to Vault. The repository design keeps them in an Ansible Vault-encrypted `secrets.yml` that is excluded from source control.

For Vault hosted directly in Azure, HashiCorp recommends managed identity where possible so static client secrets do not need to be stored in Vault configuration.
