## GitLab on Whatever with Terraform and Ansible

This collection of content will utilize Terraform to provision the infrastructure needed to deploy a single GitLab Server for workshops.  Currently it supports deploying to AWS or DigitalOcean, but other cloud providers are easy to adapt to by just creating a new set of Terraform files.

Tested on CentOS/RHEL 8.3 with GitLab CE 13.11.3.

## Deploying

1. Copy over the `example.vars.sh` file to `vars.sh`
2. Copy over the `2_ansible_config/vars/example.main.yml` file to `2_ansible_config/vars/main.yml`
3. Paste in your DigitalOcean API Token, modify other variables as needed
4. Run `./total_deployer.sh` to fully provision the entire stack