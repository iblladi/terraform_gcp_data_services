#!/bin/bash
PROJECT_ID="masterclassparis"
PROJECT_NUMBER="815606759091"

SA_NAME="masterclass-sa-gitlab"
SA_EMAIL="$SA_NAME@$PROJECT_ID.iam.gserviceaccount.com"

POOL_ID="gitlab-pool"

echo "Creating service account..."

# Only create if it doesn't already exist
if ! gcloud iam service-accounts describe $SA_EMAIL --project=$PROJECT_ID &>/dev/null; then
  gcloud iam service-accounts create $SA_NAME \
    --project=$PROJECT_ID \
    --display-name="GitLab Terraform Service Account"
  echo "Service account created."
else
  echo "Service account already exists, skipping creation."
fi

echo "-------------------------------------"
echo "Assigning PROJECT roles"

PROJECT_ROLES=(
"roles/run.admin"
"roles/artifactregistry.admin"
"roles/storage.admin"
"roles/pubsub.admin"
"roles/bigquery.admin"
"roles/workflows.admin"
"roles/iam.workloadIdentityPoolAdmin"
"roles/iam.serviceAccountAdmin"
"roles/resourcemanager.projectIamAdmin"
)

for ROLE in "${PROJECT_ROLES[@]}"; do
  echo "Assigning $ROLE"
  gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:$SA_EMAIL" \
    --role="$ROLE" \
    --condition=None
done


echo "-------------------------------------"
echo "Assigning SERVICE ACCOUNT roles"

SA_ROLES=(
"roles/iam.workloadIdentityUser"
"roles/iam.serviceAccountTokenCreator"
)

for ROLE in "${SA_ROLES[@]}"; do
  echo "Assigning $ROLE"

  gcloud iam service-accounts add-iam-policy-binding \
    $SA_EMAIL \
    --role="$ROLE" \
    --member="principalSet://iam.googleapis.com/projects/$PROJECT_NUMBER/locations/global/workloadIdentityPools/$POOL_ID/*"
done

echo "-------------------------------------"
echo "Service account setup complete"