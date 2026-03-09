variable "project_id" {
  type = string
}

variable "region" {
  type    = string
  default = "us-central1"
}

variable "bucket_name" {
  description = "GCS bucket to listen for object finalize events"
  type        = string
}

variable "workflow_id" {
  description = "Full workflow resource ID to trigger"
  type        = string
}

variable "workflow_sa_email" {
  description = "Service account email used by Eventarc to invoke the workflow"
  type        = string
}