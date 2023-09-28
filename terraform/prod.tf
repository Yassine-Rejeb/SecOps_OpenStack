// create a new credential ssh
resource "openstack_compute_keypair_v2" "ssh_prod" {
  name       = "ssh_prod"
  public_key = "${file("~/.ssh/prod.pub")}"
}

// create a new security group 22
resource "openstack_compute_secgroup_v2" "sg_prod" {
  name        = "prod"
  description = "ssh"
  rule {
    from_port   = 22
    to_port     = 22
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
    }
rule {
    from_port   = 8080
    to_port     = 8080
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
    }
rule {
    from_port   = 8000
    to_port     = 8000
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
    }
}

// Create floating ip for the instance jenkins
resource "openstack_networking_floatingip_v2" "Public_IP_prod" {
  pool = "public"
  provisioner "local-exec" {
    command = "sudo sed -i '/production_server/d' /etc/hosts && echo '${self.address} production_server' | sudo tee -a /etc/hosts"
  } 
}

// Create a new instance jenkins
resource "openstack_compute_instance_v2" "prod" {
  name            = "prod"
  image_id        = "a7167185-6aa1-4e50-b30b-f26c9fddcf76"
  flavor_id       = "4c10s"
  key_pair        = "${openstack_compute_keypair_v2.ssh_prod.name}"
  security_groups = ["${openstack_compute_secgroup_v2.sg_prod.name}"]
  network {
    name = "shared"
  }
  //floating_ip = "${openstack_networking_floatingip_v2.Public_IP_prod.address}"
}

// Output floating ip
output "prod_floating_ip" {
  value = "${openstack_networking_floatingip_v2.Public_IP_prod.address}"
}

// Attach floating ip to the instance
resource "openstack_compute_floatingip_associate_v2" "public_ip_prod_attach" {
  floating_ip = "${openstack_networking_floatingip_v2.Public_IP_prod.address}"
  instance_id = "${openstack_compute_instance_v2.prod.id}"
}
