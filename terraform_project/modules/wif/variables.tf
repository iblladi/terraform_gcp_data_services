variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "pool_name" {
  description = "Workload Identity Pool name"
  type        = string
  default     = "gitlab-pool"
}

variable "provider_name" {
  description = "OIDC Provider name"
  type        = string
  default     = "gitlab"
}

variable "display_name" {
  description = "Display name for pool and provider"
  type        = string
  default     = "GitLab"
}

variable "issuer_uri" {
  description = "OIDC issuer URI"
  type        = string
  default     = "https://gitlab.com"
}

variable "gitlab_group" {
  description = "GitLab group path prefix for attribute condition"
  type        = string
  # e.g. "ibeytraininggcp-group"
}

variable "service_account_email" {
  description = "Email of the SA that GitLab will impersonate"
  type        = string
}