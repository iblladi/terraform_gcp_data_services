resource "google_workflows_workflow" "pipeline" {
  name            = "gcs-to-bq-cloudrun"
  region          = var.region
  service_account = var.workflow_sa_email
  source_contents = file("${path.module}/workflow.yaml", {
    bq_dataset   = var.bq_dataset
    bq_table     = var.bq_table
    job_name     = var.cloud_run_job_name
    location     = var.region
  })
}