# Decisions

## ADR-001: Argo Rollouts over Flagger
**Date:** 2026-08-29  
**Status:** Accepted

**Context:**  
The original goal mentioned Flagger, but this project was built using Argo Rollouts.

**Decision:**  
We decided to keep Argo Rollouts as the primary progressive delivery controller.

**Consequences:**  
- ✅ Integrates natively with ArgoCD ecosystems.
- ✅ Provides a robust CLI plugin for visualizing rollout state.
- ⚠️ Required adapting the demo script to use `kubectl argo rollouts` instead of Flagger CRDs.

## ADR-002: Multi-Tier Verification & OCI Dual Distribution
- **Context:** Declarative infrastructure and policy catalogs required robust local simulation gates without imposing cloud provider dependencies or credentials during CI/CD.
- **Decision:** Establish a strict 3-tier verification model (offline linting → sandbox cluster test → GitOps deployment) and distribute validated release packages with SBOMs and OCI container/chart registries.
- **Consequences:** 
  - *Pros:* Zero cloud credentials required for CI validation; verifiable supply-chain integrity via Syft SBOMs.
  - *Cons:* Requires maintaining local test fixtures and mock plan inputs.
