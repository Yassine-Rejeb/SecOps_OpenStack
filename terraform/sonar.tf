// create a new credential ssh
resource "openstack_compute_keypair_v2" "ssh_sonar" {
  name       = "ssh_sonar"
  public_key = "${file("~/.ssh/sonar.pub")}"
}

// create a new security group 22
resource "openstack_compute_secgroup_v2" "sg_sonar" {
  name        = "sonar"
  description = "ssh"
  rule {
    from_port   = 22
    to_port     = 22
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
    }
rule {
    from_port   = 9000
    to_port     = 9000
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
    }
}

// Create floating ip for the instance jenkins
resource "openstack_networking_floatingip_v2" "Public_IP_sonar" {
  pool = "public"
  provisioner "local-exec" {
    command = "sudo sed -i '/sonar/d' /etc/hosts && echo '${self.address} sonar' | sudo tee -a /etc/hosts"
  }
}

// Create a new instance jenkins
resource "openstack_compute_instance_v2" "sonar" {
  name            = "sonar"
  image_id        = "a7167185-6aa1-4e50-b30b-f26c9fddcf76"
  flavor_id       = "d3q"
  key_pair        = "${openstack_compute_keypair_v2.ssh_sonar.name}"
  security_groups = ["${openstack_compute_secgroup_v2.sg_sonar.name}"]
  network {
    name = "shared"
  }
}

// Output floating ip
output "sonar_floating_ip" {
  value = "${openstack_networking_floatingip_v2.Public_IP_sonar.address}"
}

// Attach floating ip to the instance
resource "openstack_compute_floatingip_associate_v2" "public_ip_sonar_attach" {
  floating_ip = "${openstack_networking_floatingip_v2.Public_IP_sonar.address}"
  instance_id = "${openstack_compute_instance_v2.sonar.id}"
}

