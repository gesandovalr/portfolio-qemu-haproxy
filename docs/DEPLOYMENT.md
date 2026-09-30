# Deployment Guide

## Host prerequisites

The workstation running OpenTofu needs:

- OpenTofu
- libvirt/QEMU/KVM
- a working libvirt network matching `vm_network_name`
- access to the configured libvirt storage pool
- `nc` / netcat
- Ansible
- Ansible Galaxy access if collections are not already local
- an SSH key pair matching the public key configured in `terraform.tfvars`

## Current lab assumptions

The delivered configuration assumes:

```text
libvirt pool: Virtual_Machines
base image: /home/gesora/Templates/al9-golden-build.qcow2
network: LAN
DNS/search domain: lab.local
gateway: 10.20.10.1
VM addresses: 10.20.10.10 and 10.20.10.11
VIP: 10.20.10.12
```

## Before running

Review these files:

```text
Tofu/terraform.tfvars
Tofu/storage.tf
Ansible/inventory.yml
Ansible/group_vars/deploy_info.yaml
Ansible/templates/haproxy.cfg.j2
Ansible/templates/keepalived.conf-h1.j2
Ansible/templates/keepalived.conf-h2.j2
```

The same node addresses are declared in both OpenTofu and Ansible and should remain consistent.

## Important configuration issue

`Tofu/providers.tf` currently sets:

```text
ANSIBLE_CONFIG=${path.module}/../Ansible/config/ansible.cfg
```

but the repository contains:

```text
Ansible/ansible.cfg
```

Correct the path or create the expected directory before relying on automatic Ansible execution.

## Deploy

```bash
cd Tofu
tofu init
tofu validate
tofu plan
tofu apply
```

Or use:

```bash
./apply.sh
```

OpenTofu waits for SSH on both VMs before starting Ansible.

## Post-deployment checks

On each node:

```bash
systemctl status haproxy
systemctl status keepalived
systemctl status rsyslog
```

Validate HAProxy configuration:

```bash
haproxy -c -f /etc/haproxy/haproxy.cfg
```

Check the VIP:

```bash
ip addr show eth0
```

Check HAProxy logs:

```bash
tail -f /var/log/haproxy.log
```

## Destroy

The included script runs:

```bash
tofu destroy
```

and removes SSH known-host entries for `10.20.10.10` and `10.20.10.11`.
