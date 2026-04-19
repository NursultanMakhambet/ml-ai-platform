# ml-ai-platform

Kubernetes manifests and docs for a **dev** AI/ML stack: **OCR → embeddings → Milvus → LLM (vLLM / SGLang)**, with **Langfuse** tracing.

## What each component does

| Component | Role |
|-----------|------|
| **OCR** | Turns images/PDFs into text (RapidOCR in a small FastAPI app). |
| **Embeddings (TEI)** | Turns text into vectors for Milvus (Hugging Face Text Embeddings Inference, CPU). |
| **Milvus** | Vector database: store and search embeddings. |
| **vLLM** | OpenAI-compatible LLM HTTP API (CPU mode here; switch to GPU when a node has an NVIDIA GPU + GPU Operator). |
| **SGLang** | Structured generation / alternative LLM runtime (often GPU-oriented; CPU may be limited). |
| **Langfuse** | Traces and observability for LLM calls (needs PostgreSQL + Redis). |

## How they interact

1. **Document/image** → **OCR** → text.  
2. Text → **TEI** → embedding vector → **Milvus** (insert/search).  
3. Retrieved context + user prompt → **vLLM** or **SGLang** → answer.  
4. **Langfuse** records spans/events from apps that use its SDK (see `docs/INTEGRATION.md`).

## Storage (your Proxmox pools)

| Pool | Typical use now | Notes |
|------|-----------------|--------|
| **NVME_STORAGE_FAST1** (~300 GB) | Fast PVCs (Postgres, Milvus, Langfuse) | Prefer `local-path` / NVMe-backed classes for latency-sensitive data. |
| **HDD_STORAGE_SLOW1** (1 TB) | ISOs, backups | Not ideal for random I/O databases. |
| **Future HDD_STORAGE_1x3TB** | Large cold files, archives, extra PVCs | Add a StorageClass pointing at this pool when ready; migrate or bind new PVCs there. |

Today’s cluster uses **`local-path` (default)** on nodes’ disks (often NVMe). When you add a **3 TB HDD**, create a **new StorageClass** (e.g. `hdd-slow`) and set `storageClassName` on specific PVCs that need bulk/cheap space.

## Quick start

```bash
export KUBECONFIG=~/.kube/config-localVM   # or your kubeconfig

# 1) Create secrets (edit secrets/secrets.env.example → secrets.env, then:)
kubectl apply -f secrets/generated-secrets.yaml   # after running scripts/gen-secrets.sh if provided

# 2) Apply in order (namespaces → data → apps → ingress)
./scripts/apply.sh

# 3) Verify
./scripts/verify.sh
```

Full steps: **`docs/DEPLOYMENT.md`**. Integration flow: **`docs/INTEGRATION.md`**. Sizes and limits: **`docs/RESOURCE-GUIDE.md`**.

## Repo layout

- `namespaces/` — namespaces + ResourceQuota  
- `milvus/`, `langfuse/`, `embeddings/`, `vllm/`, `sglang/`, `ocr/` — workloads  
- `ingress/` — Ingress rules (adjust hosts / TLS)  
- `scripts/` — apply / verify helpers  
- `terraform/gpu-vm.tf.example` — optional Proxmox GPU worker VM  
- `docker-compose/docker-compose.dev.yml` — optional local smoke test (not identical to prod)

## GPU (later: GTX 1070 8 GB)

1. Add a GPU-capable node (VM with PCIe passthrough or physical host).  
2. Install **NVIDIA GPU Operator** (or device plugin + driver on the node).  
3. Switch **vLLM** / **SGLang** manifests to request `nvidia.com/gpu: 1` and use CUDA images (see `docs/RESOURCE-GUIDE.md`).  
4. Use `terraform/gpu-vm.tf.example` as a starting point for a Proxmox GPU VM.

## License

Configuration only; follow each upstream image’s license.
