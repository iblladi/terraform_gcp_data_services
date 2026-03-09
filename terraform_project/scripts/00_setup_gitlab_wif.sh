#!/bin/bash
# setup_gitlab_wif.sh
# Sets up Workload Identity Federation (WIF) for GitLab in GCP
# Handles ACTIVE, DELETED, and missing states for both pool and provider

set -euo pipefail

# ----------- CONFIGURATION -----------
PROJECT_ID="masterclassparis"
POOL_NAME="gitlab-pool"
PROVIDER_NAME="gitlab"
DISPLAY_NAME="GitLab"
LOCATION="global"
ISSUER_URI="https://gitlab.com"
ATTRIBUTE_MAPPING="google.subject=assertion.sub,attribute.actor=assertion.user_login,attribute.repository=assertion.project_path"
ATTRIBUTE_CONDITION="attribute.repository.startsWith('ibeytraininggcp-group/')"
# ------------------------------------

echo "=== Setting GCP Project ==="
gcloud config set project "$PROJECT_ID"

# ─────────────────────────────────────────────
# 1️⃣  Workload Identity Pool
# ─────────────────────────────────────────────
echo ""
echo "=== Managing Workload Identity Pool: $POOL_NAME ==="

POOL_STATE=$(gcloud iam workload-identity-pools describe "$POOL_NAME" \
  --location="$LOCATION" \
  --project="$PROJECT_ID" \
  --format="value(state)" 2>/dev/null || echo "NOT_FOUND")

case "$POOL_STATE" in
  ACTIVE)
    echo "✔ Pool '$POOL_NAME' is already ACTIVE — skipping."
    ;;
  DELETED)
    echo "⚠ Pool '$POOL_NAME' is DELETED — undeleting..."
    gcloud iam workload-identity-pools undelete "$POOL_NAME" \
      --location="$LOCATION" \
      --project="$PROJECT_ID"
    echo "✔ Pool '$POOL_NAME' undeleted."
    ;;
  NOT_FOUND)
    echo "➕ Pool '$POOL_NAME' not found — creating..."
    gcloud iam workload-identity-pools create "$POOL_NAME" \
      --project="$PROJECT_ID" \
      --location="$LOCATION" \
      --display-name="$DISPLAY_NAME" \
      --description="Pool for GitLab CI/CD"
    echo "✔ Pool '$POOL_NAME' created."
    ;;
  *)
    echo "❌ Unexpected pool state: '$POOL_STATE'. Aborting." >&2
    exit 1
    ;;
esac

# ─────────────────────────────────────────────
# 2️⃣  OIDC Provider
# ─────────────────────────────────────────────
echo ""
echo "=== Managing OIDC Provider: $PROVIDER_NAME ==="

PROVIDER_STATE=$(gcloud iam workload-identity-pools providers describe "$PROVIDER_NAME" \
  --workload-identity-pool="$POOL_NAME" \
  --location="$LOCATION" \
  --project="$PROJECT_ID" \
  --format="value(state)" 2>/dev/null || echo "NOT_FOUND")

case "$PROVIDER_STATE" in
  ACTIVE)
    echo "✔ Provider '$PROVIDER_NAME' is already ACTIVE — updating to ensure config is current..."
    gcloud iam workload-identity-pools providers update-oidc "$PROVIDER_NAME" \
      --project="$PROJECT_ID" \
      --location="$LOCATION" \
      --workload-identity-pool="$POOL_NAME" \
      --display-name="$DISPLAY_NAME" \
      --issuer-uri="$ISSUER_URI" \
      --attribute-mapping="$ATTRIBUTE_MAPPING" \
      --attribute-condition="$ATTRIBUTE_CONDITION"
    echo "✔ Provider '$PROVIDER_NAME' updated."
    ;;
  DELETED)
    echo "⚠ Provider '$PROVIDER_NAME' is DELETED — undeleting then updating..."
    gcloud iam workload-identity-pools providers undelete "$PROVIDER_NAME" \
      --workload-identity-pool="$POOL_NAME" \
      --location="$LOCATION" \
      --project="$PROJECT_ID"
    gcloud iam workload-identity-pools providers update-oidc "$PROVIDER_NAME" \
      --project="$PROJECT_ID" \
      --location="$LOCATION" \
      --workload-identity-pool="$POOL_NAME" \
      --display-name="$DISPLAY_NAME" \
      --issuer-uri="$ISSUER_URI" \
      --attribute-mapping="$ATTRIBUTE_MAPPING" \
      --attribute-condition="$ATTRIBUTE_CONDITION"
    echo "✔ Provider '$PROVIDER_NAME' undeleted and updated."
    ;;
  NOT_FOUND)
    echo "➕ Provider '$PROVIDER_NAME' not found — creating..."
    gcloud iam workload-identity-pools providers create-oidc "$PROVIDER_NAME" \
      --project="$PROJECT_ID" \
      --location="$LOCATION" \
      --workload-identity-pool="$POOL_NAME" \
      --display-name="$DISPLAY_NAME" \
      --issuer-uri="$ISSUER_URI" \
      --attribute-mapping="$ATTRIBUTE_MAPPING" \
      --attribute-condition="$ATTRIBUTE_CONDITION"
    echo "✔ Provider '$PROVIDER_NAME' created."
    ;;
  *)
    echo "❌ Unexpected provider state: '$PROVIDER_STATE'. Aborting." >&2
    exit 1
    ;;
esac

echo ""
echo "✅ Workload Identity Federation setup completed!"