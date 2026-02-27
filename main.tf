terraform {
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 1.54"
    }
  }

  backend "s3" {
    bucket                      = "iac-axel-dln"
    key                         = "terraform.tfstate"
    region                      = "sbg"
    endpoints = {
      s3 = "https://s3.sbg.perf.cloud.ovh.net"
    }
    skip_credentials_validation = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    skip_metadata_api_check     = true
    skip_s3_checksum            = true
  }
}

provider "openstack" {}

#################################
# KEYPAIR SSH
#################################

resource "openstack_compute_keypair_v2" "ssh_key" {
  name       = "iac-ubuntu-key"
  public_key = file(pathexpand("~/.ssh/id_rsa.pub"))
}

#################################
# SECURITY GROUP (existant)
#################################

data "openstack_networking_secgroup_v2" "secgroup" {
  name = "default"
}

#################################
# RÉSEAU PUBLIC (OVH)
#################################

data "openstack_networking_network_v2" "public" {
  name = "Ext-Net"
}

#################################
# INSTANCE
#################################

resource "openstack_compute_instance_v2" "vm" {
  name            = "iac-axel-dln"
  image_name      = "Ubuntu 24.04"
  flavor_name     = "d2-2"
  key_pair        = openstack_compute_keypair_v2.ssh_key.name
  security_groups = [data.openstack_networking_secgroup_v2.secgroup.name]

  network {
    uuid = data.openstack_networking_network_v2.public.id
  }
}

#################################
# OUTPUTS
#################################

output "instance_ip" {
  value = openstack_compute_instance_v2.vm.access_ip_v4
}