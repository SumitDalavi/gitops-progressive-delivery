.PHONY: setup demo teardown canary-promote canary-abort verify help

CLUSTER_NAME := gitops-demo
ROLLOUT_NS := default

## setup: Create kind cluster and install Argo Rollouts
setup:
	@echo "🚀 Setting up GitOps Progressive Delivery demo..."
	kind create cluster --name $(CLUSTER_NAME) --wait 60s || echo "Cluster may already exist"
	kubectl apply -n argo-rollouts -f https://github.com/argoproj/argo-rollouts/releases/latest/download/install.yaml || true
	kubectl create namespace argo-rollouts --dry-run=client -o yaml | kubectl apply -f -
	kubectl wait --for=condition=Available deployment/argo-rollouts -n argo-rollouts --timeout=120s
	@echo "✅ Cluster ready with Argo Rollouts installed"

## demo: Run the progressive delivery demo (canary → promote → verify)
demo:
	@echo "🎯 Running Progressive Delivery demo..."
	bash scripts/test_progressive_delivery_e2e.sh 2>&1 | tee docs/run-history/$(shell date +%Y-%m-%d-%H)-demo.txt
	@echo "✅ Demo complete. See docs/run-history/ for output."

## canary-promote: Manually promote the active canary to 100%
canary-promote:
	kubectl argo rollouts promote rollout-demo -n $(ROLLOUT_NS)

## canary-abort: Abort the canary and rollback to stable
canary-abort:
	kubectl argo rollouts abort rollout-demo -n $(ROLLOUT_NS)
	bash scripts/rollback.sh

## verify: Check current rollout status
verify:
	kubectl argo rollouts status rollout-demo -n $(ROLLOUT_NS) || true
	bash scripts/validate-rollouts.sh

## teardown: Delete kind cluster
teardown:
	kind delete cluster --name $(CLUSTER_NAME)

## help: Show this help
help:
	@grep -E '^## ' Makefile | sed 's/## /  /'
