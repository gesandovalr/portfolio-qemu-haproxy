# HAProxy High Availability on QEMU/KVM

Automated two-node HAProxy high-availability lab built with OpenTofu, libvirt/QEMU/KVM, cloud-init, Ansible, and Keepalived.

The project provisions two AlmaLinux 9 virtual machines, installs and configures HAProxy, configures rsyslog for HAProxy logging, applies SELinux-related settings, and uses Keepalived to provide a floating virtual IP (VIP) that can move between the two load-balancer nodes.

## Architecture

| Component | Implementation |
| --- | --- |
| Hypervisor | QEMU/KVM through libvirt |
| Infrastructure as Code | OpenTofu |
| Configuration management | Ansible |
| Guest OS | AlmaLinux 9 golden QCOW2 image |
| Load balancer | HAProxy |
| HA mechanism | Keepalived / VRRP in unicast mode |
| Logging | rsyslog with dedicated `/var/log/haproxy.log` |
| SELinux | `haproxy_connect_any` enabled persistently |
| HAProxy frontend | TCP/80 |
| HAProxy balancing algorithm | `leastconn` |

### Lab addressing

| System | Address | Role |
| --- | --- | --- |
| `HAPRXTEST01` | `10.20.10.10` | HAProxy node 1 / Keepalived MASTER |
| `HAPRXTEST02` | `10.20.10.11` | HAProxy node 2 / Keepalived BACKUP |
| Keepalived VIP | `10.20.10.12/24` | Floating client endpoint |
| Example backend | `10.10.40.13:80` | HAProxy backend configured in the current template |

## Deployment flow

```text
OpenTofu
  |
  +-- clone the AlmaLinux QCOW2 golden image
  +-- create cloud-init data for each VM
  +-- configure static networking and SSH key access
  +-- create two libvirt/QEMU domains
  +-- wait until TCP/22 is available on every VM
  |
  v
Ansible
  |
  +-- install prerequisites, firewalld and SELinux utilities
  +-- install/configure HAProxy
  +-- configure rsyslog and HAProxy logging
  +-- enable the HAProxy SELinux network boolean
  +-- install/configure Keepalived
  +-- deploy the HAProxy health-check script
  +-- start and enable HAProxy and Keepalived
```

OpenTofu automatically invokes Ansible after SSH becomes available on all VMs.

## Repository layout

```text
.
├── Ansible/
│   ├── ansible.cfg
│   ├── inventory.yml
│   ├── main.yml
│   ├── requirements.yml
│   ├── group_vars/
│   │   ├── all.yaml
│   │   └── deploy_info.yaml
│   ├── roles/
│   │   ├── prerequisites_install/
│   │   ├── haproxy_install/
│   │   └── keepalived_install/
│   └── templates/
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

The active playbook applies these roles in this order:

1. `prerequisites_install`
2. `haproxy_install`
3. `keepalived_install`

## HAProxy configuration

The current `haproxy.cfg.j2` template defines:

- a frontend named `my_frontend` listening on `*:80`
- HTTP mode
- a backend named `my_backend`
- `leastconn` balancing
- cookie insertion using `appid`
- one active example backend server: `10.10.40.13:80`
- HAProxy statistics enabled inside the backend block at `/haproxy?stats`
- HAProxy logs through `/dev/log` using rsyslog

Additional multi-server examples exist in the template but are commented out.

## Keepalived configuration

Keepalived is configured in unicast mode:

- `HAPRXTEST01` starts as `MASTER` with priority `100`
- `HAPRXTEST02` starts as `BACKUP` with priority `99`
- virtual router ID: `90`
- VIP: `10.20.10.12/24`
- interface: `eth0`
- HAProxy is checked every 2 seconds

The deployed health script checks whether the `haproxy` systemd service is active. If HAProxy is not active, the script stops Keepalived on that node.

## Deployment

From the `Tofu/` directory:

```bash
tofu init
tofu validate
tofu plan
tofu apply
```

The included `apply.sh` runs these commands sequentially.

After OpenTofu creates both VMs, the `terraform_data.wait_for_ssh` resource waits for SSH and `terraform_data.run_ansible` installs the declared Ansible collection dependencies and executes `main.yml`.

See [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md) before running the lab.

## Documentation

- [Architecture](docs/ARCHITECTURE.md)
- [OpenTofu](docs/OPENTOFU.md)
- [Ansible](docs/ANSIBLE.md)
- [HAProxy](docs/HAPROXY.md)
- [High Availability](docs/HIGH-AVAILABILITY.md)
- [Logging and SELinux](docs/LOGGING-SELINUX.md)
- [Deployment](docs/DEPLOYMENT.md)
- [Security](docs/SECURITY.md)
- [Troubleshooting](docs/TROUBLESHOOTING.md)

## Current implementation notes

The documentation reflects the uploaded code as delivered. Important current-state observations:

- `Tofu/providers.tf` points to `../Ansible/config/ansible.cfg`, while the repository contains `Ansible/ansible.cfg`.
- `Ansible/requirements.yml` installs `ansible.mysql`, but the active roles do not use MySQL modules. The playbook does use `ansible.posix` modules, which are not declared in `requirements.yml`.
- `Tofu/storage.tf` hard-codes `file:///home/gesora/Templates/al9-golden-build.qcow2` instead of using `var.vm_base_image_path`.
- The active HAProxy backend is hard-coded to `10.10.40.13:80` in the Jinja template.
- Firewalld is enabled, but the current prerequisites role explicitly opens only TCP/22. The HAProxy listener on TCP/80 and Keepalived/VRRP traffic are not explicitly allowed by the current Ansible tasks.
- The Keepalived authentication password is hard-coded in both templates.
- `health_check_url.sh.j2`, `haproxy_logrotate.conf.j2`, and the generated `rsyslog-haproxy.te` policy source are present, but they are not fully wired into the active runtime configuration.
- The repository archive contains local OpenTofu state, `.terraform/`, and `terraform.tfvars` even though the project `.gitignore` is configured to ignore them.

These are documented as implementation details and improvement opportunities rather than represented as completed functionality.
