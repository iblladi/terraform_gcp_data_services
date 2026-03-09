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


# Résout automatiquement le project_number depuis le project_id
data "google_project" "current" {
  project_id = var.project_id
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
  ]

  # Le pool WIF peut impersonater ce SA (remplace la boucle SA_ROLES)
  impersonating_sas = []  # géré via wif_bindings ci-dessous
}

# Bind WIF pool → masterclass-sa-gitlab
# Remplace la double boucle SA_ROLES du script bash
resource "google_service_account_iam_member" "gitlab_wif_identity_user" {
  service_account_id = module.iam_gitlab.service_account_name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/projects/${data.google_project.current.number}/locations/global/workloadIdentityPools/gitlab-pool/*"
}

resource "google_service_account_iam_member" "gitlab_wif_token_creator" {
  service_account_id = module.iam_gitlab.service_account_name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "principalSet://iam.googleapis.com/projects/${data.google_project.current.number}/locations/global/workloadIdentityPools/gitlab-pool/*"
}


# 2. Configure WIF GitLab → ce Service Account
module "wif" {
  source = "../../modules/wif"

  project_id            = var.project_id
  gitlab_group          = "ibeytraininggcp-group"
  service_account_email = module.iam.service_account_email  # ← output du module iam

  # Valeurs optionnelles si vous gardez les defaults
  pool_name      = "gitlab-pool"
  provider_name  = "gitlab"
}

# Affiche la valeur à copier dans GitLab CI
output "gitlab_wif_provider" {
  description = "Valeur pour GCP_WORKLOAD_IDENTITY_PROVIDER dans GitLab CI"
  value       = module.wif.provider_resource_name
}