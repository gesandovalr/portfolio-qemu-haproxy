resource "libvirt_volume" "vm_disk" {
  for_each = var.VMS

  name = "${each.key}-disk.qcow2"
  pool = var.vm_pool_name

  target = {
    format = {
      type = "qcow2"
  
    }
    permissions = {
      owner = "1000"
      group = "1000"
      mode  = "0644"
    }
  }
  
  create = {
    content = {
      url = "file:///home/gesora/Templates/al9-golden-build.qcow2"
    }
  }
}
