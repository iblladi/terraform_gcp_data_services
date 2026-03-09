# Create Service Account
resource "google_service_account" "sa" {
  account_id   = var.service_account_name
  display_name = "${var.service_account_name}-sa"
  project      = var.project_id
}

# Attach IAM roles to the Service Account
resource "google_project_iam_member" "sa_roles" {
  for_each = toset(var.roles)

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.sa.email}"
}

# Allow other SAs to impersonate this Service Account
resource "google_service_account_iam_member" "sa_impersonation" {
  for_each = toset(var.impersonating_sas)

  service_account_id = google_service_account.sa.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${each.value}"
}