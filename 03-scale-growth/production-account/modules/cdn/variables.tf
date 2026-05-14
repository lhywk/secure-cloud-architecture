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

variable "s3_cmk_arn" {
  type = string
}

variable "waf_web_acl_arn" {
  type = string
}

variable "alb_dns_name" {
  type = string
}

variable "cloudfront_origin_secret" {
  type      = string
  sensitive = true
}

variable "cloudfront_certificate_arn" {
  type = string
}

variable "domain_name" {
  type = string
}

variable "log_archive_bucket_name" {
  type = string
}
