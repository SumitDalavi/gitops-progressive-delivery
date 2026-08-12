# GitOps Progressive Delivery Platform 🚢🚀

> Automated Canary deployments and metric-driven rollbacks using Argo Rollouts and Prometheus — turning deployments from "hope and pray" into statistically validated rollout strategies.

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

## 👨‍💻 Author

*Built to demonstrate advanced GitOps patterns and reliability-aware deployment automation.*
