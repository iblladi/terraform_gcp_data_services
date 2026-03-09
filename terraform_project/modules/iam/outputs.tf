output "service_account_email" {
  value = google_service_account.sa.email
}

output "service_account_name" {
  description = "Full resource name, used for IAM bindings on the SA itself"
  value       = google_service_account.sa.name  # projects/{project}/serviceAccounts/{email}
}