output "pool_name" {
  value = google_iam_workload_identity_pool.gitlab_pool.name
}

output "provider_name" {
  value = google_iam_workload_identity_pool_provider.gitlab_provider.name
}

# Ready-to-use value for GitLab CI variable GCP_WORKLOAD_IDENTITY_PROVIDER
output "provider_resource_name" {
  description = "Use this as GCP_WORKLOAD_IDENTITY_PROVIDER in GitLab CI"
  value       = google_iam_workload_identity_pool_provider.gitlab_provider.name
}