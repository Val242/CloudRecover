variable "domain_name" {
  description = "Private DNS domain for the application"
  type        = string
  default     = "cloudrecover.internal"
}

variable "create_hosted_zone" {
  description = "Whether this stack creates and manages the hosted zone"
  type        = bool
  default     = false
}

variable "hosted_zone_id" {
  description = "Private hosted zone ID created by the primary stack"
  type        = string
  default     = null
  nullable    = true

  validation {
    condition     = var.hosted_zone_id == null || try(trimspace(var.hosted_zone_id) != "", false)
    error_message = "hosted_zone_id must be null or a non-empty ID."
  }
}

variable "vpc_id" {
  description = "VPC to associate with the private hosted zone"
  type        = string
}

variable "vpc_region" {
  description = "AWS region containing the VPC"
  type        = string
}

variable "record_name" {
  description = "Application DNS name in the private hosted zone"
  type        = string
  default     = "api.cloudrecover.internal"
}

variable "alb_dns_name" {
  description = "DNS name of the application load balancer in this environment"
  type        = string
}

variable "alb_zone_id" {
  description = "Canonical Route 53 hosted zone ID of this environment's ALB"
  type        = string
}

variable "failover_type" {
  description = "Route 53 failover role for this environment's record"
  type        = string

  validation {
    condition     = contains(["PRIMARY", "SECONDARY"], var.failover_type)
    error_message = "failover_type must be PRIMARY or SECONDARY."
  }
}

variable "project" {
  description = "Project name used in the Route 53 record set identifier"
  type        = string
  default     = "cloudrecover"
}
