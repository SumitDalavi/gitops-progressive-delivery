#!/bin/bash
set -e

echo "Running Conftest on Argo Rollout manifests..."
# Assuming conftest is installed, testing the rollout against the policies
# Using dockerized conftest for portable execution
docker run --rm -v $(pwd):/project openpolicyagent/conftest test /project/k8s/rollout.yaml -p /project/policies/rollout-validation.rego

echo "✅ Rollout manifests pass policy checks!"
