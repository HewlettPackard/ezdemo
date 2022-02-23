variable "admin_password" {}
variable "is_mlops" { default = true }
variable "is_mapr" { default = false }
variable "is_runtime" { default = true }

variable "worker_count" { default = 2 }
variable "mapr_count" { default = 3 }
