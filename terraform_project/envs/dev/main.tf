module "artifact_registry" {
  source = "../../modules/artifact_registry"

  project_id      = var.project_id
  region          = var.region
  repository_name = "masterclass-repo"
}

module "storage" {
  source = "../../modules/gcs"

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
    "roles/bigquery.readSessionUser"
  ]

  impersonating_sas = [
    "masterclass-sa-gitlab@${var.project_id}.iam.gserviceaccount.com"
  ]

}

module "iam_gitlab" {
  source = "../../modules/iam"

  project_id           = var.project_id
  service_account_name = "masterclass-sa-gitlab"

  roles = [
    "roles/run.admin",
    "roles/artifactregistry.admin",
    "roles/storage.admin",
    "roles/pubsub.admin",
    "roles/bigquery.admin",
    "roles/workflows.admin",
    "roles/iam.workloadIdentityPoolAdmin",
  ]

  # Le pool WIF peut impersonater ce SA (remplace la boucle SA_ROLES)
  impersonating_sas = []  # géré via wif_bindings ci-dessous
}

# Add this module call (was missing entirely!)
module "wif" {
  source = "../../modules/wif"

  project_id            = var.project_id
  pool_name             = "gitlab-pool"
  provider_name         = "gitlab"
  display_name          = "GitLab"
  gitlab_group          = var.gitlab_group   # add to variables.tf
  service_account_email = module.iam_gitlab.service_account_email
}