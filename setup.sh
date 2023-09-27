#!/bin/bash

# Set versions for tools
terraform_version="1.4.5"
ansible_version="latest"

sudo apt install wget curl unzip -y

# Check if git is already installed
if command -v pip3 &>/dev/null; then
  echo "pip3 is already installed"
else
  # Download git
  sudo apt-get update
  sudo apt-get install python3-pip -y
fi

# Check if git is already installed
if command -v git &>/dev/null; then
  echo "Git is already installed"
else
  # Download git
  sudo apt-get update
  sudo apt-get install git -y
fi

# Check if DevStack repo is already cloned
if -f /home/$USER/devstack/stack.sh &>/dev/null; then
  echo "DevStack is already cloned"
else
  # Clone DevStack
  git clone https://github.com/openstack/devstack.git /home/$USER/devstack
fi

read -p "Set DevStack Password: " -sr stackPass

touch /home/$USER/devstack/local.conf
echo """[[local|localrc]]
ADMIN_PASSWORD=$stackPass
DATABASE_PASSWORD=$ADMIN_PASSWORD
RABBIT_PASSWORD=$ADMIN_PASSWORD
SERVICE_PASSWORD=$ADMIN_PASSWORD""" > /home/$USER/devstack/local.conf

# Check if Terraform is already installed
if command -v terraform &>/dev/null; then
  echo "Terraform is already installed"
else
  # Download Terraform
  curl "https://releases.hashicorp.com/terraform/${terraform_version}/terraform_${terraform_version}_linux_amd64.zip" -o "setup/terraform.zip"
  unzip setup/terraform.zip -d setup/
  sudo mv setup/terraform /usr/local/bin/
fi

# Check if Ansible is already installed
if command -v ansible &>/dev/null; then
  echo "Ansible is already installed"
else
  # Download Ansible
  sudo pip install ansible
fi

# Verify installation
terraform --version
ansible --version
