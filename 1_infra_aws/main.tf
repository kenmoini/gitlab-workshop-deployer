terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
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

provider "aws" {
  # Configure the AWS Provider
  region = var.aws_region
}

variable "vpc_id" {
  type    = string
}
variable "aws_region" {
  type    = string
  default = "us-east-2"
}
variable "gitlab_hostname" {
  type    = string
  default = "gitlab"
}
# also the R53 zone
variable "domain" {
  type    = string
  default = "example.com"
}

## Cloud Access RHEL
#data "aws_ami" "rhel" {
#  most_recent = true
#  name_regex = "^(RHEL-8.3.0_HVM-)(.*)(Access)*$"
#  filter {
#    name   = "virtualization-type"
#    values = ["hvm"]
#  }
#  filter {
#    name   = "architecture"
#    values = ["x86_64"]
#  }
#  owners = ["309956199498"] # Red Hat
#}

## AWS Marketplace RHEL
data "aws_ami" "rhel" {
  most_recent = true
  name_regex = "^(RHEL-8.3.0_HVM-)(.*)(Hourly2)*$"
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
  owners = ["309956199498"] # Red Hat
}

data "aws_route53_zone" "zone" {
  name         = var.domain
  private_zone = false
}

data "aws_vpc" "target_vpc" {
  id = var.vpc_id
}

data "aws_subnet" "target_subnet" {
  filter {
    name  = "tag:Name"
    values = ["*public-${var.aws_region}b"]
  }
  filter {
    name  = "availability-zone"
    values = ["${var.aws_region}b"]
  }
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

resource "aws_key_pair" "cluster_ssh_key" {
  key_name   = "${var.gitlab_hostname}SSHKey"
  public_key = tls_private_key.cluster_new_key.public_key_openssh
}

data "template_file" "ansible_inventory" {
  template = file("./inventory.tpl")
  vars = {
    gitlab_node = join("\n", formatlist("%s ansible_do_host=%s ansible_internal_private_ip=%s", aws_instance.gitlab.public_ip, "${var.gitlab_hostname}.${var.domain}", aws_instance.gitlab.private_ip))
    ssh_private_file = "../.generated/.${var.gitlab_hostname}.${var.domain}/priv.pem"
  }
  depends_on = [aws_instance.gitlab]
}

resource "local_file" "ansible_inventory" {
  content  = data.template_file.ansible_inventory.rendered
  filename = "../.generated/.${var.gitlab_hostname}.${var.domain}/inventory"

  depends_on = [aws_instance.gitlab]
}

resource "aws_route53_record" "gitlab" {
  zone_id = data.aws_route53_zone.zone.zone_id
  name    = "${var.gitlab_hostname}.${data.aws_route53_zone.zone.name}"
  type    = "A"
  ttl     = "300"
  records = [aws_instance.gitlab.public_ip]
}

resource "aws_route53_record" "gitlab_wildcard" {
  zone_id = data.aws_route53_zone.zone.zone_id
  name    = "*.${var.gitlab_hostname}.${data.aws_route53_zone.zone.name}"
  type    = "A"
  ttl     = "300"
  records = [aws_instance.gitlab.public_ip]
}

resource "aws_security_group" "gitlab_sg" {
  name        = "gitlab_sg"
  description = "Allow GitLab traffic"
  vpc_id      = data.aws_vpc.target_vpc.id

  tags = {
    Name = "allow_gitlab"
  }
}

resource "aws_security_group_rule" "allow_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 65535
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.gitlab_sg.id
}

resource "aws_security_group_rule" "allow_https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.gitlab_sg.id
}

resource "aws_security_group_rule" "allow_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.gitlab_sg.id
}

resource "aws_security_group_rule" "allow_container_reg" {
  type              = "ingress"
  from_port         = 5000
  to_port           = 5010
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.gitlab_sg.id
}

resource "aws_security_group_rule" "allow_ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.gitlab_sg.id
}

resource "aws_instance" "gitlab" {
  ami                         = data.aws_ami.rhel.id
  instance_type               = "m5.xlarge"
  associate_public_ip_address = true
  subnet_id                   = data.aws_subnet.target_subnet.id
  security_groups             = [ aws_security_group.gitlab_sg.id ]
  key_name                    = aws_key_pair.cluster_ssh_key.key_name

  tags = {
    Name = "gitlab"
  }
}