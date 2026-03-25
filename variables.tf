variable "aws_region" {
    default = "us-east-1"  
}
variable "project_name" {
    default = "three-tier-vpc"
}
variable "environment" {
    default = "prod"
}

variable "db_master_password" {
  description = "Database master password"
  type = string
  sensitive = true
}

variable "vpc_cidr" {
    default = "10.0.0.0/16"
}

# Public Subnet
variable "public_subnet_cidr" {
    default = ["10.0.1.0/24", "10.0.2.0/24"]
}

# Private Subnet (App Tier)
variable "private_subnet_cidr" {
  default = ["10.0.11.0/24","10.0.12.0/24"]
}

# Private Subnet (Database Tier)
variable "private_db_subnet_cidr" {
    default = ["10.0.21.0/24", "10.0.22.0/24"]
}

variable "availability_zones" {
  default = ["us-east-1a","us-east-1b"]
}

variable "instance_type" {
  default = "t3.micro"
}
variable "db_instance_class" {
  default = "db.t3.medium"
}
variable "key_pair_name" {
  default = "projects101"
}

