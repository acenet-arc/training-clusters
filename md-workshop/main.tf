terraform {
  required_version = ">= 1.4.0"
}

variable "pool" {
  description = "Slurm pool of compute nodes"
  default = []
}

module "openstack" {
  source         = "git::https://github.com/ComputeCanada/magic_castle.git//openstack?ref=14.2.1"
  config_git_url = "https://github.com/ComputeCanada/puppet-magic_castle.git"
  config_version = "14.2.1"

  cluster_name = "md-workshop"
  domain       = "ace-net.training"
  image        = "Rocky-8.10-x64-2024-06"

  instances = {
    mgmt   = { type = "p8-12gb", tags = ["puppet", "mgmt", "nfs"], count = 1}
    login  = { type = "p8-12gb", tags = ["login", "public", "proxy"], count = 1}
    node8c-   = { type = "c8-30gb-186-avx2", tags = ["node"], count = 1 }
    node4c1g-   = { type = "g1-8gb-c4-22gb", tags = ["node"], count = 1 }
  }

  # var.pool is managed by Slurm through Terraform REST API.
  # To let Slurm manage a type of nodes, add "pool" to its tag list.
  # When using Terraform CLI, this parameter is ignored.
  # Refer to Magic Castle Documentation - Enable Magic Castle Autoscaling
  pool = var.pool

  volumes = {
    nfs = {
      home     = { size = 100 }
      project  = { size = 50 }
      scratch  = { size = 50 }
    }
  }

  public_keys = ["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILWHSMDMhlXIy+C7/Dw4b7dUgfZkE3AXnG8PDDkyY9Qm cgeroux@lunar","ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKNJSw9+yFmtwRpJzoagrQEzobMkMEQxGLqs7edjNJZS 2021-07-28 ostueker@ACE-Helium","ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOCI9Gh8K6m1V+qpSoyp9tBmMCvtk0uY4rUD+6GaWgAX rdickson@BRTJTQ2 ssh-ed25519","AAAAC3NzaC1lZDI1NTE5AAAAIBjz+roGXPS1iY+/dPbTAsQcGSYjv1XPvtJP/CoN3V38 svassili@Sergueis-Air"]

  nb_users = 100
  # Shared password, randomly chosen if blank
  guest_passwd = ""
  
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
   source           = "git::https://github.com/ComputeCanada/magic_castle.git//dns/cloudflare"
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

output "hostnames" {
  value = module.dns.hostnames
}
