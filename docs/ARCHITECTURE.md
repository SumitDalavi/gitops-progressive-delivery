# Architecture: GitOps Progressive Delivery

## Moving Beyond "Deployments"
The standard K8s `Deployment` object provides minimal safety. It performs a rolling update based purely on Pod Readiness probes. But a pod can be "ready" (accepting TCP connections) while simultaneously returning HTTP 500s for every request.

## The Argo Rollouts State Machine
Argo Rollouts introduces a Custom Resource Definition (CRD) called `Rollout` that acts as a drop-in replacement for `Deployment`. 

The core of this architecture is the **Canary State Machine**:
1. **setWeight: 20**: The Ingress controller is programmed to route exactly 20% of HTTP traffic to the new ReplicaSet.
2. **AnalysisRun**: An `AnalysisRun` controller triggers a Prometheus query. It calculates the Success Rate SLI (2xx/3xx vs 5xx).
3. **Decision Gate**:
   - If the Success Rate < 99%, the Rollout is instantly **aborted**. Traffic routing reverts to 100% stable, and the canary pods are killed.
   - If Success Rate >= 99%, the state machine advances.
4. **Progression**: The weight scales up to 40%, 60%, 80%, and finally 100%.

## Integrations
This pattern requires tight integration between:
- The **GitOps Engine** (ArgoCD syncing the desired Rollout state)
- The **Progressive Delivery Controller** (Argo Rollouts)
- The **Observability Stack** (Prometheus)
- The **Ingress Layer** (NGINX/ALB/GatewayAPI capable of weighted traffic splitting)
