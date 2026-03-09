terraform {
  backend "gcs" {
    bucket  = "terraform-state-masterclassparis"
    prefix  = "terraform/state"
  }
}