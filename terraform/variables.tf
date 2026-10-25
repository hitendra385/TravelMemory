variable "aws_region" {
  description = "AWS region in which to create the infrastructure."
  type        = string
  default     = "us-east-1"
}

variable "name_prefix" {
  description = "Prefix used for resource names and tags."
  type        = string
  default     = "travelmemory"
}

variable "ssh_allowed_cidr" {
  description = "Your public IPv4 CIDR allowed to SSH to the web instance; use a /32 for one IP."
  type        = string

  validation {
    condition     = can(cidrnetmask(var.ssh_allowed_cidr))
    error_message = "ssh_allowed_cidr must be a valid IPv4 CIDR, preferably your public IP with a /32 mask."
  }
}

variable "ec2_key_pair_name" {
  description = "Name of an existing EC2 key pair in the selected AWS region."
  type        = string
}

variable "web_instance_type" {
  description = "EC2 instance type for the public web host."
  type        = string
  default     = "t3.micro"
}

variable "database_instance_type" {
  description = "EC2 instance type for the private MongoDB host."
  type        = string
  default     = "t3.micro"
}