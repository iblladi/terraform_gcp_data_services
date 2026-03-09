variable "project_id" {
  type = string
}

variable "service_account_name" {
  type = string
}

variable "roles" {
  type = list(string)
}

variable "impersonating_sas" {
  type        = list(string)
  description = "List of service account emails that should be allowed to impersonate this SA"
  default     = []
}