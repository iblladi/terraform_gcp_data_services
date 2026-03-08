#!/bin/bash
# setup_gitlab_wif.sh
# This script sets up Workload Identity Federation (WIF) for GitLab in GCP

# ----------- CONFIGURATION -----------
PROJECT_ID="masterclassparis"
POOL_NAME="gitlab-pool"
PROVIDER_NAME="gitlab"
DISPLAY_NAME="GitLab"
LOCATION="global"
ISSUER_URI="https://gitlab.com"
ATTRIBUTE_CONDITION="attribute.repository.startsWith('ibeytraininggcp-group/')"
# ------------------------------------

echo "=== Setting GCP Project ==="
gcloud config set project $PROJECT_ID

# 1️⃣ Create Workload Identity Pool (if it doesn't exist)
echo "=== Creating Workload Identity Pool: $POOL_NAME ==="
gcloud iam workload-identity-pools describe $POOL_NAME \
  --location=$LOCATION \
  --project=$PROJECT_ID &>/dev/null

if [ $? -ne 0 ]; then
  gcloud iam workload-identity-pools create $POOL_NAME \
    --project=$PROJECT_ID \
    --location=$LOCATION \
    --display-name="$DISPLAY_NAME" \
    --description="Pool for GitLab CI/CD"
else
  echo "Pool $POOL_NAME already exists"
fi

# 2️⃣ Create OIDC provider (if it doesn't exist)
echo "=== Creating OIDC Provider: $PROVIDER_NAME ==="
gcloud iam workload-identity-pools providers describe $PROVIDER_NAME \
  --workload-identity-pool=$POOL_NAME \
  --location=$LOCATION \
  --project=$PROJECT_ID &>/dev/null

if [ $? -ne 0 ]; then
  gcloud iam workload-identity-pools providers create-oidc $PROVIDER_NAME \
    --project=$PROJECT_ID \
    --location=$LOCATION \
    --workload-identity-pool=$POOL_NAME \
    --display-name="$DISPLAY_NAME" \
    --issuer-uri="$ISSUER_URI" \
    --attribute-mapping="google.subject=assertion.sub,attribute.actor=assertion.user_login,attribute.repository=assertion.project_path" \
    --attribute-condition="$ATTRIBUTE_CONDITION"
else
  echo "Provider $PROVIDER_NAME already exists"
fi

echo "✅ Workload Identity Federation setup completed!"