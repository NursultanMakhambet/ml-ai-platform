#!/usr/bin/env bash
set -euo pipefail
export KUBECONFIG="${KUBECONFIG:-$HOME/.kube/config}"

for ns in milvus langfuse embeddings vllm sglang ocr; do
  echo "==> Namespace $ns"
  kubectl get pods -n "$ns" -o wide || true
done

echo "==> Ingress (ML)"
kubectl get ingress -A | grep -E 'langfuse|vllm|sglang|ocr|embeddings|NAMESPACE' || true

NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
echo "Tip: curl -H \"Host: ocr.local\" http://${NODE_IP}:30801/health"
