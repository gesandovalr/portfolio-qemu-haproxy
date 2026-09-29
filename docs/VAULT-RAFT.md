# Vault Integrated Storage (Raft)

## Storage configuration

Every Vault node uses:

```hcl
storage "raft" {
  node_id = "<node-specific-name>"
  path    = "/opt/vault/data"
  ...
}
```

The three delivered templates set node IDs to the corresponding short host names.

## Retry join

Each node template includes `retry_join` entries for:

```text
https://HCKVTEST01.lab.local:8200
https://HCKVTEST02.lab.local:8200
https://HCKVTEST03.lab.local:8200
```

## API and cluster addresses

`cluster_addr` is unique per node and points to its own FQDN on TCP/8201.

`api_addr` points to the cluster FQDN on TCP/8200:

```text
https://HCKVCLUSTER01.lab.local:8200
```

## Initialization

The current `vault_install` role initializes Vault only on node 1:

```text
vault operator init | tee /opt/vault/init.file
```

This output contains highly sensitive bootstrap material and must not be treated as an ordinary log file.

When Azure Key Vault auto-unseal is not configured, Vault uses its normal Shamir seal behavior. When auto-unseal is configured before initial initialization, Vault returns recovery keys rather than normal unseal keys.

## Cluster join behavior

The templates rely on Raft `retry_join` for discovery. Nodes must be able to resolve the configured FQDNs, trust the TLS certificate, and communicate over the configured API and cluster ports.
