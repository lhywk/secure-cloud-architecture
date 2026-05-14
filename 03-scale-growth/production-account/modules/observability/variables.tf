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

variable "ops_email" {
  type = string
}

variable "log_archive_bucket_name" {
  type = string
}

variable "log_archive_kms_arn" {
  type = string
}

variable "alb_arn_suffix" {
  type = string
}

variable "ecs_cluster_name" {
  type = string
}

variable "ecs_service_name" {
  type = string
}

variable "rds_instance_id" {
  type = string
}

variable "waf_web_acl_name" {
  type = string
}
