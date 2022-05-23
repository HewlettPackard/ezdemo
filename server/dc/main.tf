terraform {
  required_providers {
    shell = {
      source = "scottwinkler/shell"
      version = "1.7.10"
    }
  }
}

provider "shell" {
  enable_parallelism = true
}

resource "shell_script" "ansiblevms" {
  # count = (var.is_runtime ? var.worker_count + 3 : 1) + local.maprcount
  lifecycle_commands {
    create = file("./ansible-create.sh")
    delete = file("./ansible-delete.sh")
  }
  interpreter = ["/bin/bash", "-c"]
  triggers = {
        is_mlops_changed = var.is_mlops
        is_mapr_changed = var.is_mapr
        is_mapr_ha_changed = var.is_mapr_ha
        is_runtime_changed = var.is_runtime
        is_ha_changed = var.is_ha
        install_ad_changed = var.install_ad
        worker_count_changed = var.worker_count
        mapr_count_changed = var.mapr_count
    }
}

output "controller_private_ips" {
  value = var.is_runtime ? jsondecode(shell_script.ansiblevms.output.controller)["hosts"] : []
}
output "controller_private_dns" {
  value = var.is_runtime ? jsondecode(shell_script.ansiblevms.output.controller)["hosts"] : []
}
output "gateway_private_ips" {
  value = jsondecode(shell_script.ansiblevms.output.gateway)["hosts"]
}
output "gateway_public_ips" {
  value = jsondecode(shell_script.ansiblevms.output.gateway)["hosts"]
}
output "gateway_private_dns" {
  value = jsondecode(shell_script.ansiblevms.output.gateway)["hosts"]
}
output "gateway_public_dns" {
  value = [ [ for k, v in jsondecode(shell_script.ansiblevms.output._meta)["hostvars"] : v["gw_fqdn"] ][0] ]
}
output "worker_count" {
  value = var.is_runtime ? (length(jsondecode(shell_script.ansiblevms.output.picasso)["hosts"]) + length(jsondecode(shell_script.ansiblevms.output.k8s)["hosts"])) : 0
}
output "workers_private_ip" {
  value = var.is_runtime ? concat(jsondecode(shell_script.ansiblevms.output.picasso)["hosts"], jsondecode(shell_script.ansiblevms.output.k8s)["hosts"]) : []
}
output "gworker_count" {
  value = 0
}
output "gworkers_private_ip" {
  value = [ ]
}
output "mapr_count" {
  value = var.is_mapr ? var.mapr_count : 0
}
output "mapr_private_ips" {
  value = var.is_mapr ? jsondecode(shell_script.ansiblevms.output.mapr)["hosts"] : []
}
output "ad_server_private_ip" {
  value = [ for k, v in jsondecode(shell_script.ansiblevms.output._meta)["hostvars"] : v["ad_server"] ][0]
}
