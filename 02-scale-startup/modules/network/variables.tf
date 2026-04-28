# Common
variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev / stg / prod)"
  type        = string
}

# Network
variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zone_a" {
  description = "Primary AZ for the app and database tiers"
  type        = string
}

variable "availability_zone_b" {
  description = "Secondary AZ used only for the ALB's additional public subnet"
  type        = string
}

variable "public_subnet_cidr_a" {
  description = "CIDR block for public_a (app subnet)"
  type        = string
}

variable "public_subnet_cidr_b" {
  description = "CIDR block for public_b (kept empty except for the ALB)"
  type        = string
}

variable "private_subnet_cidr" {
  description = "Private subnet CIDR block"
  type        = string
}

# Security Groups
variable "app_port" {
  description = "Port the app server listens on"
  type        = number
  default     = 8080
}

variable "db_port" {
  description = "Database port (e.g. 3306 for MySQL, 5432 for PostgreSQL)"
  type        = number
  default     = 3306
}

# ALB
variable "health_check_path" {
  description = "Health check path for the target group"
  type        = string
  default     = "/health"
}

variable "alb_certificate_arn" {
  description = "ACM certificate ARN for ALB HTTPS listener"
  type        = string
}
