#!/bin/bash


RED='\e[31m' 
GREEN='\033[0;32m'

read -p "Do you want to generate SSH keys for jenkins server, jenkins worker and sonarqube? (y/n): " answer

keys=(jenkins prod sonar)

if [[ "$answer" == "y" ]]; then
    if [ ! -d ~/.ssh ]; then
        mkdir -p ~/.ssh
    fi

    for id in "${keys[@]}"; do
        ssh-keygen -t rsa -b 4096 -f ~/.ssh/$id -N ''
    done

    for id in "${keys[@]}"; do
        echo "${GREEN}Generated ssh keys for $id:"
    done
else
    echo -e "${RED}SSH key generation cancelled."
    exit 0
fi
