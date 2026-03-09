variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "workflow_sa_email" {
  description = "Service account email to run the workflow"
  type        = string
}

variable "bq_dataset" {
  description = "BigQuery dataset ID"
  type        = string
}

variable "bq_table" {
  description = "BigQuery table ID"
  type        = string
}

variable "cloud_run_job_name" {
  description = "Cloud Run Job name"
  type        = string
}
