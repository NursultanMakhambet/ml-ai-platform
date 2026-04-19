#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/secrets/langfuse-secrets.yaml"
NS="langfuse"

PG=$(openssl rand -hex 16)
NA=$(openssl rand -hex 24)
SALT=$(openssl rand -hex 16)

mkdir -p "$(dirname "$OUT")"

cat >"$OUT" <<EOF
---
apiVersion: v1
kind: Secret
metadata:
  name: langfuse-secrets
  namespace: ${NS}
type: Opaque
stringData:
  postgres-password: "${PG}"
  database-url: "postgresql://langfuse:${PG}@postgres:5432/langfuse"
  nextauth-secret: "${NA}"
  salt: "${SALT}"
EOF

echo "Wrote $OUT (gitignored). Apply namespaces first, then: kubectl apply -f $OUT"
