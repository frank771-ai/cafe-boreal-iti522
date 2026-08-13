#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"; OUT="$ROOT/evidence"; mkdir -p "$OUT"
kubectl get nodes -o wide > "$OUT/kubectl-nodes.txt"
kubectl get pods -A -o wide > "$OUT/kubectl-pods-all.txt"
kubectl get ingress,svc -A > "$OUT/kubectl-network.txt"
for service in catalog orders customers; do curl -ksS "https://localhost/api/$service/healthz" > "$OUT/health-$service.json"; done
curl -ksS 'https://localhost/legacy/inventory?sku=CB-001' > "$OUT/legacy-CB-001.json"
curl -sSI http://localhost > "$OUT/http-redirect.txt"
curl -ksSI https://localhost > "$OUT/https-headers.txt"
POD=$(kubectl -n cafe-boreal get pod -l app=postgres -o jsonpath='{.items[0].metadata.name}')
kubectl -n cafe-boreal exec "$POD" -- sh -c 'PGPASSWORD="$POSTGRES_PASSWORD" psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "SELECT id,nombre,email,identity_ciphertext,key_version FROM customers LIMIT 10"' > "$OUT/select-identidad-cifrada.txt"
kubectl -n cafe-boreal get secret app-secret -o jsonpath='{.data.identity-key}' | wc -c > "$OUT/secret-reference-length.txt"
echo "Evidencias de texto recopiladas. Añada capturas del panel, Grafana y Loki."
