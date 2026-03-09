output "workflow_id" {
  description = "Cloud Workflows ID"
  value       = google_workflows_workflow.pipeline.id
}

output "workflow_name" {
  description = "Cloud Workflows name"
  value       = google_workflows_workflow.pipeline.name
}
