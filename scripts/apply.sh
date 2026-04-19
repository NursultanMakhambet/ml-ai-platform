#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
export KUBECONFIG="${KUBECONFIG:-$HOME/.kube/config}"

echo "==> Namespaces + quotas"
kubectl apply -f "$ROOT/namespaces/namespaces.yaml"
kubectl apply -f "$ROOT/namespaces/resource-quotas.yaml"

if [[ ! -f "$ROOT/secrets/langfuse-secrets.yaml" ]]; then
  echo "ERROR: Missing $ROOT/secrets/langfuse-secrets.yaml — run: bash scripts/gen-secrets.sh"
  exit 1
fi

echo "==> Langfuse secrets"
kubectl apply -f "$ROOT/secrets/langfuse-secrets.yaml"

echo "==> Langfuse data plane"
kubectl apply -f "$ROOT/langfuse/postgres.yaml"
kubectl apply -f "$ROOT/langfuse/redis.yaml"
echo "Waiting for postgres..."
kubectl wait --for=condition=ready pod -l app=postgres -n langfuse --timeout=300s

echo "==> Milvus"
kubectl apply -f "$ROOT/milvus/pvc.yaml"
kubectl apply -f "$ROOT/milvus/deployment.yaml"

echo "==> Langfuse app"
kubectl apply -f "$ROOT/langfuse/langfuse-deployment.yaml"

echo "==> Embeddings / OCR / LLM"
kubectl apply -f "$ROOT/embeddings/tei-deployment.yaml"
kubectl apply -f "$ROOT/ocr/configmap.yaml"
kubectl apply -f "$ROOT/ocr/deployment.yaml"
kubectl apply -f "$ROOT/vllm/deployment.yaml"
kubectl apply -f "$ROOT/sglang/deployment.yaml"

echo "==> Ingress"
kubectl apply -f "$ROOT/ingress/ml-ai-ingresses.yaml"

echo "Done. Add hosts + use port 30801 (see README). Verify: bash scripts/verify.sh"
