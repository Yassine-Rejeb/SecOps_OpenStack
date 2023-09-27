#! /usr/bin/bash

# Stop script if in the wrong directory
cwd="$(pwd)"

if [ "$cwd" != "/home/$USER/SecOps" ]; then
        echo "You are calling the script from the wrong directory."
        echo "Solution: cd /home/$USER/SecOps/"
        exit 1
fi

# This command is used to exit the script if any command exits with a non-zero status
set -e

YELLOW='\e[33m'
GREEN='\e[32m'
NCG='\e[0m'
NC='\033[0m'
RED='\e[31m'
echo -e "${YELLOW}******************************************************************************************************************************************************${NC}"
echo -e "${YELLOW}******************************************************************************************************************************************************${NC}"

echo -e "${YELLOW}------------------------------------------------------------------------------------------------------------------------------------------------------${NC}"
echo -e "${YELLOW}-----------------------------------------------------------------//-Installing Required Tools-//------------------------------------------------------${NC}"
echo -e "${YELLOW}------------------------------------------------------------------------------------------------------------------------------------------------------${NC}"
echo ""
read -p "To proceed, we need to install the required tools. Would you like to proceed? (y/n): " confirm

if [ "$confirm" = "y" ]; then
        ./setup.sh
else
        echo -e "${RED}Skipping..."
fi

echo ""
echo -e "${YELLOW}------------------------------------------------------------------------------------------------------------------------------------------------------${NC}"
echo -e "${YELLOW}-----------------------------------------------------------------//-Configuring SSH Keys-//-----------------------------------------------------------${NC}"
echo -e "${YELLOW}------------------------------------------------------------------------------------------------------------------------------------------------------${NC}"
echo ""
rm -rf ~/.ssh/known_hosts
read -p "To proceed, we need authorization to create (recreate) ssh keys. Would you like to proceed? (y/n): " re_ssh
if [ "$re_ssh" = "y" ]; then
        ./sshkeys.sh
else
        echo -e "${RED}Skipping..."
fi
echo ""

echo -e "${YELLOW}------------------------------------------------------------------------------------------------------------------------------------------------------${NC}"
echo -e "${YELLOW}-----------------------------------------------------------------//-Setting UP DevSTACK-//-----------------------------------------------------------${NC}"
echo -e "${YELLOW}------------------------------------------------------------------------------------------------------------------------------------------------------${NC}"
echo ""
read -p "To proceed, we need authorization to setup devstack. Would you like to proceed? (y/n): " stack_it
if [ "$stack_it" = "y" ]; then
        ./devstack.sh > $(pwd)/setup_logs/devstack.log
        source setup/openrc
        openstack flavor create --id d3p --vcpus 2 --ram 4096 --swap 256 --disk 20 --public ds4G-
        openstack image create --disk-format qcow2 --min-disk 8 --min-ram 512 --public --id a7167185-6aa1-4e50-b30b-f26c9fddcf76 --file ./setup/centos8.qcow2 centos
        openstack router add subnet router1 shared-subnet
        openstack flavor create --id d3q --vcpus 2 --ram 4096 --swap 256 --disk 10 --public ds4G10
else
        echo -e "${RED}Skipping..."
        source setup/openrc
fi
echo ""

echo -e "${YELLOW}------------------------------------------------------------------------------------------------------------------------------------------------------${NC}"
echo -e "${YELLOW}-----------------------------------------------------------------//-Running Terraform-//--------------------------------------------------------------${NC}"
echo -e "${YELLOW}------------------------------------------------------------------------------------------------------------------------------------------------------${NC}"
echo ""
terraform -chdir=terraform init #> $(pwd)/setup_logs/terraform.log
terraform -chdir=terraform apply -auto-approve #>> $(pwd)/setup_logs/terraform.log
echo ""

echo -e "${YELLOW}------------------------------------------------------------------------------------------------------------------------------------------------------${NC}"
echo -e "${YELLOW}----------------------------------------------------------//-Waiting for the Cloud Instances to boot-//-----------------------------------------------${NC}"
echo -e "${YELLOW}------------------------------------------------------------------------------------------------------------------------------------------------------${NC}"
echo ""
./wait.sh $(terraform -chdir=./terraform/ output -raw jenkins_floating_ip) $(terraform -chdir=./terraform/ output -raw prod_floating_ip) $(terraform -chdir=./terraform/ output -raw sonar_floating_ip)
echo ""

echo -e "${YELLOW}------------------------------------------------------------------------------------------------------------------------------------------------------${NC}"
echo -e "${YELLOW}-----------------------------------------------------------------//-Running Ansible Playbooks-//------------------------------------------------------${NC}"
echo -e "${YELLOW}------------------------------------------------------------------------------------------------------------------------------------------------------${NC}"
echo ""

cd ansible

# Check if the file exists
if [ ! -f progress.log ]; then
        touch progress.log
	# Initialize the log file
	echo "jenkins.yml: 0" > progress.log
	echo "prod.yml: 0" >> progress.log
	echo "sonar.yml: 0" >> progress.log
	echo "jenkins-plugins.yml: 0" >> progress.log
	echo "compliance.yml: 0" >> progress.log
fi
# Check the state of jenkins.yml in the log file
jenkins=$(grep -E 'jenkins.yml: 0' progress.log; echo '')

# If the state is 0, run the playbook
if [ "$jenkins" = "jenkins.yml: 0" ]; then
        ansible-playbook --private-key ~/.ssh/jenkins jenkins.yml --vault-password-file vault_pass
        sed -iE 's/jenkins.yml: 0/jenkins.yml: 1/g' progress.log
else
        echo -e "${RED}Skipping...${NC}"
fi

# Check the state of prod.yml in the log file
prod=$(grep -E 'prod.yml: 0' progress.log; echo '')

# If the state is 0, run the playbook
if [ "$prod" = "prod.yml: 0" ]; then
        ansible-playbook --private-key ~/.ssh/prod prod.yml --vault-password-file vault_pass
        sed -iE 's/prod.yml: 0/prod.yml: 1/g' progress.log
else
        echo -e "${RED}Skipping...${NC}"
fi

# Check the state of sonar.yml in the log file
sonar=$(grep -E 'sonar.yml: 0' progress.log; echo '')

# If the state is 0, run the playbook
if [ "$sonar" = "sonar.yml: 0" ]; then
        ansible-playbook --private-key ~/.ssh/sonar sonar.yml --vault-password-file vault_pass
        sed -iE 's/sonar.yml: 0/sonar.yml: 1/g' progress.log
else
        echo -e "${RED}Skipping...${NC}"
fi

# Check the state of jenkins-plugins.yml in the log file
plugins=$(grep -E 'jenkins-plugins.yml: 0' progress.log; echo '')

# If the state is 0, request the user to install the plugins
if [ "$plugins" = "jenkins-plugins.yml: 0" ]; then
        read -p "We will now install jenkins plugins (high internet bandwifth is required). Would you like to proceed? [If you do not approve we will than copy a pre-installed plugins folder to the instance running Jenkins] (y/n): " plugins
        if [ "$plugins" = "y" ]; then
                ansible-playbook --private-key ~/.ssh/jenkins jenkins-plugins.yml --vault-password-file vault_pass #> $(pwd)/../setup_logs/ansible/compliance.log
        else
                scp -i ~/.ssh/jenkins ../files/plugins.tar  centos@remote_jenkins:/tmp/
                ssh centos@remote_jenkins -i /home/$USER/.ssh/jenkins sudo tar -xf /tmp/plugins.tar -C /var/lib/jenkins/ >/dev/null 2>&1
                ssh centos@remote_jenkins -i /home/$USER/.ssh/jenkins sudo systemctl restart jenkins >/dev/null 2>&1 &
        fi
        sed -iE 's/jenkins-plugins.yml: 0/jenkins-plugins.yml: 1/g' progress.log
else
        echo -e "${RED}Skipping...${NC}"
fi

# Check the state of compliance.yml in the log file
compliance=$(grep -E 'compliance.yml: 0' progress.log); echo ''

# If the state is 0, run the playbook
if [ "$compliance" = "compliance.yml: 0" ]; then
        ansible-playbook --private-key ~/.ssh/prod compliance.yml --vault-password-file vault_pass
        sed -iE 's/compliance.yml: 0/compliance.yml: 1/g' progress.log
else
        echo -e "${RED}Skipping...${NC}"
fi

echo ""
echo -e "${YELLOW}******************************************************************************************************************************************************${NC}"
echo -e "${YELLOW}******************************************************************************************************************************************************${NC}"
echo -e "${GREEN} Everything is done!${NCG}"

