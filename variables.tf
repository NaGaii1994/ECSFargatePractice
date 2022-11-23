variable "region" {
  description = "The AWS region to create resources in."
  default     = "ap-northeast-1"
}

variable "project_name" {
  description = "The AWS region to create resources in."
  default     = "ACMRoute53Practice"
}

variable "ssh_public_key" {
  description = "SSH key to login ec2"
  default     = "~/.ssh/id_rsa.pub"
}

variable "host_domain" {
  description = "Domain that you already have."
}