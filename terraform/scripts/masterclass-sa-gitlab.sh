#!/bin/bash

PROJECT_ID=$PROJECT_ID
SA_NAME="masterclass-sa-gitlab"
SA_EMAIL="$SA_NAME@$PROJECT_ID.iam.gserviceaccount.com"

echo "Creating service account..."

gcloud iam service-accounts create $SA_NAME \
  --project=$PROJECT_ID \
  --display-name="GitLab Terraform Service Account"

ROLES=(
"roles/run.admin"
"roles/artifactregistry.admin"
"roles/storage.admin"
"roles/pubsub.admin"
"roles/bigquery.admin"
"roles/workflows.admin"
)

for ROLE in "${ROLES[@]}"; do
  echo "Assigning $ROLE"
  gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:$SA_EMAIL" \
    --role="$ROLE"
done

echo "Service account setup complete"