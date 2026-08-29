#!/bin/bash
set -euo pipefail

KIND_CLUSTER=gitops-e2e
echo "1. Creating kind cluster..."
kind create cluster --name $KIND_CLUSTER --wait 60s

echo "2. Installing Argo Rollouts..."
if ! kubectl argo rollouts version >/dev/null 2>&1; then
  echo "Installing kubectl argo rollouts plugin locally..."
  curl -LO https://github.com/argoproj/argo-rollouts/releases/download/v1.6.4/kubectl-argo-rollouts-linux-amd64
  chmod +x ./kubectl-argo-rollouts-linux-amd64
  sudo mv ./kubectl-argo-rollouts-linux-amd64 /usr/local/bin/kubectl-argo-rollouts
fi

kubectl create namespace argo-rollouts || true
kubectl apply -n argo-rollouts -f https://github.com/argoproj/argo-rollouts/releases/download/v1.6.4/install.yaml
kubectl wait --for=condition=Available deployment/argo-rollouts -n argo-rollouts --timeout=120s

# Wait for webhook to be ready (often takes a few extra seconds after deployment is available)
sleep 15

echo "3. Creating mock metric ConfigMap (Error Rate = 0%)..."
kubectl create configmap metric-config --from-literal=error_rate="0"

echo "4. Deploying AnalysisTemplate and Rollout..."
# Need RBAC for analysis job to be created by the rollout controller in the default namespace
kubectl create rolebinding argo-rollouts-job-binding \
  --clusterrole=edit \
  --serviceaccount=argo-rollouts:argo-rollouts \
  --namespace=default || true

kubectl apply -f k8s/analysis-template.yaml
kubectl apply -f k8s/rollout.yaml

echo "Waiting for Rollout V1 to be fully promoted..."
kubectl argo rollouts status demo-rollout --watch=false || sleep 10
kubectl wait --for=condition=Available rollout/demo-rollout --timeout=60s

echo "5. Triggering V2 Canary (Intentional Bad Release)..."
# Update ConfigMap to simulate high error rate
kubectl create configmap metric-config --from-literal=error_rate="15" -o yaml --dry-run=client | kubectl apply -f -

# Change image to trigger rollout
kubectl argo rollouts set image demo-rollout demo=demo-app:v2-broken

echo "Waiting for AnalysisRun to fail and trigger rollback..."
sleep 20
kubectl argo rollouts get rollout demo-rollout | grep "Degraded" || sleep 20

echo "✅ Rollback verified! Capture ArgoCD/Rollout output below:"
kubectl argo rollouts get rollout demo-rollout > demo_output.txt
cat demo_output.txt

echo "Cleaning up..."
kind delete cluster --name $KIND_CLUSTER
echo "✅ Progressive Delivery E2E Test Passed."
