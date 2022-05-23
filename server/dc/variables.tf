variable "admin_password" { default = "admin123" }
variable "is_mlops" { default = false }
variable "is_mapr" { default = false }
variable "is_mapr_ha" { default = false }
variable "is_runtime" { default = true }
variable "is_ha" { default = false }
variable "install_ad" { default = false }
variable "extra_tags" { default = "" }

variable "worker_count" { default = 1 }
variable "mapr_count" { default = 5 }

variable "project_id" { default = "Demo" }
variable "user" { default = "hpeuser" }
