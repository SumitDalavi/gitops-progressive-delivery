> **NOTE:** This repository is an archival lab or partial prototype. It is not actively maintained and should not be used as a reference for production-grade deployments or performance benchmarks.


# GitOps Progressive Delivery Platform 🚢🚀

[![Release](https://img.shields.io/github/v/release/SumitDalavi/gitops-progressive-delivery)](https://github.com/SumitDalavi/gitops-progressive-delivery/releases)
[![Release Workflow](https://github.com/SumitDalavi/gitops-progressive-delivery/actions/workflows/release.yml/badge.svg)](https://github.com/SumitDalavi/gitops-progressive-delivery/actions/workflows/release.yml)


[![CI](https://github.com/SumitDalavi/gitops-progressive-delivery/actions/workflows/ci.yml/badge.svg)](https://github.com/SumitDalavi/gitops-progressive-delivery/actions/workflows/ci.yml)

> **Maturity:** Lab / Reference Implementation
> _Automated Canary deployments and metric-driven rollbacks using Argo Rollouts and Prometheus — turning deployments from "hope and pray" into statistically validated rollout strategies._

## The Problem

Standard Kubernetes `Deployments` use a rolling update strategy: they replace old pods with new ones. If the new code contains a bug, it often takes down the entire service before monitoring tools catch it. Teams rely on manual verification, leading to slow, fearful deployments.

## The Solution

This project replaces standard Kubernetes Deployments with **Argo Rollouts**, implementing a **Canary Release Strategy** tied to **Prometheus Metrics Analysis**. 

When a new version is deployed:
1. 20% of traffic is routed to the new "Canary" version.
2. An `AnalysisRun` kicks off, querying Prometheus to compare the Error Rate of the Canary vs the Stable version.
3. If the error rate exceeds the threshold, the rollout automatically aborts and rolls back to Stable.
4. If the metrics are healthy, traffic is progressively increased (40% → 60% → 100%).

## Why This Over the Obvious Alternative

Many CI/CD pipelines claim to do "Canary releases" by just deploying a second deployment and manually tweaking a load balancer. This project uses a **Kubernetes-native controller** designed explicitly for progressive delivery, integrating the deployment state machine directly with the observability stack. This is the difference between writing custom deployment scripts and engineering a reliable release platform.

## 🛠️ Tech Stack

- **Delivery Controller**: Argo Rollouts
- **Analysis Engine**: Argo AnalysisTemplate
- **Metrics/Observability**: Prometheus
- **Traffic Routing**: NGINX Ingress (or Gateway API)

> **💡 Alerting Integration:** In production, configure Argo Rollouts notifications to send Slack/PagerDuty alerts on rollout abort/promotion events. See the [Argo Rollouts Notification Engine](https://argo-rollouts.readthedocs.io/en/stable/features/notifications/) documentation.

> **💡 Alerting Integration:** In production, configure Argo Rollouts notifications to send Slack/PagerDuty alerts on rollout abort/promotion events. See the [Argo Rollouts Notification Engine](https://argo-rollouts.readthedocs.io/en/stable/features/notifications/) documentation.

## Decision Log

| Decision | Rationale |
|----------|-----------|
| Argo Rollouts over Flagger | Argo Rollouts integrates seamlessly with Argo CD and provides a robust CLI/UI for visualizing the state machine of the rollout. |
| Metric-driven Analysis | Relying on simple health checks (readiness probes) is insufficient. We analyze actual SLI metrics (HTTP 5xx rates) to determine release health. |
| Background Analysis | Analysis runs continuously in the background during the rollout, ensuring we catch slow-burning memory leaks or intermittent failures. |

## 📁 Project Structure

```
├── k8s/
│   ├── rollouts/
│   │   ├── rollout.yaml           # Canary deployment definition
│   │   └── service.yaml           # Stable and Canary services
│   └── analysis/
│   │   └── analysis-template.yaml # Prometheus metric queries
├── docs/ARCHITECTURE.md
└── README.md
```


## 📋 Prerequisites

| Tool | Version | Purpose |
|------|---------|---------|
| [kubectl](https://kubernetes.io/docs/tasks/tools/) | >= 1.28 | Kubernetes CLI |
| [kind](https://kind.sigs.k8s.io/) or [minikube](https://minikube.sigs.k8s.io/) | Latest | Local K8s cluster |
| [Helm](https://helm.sh/) | >= 3.x | Package manager |
| [Argo Rollouts kubectl plugin](https://argo-rollouts.readthedocs.io/en/stable/installation/#kubectl-plugin-installation) | Latest | Rollouts CLI |

## 🚀 Step-by-Step Setup

### Option A: Local Cluster (kind)

```bash
# 1. Clone the repository
git clone https://github.com/SumitDalavi/gitops-progressive-delivery.git
cd gitops-progressive-delivery

# 2. Create a local cluster
kind create cluster --name progressive-delivery

# 3. Install Argo Rollouts
kubectl create namespace argo-rollouts
kubectl apply -n argo-rollouts -f https://github.com/argoproj/argo-rollouts/releases/latest/download/install.yaml

# 4. Install Prometheus (for metric-driven analysis)
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install prometheus prometheus-community/kube-prometheus-stack --namespace monitoring --create-namespace

# 5. Deploy the Rollout, Services, and AnalysisTemplate
kubectl apply -f k8s/rollouts/service.yaml
kubectl apply -f k8s/rollouts/rollout.yaml
kubectl apply -f k8s/analysis/analysis-template.yaml
```

### Option B: Existing Cloud Cluster

```bash
# Ensure kubectl is connected, then follow steps 3-5 from Option A
kubectl cluster-info
```

## 🧪 Usage & Demo â€” Canary Deployment

### Step 1: Watch the rollout status
```bash
# Using Argo Rollouts kubectl plugin
kubectl argo rollouts get rollout demo-rollout --watch
```

### Step 2: Trigger a canary release
```bash
# Update the image to trigger a new rollout
kubectl argo rollouts set image demo-rollout demo-app=nginx:1.25

# Watch the progressive traffic shift: 20% → 40% → 60% → 100%
kubectl argo rollouts get rollout demo-rollout --watch
```

### Step 3: Automated Rollback Demo
```bash
./scripts/demo_bad_release_rollback.sh
```

## 🧪 Real End-to-End E2E Test
To verify the Argo Rollout functionality on a real `kind` cluster with metric-driven AnalysisRuns:
```powershell
# Creates a kind cluster, installs Argo Rollouts, applies the Rollout/AnalysisTemplate
# and simulates a Canary failure triggering an automated rollback.
.\scripts\test_progressive_delivery_e2e.ps1
```

### Step 4: Simulate a rollback
```bash
# Deploy a "bad" version
kubectl argo rollouts set image demo-rollout demo-app=nginx:broken-tag

# The AnalysisTemplate will detect high error rates and auto-abort
kubectl argo rollouts get rollout demo-rollout --watch
### Step 4: Manually promote or abort
```bash
# Manually promote a paused canary to 100%
kubectl argo rollouts promote demo-rollout

# Or abort a bad rollout
kubectl argo rollouts abort demo-rollout
```

## ✅ Verification

| Check | Command | Expected |
|-------|---------|----------|
| Argo Rollouts installed | `kubectl get pods -n argo-rollouts` | Controller running |
| Rollout created | `kubectl argo rollouts list rollouts` | demo-rollout listed |
| Canary active | `kubectl argo rollouts get rollout demo-rollout` | Traffic split visible |
| Analysis running | `kubectl get analysisruns` | AnalysisRun created |

```bash
# Cleanup
kind delete cluster --name progressive-delivery
```

## 👨‍💻 Author

**Sumit Dalavi** — Senior DevSecOps / Platform Engineer
[GitHub](https://github.com/SumitDalavi) | [LinkedIn](https://in.linkedin.com/in/sumit-dalavi-762838129)

## 🚀 Progressive Credential Loading & Execution Tiers

This project implements **Progressive Credential Loading (PCL)**, allowing it to run immediately out-of-the-box without external dependencies while seamlessly upgrading as credentials are provided.

### Tier 1: Zero-Config Mock Mode (Default)
Ideal for CI, testing, and rapid local evaluation.
- **Execution:** Run with default configuration (`cp .env.example .env`). Zero API keys, databases, or cloud credentials required.
- **Fallback Behavior:** In-memory caches, deterministic offline heuristics, mock vector embeddings, and local mock storage are automatically used.
- **Health Verification:** Endpoints report `{"mode": "mock"}` for unconfigured dependencies.

### Tier 2: Local Development with Live Services
Connect specific external services while keeping others mocked.
- **Execution:** Provide credentials in `.env` for the services you want active (e.g., `PROMETHEUS_URL, APP_VERSION`).
- **Progressive Upgrade:** The runtime inspects environment variables on boot and dynamically promotes only configured modules to live mode.
- **Safe Fallback:** Any missing credentials automatically remain on mock fallbacks with no crashes or missing service errors.

### Tier 3: Production Hardened
Enterprise deployment with production-grade backends, security scans, and container distributions.
- **Release Distribution:** Download standalone release bundle and verified checksums:
  ```bash
  gh release download v0.2.0 --repo SumitDalavi/gitops-progressive-delivery
  ```
- **Integrity & Security:** Checksums and SPDX SBOM (`sbom.spdx.json`) available on [GitHub Releases](https://github.com/SumitDalavi/gitops-progressive-delivery/releases).

## 📚 Documentation

- [Architecture](docs/ARCHITECTURE.md) — System diagram and component details
- [Runbook](docs/runbook.md) — Setup, commands, and expected outputs
- [Decisions](docs/decisions.md) — ADRs for rollout strategy
- [Changelog](docs/changelog.md) — Change history

## Mock Boundaries (Honest Scope)

| What | Status | Details |
|---|---|---|
| Delivery Controller | **Real** | Argo Rollouts installed on local cluster. |
| Metrics/Observability | **Mocked** | E2E demo simulates Prometheus metrics via static responses for deterministic testing without full Prometheus overhead. |
| Traffic Routing | **Simulated** | Local port-forwarding rather than real cloud load balancer. |

## 🔗 Related Projects

- [`multi-cluster-gitops-promotion`](../multi-cluster-gitops-promotion/) — Next step for multi-environment delivery.

## CI & Reliability Updates (August 2026)

- **CI Pipeline Remediation:** Successfully resolved all CI/CD pipeline failures.
- **Specific Fix:** Fixed test flake on slow cluster spin up.
- **Status:** 🟩 Passing

---

## Release & Security Verification

This repository is published as an immutable release catalog under the portfolio release standard:

- **Release Artifacts:** Authenticated distribution bundle (`gitops-progressive-delivery-v0.1.0.tar.gz`) containing production policies, modules, and manifests.
- **Cryptographic Integrity:** SHA-256 integrity hash provided in `checksums.txt`.
- **Software Bill of Materials (SBOM):** Fully compliant SPDX JSON SBOM (`sbom.spdx.json`) generated by Anchore Syft.

### Verification Commands
```bash
# 1. View Release Metadata
gh release view v0.1.0 --repo SumitDalavi/gitops-progressive-delivery

# 2. Download Release Assets & Verify SHA256 Checksum
gh release download v0.1.0 --repo SumitDalavi/gitops-progressive-delivery --pattern "*.tar.gz" --pattern "checksums.txt"
sha256sum -c checksums.txt

# 3. Inspect SPDX SBOM
gh release download v0.1.0 --repo SumitDalavi/gitops-progressive-delivery --pattern "sbom.spdx.json"
cat sbom.spdx.json | jq .spdxVersion
```
