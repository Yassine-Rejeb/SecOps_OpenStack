# Automating the implementation of a DevSecOps Environment and pipeline

In this project, I use a set of tools: OpenStack, Ansible, terraform to automate the set up of an DevSecOps environment for the purepose of running a sec pipeline : 
git checkout -> SCA (OWASP Dependency Check) -> SAST (Sonarqube) -> Building the code -> DAST (OWASP ZAP)

## Requirements
This project was tested on a 
- ubuntu server 22.04
- Storage: 100 GB
- RAM: 16GB
- CPU: 8 vCPUs

PS: These are the minimum requirement for fair results. (The more the better)

## Set up
After cloning the repo
1. Run setup/getCentOSCloud.sh to Download the OS image

2. Change the IP @ in the file setup/openrc with the IP of an interface that has access to internet. The line is:
export OS_AUTH_URL=http://{{IP@}}/identity

3. Run prepare_infra.sh, accept everything at first run.

PS: This WILL take a LONG time, and you are needed in the first 10-15 minutes to fill some needed variables (like the password for openstack admin user and other passwords and things, ADVICE: Document everything you type) after those 15 minutes you can go have a coffee.

4. There may be some errors cause of internet connectivity or lack of performance, either way running the script again while refusing all the prompts will solve the issue. 
(PS: If the issue did not stop the script, it's not worth worrying about)

5. After the infra is up and you have access to both jenkins and sonarqube in browser (IPs are available in openstack webui), You need to run the script configure.sh and follow the instructions that it gives you. 

By the end of these steps you will have access to a jenkins server with the credentials (M0D4S/M0D4S) in which you will find your 2 pipelines for compliance and DevSecOps.

## Notice
If you found any issue with it plz inform me and we'll get it solved, if you have any suggestion do not hesitate to contact me with it.
