terraform {
  required_providers {
    libvirt = {
      source = "dmacvicar/libvirt"
    }
  }
}

resource "terraform_data" "wait_for_ssh" {
  depends_on = [
    libvirt_domain.virtual_machines
  ]

  triggers_replace = [
    sha256(jsonencode(var.VMS))
  ]

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]

    command = <<-EOT
      set -e

      for ip in ${join(" ", [for vm in values(var.VMS) : vm.ipv4_add_nic])}; do
        echo "Waiting for SSH on $ip..."

        until nc -z -w 2 "$ip" 22 >/dev/null 2>&1; do
          sleep 3
        done

        echo "SSH available on $ip"
      done
    EOT
  }
}

resource "terraform_data" "run_ansible" {
  depends_on = [
    terraform_data.wait_for_ssh
  ]

  triggers_replace = [
    sha256(jsonencode(var.VMS)),
    filesha256("${path.module}/../Ansible/requirements.yml"),
    filesha256("${path.module}/../Ansible/main.yml")
  ]

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]

    working_dir = "${path.module}/../Ansible"

    command = <<-EOT
      set -e

      echo "Installing Ansible collections..."

      ansible-galaxy collection install \
        -r ./requirements.yml \
        -p ./collections

      echo "Running Ansible playbook..."

      ANSIBLE_CONFIG=${path.module}/../Ansible/config/ansible.cfg \
      ansible-playbook \
        -i ./inventory.yml \
        ./main.yml
    EOT
  }
}