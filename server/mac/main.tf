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

locals {
  maprcount = (var.is_mapr ? var.mapr_count : 0)
  dfnodes = [ for i in range(local.maprcount) : format("df%02d", i ) ]
  wrknodes = [ for i in range(var.worker_count) : format("wrk%02d", i) ]
  NAMES = concat(["ct", "gw", "ad"], local.wrknodes, local.dfnodes)
  CPUS = concat(["4", "2", "1"], [ for i in range(var.worker_count) : "8" ], [ for i in range(local.maprcount) : "4" ])
  MEMS = concat(["8", "8", "4"], [ for i in range(var.worker_count) : "16" ], [ for i in range(local.maprcount) : "32" ])
  DISKS = concat(["500", "0", "0"], [ for i in range(var.worker_count) : "500" ], [ for i in range(local.maprcount) : "100" ])
}

resource "shell_script" "centosvm" {
  
  count = (var.is_runtime ? var.worker_count + 3 : 1) + local.maprcount
  lifecycle_commands {
    create = file("./create-vm.sh")
    delete = file("./delete-vm.sh")
  }

  interpreter = ["/bin/bash", "-c"]

  environment = {
    NAME        = local.NAMES[var.is_runtime ? count.index : count.index + 2]
    CPU         = local.CPUS[var.is_runtime ? count.index : count.index + 2]
    MEM         = local.MEMS[var.is_runtime ? count.index : count.index + 2]
    DISKSIZE    = local.DISKS[var.is_runtime ? count.index : count.index + 2]
  }
}

output "controller_private_ips" {
  value = var.is_runtime ? [ shell_script.centosvm[0].output.ip_address ] : []
}
output "controller_private_dns" {
  value = var.is_runtime ? [ shell_script.centosvm[0].output.ip_address ] : []
}
output "gateway_private_ips" {
  value = var.is_runtime ? [ shell_script.centosvm[1].output.ip_address ] : []
}
output "gateway_public_ips" {
  value = var.is_runtime ? [ shell_script.centosvm[1].output.ip_address ] : []
}
output "gateway_private_dns" {
  value = var.is_runtime ? [ shell_script.centosvm[1].output.ip_address ] : []
}
output "gateway_public_dns" {
  value = var.is_runtime ? [ shell_script.centosvm[1].output.ip_address ] : []
}
output "worker_count" {
  value = var.worker_count
}
output "workers_private_ip" {
  value = var.is_runtime ? slice(shell_script.centosvm.*.output.ip_address, 3, 3 + var.worker_count) : []
}
output "gworker_count" {
  value = 0
}
output "gworkers_private_ip" {
  value = [ ]
}
output "mapr_count" {
  value = local.maprcount
}
output "mapr_private_ips" {
  value = var.is_mapr ? var.is_runtime ? slice(shell_script.centosvm.*.output.ip_address, 3 + var.worker_count, 3 + var.worker_count + local.maprcount) : slice(shell_script.centosvm.*.output.ip_address, 1, 1 + local.maprcount) : []
}
output "ad_server_private_ip" {
  value = element(shell_script.centosvm.*.output.ip_address, var.is_runtime ? 2 : 0)
}
