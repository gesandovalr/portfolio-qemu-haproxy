# Architecture

## Overview

This lab deploys a three-node HashiCorp Vault cluster on local QEMU/KVM infrastructure. OpenTofu manages the libvirt virtual machines and cloud-init metadata. Ansible configures the operating system, TLS, Vault Integrated Storage (Raft), firewall rules, and Keepalived.

```text
                         Client traffic
                              |
                     10.20.10.13:8200
                       Keepalived VIP
                              |
              +---------------+---------------+
              |               |               |
        HCKVTEST01       HCKVTEST02       HCKVTEST03
        10.20.10.10      10.20.10.11      10.20.10.12
        Vault/Raft       Vault/Raft       Vault/Raft
        priority 100     priority 99      priority 98
              |               |               |
              +------- Raft / cluster --------+
                       TCP/8201 + TLS
```

## Infrastructure layer

OpenTofu uses `dmacvicar/libvirt` and creates one `libvirt_domain` per entry in `var.VMS`.

Delivered VM sizing:

| VM | vCPU | RAM | IP |
| --- | ---: | ---: | --- |
| HCKVTEST01 | 2 | 2048 MiB | 10.20.10.10/24 |
| HCKVTEST02 | 2 | 2048 MiB | 10.20.10.11/24 |
| HCKVTEST03 | 2 | 2048 MiB | 10.20.10.12/24 |

The domains use:

- KVM virtualization
- Q35 machine type
- host-passthrough CPU
- VirtIO storage/networking
- QCOW2 disks derived from a local AlmaLinux 9 golden image
- cloud-init ISO attached through SATA
- VNC listening only on `127.0.0.1`

## Network layer

Cloud-init applies static IPv4 addressing on `eth0` with the configured gateway and domain search suffix.

The Ansible inventory uses the same three IP addresses and connects with the `almalinux` account using an Ed25519 private key.

Vault opens:

- TCP/8200 - API/UI listener
- TCP/8201 - Vault cluster communication

Keepalived also allows VRRP through `firewalld`.

## Vault layer

All three nodes use Integrated Storage (Raft). Each node has:

- a unique `node_id`
- a node-specific `cluster_addr`
- identical `retry_join` targets for all three FQDNs
- the same cluster name
- the same TLS certificate set

The configured `api_addr` points to the cluster FQDN rather than a node-specific address.

## Availability layer

Keepalived manages VIP `10.20.10.13`. Node 1 has the highest priority, followed by nodes 2 and 3. A local health-check script calls the Vault health endpoint to determine whether the VIP should remain on the node.

## Automation chain

`terraform_data.wait_for_ssh` waits for port 22 on every VM. `terraform_data.run_ansible` then installs Ansible Galaxy dependencies from `requirements.yml` and executes `main.yml`.

This means the intended operator workflow is a single OpenTofu apply that transitions from provisioning to configuration automatically.
