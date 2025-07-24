variable "project_name" {
  description = "The name of the project"
  type        = string
}

variable "availability_zone" {
  description = "The availability zone to create the EBS volume in"
  type        = string
}

variable "paper_ebs_size" {
  description = "The size of the EBS volume for PaperMC in gigabytes"
  type        = number
}

variable "velocity_ebs_size" {
  description = "The size of the EBS volume for Velocity in gigabytes"
  type        = number
}