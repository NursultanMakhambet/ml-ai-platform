# Integration flow (conceptual)

Target pipeline:

1. **Document/image** → **OCR** (`http://ocr.ocr.svc.cluster.local:8000/ocr`) → **text**  
2. **Text** → **TEI** (`http://tei-embeddings.embeddings.svc.cluster.local/embed`) → **embedding**  
3. **Embedding** → **Milvus** (insert/query over gRPC `milvus.milvus:19530`)  
4. **Query** Milvus for context → build prompt → **vLLM** or **SGLang** OpenAI-compatible API  
5. **Langfuse** Python SDK in your worker records traces/spans (see [Langfuse docs](https://langfuse.com/docs)).

## Minimal Python sketch (run outside cluster or as a `Job`)

```python
# Pseudocode — install: pip install langfuse pymilvus openai requests

import os, requests
from openai import OpenAI

# Langfuse
from langfuse import Langfuse
lf = Langfuse(host=os.environ.get("LANGFUSE_HOST", "http://langfuse.langfuse.svc.cluster.local:3000"))

# 1) OCR
img = open("sample.png", "rb").read()
text = requests.post("http://ocr.ocr.svc.cluster.local:8000/ocr", files={"file": img}).json()["text"]

# 2) Embedding (TEI OpenAI-compatible)
emb = requests.post(
    "http://tei-embeddings.embeddings.svc.cluster.local/embed",
    json={"inputs": text[:2000]},
).json()

# 3) Milvus: use pymilvus to insert/search (collection/schema setup required — see Milvus docs)

# 4) LLM
client = OpenAI(base_url="http://vllm.vllm.svc.cluster.local:8000/v1", api_key="EMPTY")
resp = client.chat.completions.create(model="TinyLlama/TinyLlama-1.1B-Chat-v1.0", messages=[{"role": "user", "content": text}])
```

## Critical env vars (examples)

| Variable | Example | Purpose |
|----------|---------|---------|
| `MILVUS_URI` | `http://milvus.milvus:19530` | Milvus endpoint |
| `OPENAI_BASE_URL` | `http://vllm.vllm:8000/v1` | Route SDK to vLLM |
| `LANGFUSE_HOST` | `http://langfuse.langfuse:3000` | Langfuse API |
| `TEI_URL` | `http://tei-embeddings.embeddings` | Embeddings |

## Production notes

- Use **mTLS** or **NetworkPolicies** between namespaces.  
- Store secrets in **Sealed Secrets** / **External Secrets**, not plain YAML.  
- Replace TinyLlama with a model appropriate for your GPU and license.
