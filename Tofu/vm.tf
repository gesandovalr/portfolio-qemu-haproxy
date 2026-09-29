resource "libvirt_domain" "virtual_machines" {
  for_each = var.VMS

  name        = each.value.name
  type        = "kvm"
  memory      = each.value.memory
  memory_unit = "MiB"
  vcpu        = each.value.vcpu

  features = { acpi = true }

  os = {
    type         = "hvm"
    type_arch    = "x86_64"
    type_machine = "q35"
  }

  cpu = { mode = "host-passthrough" }

  devices = {
    disks = [
      # Your OS Disk
      {
        source = {
          volume = {
            pool   = var.vm_pool_name
            volume = libvirt_volume.vm_disk[each.key].name
          }
        }
        target = { dev = "vda", bus = "virtio" }
        device = "disk"
        driver = { name = "qemu", type = "qcow2" }
        boot   = { order = 1 }
      },

      {
        device = "cdrom"
        source = {
          volume = {
            pool   = var.vm_pool_name
            volume = libvirt_volume.cloudinit_iso[each.key].name
          }
        }
        target = { 
          dev = "sda"
          bus = "sata" # Crucial for Q35 machines
        }
      }
    ]

    interfaces = [
      {
        model  = { type = "virtio" }
        source = { network = { network = var.vm_network_name } }
      }
    ]
    graphics = [ { vnc = { listen = "127.0.0.1" } } ]
    videos   = [ { model = { type = "virtio", heads = 1, primary = "yes" } } ]
  }

  running   = true
  autostart = false

  depends_on = [
    libvirt_volume.vm_disk,
    libvirt_volume.cloudinit_iso
  ]
}