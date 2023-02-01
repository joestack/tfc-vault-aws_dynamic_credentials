provider "vault" {
  address   = data.terraform_remote_state.vault-cluster.outputs.vault_public_url
  namespace = data.terraform_remote_state.vault-cluster.outputs.vault_namespace
  token     = data.terraform_remote_state.vault-cluster.outputs.vault_token
}

resource "vault_auth_backend" "userpass" {
  type = "userpass"
}

resource "vault_generic_endpoint" "cia-user" {
  depends_on           = [vault_auth_backend.userpass]
  path                 = "auth/userpass/users/cia-user"
  ignore_absent_fields = true

    data_json = data.template_file.cia.rendered
}

data "template_file" "cia" {
  template = file("${path.root}/templates/cia.tpl") 
  vars = {
    policy = vault_policy.admins.name
    password = var.cia_user_password
  }
}

resource "vault_policy" "admins" {
  name = "vault-admins"

  policy = <<EOT

# Allow managing leases
path "sys/leases/*"
{
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# Manage auth backends broadly across Vault
path "auth/*"
{
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# List, create, update, and delete auth backends
path "sys/auth/*"
{
  capabilities = ["create", "read", "update", "delete", "sudo"]
}

# List existing policies
path "sys/policies"
{
  capabilities = ["read"]
}

# Create and manage ACL policies broadly across Vault
path "sys/policies/*"
{
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# List, create, update, and delete key/value secrets
path "secret/*"
{
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# Manage and manage secret backends broadly across Vault.
path "sys/mounts/*"
{
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# List existing secret engines.
path "sys/mounts"
{
  capabilities = ["read"]
}

# Read health checks
path "sys/health"
{
  capabilities = ["read", "sudo"]
}

EOT
}




resource "vault_aws_secret_backend" "aws" {
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

resource "vault_aws_secret_backend_role" "role" {
  backend = vault_aws_secret_backend.aws.path
  name    = "deploy"
  credential_type = "iam_user"

  policy_document = <<EOT
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "iam:*",
      "Resource": "*"
    }
  ]
}
EOT
}

/*
// AWS Secrets Engine

resource "vault_aws_secret_backend" "aws" {
  path       = "${var.pipeline_name}/aws"
  access_key = var.aws_access_key_id
  secret_key = var.aws_secret_access_key
}

resource "vault_aws_secret_backend_role" "role" {
  backend         = vault_aws_secret_backend.aws.path
  name            = "pipeline"
  credential_type = "assumed_role"
  role_arns       = var.aws_role_arns
  default_sts_ttl = 1800
  max_sts_ttl     = 3600
}
*/
