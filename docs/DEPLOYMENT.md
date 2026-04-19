# Deployment order and commands

## Dependencies (order)

1. **Namespaces + ResourceQuota** — `namespaces/`  
2. **Secrets** — Langfuse needs `NEXTAUTH_SECRET`, `SALT`, DB passwords (see `secrets/README.md`)  
3. **PostgreSQL + Redis** — `langfuse/` (Langfuse depends on them)  
4. **Milvus** — `milvus/`  
5. **Langfuse** — `langfuse/langfuse-deployment.yaml`  
6. **TEI embeddings** — `embeddings/`  
7. **OCR** — `ocr/`  
8. **vLLM** — `vllm/` (large image; may take time)  
9. **SGLang** — `sglang/`  
10. **Ingress** — `ingress/`  

## Prerequisites

- Default **StorageClass** (e.g. `local-path`).  
- **Ingress controller** (e.g. ingress-nginx) if you use `ingress/`.  
- **Metrics server** optional (`kubectl top`).

## kubectl commands

```bash
# Namespaces (labels for governance / NetworkPolicy later)
kubectl apply -f namespaces/namespaces.yaml
kubectl apply -f namespaces/resource-quotas.yaml

# Secrets (create from your env file first)
kubectl apply -f secrets/langfuse-secrets.yaml

# Data plane
kubectl apply -f langfuse/postgres.yaml
kubectl apply -f langfuse/redis.yaml
kubectl wait --for=condition=ready pod -l app=postgres -n langfuse --timeout=300s
kubectl apply -f milvus/
kubectl apply -f langfuse/langfuse-deployment.yaml

# Apps
kubectl apply -f embeddings/
kubectl apply -f ocr/
kubectl apply -f vllm/
kubectl apply -f sglang/

# Ingress (edit hosts first)
kubectl apply -f ingress/
```

## Status

```bash
kubectl get pods -n milvus -o wide
kubectl get pods -n langfuse -o wide
kubectl get pods -n vllm -o wide
kubectl get pods -n sglang -o wide
kubectl get pods -n ocr -o wide
kubectl get pods -n embeddings -o wide
```

## Endpoints (in-cluster DNS)

| Service | DNS | Port |
|---------|-----|------|
| Milvus | `milvus.milvus.svc.cluster.local` | 19530 |
| Langfuse | `langfuse.langfuse.svc.cluster.local` | 3000 |
| TEI | `tei-embeddings.embeddings.svc.cluster.local` | 80 |
| vLLM | `vllm.vllm.svc.cluster.local` | 8000 |
| SGLang | `sglang.sglang.svc.cluster.local` | 30000 |
| OCR | `ocr.ocr.svc.cluster.local` | 8000 |

## Port-forward (local testing)

```bash
kubectl -n langfuse port-forward svc/langfuse 3000:3000
kubectl -n milvus port-forward svc/milvus 19530:19530
kubectl -n vllm port-forward svc/vllm 8000:8000
```

## Verify health

```bash
kubectl exec -n milvus deploy/milvus -- curl -sS localhost:9091/healthz || true
curl -sS http://127.0.0.1:3000/api/public/health -H "Host: langfuse.local"   # via ingress or port-forward
```

## Troubleshooting

| Symptom | Check |
|---------|--------|
| `Pending` pods | `kubectl describe pod` → PVC / quota / RAM |
| vLLM OOM | Lower `max-model-len` or use smaller model; add RAM limit |
| Milvus won’t start | Disk full; check PVC bound (`kubectl get pvc -n milvus`) |
| Langfuse 500 | Postgres URL, secrets, migrations (see Langfuse docs) |
| Image pull errors | Image tags / registry auth |
