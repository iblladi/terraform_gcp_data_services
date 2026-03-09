# Affiche la valeur à copier dans GitLab CI
output "gitlab_wif_provider" {
  description = "Valeur pour GCP_WORKLOAD_IDENTITY_PROVIDER dans GitLab CI"
  value       = "projects/${var.project_number}/locations/global/workloadIdentityPools/gitlab-pool/providers/gitlab"
}