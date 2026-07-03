variable "aws_region" {
  description = "AWS region — EU for GDPR data residency"
  type        = string
  default     = "eu-north-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name prefix for resources"
  type        = string
  default     = "orderflow"
}

variable "alert_email" {
  description = "Email for security alarm notifications (optional)"
  type        = string
  default     = ""
}
