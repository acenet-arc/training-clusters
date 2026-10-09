terraform {
  required_version = ">= 1.5.7"
}

variable "pool" {
  description = "Slurm pool of compute nodes"
  default     = []
}

module "openstack" {
  source         = "git::https://github.com/ComputeCanada/magic_castle.git//openstack?ref=16.0.2"
  config_git_url = "https://github.com/ComputeCanada/puppet-magic_castle.git"
  config_version = "16.0.2"

  cluster_name = "cbw"
  domain       = "ace-net.training"
  image        = "Rocky-9.7-x64-2026-03"

  instances = {
    mgmt  = { type = "p8-15gb", tags = ["puppet", "mgmt", "nfs"], count = 1 , disk_size = 50}
    login = { type = "p8-15gb", tags = ["login", "public", "proxy"], count = 1 , disk_size = 50}
    node  = { type = "c4-15gb", tags = ["node"], count = 1 }
  }

  # var.pool is managed by Slurm through Terraform REST API.
  # To let Slurm manage a type of nodes, add "pool" to its tag list.
  # When using Terraform CLI, this parameter is ignored.
  # Refer to Magic Castle Documentation - Enable Magic Castle Autoscaling
  pool = var.pool

  volumes = {
    nfs = {
      home    = { size = 100 }
      project = { size = 50 }
      scratch = { size = 50 }
    }
  }

  public_keys = ["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILWHSMDMhlXIy+C7/Dw4b7dUgfZkE3AXnG8PDDkyY9Qm cgeroux@lunar","ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOCI9Gh8K6m1V+qpSoyp9tBmMCvtk0uY4rUD+6GaWgAX rdickson@BRTJTQ2"]

  nb_users = 20
  # Shared password, randomly chosen if blank
  guest_passwd = ""
  subnet_id = "a7f9fef1-a43e-4502-83a9-e47c936b635d"
  
  hieradata = file("./config.yml")
}

output "accounts" {
  value = module.openstack.accounts
}

output "public_ip" {
  value = module.openstack.public_ip
}

## Uncomment to register your domain name with CloudFlare
module "dns" {
  source           = "git::https://github.com/ComputeCanada/magic_castle.git//dns/cloudflare?ref=16.0.2"
  name             = module.openstack.cluster_name
  domain           = module.openstack.domain
  public_instances = module.openstack.public_instances
}

## Uncomment to register your domain name with Google Cloud
# module "dns" {
#   source           = "git::https://github.com/ComputeCanada/magic_castle.git//dns/gcloud"
#   project          = "your-project-id"
#   zone_name        = "you-zone-name"
#   name             = module.openstack.cluster_name
#   domain           = module.openstack.domain
#   public_instances = module.openstack.public_instances
# }

# output "hostnames" {
#   value = module.dns.hostnames
# }
