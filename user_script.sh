#!/bin/bash

# Install Ansible
yum install -y ansible

# Mounting secondary volume for logs
mkdir /var/log
mount /dev/xvdb /var/log

# Run the Ansible playbook
ansible-playbook -i "localhost," -c local /etc/ansible/WebApp.yaml