resource "google_bigquery_dataset" "dataset" {
  dataset_id                  = var.dataset_id
  friendly_name               = "${var.dataset_id} dataset"
  description                 = "Dataset for ${var.dataset_id}"
  location                    = var.region
}
