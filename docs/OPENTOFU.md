# OpenTofu

## Provider

The project declares the `dmacvicar/libvirt` provider and uses libvirt resources for disks, cloud-init media, and KVM domains.

## Variables

Important declared variables include:

- `vm_pool_name`
- `vm_pool_path`
- `vm_base_template_name`
- `vm_base_image_path`
- `vm_ssh_public_key`
- `vm_network_name`
- `vm_disk_capacity`
- `vm_domain_name`
- `vm_gateway`
- `VMS`

`VMS` is a map containing VM name, memory, vCPU, static IPv4 address, and netmask.

## Storage

`storage.tf` creates one QCOW2 disk per VM. In the delivered code, the base image source is hard-coded as:

```text
file:///home/gesora/Templates/al9-golden-build.qcow2
```

Although `vm_base_image_path` exists as a variable, it is not currently used by `storage.tf`.

## Cloud-init

Cloud-init creates the `almalinux` account with:

- password login disabled
- root login disabled
- passwordless sudo
- SSH authorized key from `vm_ssh_public_key`

Networking is configured statically on `eth0` and includes DNS resolvers plus the configured search domain.

## VM resources

Each VM uses Q35, host-passthrough CPU, VirtIO devices, and a cloud-init CD-ROM.

## Ansible handoff

After domain creation, `terraform_data.wait_for_ssh` polls TCP/22 for every `VMS` address.

Then `terraform_data.run_ansible`:

1. changes working directory to `../Ansible`
2. installs Galaxy collections from `requirements.yml` into `./collections`
3. invokes `ansible-playbook -i ./inventory.yml ./main.yml`

### Current path caveat

The environment variable in the delivered code is:

```text
ANSIBLE_CONFIG=${path.module}/../Ansible/config/ansible.cfg
```

but the uploaded repository contains `Ansible/ansible.cfg`, not `Ansible/config/ansible.cfg`. Review this path before running the deployment.

## Trigger behavior

The Ansible `terraform_data` resource is replaced when:

- the `VMS` object changes
- `Ansible/requirements.yml` changes
- `Ansible/main.yml` changes

Changes inside individual roles/templates are not currently included in `triggers_replace`.

## Local state

The uploaded development tree contains local OpenTofu state and provider-cache files. These should not be committed to a public portfolio repository. See `SECURITY.md`.
