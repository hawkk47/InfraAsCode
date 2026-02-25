terraform {
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 1.54"
    }
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
# INSTANCE UBUNTU
#################################

resource "openstack_compute_instance_v2" "ubuntu_vm" {
  name            = "ubuntu-iac-axel"
  flavor_name     = "d2-2"
  key_pair        = openstack_compute_keypair_v2.ssh_key.name
  security_groups = [data.openstack_networking_secgroup_v2.secgroup.name]

  image_name = "Ubuntu 24.04"

  network {
    uuid = data.openstack_networking_network_v2.public.id
  }
}

#################################
# OUTPUT IP
#################################

output "instance_ip" {
  value = openstack_compute_instance_v2.ubuntu_vm.access_ip_v4
}