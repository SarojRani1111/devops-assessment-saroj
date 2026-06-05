#!/bin/bash

set -e


# ── Variables ─────────────────────────────────────────────────
AWS_ACCOUNT_ID="${AWS_ACCOUNT_ID}"
AWS_REGION="${AWS_REGION:-us-east-1}"
ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
IMAGE_TAG="${1:-latest}"

echo "Building Docker images..."
echo "Registry: ${ECR_REGISTRY}"
echo "Tag: ${IMAGE_TAG}"

# ── Login to ECR ──────────────────────────────────────────────
echo "Logging in to ECR..."
aws ecr get-login-password --region ${AWS_REGION} | \
  docker login --username AWS --password-stdin ${ECR_REGISTRY}

# ── Create ECR repos if not exists ───────────────────────────
echo "Creating ECR repositories if not exists..."
aws ecr describe-repositories --repository-names frontend \
  --region ${AWS_REGION} 2>/dev/null || \
  aws ecr create-repository --repository-name frontend \
  --region ${AWS_REGION}

aws ecr describe-repositories --repository-names backend \
  --region ${AWS_REGION} 2>/dev/null || \
  aws ecr create-repository --repository-name backend \
  --region ${AWS_REGION}

# ── Build Frontend ────────────────────────────────────────────
echo "Building frontend image..."
docker build -t frontend:${IMAGE_TAG} ./docker/frontend
docker tag frontend:${IMAGE_TAG} ${ECR_REGISTRY}/frontend:${IMAGE_TAG}

# ── Build Backend ─────────────────────────────────────────────
echo "Building backend image..."
docker build -t backend:${IMAGE_TAG} ./docker/backend
docker tag backend:${IMAGE_TAG} ${ECR_REGISTRY}/backend:${IMAGE_TAG}

# ── Push images ───────────────────────────────────────────────
echo "Pushing images to ECR..."
docker push ${ECR_REGISTRY}/frontend:${IMAGE_TAG}
docker push ${ECR_REGISTRY}/backend:${IMAGE_TAG}

echo "Done! Images pushed successfully."
echo "Frontend: ${ECR_REGISTRY}/frontend:${IMAGE_TAG}"
echo "Backend:  ${ECR_REGISTRY}/backend:${IMAGE_TAG}"