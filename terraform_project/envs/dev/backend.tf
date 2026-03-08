terraform {
  backend "gcs" {
    bucket  = "terraform-state-dev-bucket"
    prefix  = "terraform/state"
  }
}