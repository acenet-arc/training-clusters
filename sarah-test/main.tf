terraform {
  required_version = ">= 1.5.7"
}

variable "pool" {
  description = "Slurm pool of compute nodes"
  default = []
}

module "openstack" {
  source         = "git::https://github.com/ComputeCanada/magic_castle.git//openstack?ref=14.3.0"
  config_git_url = "https://github.com/ComputeCanada/puppet-magic_castle.git"
  config_version = "14.3.0"
  subnet_id = "f7412a24-e802-4a72-8e1f-f74bac4a0b5a"
  os_ext_network = "Public-Network"

  cluster_name = "sarah"
  domain       = "ace-net.training"
  image        = "Rocky-9.5-x64-2024-11"

  instances = {
    mgmt   = { type = "p4-7.5gb", tags = ["puppet", "mgmt", "nfs"], count = 1 }
    login  = { type = "p2-3.75gb", tags = ["login", "public", "proxy"], count = 1 }
    node   = { type = "p2-3.75gb", tags = ["node"], count = 1 }
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

  public_keys = ["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINlyiuF0yzWv9D73SjSBmBafDbIS1JHefefg0ym8Je9A Sarah@sjnc-work"]

  nb_users = 10
  # Shared password, randomly chosen if blank
  guest_passwd = ""
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
