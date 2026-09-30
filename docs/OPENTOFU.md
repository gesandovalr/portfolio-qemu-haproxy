# OpenTofu Implementation

## Provider

The project uses:

```hcl
source = "dmacvicar/libvirt"
```

The lock file in the delivered repository resolves libvirt provider `0.9.9`.

## VM definitions

`var.VMS` is a map of VM objects containing:

- `name`
- `memory`
- `vcpu`
- `ipv4_add_nic`
- `netmask`

The current `terraform.tfvars` defines:

| VM | Address | vCPU | Memory |
| --- | --- | ---: | ---: |
| HAPRXTEST01 | 10.20.10.10/24 | 2 | 2048 MiB |
| HAPRXTEST02 | 10.20.10.11/24 | 2 | 2048 MiB |

## Storage

`storage.tf` creates one QCOW2 disk for each VM.

The current implementation clones this hard-coded image:

```text
/home/gesora/Templates/al9-golden-build.qcow2
```

Although variables exist for `vm_base_image_path` and `vm_base_template_name`, `storage.tf` currently does not consume `vm_base_image_path`.

## Cloud-init

Cloud-init performs the initial guest configuration:

- creates/uses the `almalinux` account
- locks password authentication for that account
- grants passwordless sudo
- injects the configured SSH public key
- disables SSH password authentication
- disables root login through cloud-init
- assigns hostname and FQDN
- configures static IPv4 networking
- configures the default route
- configures Google DNS (`8.8.8.8`, `8.8.4.4`)
- configures the search domain

## VM hardware

The domain resource uses:

- machine type `q35`
- architecture `x86_64`
- CPU mode `host-passthrough`
- VirtIO OS disk
- VirtIO network interface
- VNC bound to `127.0.0.1`
- VirtIO video

The cloud-init ISO is attached as a SATA CD-ROM.

## SSH readiness

After the libvirt domains are created, `terraform_data.wait_for_ssh` loops over every configured VM IP and checks TCP/22 using `nc`.

Ansible does not run until all configured addresses accept SSH connections.

## Automatic Ansible execution

`terraform_data.run_ansible`:

1. changes to the `Ansible/` directory
2. runs `ansible-galaxy collection install -r ./requirements.yml -p ./collections`
3. invokes `ansible-playbook -i ./inventory.yml ./main.yml`

The resource is replaced when:

- `var.VMS` changes
- `Ansible/requirements.yml` changes
- `Ansible/main.yml` changes

Changes inside roles or templates are not included in the current `triggers_replace` expression.

## Current path mismatch

The command sets:

```text
ANSIBLE_CONFIG=../Ansible/config/ansible.cfg
```

relative to the OpenTofu module, but the delivered repository contains:

```text
Ansible/ansible.cfg
```

Review this path before deployment.
