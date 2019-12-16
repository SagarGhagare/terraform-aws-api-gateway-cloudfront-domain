
variable "api_name" {}
variable "domain_name" {}

variable "route53_zone_id" {}

variable "ssl_cert_arn" {}

variable "project" {
  description = "The parent project being deployed"
}

variable "environment" {
  description = "The deployment environment"
}

variable "region" {}
variable "account_name" {}
