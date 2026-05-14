variable "project_name" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "db_subnet_ids" {
  type = list(string)
}

variable "db_security_group_id" {
  type = string
}

variable "cache_security_group_id" {
  type = string
}

variable "rds_cmk_arn" {
  type = string
}

variable "secrets_cmk_arn" {
  type = string
}

variable "rds_instance_class" {
  type    = string
  default = "db.t3.medium"
}

variable "db_name" {
  type    = string
  default = "appdb"
}

variable "db_username" {
  type      = string
  sensitive = true
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "redis_node_type" {
  type    = string
  default = "cache.t3.medium"
}

variable "redis_auth_token" {
  type      = string
  sensitive = true
}
