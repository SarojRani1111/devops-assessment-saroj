#!/bin/bash

set -e

# ── Variables ─────────────────────────────────────────────────
AWS_ACCOUNT_ID="${AWS_ACCOUNT_ID}"
AWS_REGION="${AWS_REGION:-us-east-1}"
ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
CLUSTER_NAME="${CLUSTER_NAME:-devops-sr-dev-eks}"
IMAGE_TAG="${1:-latest}"
NAMESPACE="app"

echo "Deploying to EKS cluster: ${CLUSTER_NAME}"
echo "Image tag: ${IMAGE_TAG}"

# ── Update kubeconfig ─────────────────────────────────────────
echo "Updating kubeconfig..."
aws eks update-kubeconfig \
  --name ${CLUSTER_NAME} \
  --region ${AWS_REGION}

# ── Create namespace if not exists ───────────────────────────
echo "Creating namespace ${NAMESPACE}..."
kubectl get namespace ${NAMESPACE} 2>/dev/null || \
  kubectl create namespace ${NAMESPACE}

# ── Install Nginx Ingress ─────────────────────────────────────
echo "Installing Nginx Ingress Controller..."
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.replicaCount=1

# ── Deploy Frontend ───────────────────────────────────────────
echo "Deploying frontend..."
helm upgrade --install frontend ./kubernetes/helm/frontend \
  --namespace ${NAMESPACE} \
  --create-namespace \
  --set image.repository=${ECR_REGISTRY}/frontend \
  --set image.tag=${IMAGE_TAG} \
  --wait

# ── Deploy Backend ────────────────────────────────────────────
echo "Deploying backend..."
helm upgrade --install backend ./kubernetes/helm/backend \
  --namespace ${NAMESPACE} \
  --create-namespace \
  --set image.repository=${ECR_REGISTRY}/backend \
  --set image.tag=${IMAGE_TAG} \
  --wait

# ── Verify deployments ────────────────────────────────────────
echo "Verifying deployments..."
kubectl rollout status deployment/frontend-frontend -n ${NAMESPACE}
kubectl rollout status deployment/backend-backend -n ${NAMESPACE}

echo "Deployment complete!"
kubectl get all -n ${NAMESPACE}