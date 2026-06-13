# Infra

Terraform config for the VM that the CD workflow deploys to: an EC2 instance with Docker installed, and a security group allowing SSH and the app port (8000).

## Usage

```sh
terraform init
terraform apply
```

Then read the values for the GitHub repo secrets:

```sh
terraform output vm_host
terraform output vm_user
terraform output vm_port
terraform output -raw vm_ssh_key
```

`vm_ssh_key` is the private key - copy its full output, including the `BEGIN`/`END` lines, into the `VM_SSH_KEY` secret.

To remove everything when you're done:

```sh
terraform destroy
```
