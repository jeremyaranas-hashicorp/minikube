# Ubuntu
output "endpoints" {
  value = <<EOF

  minikube_vault_k8s_server (${aws_instance.minikube-vault-k8s-lab[0].public_ip}) | internal: (${aws_instance.minikube-vault-k8s-lab[0].private_ip})
  
    ssh ubuntu@${aws_instance.minikube-vault-k8s-lab[0].public_ip} -i ~/Saved/${var.key_name}.cer
  
EOF
}