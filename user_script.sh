#!/bin/bash

# Install Ansible
yum install -y ansible

# Mounting secondary volume for logs
mkdir /var/log
mount /dev/xvdb /var/log

# Copy the ansible-playbook to instance
aws s3 cp s3://aws-east-1-webapp-bucket/WebApp.yaml /etc/ansible/WebApp.yaml

# Run the Ansible playbook
ansible-playbook -i "localhost," -c local /etc/ansible/WebApp.yaml