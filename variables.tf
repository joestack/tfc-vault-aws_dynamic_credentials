variable "aws_access_key" {}

variable "aws_secret_key" {}

# variable "vault_namespace" {
#   type    = string
#   default = "admin"
# }

variable "cia_user" {
    default = "cia-user"
}

variable "cia_user_password" {}


variable "tfc_access_organization" {
    default = "JoeStack"
}

variable "tfc_access_workspace" {
    default = "tfc-hcp-vault_cluster"
}
