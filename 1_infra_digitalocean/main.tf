terraform {
  required_providers {
    digitalocean = {
      source = "digitalocean/digitalocean"
      version = "1.23.0"
    }
    template = {
      source = "hashicorp/template"
      version = "2.2.0"
    }
  }
}

provider "template" {
  # Configuration options
}

variable "do_datacenter" {
  type    = string
  default = "nyc3"
}
variable "gitlab_hostname" {
  type    = string
  default = "gitlab"
}
variable "domain" {
  type    = string
  default = "example.com"
}
variable "droplet_size" {
  type    = string
  default = "s-4vcpu-8gb"
}
variable "droplet_image" {
  type    = string
  default = "centos-8-x64"
}
variable "do_token" {}
variable "do_vpc_cidr" {}

provider "digitalocean" {
  token = var.do_token
}

resource "tls_private_key" "cluster_new_key" {
  algorithm = "RSA"
}

resource "local_file" "cluster_new_priv_file" {
  content         = tls_private_key.cluster_new_key.private_key_pem
  filename        = "../.generated/.${var.gitlab_hostname}.${var.domain}/priv.pem"
  file_permission = "0600"
}
resource "local_file" "cluster_new_pub_file" {
  content  = tls_private_key.cluster_new_key.public_key_openssh
  filename = "../.generated/.${var.gitlab_hostname}.${var.domain}/pub.key"
}

resource "digitalocean_ssh_key" "cluster_ssh_key" {
  name       = "${var.gitlab_hostname}SSHKey"
  public_key = tls_private_key.cluster_new_key.public_key_openssh
}

locals {
  ssh_fingerprint = digitalocean_ssh_key.cluster_ssh_key.fingerprint
}

data "template_file" "ansible_inventory" {
  template = file("./inventory.tpl")
  vars = {
    gitlab_node = join("\n", formatlist("%s ansible_do_host=%s ansible_internal_private_ip=%s", digitalocean_droplet.gitlab_node.ipv4_address, digitalocean_droplet.gitlab_node.name, digitalocean_droplet.gitlab_node.ipv4_address_private))
    ssh_private_file = "../.generated/.${var.gitlab_hostname}.${var.domain}/priv.pem"
  }
  depends_on = [digitalocean_droplet.gitlab_node]
}

resource "local_file" "ansible_inventory" {
  content  = data.template_file.ansible_inventory.rendered
  filename = "../.generated/.${var.gitlab_hostname}.${var.domain}/inventory"
}

resource "digitalocean_vpc" "gitlabVPC" {
  name     = "${var.gitlab_hostname}-priv-net"
  region   = var.do_datacenter
  ip_range = var.do_vpc_cidr
}

resource "digitalocean_droplet" "gitlab_node" {
  image              = var.droplet_image
  name               = "${var.gitlab_hostname}.${var.domain}"
  region             = var.do_datacenter
  size               = var.droplet_size
  private_networking = true
  vpc_uuid           = digitalocean_vpc.gitlabVPC.id
  ssh_keys           = [local.ssh_fingerprint]
  depends_on         = [digitalocean_ssh_key.cluster_ssh_key, digitalocean_vpc.gitlabVPC]
  tags               = [var.gitlab_hostname]
}

resource "digitalocean_record" "gitlabHostname" {
  domain      = var.domain
  type        = "A"
  name        = var.gitlab_hostname
  value       = digitalocean_droplet.gitlab_node.ipv4_address
  ttl         = "6400"
  depends_on  = [digitalocean_droplet.gitlab_node]
}