variable "aws_region" {
  default = "us-east-1"
}

variable "availability_zones" {
  default = "us-east-1a"
}

variable "environment_name" {
  default = "minikube-vault-k8s-ec2"
}

variable "minikube_vault_k8s_lab_name" {
  type    = list(string)
  default = ["minikube-vault-k8s-lab"]
}

variable "minikube_vault_k8s_server_ip" {
  type    = list(string)
  default = ["10.0.101.21"]
}

# Instance size
variable "instance_type" {
  default = "t2.large"
}

# SSH key name to access EC2 instances in the AWS region 
variable "key_name" {
}
