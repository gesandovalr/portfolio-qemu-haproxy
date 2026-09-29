## Variables  

## Define Storage Pool Name
variable "vm_pool_name" {
  description = "Name of the libvirt storage pool"
  type        = string
  default     = "Virtual_Machines"
  
}

## Define Storage Pool Path
variable "vm_pool_path" {
  description = "Filesystem path used by the libvirt storage pool"
  type        = string
}

## Define base image path
variable "vm_base_template_name" {
    description = "name of the local QCOW2 base image"
    type        = string

}

## Define base image path
variable "vm_base_image_path" {
    description = "Path to the local QCOW2 base image"
    type        = string
}

variable "vm_ssh_public_key" {
    description = "Public SSH key for the VMs"
    type        = string
}

variable "vm_network_name" {
  description = "Existing libvirt network used by the VMs"
  type        = string
  default     = "LAN"
}

variable "vm_disk_capacity" {
  description = "Existing libvirt network used by the VMs"
  type        = number
  default     = "50"
}

variable "vm_domain_name" {
  description = "Domain name for the VMs"
  type        = string
}

variable "vm_gateway" {
  type    = string
}

variable "VMS" {
  type = map(object({
    name         = string
    memory       = number
    vcpu         = number
    ipv4_add_nic = string
    netmask      = number
  }))
}