# Deployment

## Controller prerequisites

The controller running OpenTofu/Ansible needs at least:

- OpenTofu
- libvirt/QEMU/KVM access
- the `dmacvicar/libvirt` provider
- Ansible
- `ansible-galaxy`
- `nc`/netcat for the SSH readiness loop
- SSH access to the guest VMs

## Infrastructure prerequisites

The delivered configuration assumes:

- an existing libvirt network named `LAN`
- a libvirt storage pool named `Virtual_Machines`
- a local AlmaLinux golden image
- gateway `10.20.10.1`
- no conflicting addresses at `.10`, `.11`, `.12`, or `.13`
- SSH public/private key pair matching the OpenTofu and Ansible configuration

## Private Ansible configuration

Create a private encrypted file at:

```text
Ansible/secrets/secrets.yml
```

For the optional Azure auto-unseal extension, start from `Ansible/secrets.example.yml` and replace placeholders locally.

The repository also expects an Ansible Vault password source through `.vault_pass` as configured in `ansible.cfg`. Do not commit it.

## Apply

```bash
cd Tofu
tofu init
tofu validate
tofu plan
tofu apply
```

OpenTofu waits for SSH and then calls Ansible automatically.

## Current configuration-path issue

Before running, review `Tofu/providers.tf`. It currently sets:

```text
../Ansible/config/ansible.cfg
```

while the uploaded project contains:

```text
../Ansible/ansible.cfg
```

These paths must agree for the intended configuration to be loaded.

## Verify Vault services

Useful post-deployment checks include:

```bash
systemctl status vault
systemctl status keepalived
vault status
```

For Raft, use the Vault operator commands after authenticating with appropriate credentials.

## Destroy

The included script runs `tofu destroy` and removes the three VM IP addresses from the local SSH known_hosts file.
