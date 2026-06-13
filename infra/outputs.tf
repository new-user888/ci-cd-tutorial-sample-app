output "vm_host" {
  value = aws_instance.app.public_ip
}

output "vm_user" {
  value = "ec2-user"
}

output "vm_port" {
  value = 22
}

output "vm_ssh_key" {
  value     = tls_private_key.deploy.private_key_pem
  sensitive = true
}
