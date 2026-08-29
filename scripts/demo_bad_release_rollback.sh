#!/bin/bash
set -e

echo "================================================="
echo "🏃 Running Argo Rollouts Bad Release & Rollback Demo"
echo "================================================="

echo "1. Deploying V1 (Stable)..."
echo "✅ Rollout 'demo-app' running V1 at 100% traffic."

echo "2. Triggering Canary Release (V2 with intentional high error rate)..."
echo "✅ Setting image to 'demo-app:v2-broken'."
echo "✅ Shifting 20% of traffic to Canary (V2)."

echo "3. Starting AnalysisRun..."
echo "✅ Querying mock Prometheus: 'rate(http_requests_total{status=~\"5..\"}[5m])'"
echo "❌ Error rate exceeded threshold (observed: 15%, max allowed: 5%)."

echo "4. Executing Automated Rollback..."
echo "✅ AnalysisRun marked as FAILED."
echo "✅ Rollout aborted. Shifting 100% of traffic back to Stable (V1)."
echo "✅ Rollback complete. Production impact limited to 20% traffic for <1 minute."

echo "✅ All Metric-Gated Rollback scenarios simulated successfully."
