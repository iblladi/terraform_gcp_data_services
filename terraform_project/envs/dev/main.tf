module "artifact_registry" {
  source = "../../modules/artifact_registry"

  project_id      = var.project_id
  region          = var.region
  repository_name = "masterclass-repo"
}

module "storage" {
  source = "../../modules/storage"

  bucket_name = "masterclass-bucket"
  region = var.region
}

module "bigquery" {
  source = "../../modules/bigquery"
  project_id = var.project_id
  dataset_id = "masterclassdbt"
  region   = var.region
}

module "pubsub" {
  source = "../../modules/pubsub"

  topic_name = "masterclass-topic"
}

module "iam" {
  source = "../../modules/iam"

  project_id           = var.project_id
  service_account_name = "masterclass-sa"

  
  roles = [
    "roles/run.invoker",
    "roles/artifactregistry.reader",
    "roles/storage.objectViewer",
    "roles/pubsub.publisher",
    "roles/bigquery.dataEditor",
    "roles/bigquery.jobUser",
    "roles/workflows.invoker",
    "roles/bigquery.readSessionUser",
    "roles/storage.objectCreator",
    "roles/eventarc.eventReceiver",
  ]

  impersonating_sas = [
    "masterclass-sa-gitlab@${var.project_id}.iam.gserviceaccount.com"
  ]

}

module "workflow" {
  source = "../../modules/workflow"

  project_id         = var.project_id
  region             = var.region
  workflow_sa_email  = "masterclass-sa@${var.project_id}.iam.gserviceaccount.com"
  bq_dataset         = module.bigquery.dataset_id
  bq_table           = "ecommerce_data"
  cloud_run_job_name = "dbt-job-masterclass"
}

module "eventarc" {
  source = "../../modules/eventarc"

  project_id        = var.project_id
  region            = var.region
  bucket_name       = module.storage.bucket_name
  workflow_id       = module.workflow.workflow_id
  workflow_sa_email = "masterclass-sa@${var.project_id}.iam.gserviceaccount.com"
}