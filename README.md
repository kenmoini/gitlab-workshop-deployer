## GitLab on Whatever with Terraform and Ansible

This collection of content will utilize Terraform to provision the infrastructure needed to deploy a single GitLab Server for workshops.  Currently it supports deploying to DigitalOcean, but other cloud providers are easy to adapt to by just creating a new set of Terraform files.

Tested on CentOS 8.2 with GitLab CE 13.4.4.

## Deploying

1. Copy over the `example.vars.sh` file to `vars.sh`
2. Copy over the `2_ansible_config/vars/example.main.yml` file to `2_ansible_config/vars/main.yml`
3. Paste in your DigitalOcean API Token, modify other variables as needed
4. Run `./total_deployer.sh` to fully provision the entire stack