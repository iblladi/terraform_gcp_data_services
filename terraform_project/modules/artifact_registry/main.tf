resource "google_artifact_registry_repository" "repo_gitlab" {
  location      = var.region
  repository_id = var.repository_name
  description   = "Docker repository"
  format        = "DOCKER"

  docker_config {
    immutable_tags = true
  }

}