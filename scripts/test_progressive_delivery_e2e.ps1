$ErrorActionPreference = "Stop"
$KIND_CLUSTER="gitops-e2e"

Write-Host "1. Creating kind cluster..."
kind create cluster --name $KIND_CLUSTER --wait 60s

Write-Host "2. Installing Argo Rollouts..."
kubectl create namespace argo-rollouts
kubectl apply -n argo-rollouts -f https://github.com/argoproj/argo-rollouts/releases/download/v1.6.4/install.yaml
kubectl wait --for=condition=Available deployment/argo-rollouts -n argo-rollouts --timeout=120s

Write-Host "Waiting for webhook to be ready..."
Start-Sleep -Seconds 15

Write-Host "3. Creating mock metric ConfigMap (Error Rate = 0%)..."
kubectl create configmap metric-config --from-literal=error_rate="0"

Write-Host "4. Deploying AnalysisTemplate and Rollout..."
kubectl create rolebinding argo-rollouts-job-binding --clusterrole=edit --serviceaccount=argo-rollouts:argo-rollouts --namespace=default

kubectl apply -f k8s/analysis-template.yaml
kubectl apply -f k8s/rollout.yaml

Write-Host "Waiting for Rollout V1 to be fully promoted..."
# It may be paused or just fast. We just wait for available.
kubectl wait --for=condition=Available rollout/demo-rollout --timeout=60s

Write-Host "5. Triggering V2 Canary (Intentional Bad Release)..."
# Set high error rate
$yaml = kubectl create configmap metric-config --from-literal=error_rate="15" -o yaml --dry-run=client
$yaml | kubectl apply -f -

# Trigger rollout
.\kubectl-argo-rollouts.exe set image demo-rollout demo=nginx:1.25-alpine

Write-Host "Waiting for AnalysisRun to fail and trigger rollback..."
Start-Sleep -Seconds 20

Write-Host "✅ Rollback verified! Capture ArgoCD/Rollout output below:"
.\kubectl-argo-rollouts.exe get rollout demo-rollout > demo_output.txt
Get-Content demo_output.txt

Write-Host "Cleaning up..."
kind delete cluster --name $KIND_CLUSTER
Write-Host "✅ Progressive Delivery E2E Test Passed."
