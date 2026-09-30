# HAProxy Configuration

## Global configuration

The active HAProxy template configures:

- chroot: `/var/lib/haproxy`
- PID file: `/var/run/haproxy.pid`
- maximum global connections: `5000`
- runtime user/group: `haproxy`
- daemon mode
- statistics Unix socket: `/var/lib/haproxy/stats`
- system crypto policy profiles for bind/server ciphers
- logging through `/dev/log` using facility `local0`

## Defaults

The defaults section sets:

- global logging
- HTTP logging
- `dontlognull`
- `http-server-close`
- `forwardfor`, except localhost
- redispatch
- 3 retries
- HTTP request, queue, connect, client, server, keep-alive and health-check timeouts
- `maxconn 15000`

## Active frontend

```text
frontend my_frontend
  bind *:80
  mode http
  default_backend my_backend
```

The template currently also enables `option tcplog` in this HTTP frontend.

## Active backend

The backend is configured with:

- HTTP mode
- statistics enabled
- stats URI `/haproxy?stats`
- `leastconn` balancing
- sticky-cookie insertion through cookie `appid`
- one active backend server:

```text
app1 10.10.40.13:80
```

Health checks run every 10 seconds with `fall 5` and `rise 5`.

## Commented examples

The template includes a commented multi-server backend named `my.pod.com` and a corresponding frontend. These examples are not active.

## Health-check helper

`health_check_url.sh.j2` accepts one URL and exits successfully only when the HTTP result contains status 200.

The current HAProxy configuration does not reference this external check script, so the file is deployed but not actively used by the delivered `haproxy.cfg`.
