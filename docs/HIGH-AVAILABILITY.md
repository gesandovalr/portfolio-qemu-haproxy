# High Availability with Keepalived

## VIP

The lab defines a client VIP:

```text
10.20.10.13
```

## VRRP priorities

| Node | Priority |
| --- | ---: |
| HCKVTEST01 | 100 |
| HCKVTEST02 | 99 |
| HCKVTEST03 | 98 |

The configuration uses unicast VRRP peers and `virtual_router_id 90`.

## Health check

The installed health script is invoked with:

```text
https://localhost:8200/v1/sys/health
```

It treats HTTP `200` as healthy. Keepalived tracks this script and the configured interface.

## Firewall

The role adds a firewalld rich rule allowing VRRP.

## Operational note

Vault's `/v1/sys/health` endpoint can return different status codes depending on active/standby/sealed state. The delivered script checks only for 200, so its failover semantics correspond to the exact script in the repository and may be intentionally stricter than a broader HA health policy.
