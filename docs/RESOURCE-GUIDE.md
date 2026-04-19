# Resource recommendations

Rough **dev** targets; tune `requests`/`limits` per namespace quotas.

## Without GPU (current)

| Service | CPU (requests) | RAM (requests) | Notes |
|---------|----------------|----------------|--------|
| Milvus standalone | 500m–1000m | 2–4 Gi | One pod; gRPC 19530 |
| PostgreSQL (Langfuse) | 250m | 512 Mi–1 Gi | + PVC 10–20 Gi |
| Redis (Langfuse) | 100m | 256 Mi | `emptyDir` ok for dev |
| Langfuse web | 250m | 512 Mi | Depends on Postgres/Redis |
| TEI (embeddings) | 500m–1000m | 2–4 Gi | Smaller models use less |
| vLLM (CPU) | 1000m–2000m | 4–8 Gi | Slow; TinyLlama-class models |
| SGLang | 500m–1000m | 4 Gi | GPU strongly preferred |
| OCR (FastAPI) | 200m | 512 Mi–1 Gi | ONNX models |

## With GPU (e.g. GTX 1070 8 GB)

| Service | GPU | VRAM | Notes |
|---------|-----|------|--------|
| vLLM | 1× NVIDIA | 6–8 GB used | Use 7B quantized (AWQ/GPTQ) or smaller |
| SGLang | 1× NVIDIA | similar | Same node or separate GPU pod |
| TEI | optional CPU | — | Keeps GPU for generation |

Install **GPU Operator**, label nodes, set:

```yaml
resources:
  limits:
    nvidia.com/gpu: 1
```

## Namespace quotas (this repo)

See `namespaces/resource-quotas.yaml`: aggregate caps per namespace so one service cannot starve others.
