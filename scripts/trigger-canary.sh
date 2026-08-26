#!/usr/bin/env bash
# Trigger a canary release using Argo Rollouts
set -euo pipefail

APP="${1:?Usage: $0 <app-name> <new-image-tag>}"
TAG="${2:?}"
NAMESPACE="${NAMESPACE:-demo}"

log() { echo "[canary] $*"; }

log "Triggering canary release: $APP → $TAG"

# Set the new image (triggers the canary rollout)
kubectl argo rollouts set image "$APP" "$APP=myapp:$TAG" -n "$NAMESPACE"

log "Canary rollout started. Monitoring..."
kubectl argo rollouts get rollout "$APP" -n "$NAMESPACE" --watch --timeout=10m &
WATCH_PID=$!

# Poll for rollout completion
for i in $(seq 1 60); do
    STATUS=$(kubectl argo rollouts get rollout "$APP" -n "$NAMESPACE"         -o json 2>/dev/null | python3 -c "import json,sys; print(json.load(sys.stdin).get('status',{}).get('phase','unknown'))" 2>/dev/null || echo "unknown")
    log "Status: $STATUS (attempt $i/60)"
    [[ "$STATUS" == "Healthy" ]] && { log "SUCCESS: Canary promoted to 100%"; kill $WATCH_PID 2>/dev/null; exit 0; }
    [[ "$STATUS" == "Degraded" ]] && { log "FAIL: Rollout degraded — auto-rollback triggered"; kill $WATCH_PID 2>/dev/null; exit 1; }
    sleep 10
done

kill $WATCH_PID 2>/dev/null
log "TIMEOUT: Rollout did not complete in 10 minutes"
exit 1
