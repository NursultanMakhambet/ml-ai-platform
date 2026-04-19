# Secrets

Generate Langfuse secrets:

```bash
bash scripts/gen-secrets.sh
kubectl apply -f namespaces/namespaces.yaml   # ensures langfuse ns exists
kubectl apply -f secrets/langfuse-secrets.yaml
```

Do **not** commit `langfuse-secrets.yaml`.
