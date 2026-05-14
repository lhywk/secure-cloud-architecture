variable "project_name" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "secrets_cmk_arn" {
  type = string
}

variable "db_username" {
  type      = string
  sensitive = true
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "db_name" {
  type    = string
  default = "appdb"
}

variable "redis_auth_token" {
  type      = string
  sensitive = true
}

variable "api_key" {
  type      = string
  sensitive = true
  default   = "REPLACE_ME"
}

variable "cloudfront_origin_secret" {
  type      = string
  sensitive = true
}
