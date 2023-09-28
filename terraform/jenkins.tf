// create a new credential ssh
resource "openstack_compute_keypair_v2" "ssh_jenkins" {
  name       = "ssh_jenkins"
  public_key = "${file("~/.ssh/jenkins.pub")}"
}

// create a new security group 22, 8080
resource "openstack_compute_secgroup_v2" "sg_jenkins" {
  name        = "jenkins"
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
}

// Create floating ip for the instance jenkins
resource "openstack_networking_floatingip_v2" "public_ip_jenkins" {
  pool = "public"
  provisioner "local-exec" {
    command = "sudo sed -i '/remote_jenkins/d' /etc/hosts && echo '${self.address} remote_jenkins' | sudo tee -a /etc/hosts"
  }
}

// Create a new instance jenkins
resource "openstack_compute_instance_v2" "jenkins" {
  name            = "jenkins"
  image_id        = "a7167185-6aa1-4e50-b30b-f26c9fddcf76"
  flavor_id       = "d4"
  key_pair        = "${openstack_compute_keypair_v2.ssh_jenkins.name}"
  security_groups = ["${openstack_compute_secgroup_v2.sg_jenkins.name}"]
  network {
    name = "shared"
  } 
}

// Output floating ip
output "jenkins_floating_ip" {
  value = "${openstack_networking_floatingip_v2.public_ip_jenkins.address}"
}

// Attach floating ip to the instance
resource "openstack_compute_floatingip_associate_v2" "public_ip_jenkins_attach" {
  floating_ip = "${openstack_networking_floatingip_v2.public_ip_jenkins.address}"
  instance_id = "${openstack_compute_instance_v2.jenkins.id}"
}
