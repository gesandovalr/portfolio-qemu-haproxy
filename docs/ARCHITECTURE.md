# Architecture

## Overview

This project deploys a two-node HAProxy pair on AlmaLinux 9 virtual machines running on QEMU/KVM through libvirt.

```text
                        Clients
                           |
                           v
                  10.20.10.12/24
                   Keepalived VIP
                           |
                +----------+----------+
                |                     |
                v                     v
        HAPRXTEST01              HAPRXTEST02
        10.20.10.10              10.20.10.11
        MASTER / prio 100        BACKUP / prio 99
        HAProxy                  HAProxy
                |                     |
                +----------+----------+
                           |
                           v
                 Example application
                    10.10.40.13:80
```

## Infrastructure layer

OpenTofu uses `dmacvicar/libvirt` to create one KVM domain per entry in `var.VMS`.

Each VM uses:

- Q35 machine type
- `host-passthrough` CPU mode
- VirtIO disk and network devices
- QCOW2 storage cloned from an AlmaLinux golden image
- cloud-init for hostname, static IP configuration, SSH public key injection and user configuration

The delivered `terraform.tfvars` defines two VMs, each with:

- 2 vCPU
- 2048 MiB RAM
- static `/24` address

## Configuration layer

Ansible runs after OpenTofu confirms that TCP/22 is available on each configured VM.

The play targets the `haproxy` inventory group and runs three roles:

1. prerequisites
2. HAProxy
3. Keepalived

## Availability design

Keepalived uses unicast VRRP between the two nodes.

Node 1 is configured as MASTER and node 2 as BACKUP. Both reference the same floating address, `10.20.10.12/24`.

The Keepalived `track_script` checks whether HAProxy is active. In the current implementation, the script stops Keepalived when HAProxy is inactive, allowing the peer to assume the VIP.

## Traffic flow

The active HAProxy template listens on TCP/80 and forwards HTTP traffic to backend `my_backend`.

The delivered backend configuration contains one active server:

```text
10.10.40.13:80
```

The configured balancing algorithm is `leastconn`.

## Logging

HAProxy logs to `/dev/log`. rsyslog is configured with an additional Unix socket under the HAProxy chroot and routes HAProxy messages to:

```text
/var/log/haproxy.log
```
