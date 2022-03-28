variable "admin_password" {}
variable "is_mlops" { default = false }
variable "is_mapr" { default = false }
variable "is_runtime" { default = true }

variable "worker_count" { default = 1 }
variable "mapr_count" { default = 3 }