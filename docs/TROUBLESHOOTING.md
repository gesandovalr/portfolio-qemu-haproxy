# Troubleshooting

## OpenTofu waits forever for SSH

Check that:

- every VM IP in `VMS` is reachable from the controller
- TCP/22 is open
- cloud-init applied the expected static address
- the configured libvirt network routes to the controller

## Ansible configuration not found

The delivered OpenTofu command references `Ansible/config/ansible.cfg`, but the uploaded file is `Ansible/ansible.cfg`. Correct the path before deployment.

## Missing Ansible collection

Active roles use `community.crypto` and `ansible.posix`, while the delivered `requirements.yml` contains only `ansible.mysql`. If module resolution fails, install/add the collections required by the active roles.

## Certificate-generation task is skipped

Several role conditions compare `ansible_hostname` against FQDN variables such as `node_01_fqdn`. Confirm what `ansible_hostname` resolves to in your environment and that it matches the configured comparison values.

## Vault does not start

Check:

```bash
journalctl -u vault -n 200 --no-pager
vault status
```

Then verify:

- `/etc/vault.d/vault.hcl` syntax
- ownership/SELinux context
- TLS file presence and permissions
- DNS/FQDN resolution
- ports 8200 and 8201

## Raft node does not join

Check connectivity to every `retry_join` endpoint, TLS trust, DNS resolution, and whether the first Vault node has already been initialized.

## Keepalived does not hold the VIP

Check:

```bash
systemctl status keepalived
journalctl -u keepalived -n 200 --no-pager
/usr/libexec/keepalived/vault-health https://localhost:8200/v1/sys/health
echo $?
```

The delivered health script considers only HTTP 200 healthy.

## Azure auto-unseal does not activate

The active templates do not yet contain `seal "azurekeyvault"`. Merely defining values in `secrets.yml` does not enable auto-unseal. The seal stanza (or corresponding environment variables) must be configured before Vault starts.

Do not retrofit auto-unseal to an initialized cluster without following a seal-migration procedure.
