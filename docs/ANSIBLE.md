# Ansible Implementation

## Inventory

The inventory defines one group named `haproxy`:

| Inventory host | Address |
| --- | --- |
| HAPRXTEST01 | 10.20.10.10 |
| HAPRXTEST02 | 10.20.10.11 |

Group variables specify:

```text
ansible_user = almalinux
ansible_ssh_private_key_file = ~/.ssh/id_ed25519
```

## Playbook

`main.yml` runs against all hosts with privilege escalation enabled.

Role order:

1. `prerequisites_install`
2. `haproxy_install`
3. `keepalived_install`

## Variables

`group_vars/deploy_info.yaml` defines:

- HAProxy/Keepalived node IP addresses
- VIP `10.20.10.12`
- node hostnames
- interface name `eth0`

`group_vars/all.yaml` sets:

```yaml
allow_world_readable_tmpfiles: true
```

## prerequisites_install

The prerequisites role currently:

- imports the EPEL 9 RPM signing key
- installs the EPEL 9 release package
- installs and enables firewalld
- installs `policycoreutils-python-utils`
- opens TCP/22 in firewalld
- installs `net-tools`
- installs `telnet`
- installs `bind-utils`

## haproxy_install

The HAProxy role:

- installs the latest available `haproxy` package
- renders `/etc/haproxy/haproxy.cfg`
- prepares `/var/lib/haproxy/dev`
- prepares `/usr/libexec/haproxy`
- deploys `health_check_url.sh`
- restores SELinux contexts under `/usr/libexec/haproxy`
- configures rsyslog integration
- renders an SELinux policy source file to `/tmp/rsyslog-haproxy.te`
- enables `haproxy_connect_any`
- restarts rsyslog
- starts and enables HAProxy

The SELinux `.te` file is rendered but the module compilation/install command is commented out.

## keepalived_install

The Keepalived role:

- installs Keepalived
- renders a MASTER configuration on node 1
- renders a BACKUP configuration on node 2
- deploys `/usr/libexec/keepalived/check_haproxy.sh`
- changes the script context with `chcon`
- subsequently runs `restorecon`
- starts and enables Keepalived

## Collections

The delivered `requirements.yml` contains:

```yaml
collections:
  - name: ansible.mysql
```

The active HAProxy roles do not use `ansible.mysql`. They do use modules from `ansible.posix`, including `firewalld` and `seboolean`, so the requirements file does not currently describe the actual active collection dependency set.
