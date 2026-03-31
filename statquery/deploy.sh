#!/bin/bash
# ============================================================
# StatQuery — Full Deploy Script
# Track 3: Gen AI Academy APAC
# Project: my-project-31-491314
# ============================================================
# USAGE: Fill in the VARIABLES section below, then run:
#   chmod +x deploy.sh && sh deploy.sh
# ============================================================

set -e

# ============================================================
# VARIABLES — fill these in before running
# ============================================================
PROJECT_ID="my-project-31-491314"
REGION="us-central1"
APP_NAME="statquery"
GEMINI_API_KEY="YOUR_GEMINI_API_KEY"
ALLOYDB_PASSWORD="YOUR_ALLOYDB_PASSWORD"
ALLOYDB_PRIVATE_IP="YOUR_ALLOYDB_PRIVATE_IP"     # e.g. 10.50.0.2
NETWORK_NAME="YOUR_VPC_NETWORK_NAME"              # e.g. default
SUBNET_NAME="YOUR_SUBNET_NAME"                    # e.g. default
# ============================================================

DATABASE_URL="postgresql+pg8000://postgres:${ALLOYDB_PASSWORD}@${ALLOYDB_PRIVATE_IP}:5432/postgres"

echo "🚀 StatQuery Deploy Script"
echo "================================="
echo "Project  : $PROJECT_ID"
echo "Region   : $REGION"
echo "App name : $APP_NAME"
echo ""

# Step 1: Set project
echo "📌 Step 1: Setting GCP project..."
gcloud config set project $PROJECT_ID

# Step 2: Enable required APIs
echo "📌 Step 2: Enabling required APIs..."
gcloud services enable \
  run.googleapis.com \
  cloudbuild.googleapis.com \
  alloydb.googleapis.com \
  aiplatform.googleapis.com \
  --project=$PROJECT_ID

echo "✅ APIs enabled."

# Step 3: Deploy to Cloud Run
echo "📌 Step 3: Deploying to Cloud Run (source deploy)..."
gcloud beta run deploy $APP_NAME \
  --source . \
  --region=$REGION \
  --network=$NETWORK_NAME \
  --subnet=$SUBNET_NAME \
  --allow-unauthenticated \
  --vpc-egress=all-traffic \
  --memory=1Gi \
  --cpu=1 \
  --timeout=120 \
  --set-env-vars GEMINI_API_KEY=$GEMINI_API_KEY,DATABASE_URL=$DATABASE_URL \
  --project=$PROJECT_ID

echo ""
echo "✅ StatQuery deployed successfully!"
echo ""
echo "🌐 App URL:"
gcloud run services describe $APP_NAME --region=$REGION --format='value(status.url)' --project=$PROJECT_ID
echo ""
echo "📋 View logs:"
echo "  gcloud run logs read $APP_NAME --region=$REGION --limit=50"
