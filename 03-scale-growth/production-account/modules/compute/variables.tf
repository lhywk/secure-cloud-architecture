variable "project_name" {
  type = string
}

variable "region" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "ecs_security_group_id" {
  type = string
}

variable "target_group_arn" {
  type = string
}

variable "task_role_arn" {
  type = string
}

variable "instance_profile_arn" {
  type = string
}

variable "ebs_cmk_arn" {
  type = string
}

variable "s3_cmk_arn" {
  type = string
}

variable "secrets_cmk_arn" {
  type = string
}

variable "db_secret_arn" {
  type = string
}

variable "redis_auth_secret_arn" {
  type = string
}

variable "db_endpoint" {
  type    = string
  default = ""
}

variable "redis_endpoint" {
  type    = string
  default = ""
}

variable "task_cpu" {
  type    = number
  default = 512
}

variable "task_memory" {
  type    = number
  default = 1024
}

variable "desired_count" {
  type    = number
  default = 2
}

variable "instance_type" {
  type    = string
  default = "t3.medium"
}

variable "asg_min_size" {
  type    = number
  default = 2
}

variable "asg_max_size" {
  type    = number
  default = 10
}

variable "asg_desired_capacity" {
  type    = number
  default = 2
}
