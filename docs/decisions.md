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
