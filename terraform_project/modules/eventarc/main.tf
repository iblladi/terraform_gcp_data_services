data "google_storage_project_service_account" "gcs_sa" {}

resource "google_project_iam_member" "gcs_pubsub_publisher" {
  project = var.project_id
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${data.google_storage_project_service_account.gcs_sa.email_address}"
}

resource "google_eventarc_trigger" "gcs_trigger" {
  name     = "gcs-upload-trigger"
  location = var.region

  matching_criteria {
    attribute = "type"
    value     = "google.cloud.storage.object.v1.finalized"
  }

  matching_criteria {
    attribute = "bucket"
    value     = var.bucket_name
  }

  destination {
    workflow = var.workflow_id
  }

  service_account = var.workflow_sa_email

  depends_on = [google_project_iam_member.gcs_pubsub_publisher]
}