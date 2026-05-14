variable "project_name" {
  type = string
}

variable "region" {
  type = string
}

variable "account_id" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "secrets_cmk_arn" {
  type = string
}

variable "s3_cmk_arn" {
  type = string
}

variable "ebs_cmk_arn" {
  type = string
}

variable "app_bucket_arn" {
  type = string
}

variable "github_org" {
  type = string
}

variable "github_repo" {
  type = string
}
