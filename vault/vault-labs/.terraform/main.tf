# Ubuntu
provider "aws" {
  region = var.aws_region
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "minikube-vault-k8s-lab" {
  count                       = length(var.minikube_vault_k8s_lab_name)
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = module.minikube_vault_k8s_vpc.public_subnets[0]
  key_name                    = var.key_name
  vpc_security_group_ids      = [aws_security_group.test.id]
  associate_public_ip_address = true
  private_ip                  = var.minikube_vault_k8s_server_ip[count.index]

  tags = {
    Name         = "${var.environment_name}-minikube-vault-k8s-server-${var.minikube_vault_k8s_lab_name[count.index]}"
    cluster_name = "minikube-vault-k8s-ec2"
  }

  lifecycle {
    ignore_changes = [ami, tags]
  }

  # Ubuntu
  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("~/Saved/${var.key_name}.cer")
    host        = self.public_ip
  }

  provisioner "file" {
    source      = "init.sh"
    destination = "/tmp/init.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/init.sh",
      "/tmp/init.sh",
    ]
  }
}

resource "random_pet" "env" {
  length    = 2
  separator = "_"
}