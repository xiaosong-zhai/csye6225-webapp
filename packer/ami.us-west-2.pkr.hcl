packer {
  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = ">= 1.0.0"
    }
  }
}

variable "aws_region" {
  type    = string
  default = ""
}

variable "source_ami" {
  type    = string
  default = ""
}

variable "ssh_username" {
  type    = string
  default = ""
}

variable "subnet_id" {
  type    = string
  default = ""
}

variable "demo_account_id" {
  type    = string
  default = ""
}

variable "instance_type" {
  type    = string
  default = ""
}

variable "volume_size" {
  type    = number
  default = 0
}

variable "volume_type" {
  type    = string
  default = ""
}

# https://www.packer.io/plugins/builders/amazon/ebs
source "amazon-ebs" "my-ami" {
  region          = "${var.aws_region}"
  ami_name        = "csye6225_${formatdate("YYYY_MM_DD_hh_mm_ss", timestamp())}"
  ami_description = "AMI for CSYE 6225"
  ami_regions = [
    "us-west-1",
  ]

  ami_users = [
    "${var.demo_account_id}",
  ]

  aws_polling {
    delay_seconds = 120
    max_attempts  = 50
  }

  instance_type = "${var.instance_type}"
  source_ami    = "${var.source_ami}"
  ssh_username  = "${var.ssh_username}"
  subnet_id     = "${var.subnet_id}"

  launch_block_device_mappings {
    delete_on_termination = true
    device_name           = "/dev/xvda"
    volume_size           = var.volume_size
    volume_type           = "${var.volume_type}"
  }

  tags = {
    Name        = "CSYE6225_AMI"
    Environment = "Development"
  }
}

build {
  sources = ["source.amazon-ebs.my-ami"]

  provisioner "file" {
    source      = "/home/runner/work/webapp/webapp/target/csye6225-0.0.1-SNAPSHOT.jar"
    destination = "/tmp/webapp.jar"
  }

  provisioner "file" {
    source      = "/home/runner/work/webapp/webapp/src/main/resources/static/users.csv"
    destination = "/tmp/users.csv"
  }

  provisioner "shell" {
    inline = [
      "sudo mv /tmp/webapp.jar /root/webapp.jar",
      "sudo chown root:root /root/webapp.jar",

      "sudo mv /tmp/users.csv /opt/users.csv",
    ]
  }

  provisioner "shell" {
    environment_vars = [
      "DEBIAN_FRONTEND=noninteractive",
      "CHECKPOINT_DISABLE=1"
    ]
    inline = [
      "sudo apt-get update",
      "sudo apt-get upgrade -y",
      "sudo apt-get install -y openjdk-17-jdk",
    ]
  }
}
