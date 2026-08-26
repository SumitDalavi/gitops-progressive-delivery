#!/usr/bin/env bash
# Emergency rollback — abort canary and return to stable
set -euo pipefail

APP="${1:?Usage: $0 <app-name>}"
NAMESPACE="${NAMESPACE:-demo}"

log() { echo "[rollback] $*"; }

log "EMERGENCY ROLLBACK: Aborting canary for $APP"
kubectl argo rollouts abort "$APP" -n "$NAMESPACE"

log "Promoting stable (restoring 100% stable traffic)"
kubectl argo rollouts undo "$APP" -n "$NAMESPACE"

log "Waiting for stable rollout to complete..."
kubectl argo rollouts status "$APP" -n "$NAMESPACE" --timeout=120s

log "Rollback complete. Current status:"
kubectl argo rollouts get rollout "$APP" -n "$NAMESPACE"
