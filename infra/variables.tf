variable "aws_region" {
  default = "eu-central-1"
}

variable "instance_type" {
  default = "t3.micro"
}

variable "name" {
  default = "peex-cicd-demo"
}

variable "allowed_cidr" {
  description = "CIDR allowed to reach SSH (22) and the app (8000)"
  default     = "0.0.0.0/0"
}
