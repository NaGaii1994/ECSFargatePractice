variable "region" {
  description = "The AWS region to create resources in."
  default     = "ap-northeast-1"
}

variable "project_name" {
  description = "The AWS region to create resources in."
  default     = "ACMRoute53Practice"
}

variable "host_domain" {
  description = "Domain that you already have."
}

# rds

variable "POSTGRES_DB" {
  description = "RDS database name"
}
variable "POSTGRES_USER" {
  description = "RDS database username"
}
variable "POSTGRES_PASSWORD" {
  description = "RDS database password"
}
variable "rds_instance_class" {
  description = "RDS instance type"
  default     = "db.t2.micro"
}
variable "DJANGO_SECRET_KEY" {
  description = "DJANGO_SECRET_KEY"
}
variable "docker_image_url_django" {
  description = "Docker image to run in the ECS cluster"
  default     = "<AWS_ACCOUNT_ID>.dkr.ecr.us-west-1.amazonaws.com/django-app:latest"
}
variable "docker_image_url_nginx" {
  description = "Docker image to run in the ECS cluster"
  default     = "<AWS_ACCOUNT_ID>.dkr.ecr.us-west-1.amazonaws.com/django-app:latest"
}