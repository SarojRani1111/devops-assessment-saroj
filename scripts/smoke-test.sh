#!/bin/bash

set -e

# ── Variables ─────────────────────────────────────────────────
NAMESPACE="app"
MAX_RETRIES=10
RETRY_INTERVAL=10

echo "Running smoke tests..."

# ── Wait for pods to be ready ─────────────────────────────────
echo "Waiting for pods to be ready..."
kubectl wait --for=condition=ready pod \
  -l app=frontend-frontend \
  -n ${NAMESPACE} \
  --timeout=120s

kubectl wait --for=condition=ready pod \
  -l app=backend-backend \
  -n ${NAMESPACE} \
  --timeout=120s

# ── Port forward and test ─────────────────────────────────────
echo "Testing backend health endpoint..."
kubectl port-forward \
  svc/backend-backend ${NAMESPACE}:3001:3001 &
PF_PID=$!
sleep 5

# ── Test endpoints ────────────────────────────────────────────
echo "Testing /health endpoint..."
HEALTH_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" \
  http://localhost:3001/health)

if [ "${HEALTH_RESPONSE}" == "200" ]; then
  echo " /health endpoint passed (HTTP ${HEALTH_RESPONSE})"
else
  echo " /health endpoint failed (HTTP ${HEALTH_RESPONSE})"
  kill ${PF_PID}
  exit 1
fi

echo "Testing /metrics endpoint..."
METRICS_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" \
  http://localhost:3001/metrics)

if [ "${METRICS_RESPONSE}" == "200" ]; then
  echo "/metrics endpoint passed (HTTP ${METRICS_RESPONSE})"
else
  echo " /metrics endpoint failed (HTTP ${METRICS_RESPONSE})"
  kill ${PF_PID}
  exit 1
fi

# ── Cleanup port forward ──────────────────────────────────────
kill ${PF_PID}

# ── Show running resources ────────────────────────────────────
echo ""
echo "=== Running Resources ==="
kubectl get pods -n ${NAMESPACE}
kubectl get services -n ${NAMESPACE}
kubectl get hpa -n ${NAMESPACE}
kubectl get cronjobs -n ${NAMESPACE}

echo ""
echo " All smoke tests passed!"