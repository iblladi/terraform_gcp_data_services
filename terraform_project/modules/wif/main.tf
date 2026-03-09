# 1️⃣ Workload Identity Pool
resource "google_iam_workload_identity_pool" "gitlab_pool" {
  project                   = var.project_id
  workload_identity_pool_id = var.pool_name
  display_name              = var.display_name
  description               = "Pool for GitLab CI/CD"
}

# 2️⃣ OIDC Provider
resource "google_iam_workload_identity_pool_provider" "gitlab_provider" {
  project                            = var.project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.gitlab_pool.workload_identity_pool_id
  workload_identity_pool_provider_id = var.provider_name
  display_name                       = var.display_name

  attribute_mapping = {
    "google.subject"          = "assertion.sub"
    "attribute.actor"         = "assertion.user_login"
    "attribute.project_path"  = "assertion.project_path"
  }

  attribute_condition = "attribute.project_path.startsWith('${var.gitlab_group}/')"

  oidc {
    issuer_uri = var.issuer_uri
  }
}

# 3️⃣ Bind WIF pool → Service Account (allows GitLab to impersonate it)
resource "google_service_account_iam_member" "wif_binding_identity_user" {
  service_account_id = "projects/${var.project_id}/serviceAccounts/${var.service_account_email}"
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.gitlab_pool.name}/*"
}

# 4️⃣ Allow WIF pool → Service Account token creation (needed for impersonation)
resource "google_service_account_iam_member" "wif_token_creator" {
  service_account_id = "projects/${var.project_id}/serviceAccounts/${var.service_account_email}"
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.gitlab_pool.name}/*"
}