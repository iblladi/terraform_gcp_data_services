variable "project_id" { 
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  default = "us-central1"
}

variable "zone" {
  default = "us-central1-a"
}

variable "project_number" {
  description = "GCP Project Number (distinct from Project ID)"
  type        = string
}