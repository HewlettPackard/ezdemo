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
  dfnodes = [ for i in range(var.mapr_count) : format("df%02d", i ) ]
  wrknodes = [ for i in range(var.worker_count) : format("wrk%02d", i) ]
  NAMES = concat(["ct", "gw"], local.wrknodes, ["ad"], local.dfnodes)
  CPUS = concat(["4", "2"], [ for i in range(var.mapr_count) : "8" ], ["1"], [ for i in range(var.mapr_count) : "4" ])
  MEMS = concat(["8", "8"], [ for i in range(var.mapr_count) : "16" ], ["4"], [ for i in range(var.mapr_count) : "32" ])
  DISKS = concat(["500", "0"], [ for i in range(var.mapr_count) : "500" ], ["0"], [ for i in range(var.mapr_count) : "100" ])
}

resource "shell_script" "centosvm" {
  
  count = (var.is_runtime ? 5 : 1) + var.mapr_count
  lifecycle_commands {
    create = file("./create-centos.sh")
    delete = file("./delete-vm.sh")
  }

  interpreter = ["/bin/bash", "-c"]

  environment = {
    NAME        = local.NAMES[var.is_runtime ? count.index : count.index + 3]
    CPU         = local.CPUS[var.is_runtime ? count.index : count.index + 3]
    MEM         = local.MEMS[var.is_runtime ? count.index : count.index + 3]
    DISKSIZE    = local.DISKS[var.is_runtime ? count.index : count.index + 3]
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
  value = var.is_runtime ? slice(shell_script.centosvm.*.output.ip_address, 2, var.worker_count) : []
}
output "gworker_count" {
  value = 0
}
output "gworkers_private_ip" {
  value = [ ]
}
output "mapr_count" {
  value = var.mapr_count
}
output "mapr_private_ips" {
  value = var.is_mapr ? var.is_runtime ? slice(shell_script.centosvm.*.output.ip_address, 4, 4 + var.mapr_count) : slice(shell_script.centosvm.*.output.ip_address, 1, 1 + var.mapr_count) : []
}
output "ad_server_private_ip" {
  value = element(shell_script.centosvm.*.output.ip_address, var.is_runtime ? 4 : 0)
}
