# Security Notes

## SSH

Cloud-init configures key-based access for the `almalinux` user and disables password SSH authentication.

The Ansible inventory disables SSH host-key checking through `ansible.cfg`, which is convenient for a disposable lab but should be reconsidered for production environments.

## Firewalld

The prerequisites role installs/enables firewalld and explicitly opens TCP/22.

The current code does not explicitly open:

- TCP/80 for the HAProxy frontend
- VRRP protocol 112 between Keepalived peers
- UDP/514 despite enabling UDP rsyslog reception

Whether traffic works depends on the existing firewall zone/policy and host environment. These rules should be made explicit for a portable deployment.

## Keepalived authentication

The VRRP authentication password is hard-coded in the Jinja templates:

```text
auth_pass mypass$444
```

Treat it as a lab placeholder. Store reusable credentials in protected Ansible variables or Vault rather than source-controlled templates.

## HAProxy backend

The backend address is currently embedded directly in `haproxy.cfg.j2`. Moving backend definitions into variables would make the deployment safer and easier to review.

## SELinux

The project keeps SELinux integration rather than disabling SELinux. It enables `haproxy_connect_any` persistently and attempts to assign an executable context to the Keepalived health-check script.

Review the current `chcon` followed by `restorecon` sequence because the latter may undo the former unless a persistent file-context rule exists.

## Repository hygiene

The repository `.gitignore` files intend to exclude:

- `.terraform/`
- `*.tfstate*`
- `*.tfvars`
- Ansible local collections
- Ansible secrets and vault password files

However, the uploaded archive still contains `.terraform/`, OpenTofu state files and `terraform.tfvars`. These should not be included in a public portfolio repository if they expose environment-specific information.
