terraform {
  required_providers {
    openstack = {
      source = "terraform-provider-openstack/openstack"
      version = "1.52.1"
    }
  }
}

// Terraform provider is openstack
provider "openstack" {
  user_name   = "admin"
  password    = "secret"
  auth_url    = "http://127.0.0.1/identity"
}
