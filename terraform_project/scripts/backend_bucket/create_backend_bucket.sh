#!/bin/bash

# bucket name from first argument
TF_STATE_BUCKET=$1

# fallback to defaults if env vars missing
REGION=${TF_REGION}
GCP_PROJECT=${GOOGLE_PROJECT}

echo "TF_STATE_BUCKET=$TF_STATE_BUCKET"
echo "GCP_PROJECT=$GCP_PROJECT"
echo "REGION=$REGION"

gcloud auth list

echo "Checking if bucket exists..."
if gsutil ls -b gs://$TF_STATE_BUCKET >/dev/null 2>&1; then
  echo "Bucket already exists"
else
  echo "Creating Terraform backend bucket..."
  gsutil mb -p $GCP_PROJECT -l $REGION gs://$TF_STATE_BUCKET
  gsutil versioning set on gs://$TF_STATE_BUCKET
fi