locals {
  cloud_init_user_data = {
    preserve_hostname = false
    manage_etc_hosts  = true

    users = [
      {
        name        = "almalinux"
        lock_passwd = true
        sudo        = ["ALL=(ALL) NOPASSWD:ALL"]
        groups      = ["wheel"]
        shell       = "/bin/bash"

        ssh_authorized_keys = [
          var.vm_ssh_public_key
        ]
      }
    ]

    ssh_pwauth   = false
    disable_root = true
  }
}

resource "libvirt_cloudinit_disk" "commoninit" {
  for_each = var.VMS

  name = "${each.key}-cloudinit"

  meta_data = yamlencode({
    instance-id    = each.key
    local-hostname = each.value.name
  })

  user_data = "#cloud-config\n${yamlencode(merge(
    local.cloud_init_user_data,
    {
      hostname = each.value.name
      fqdn     = "${each.value.name}.${var.vm_domain_name}"
    }
  ))}"

  network_config = yamlencode({
    version = 2

    ethernets = {
      eth0 = {
        dhcp4 = false

        addresses = [
          "${each.value.ipv4_add_nic}/${each.value.netmask}"
        ]

        routes = [
          {
            to  = "0.0.0.0/0"
            via = var.vm_gateway
          }
        ]

        nameservers = {
          addresses = [
            "8.8.8.8",
            "8.8.4.4"
          ]

          search = [
            var.vm_domain_name
          ]
        }
      }
    }
  })
}

resource "libvirt_volume" "cloudinit_iso" {
  for_each = var.VMS

  name = "${each.key}-cloudinit.iso"
  pool = var.vm_pool_name

  create = {
    content = {
      url = libvirt_cloudinit_disk.commoninit[each.key].path
    }
  }

  target = {
    permissions = {
      owner = "1000"
      group = "1000"
      mode  = "0644"
    }
  }

  depends_on = [
    libvirt_cloudinit_disk.commoninit
  ]
}