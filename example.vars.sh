#!/usr/bin/env bash

DO_PAT="someSecretLongThing"

TERRAFORM_INSTALL="false"
TERRAFORM_VERSION="0.13.4"

DOMAIN="example.com"
GITLAB_HOSTNAME="gitlab"

INFRA_PROVIDER="aws" # aws or digitalocean

AWS_VPC_ID="vpc-something"
AWS_REGION="us-east-2"

DO_DATA_CENTER="nyc3"
DO_VPC_CIDR="10.42.0.0/24"
DO_NODE_IMAGE="centos-8-x64"
DO_NODE_SIZE="s-4vcpu-8gb"

### DO NOT EDIT PAST THIS LINE

export TF_VAR_gitlab_hostname=$GITLAB_HOSTNAME
export TF_VAR_domain=$DOMAIN
export TF_VAR_vpc_id=$AWS_VPC_ID
export TF_VAR_aws_region=$AWS_REGION
export TF_VAR_do_datacenter=$DO_DATA_CENTER
export TF_VAR_do_vpc_cidr=$DO_VPC_CIDR
export TF_VAR_do_token=$DO_PAT
export TF_VAR_droplet_size=$DO_NODE_SIZE
export TF_VAR_droplet_image=$DO_NODE_IMAGE