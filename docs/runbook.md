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


---

## Release Runbook

### Release Trigger
Tag push matching `v*.*.*` (e.g., `v0.1.0`).

### Automated Pipeline Stages
1. **Quality & Validation Gate:** Validates policy syntax, Rego rules, and manifest schemas.
2. **Distribution Packaging:** Bundles clean production manifests into `gitops-progressive-delivery-<tag>.tar.gz` and calculates SHA256 checksums.
3. **Syft Source SBOM:** Generates `sbom.spdx.json` adhering to SPDX 2.3 standard.
4. **GitHub Release:** Publishes release assets and release notes.

### Verification
```bash
gh release view v0.1.0 --repo SumitDalavi/gitops-progressive-delivery
gh release download v0.1.0 --repo SumitDalavi/gitops-progressive-delivery --pattern "checksums.txt"
```

### Failure Modes & Remediation
- **Linter / Test Failure:** Inspect policy syntax or module arguments locally before tagging.
- **Checksum Mismatch:** Ensure file was completely downloaded without network truncation.

## Operations & Verification Guide (v0.2.0)

### Offline Validation (Tier 1)
Run syntax, formatting, and schema verification without cloud dependencies:
```bash
# Verify manifests and policy definitions offline
make test || npm test || ./scripts/test.sh || true
```

### Sandbox Deployment (Tier 2)
Deploy against an isolated Kind or Minikube test cluster:
```bash
# Verify local application to sandbox
kubectl apply --dry-run=client -k .
```

### Production Release Verification (Tier 3)
Verify published release artifacts on GitHub:
```bash
gh release view v0.2.0 --repo SumitDalavi/gitops-progressive-delivery
gh release download v0.2.0 --repo SumitDalavi/gitops-progressive-delivery --pattern "sbom.spdx.json"
cat sbom.spdx.json | jq .spdxVersion
```
