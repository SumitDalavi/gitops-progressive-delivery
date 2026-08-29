# Runbook — gitops-progressive-delivery
> Last updated: 2026-08-29

## Quick Start
```bash
# Bring up the cluster and deploy Argo Rollouts
kind create cluster --name progressive-delivery
kubectl create namespace argo-rollouts
kubectl apply -n argo-rollouts -f https://github.com/argoproj/argo-rollouts/releases/latest/download/install.yaml
```

## Run Tests / Demos
```bash
bash scripts/demo_bad_release_rollback.sh
```

## Failure Modes
| Symptom | Cause | Fix |
|---|---|---|
| Rollout stuck in "Paused" | Analysis template failed or metrics unavailable | Check the AnalysisRun logs |
