variable "IIM_AWS_ACCESS_KEY" {}
variable "IIM_AWS_SECRET_KEY" {}
variable "IIM_AWS_ZONE_ID" {}
variable "IIM_DOMAIN" {}
variable "IIM_SSH_USER" {}
variable "IIM_SSH_KEY_FILE" {}
variable "IIM_SSH_KEY_NAME" {}

variable "ip_christy" {
  default = "50.251.58.9/32"
}
variable "ip_kevin" {
  default = "62.163.187.106/32"
}
variable "ip_all" {
  default = "0.0.0.0/0"
}


provider "aws" {
  access_key = "${var.IIM_AWS_ACCESS_KEY}"
  secret_key = "${var.IIM_AWS_SECRET_KEY}"
  region     = "us-east-1"
}

variable "ami" {
  // http://cloud-images.ubuntu.com/locator/ec2/
  default = {
    us-east-1 = "ami-fd378596" //	tosip-main-ec2-ebs200-v14.4.2	us-east-1	ebs
  }
}

variable "region" {
  default     = "us-east-1"
  description = "The region of AWS, for AMI lookups."
}

resource "aws_instance" "infra-imagemagick-server" {
  ami             = "${lookup(var.ami, var.region)}"
  instance_type   = "c3.xlarge"
  key_name        = "${var.IIM_SSH_KEY_NAME}"
  security_groups = [
    "fw-infra-imagemagick-main"
  ]

  connection {
    user     = "ubuntu"
    key_file = "${var.IIM_SSH_KEY_FILE}"
  }
}

resource "aws_route53_record" "www" {
  zone_id  = "${var.IIM_AWS_ZONE_ID}"
  name     = "${var.IIM_DOMAIN}"
  type     = "CNAME"
  ttl      = "300"
  records  = [ "${aws_instance.infra-imagemagick-server.public_dns}" ]
}

resource "aws_security_group" "fw-infra-imagemagick-main" {
  name        = "fw-infra-imagemagick-main"
  description = "Infra Imagemagick"

  // SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [
      "${var.ip_all}"
    ]
  }

  // Web
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [
      "${var.ip_all}"
    ]
  }

  // Ftp
  ingress {
    from_port   = 20
    to_port     = 21
    protocol    = "tcp"
    cidr_blocks = [
      "${var.ip_all}"
    ]
  }

  // Ftp Passive
  ingress {
    from_port   = 1024
    to_port     = 1048
    protocol    = "tcp"
    cidr_blocks = [
      "${var.ip_all}"
    ]
  }
}

output "public_address" {
  value = "${aws_instance.infra-imagemagick-server.0.public_dns}"
}

output "public_addresses" {
  value = "${join(\"\n\", aws_instance.infra-imagemagick-server.*.public_dns)}"
}
