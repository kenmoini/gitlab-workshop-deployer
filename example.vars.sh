#!/usr/bin/env bash

DO_PAT="someSecretLongThing"

TERRAFORM_INSTALL="false"
TERRAFORM_VERSION="0.13.4"

DOMAIN="example.com"
GITLAB_HOSTNAME="gitlab"

DO_DATA_CENTER="nyc3"
DO_VPC_CIDR="10.42.0.0/24"
DO_NODE_IMAGE="centos-8-x64"
DO_NODE_SIZE="s-4vcpu-8gb"


### DO NOT EDIT PAST THIS LINE

export TF_VAR_do_datacenter=$DO_DATA_CENTER
export TF_VAR_do_vpc_cidr=$DO_VPC_CIDR
export TF_VAR_do_token=$DO_PAT
export TF_VAR_gitlabHostname=$GITLAB_HOSTNAME
export TF_VAR_domain=$DOMAIN
export TF_VAR_droplet_size=$DO_NODE_SIZE
export TF_VAR_droplet_image=$DO_NODE_IMAGE
