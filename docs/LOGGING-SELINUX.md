# Logging and SELinux

## HAProxy logging

HAProxy sends logs to:

```text
/dev/log
```

using syslog facility `local0`.

The Ansible role creates:

```text
/var/lib/haproxy/dev
```

and rsyslog is configured to add a Unix log socket inside the HAProxy chroot:

```text
/var/lib/haproxy/dev/log
```

HAProxy messages are routed to:

```text
/var/log/haproxy.log
```

## rsyslog configuration

The project replaces `/etc/rsyslog.conf` with the supplied Jinja template and enables UDP syslog reception on port 514 inside rsyslog.

The project also renders:

```text
/etc/rsyslog.d/99-haproxy.conf
```

## SELinux

The HAProxy role enables:

```text
haproxy_connect_any
```

persistently using `ansible.posix.seboolean`.

It also executes the equivalent `setsebool -P haproxy_connect_any on` earlier in the role.

An SELinux policy source file for rsyslog/HAProxy socket access is rendered to:

```text
/tmp/rsyslog-haproxy.te
```

but the policy compilation and installation command is commented out in the delivered role.

## Keepalived script context

The Keepalived role runs:

```bash
chcon -t keepalived_unconfined_script_exec_t /usr/libexec/keepalived/check_haproxy.sh
```

and then runs `restorecon` on the same file.

Because `chcon` is not persistent and `restorecon` resets a file to its policy-defined context, this sequence should be reviewed if the custom type is required for execution. A persistent `semanage fcontext` rule would normally be preferable for a reusable configuration.
