# Troubleshooting

## OpenTofu creates VMs but Ansible does not run

Check the configured `ANSIBLE_CONFIG` path in `Tofu/providers.tf`.

The delivered code references:

```text
Ansible/config/ansible.cfg
```

while the repository contains:

```text
Ansible/ansible.cfg
```

Also confirm `ansible-playbook` and `ansible-galaxy` are available in the shell running OpenTofu.

## OpenTofu waits forever for SSH

Verify:

```bash
ping 10.20.10.10
ping 10.20.10.11
nc -zv 10.20.10.10 22
nc -zv 10.20.10.11 22
```

Check that the libvirt network, gateway, cloud-init network configuration and host routes are correct.

## HAProxy will not start

Validate the configuration:

```bash
haproxy -c -f /etc/haproxy/haproxy.cfg
```

Inspect logs:

```bash
journalctl -u haproxy -n 100 --no-pager
```

Check that the backend configuration is valid for the current environment.

## Clients cannot reach the VIP on TCP/80

Check VIP ownership:

```bash
ip addr show eth0
```

Check HAProxy listener:

```bash
ss -lntp | grep ':80'
```

Check firewalld:

```bash
firewall-cmd --list-all
```

The delivered prerequisites role opens only TCP/22, so TCP/80 may need an explicit rule.

## Keepalived nodes cannot see each other

The project uses unicast VRRP. Confirm IP reachability between `10.20.10.10` and `10.20.10.11` and inspect:

```bash
journalctl -u keepalived -n 100 --no-pager
```

If host firewall policy blocks protocol 112, add the appropriate VRRP allowance.

## VIP does not fail over when HAProxy stops

Check the health script manually:

```bash
/usr/libexec/keepalived/check_haproxy.sh
```

Check its SELinux context:

```bash
ls -Z /usr/libexec/keepalived/check_haproxy.sh
```

The role runs both `chcon` and `restorecon`; verify the resulting context permits Keepalived to execute the script.

## No `/var/log/haproxy.log`

Check:

```bash
systemctl status rsyslog
ls -l /var/lib/haproxy/dev/log
logger -p local0.info 'HAProxy logging test'
tail -f /var/log/haproxy.log
```

Inspect SELinux denials if necessary:

```bash
ausearch -m AVC -ts recent
```

The supplied rsyslog SELinux `.te` policy is rendered but not compiled/installed by the active role.

## Ansible cannot find `ansible.posix`

The active code uses `ansible.posix.firewalld` and `ansible.posix.seboolean`, but `requirements.yml` currently declares only `ansible.mysql`.

Install the missing collection or update `requirements.yml` accordingly.
