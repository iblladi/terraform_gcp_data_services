# Storage bucket
resource "google_storage_bucket" "raw_bucket" {

  name          = var.bucket_name
  location      = var.region
  force_destroy = true

}