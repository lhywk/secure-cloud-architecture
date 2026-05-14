variable "project_name" {
  type = string
}

variable "account_id" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "log_archive_bucket_name" {
  type = string
}

variable "ops_sns_topic_arn" {
  type = string
}
