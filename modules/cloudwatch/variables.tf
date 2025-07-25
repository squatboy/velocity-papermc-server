variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "velocity_instance_id" {
  description = "EC2 Instance ID for Velocity server"
  type        = string
}

variable "paper_instance_id" {
  description = "EC2 Instance ID for Paper server"
  type        = string
}

variable "sns_topic_arn" {
  description = "SNS Topic ARN for alerts"
  type        = string
}
