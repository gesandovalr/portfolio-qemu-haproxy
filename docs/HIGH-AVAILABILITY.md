# High Availability with Keepalived

## VIP

The floating service address is:

```text
10.20.10.12/24
```

## Node roles

### HAPRXTEST01

- state: `MASTER`
- priority: `100`
- source address: `10.20.10.10`
- peer: `10.20.10.11`

### HAPRXTEST02

- state: `BACKUP`
- priority: `99`
- source address: `10.20.10.11`
- peer: `10.20.10.10`

## VRRP configuration

Both nodes use:

- interface `eth0`
- virtual router ID `90`
- advertisement interval `1`
- unicast peer mode

The templates include VRRP PASS authentication with a hard-coded password. This should be moved out of the template before reuse outside a lab.

## HAProxy tracking

Keepalived executes:

```text
/usr/libexec/keepalived/check_haproxy.sh
```

every 2 seconds.

The script checks:

```bash
systemctl is-active --quiet haproxy
```

If HAProxy is not active, the script executes:

```bash
systemctl stop keepalived
```

This causes the local node to stop participating so that the peer can take ownership of the VIP.

## Validation

Check VIP ownership:

```bash
ip addr show eth0
```

Check Keepalived status:

```bash
systemctl status keepalived
journalctl -u keepalived
```

Check HAProxy status:

```bash
systemctl status haproxy
```

A simple failover test is to stop HAProxy on the active node and confirm that the VIP appears on the peer.
