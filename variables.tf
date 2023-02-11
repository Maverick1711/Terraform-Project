variable "vpc_cidr" {
    type = string
}
#variable "project_name" {
#    type = string
#    default = "Terraform-vpc"
#}

variable "pub_sub_cidr1" {
    type = string
}
variable "pub_sub_cidr2" {
    type = string
}
variable "priv_sub_cidr1" {
    type = string
}
variable "priv_sub_cidr2" {
    type = string
}


variable "instance_count" {
  default = "2"
}

variable "instance_type" {
  type = string
}

variable "tenancy" {
    type = string
}
variable "region" {
  type = string  
  default = "eu-west-2"
}

variable "ami" {
  type = map(string)

  default = {
    "eu-west-2" = "ami-08cd358d745620807"  #confirm ami id.
    "eu-west-3" = "ami-0ca5ef73451e16dc1"
  }
}

variable "db_password" {
  description = "RDS root user password"
  type        = string
  sensitive   = true
}

variable "db_username" {
  description = "RDS root user"
  type        = string
  sensitive   = true
}