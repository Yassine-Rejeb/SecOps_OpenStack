#! /usr/bin/bash

# Prepare the credential of sonarqube in jenkins to allow the server conf to be read successfully

sonarIP="$(terraform -chdir=/home/$USER/SecOps/terraform/ output -raw sonar_floating_ip)"
jenkinsIP="$(terraform -chdir=/home/$USER/SecOps/terraform/ output -raw jenkins_floating_ip)"

echo "First, you need to create an auth token in SonarQube"
echo "Go to http://$sonarIP:9000/account/security/ and create a token"
echo "Then, copy the token and use it to make a new credential here: https://$jenkinsIP:8080/credentials/store/system/domain/_/newCredentials"
# Red text
echo -e "\e[31m The ID of the credential MUST be: d712a4dd53e179cf264a53e6bccb626aa6925551 \e[0m"

read -p "Are those steps done? (y/n) " -n 1 -r
while [[ ! $REPLY =~ ^[Yy]$ ]];
do
    echo "Please, do those steps before continuing"
    read -p "Are those steps done yet? (y/n) " -n 1 -r
done

# Now we will run the ansible playbook to configure the sonarqube server and the tools
cd ansible
ansible-playbook --private-key ~/.ssh/jenkins jenkins-conf.yml --vault-password-file vault_pass

# Now we will run the playbook to add the jobs to jenkins
ansible-playbook --private-key ~/.ssh/jenkins jobs.yml --vault-pass-file vault_pass

# We now need to configure the webhook in sonarqube
echo "Go to http://$sonarIP:9000/admin/webhooks and add a webhook with the following URL: http://$jenkinsIP:8080/sonarqube-webhook/"

# End of configurations
# Green text
echo -e "\e[32m The configuration is done, you can now access the jenkins server at https://$jenkinsIP:8080 to run your pipelines \e[0m"
