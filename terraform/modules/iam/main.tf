# Create Service Account
resource "google_service_account" "sa" {
  account_id   = var.service_account_name
  display_name = concat(var.service_account_name, "-sa")
  project      = var.project_id
}

# Attach IAM roles to the Service Account
resource "google_project_iam_member" "sa_roles" {
  for_each = toset(var.roles)

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.sa.email}"
}