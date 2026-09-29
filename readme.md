# HashiCorp Vault Raft Cluster on QEMU/KVM

Automated three-node HashiCorp Vault lab built with OpenTofu, libvirt/QEMU/KVM, cloud-init, and Ansible. The project provisions AlmaLinux virtual machines, configures a Vault Integrated Storage (Raft) cluster, creates a private TLS certificate set, distributes it to every Vault node, and provides a Keepalived virtual IP for client access.

The repository is designed as a portfolio lab showing infrastructure provisioning, configuration management, TLS, high availability, and a path toward Azure Key Vault auto-unseal.

## Architecture

| Component | Value |
| --- | --- |
| Hypervisor | QEMU/KVM through libvirt |
| IaC | OpenTofu |
| Configuration | Ansible |
| Guest OS | AlmaLinux 9 golden QCOW2 image |
| Vault storage | Integrated Storage (Raft) |
| Vault API | TCP/8200 with TLS |
| Vault cluster traffic | TCP/8201 with TLS |
| HA endpoint | Keepalived VIP `10.20.10.13` |
| Nodes | `HCKVTEST01`, `HCKVTEST02`, `HCKVTEST03` |

### Lab addressing

| Node | Address | Purpose |
| --- | --- | --- |
| HCKVTEST01 | `10.20.10.10` | Vault/Raft node 1 and initial certificate source |
| HCKVTEST02 | `10.20.10.11` | Vault/Raft node 2 |
| HCKVTEST03 | `10.20.10.12` | Vault/Raft node 3 |
| Cluster VIP | `10.20.10.13` | Keepalived client endpoint |

## Deployment flow

```text
OpenTofu
  |
  +-- clone AlmaLinux QCOW2 disks
  +-- create cloud-init ISO per VM
  +-- configure static networking and SSH key
  +-- create three libvirt/QEMU domains
  +-- wait for TCP/22 on every VM
  |
  v
Ansible
  |
  +-- install prerequisites and configure /etc/hosts
  +-- generate TLS material on HCKVTEST01
  +-- distribute TLS material to HCKVTEST02/HCKVTEST03
  +-- install and configure Vault
  +-- enable Raft retry_join
  +-- open Vault API/cluster firewall ports
  +-- initialize Vault on node 1
  +-- install Keepalived and advertise the VIP
```

OpenTofu invokes Ansible automatically after all configured VM addresses accept SSH connections.

## Repository layout

```text
.
├── Ansible/
│   ├── ansible.cfg
│   ├── inventory.yml
│   ├── main.yml
│   ├── requirements.yml
│   ├── group_vars/
│   ├── roles/
│   ├── templates/
│   └── secrets/              # intentionally excluded from public source
├── Tofu/
│   ├── providers.tf
│   ├── vars.tf
│   ├── terraform.tfvars
│   ├── storage.tf
│   ├── cloud-init.tf
│   ├── vm.tf
│   ├── apply.sh
│   └── destroy.sh
└── docs/
```

## Ansible role order

The active `main.yml` applies these roles in order:

1. `prerequisites_install`
2. `hosts_configuration`
3. `certificate_authority`
4. `vault_certificate_install`
5. `vault_install`
6. `keepalived_install`

The `approle_percona` role exists in the repository but is currently commented out in `main.yml`.

## TLS implementation

`certificate_authority` generates the TLS files on the first Vault node under `/opt/vault/tls` using `community.crypto` modules. The certificate SAN list contains the three node addresses, the Keepalived VIP, node names, cluster name, localhost, and the lab wildcard DNS name.

The active Vault listeners use:

```text
/opt/vault/tls/tls.crt
/opt/vault/tls/tls.key
/opt/vault/tls/tls_ca.pem
```

The `vault_certificate_install` role fetches these files from node 1 to the Ansible controller and copies them to nodes 2 and 3 so all three Vault servers use the same certificate set.

See [docs/TLS.md](docs/TLS.md).

## Vault Raft configuration

Every node uses `storage "raft"` with `/opt/vault/data` and its own `node_id`. Each generated configuration contains `retry_join` entries for all three Vault FQDNs.

`cluster_addr` is node-specific and uses TCP/8201. `api_addr` uses the cluster DNS name and TCP/8200.

See [docs/VAULT-RAFT.md](docs/VAULT-RAFT.md).

## Keepalived high availability

Keepalived is installed on every node with unicast VRRP. Priorities in the delivered templates are:

- node 1: `100`
- node 2: `99`
- node 3: `98`

The VIP is `10.20.10.13`. A health script checks the local Vault `/v1/sys/health` endpoint and allows Keepalived to move the VIP when the health check fails.

See [docs/HIGH-AVAILABILITY.md](docs/HIGH-AVAILABILITY.md).

## Azure Key Vault auto-unseal

The repository contains a private-secrets loading step in `vault_install` and is prepared for an Azure Key Vault auto-unseal configuration, but the active Vault HCL templates do **not** currently contain a `seal "azurekeyvault"` stanza. Therefore Azure auto-unseal is documented as an optional extension, not as an enabled feature.

The private `secrets/secrets.yml` file is intentionally not included in the public project. An example structure is provided in `Ansible/secrets.example.yml` with placeholders only.

Expected private structure:

```yaml
secret:
  tenant_id: "00000000-0000-0000-0000-000000000000"
  client_id: "00000000-0000-0000-0000-000000000000"
  client_secret: "REPLACE_WITH_PRIVATE_VALUE"
  vault_name: "azure-keyvault"
  key_name: "azure-keyvault"
```

See [docs/AZURE-AUTO-UNSEAL.md](docs/AZURE-AUTO-UNSEAL.md).

## Security note

Do not publish or commit any of the following:

- `Ansible/secrets/secrets.yml`
- `Ansible/.vault_pass`
- generated TLS private keys
- Vault initialization output (`/opt/vault/init.file`)
- OpenTofu state files
- local `.terraform/` contents

See [docs/SECURITY.md](docs/SECURITY.md).

## Deployment

For the current code path, running OpenTofu provisions the infrastructure and then invokes Ansible automatically:

```bash
cd Tofu
tofu init
tofu validate
tofu plan
tofu apply
```

The included `apply.sh` performs those commands sequentially.

Before running the project, review the path and environment assumptions documented in [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md).

## Documentation

- [Architecture](docs/ARCHITECTURE.md)
- [OpenTofu](docs/OPENTOFU.md)
- [Ansible](docs/ANSIBLE.md)
- [Vault Raft](docs/VAULT-RAFT.md)
- [TLS](docs/TLS.md)
- [High Availability](docs/HIGH-AVAILABILITY.md)
- [Azure Key Vault Auto-Unseal](docs/AZURE-AUTO-UNSEAL.md)
- [Deployment](docs/DEPLOYMENT.md)
- [Security](docs/SECURITY.md)
- [Troubleshooting](docs/TROUBLESHOOTING.md)

## Current implementation notes

The documentation reflects the uploaded code exactly. A few implementation details should be reviewed before publishing or reusing the lab:

- `Tofu/providers.tf` references `../Ansible/config/ansible.cfg`, while the uploaded repository contains `Ansible/ansible.cfg`.
- `Ansible/requirements.yml` currently lists `ansible.mysql`, while the active roles also use `community.crypto` and `ansible.posix` modules.
- `Tofu/storage.tf` uses a hard-coded base-image URL rather than `var.vm_base_image_path`.
- `vault_install` initializes Vault and writes the initialization output to `/opt/vault/init.file`; this file is highly sensitive.
- Azure Key Vault auto-unseal variables are private inputs but are not yet wired into the active HCL templates.

These are documented as current-state observations rather than silently represented as completed functionality.
