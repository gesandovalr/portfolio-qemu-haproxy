# Ansible

## Inventory

The inventory defines a single `hashicorp_vault_cluster` group:

```text
HCKVTEST01 -> 10.20.10.10
HCKVTEST02 -> 10.20.10.11
HCKVTEST03 -> 10.20.10.12
```

All hosts use:

- `ansible_user: almalinux`
- `~/.ssh/id_ed25519`

## Shared variables

`group_vars/deploy_info.yaml` defines the three node IP addresses, the Keepalived VIP, DNS labels, short names, FQDNs, domain, cluster name, and network interface.

The delivered environment uses:

```text
Domain: lab.local
Cluster: HCKVCLUSTER01
VIP: 10.20.10.13
Interface: eth0
```

## Playbook order

`main.yml` runs six active stages:

1. prerequisites + host configuration
2. certificate authority/certificate generation
3. certificate distribution
4. Vault installation/configuration
5. Keepalived installation/configuration
6. gathered-facts cleanup

The `approle_percona` play is present but commented out.

## Role summary

### prerequisites_install

Installs supporting OS/Python packages, enables firewalld, creates `/opt/vault`, `/opt/vault/tls`, and `/opt/vault/data`, enables EPEL, and adds the HashiCorp RHEL repository.

### hosts_configuration

Renders `/etc/hosts` from `templates/hosts.j2`.

### certificate_authority

Uses `community.crypto` to create the key, CSR, self-signed CA certificate, and a CA-signed certificate file on node 1.

### vault_certificate_install

Fetches the generated TLS material from node 1 to the Ansible controller and copies it to nodes 2 and 3.

### vault_install

Loads `secrets/secrets.yml`, installs Vault, renders a node-specific `vault.hcl`, opens ports 8200/8201, trusts the generated certificate, starts Vault, and initializes Vault on node 1.

### keepalived_install

Installs Keepalived, deploys a Vault health-check script, deploys node-specific VRRP configuration, enables VRRP in firewalld, and restarts/enables Keepalived.

## Collection requirements

The delivered `requirements.yml` currently declares only:

```yaml
collections:
  - name: ansible.mysql
```

However, active tasks also use:

- `community.crypto`
- `ansible.posix`

Those collections must be available on the controller for the current roles to work. This is a current repository dependency gap and is documented rather than hidden.

## Private variables

`vault_install` includes `secrets/secrets.yml`. This file is intentionally excluded from the public documentation package.

A safe placeholder file is included as `Ansible/secrets.example.yml`.
