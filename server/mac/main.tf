terraform {
  required_providers {
    shell = {
      source = "scottwinkler/shell"
      version = "1.7.10"
    }
  }
}

provider "shell" {
  # sensitive_environment = {
  #   OAUTH_TOKEN = var.oauth_token
  # }
  enable_parallelism = true
}

locals {
  NAMES = ["ct", "gw", "ad", "wrk1", "wrk2", "df"]
  CPUS = ["4", "2", "1", "8", "8", "4"]
  MEMS = ["8", "8", "4", "16", "16", "32"]
  DISKS = ["500", "0", "0", "500", "500", "100"]
}

resource "shell_script" "centosvm" {
  
  count = (var.is_runtime ? 3 : 0) + var.worker_count + var.mapr_count
  lifecycle_commands {
    create = file("./create-centos.sh")
    delete = file("./delete-centos.sh")
  }

  interpreter = ["/bin/bash", "-c"]

  environment = {
    NAME        = local.NAMES[count.index]
    CPU         = local.CPUS[count.index]
    MEM         = local.MEMS[count.index]
    DATADISK    = local.DISKS[count.index]
  }
}

# resource "null_resource" "mac" {
#   provisioner "local-exec" {
#     command = "./sprayx.sh > ${null_resource.mac.id}_out.txt"
#   }
# }

# data "local_file" "script_out" {
#   filename = ("${null_resource.mac.id}_out.txt")
# }

# locals {
#   outjson = jsonencode(data.local_file.script_out.content)
# }
# data "external" "spray" {
#   program = ["./sprayx.sh"]
# }

output "controller_private_ips" {
  value = [ shell_script.centosvm[0].output.ip_address ]
}
output "controller_private_dns" {
  value = [ shell_script.centosvm[0].output.ip_address ]
}
output "gateway_private_ips" {
  value = [ shell_script.centosvm[1].output.ip_address ]
}
output "gateway_public_ips" {
  value = [ shell_script.centosvm[1].output.ip_address ]
}
output "gateway_private_dns" {
  value = [ shell_script.centosvm[1].output.ip_address ]
}
output "gateway_public_dns" {
  value = [ shell_script.centosvm[1].output.ip_address ]
}
output "worker_count" {
  value = 2
}
output "workers_private_ip" {
  value = [ shell_script.centosvm[3].output.ip_address, shell_script.centosvm[4].output.ip_address ]
}
output "gworker_count" {
  value = 0
}
output "gworkers_private_ip" {
  value = [ ]
}
output "mapr_count" {
  value = 0
}
output "mapr_private_ips" {
  value = var.is_mapr ? [ shell_script.centosvm[5].output.ip_address ] : [ ]
}
output "ad_server_private_ip" {
  value = shell_script.centosvm[2].output.ip_address
}
