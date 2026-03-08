#!/bin/bash

TF_STATE_BUCKET=$1

echo "TF_STATE_BUCKET=$TF_STATE_BUCKET"
echo "GCP_PROJECT=$GOOGLE_PROJECT"
echo "REGION=$TF_REGION"

echo "Checking if bucket exists..."

gcloud storage buckets describe gs://${TF_STATE_BUCKET} >/dev/null 2>&1

if [ $? -ne 0 ]; then
  echo "Creating Terraform backend bucket..."

  gcloud storage buckets create gs://${TF_STATE_BUCKET} \
      --project=${GOOGLE_PROJECT} \
      --location=${TF_REGION}

  echo "Enabling versioning..."

  gcloud storage buckets update gs://${TF_STATE_BUCKET} \
      --versioning
else
  echo "Bucket already exists."
fi