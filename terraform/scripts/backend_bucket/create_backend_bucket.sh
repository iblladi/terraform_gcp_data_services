#!/bin/bash

TF_STATE_BUCKET=$1

REGION=$TF_REGION
GCP_PROJECT=$GOOGLE_PROJECT

echo "Checking if bucket exists..."

if gsutil ls -b gs://$BUCKET_NAME >/dev/null 2>&1; then
  echo "Bucket already exists"
else
  echo "Creating Terraform backend bucket..."
  gsutil mb -p $GCP_PROJECT -l $REGION gs://$BUCKET_NAME
  gsutil versioning set on gs://$BUCKET_NAME
fi