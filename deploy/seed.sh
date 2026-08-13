#!/usr/bin/env bash
set -Eeuo pipefail
BASE=${BASE_URL:-https://localhost}
for _ in {1..60}; do curl -ksf "$BASE/api/catalog/healthz" >/dev/null && break; sleep 2; done
COUNT=$(curl -ks "$BASE/api/catalog" | jq length)
if [[ "$COUNT" -lt 50 ]]; then
  for i in $(seq 1 50); do
    curl -ksf -X POST "$BASE/api/catalog" -H 'Content-Type: application/json' \
      -d "{\"nombre\":\"Café Boreal $i\",\"precio\":$((1800+i*25)).00,\"stock\":$((20+i%17)),\"descripcion\":\"Lote artesanal CB-$(printf '%03d' "$i")\",\"imagen\":\"\"}" >/dev/null
  done
fi
COUNT=$(curl -ks "$BASE/api/customers" | jq length)
if [[ "$COUNT" -lt 10 ]]; then
  for i in $(seq 1 10); do
    curl -ksf -X POST "$BASE/api/customers" -H 'Content-Type: application/json' \
      -d "{\"nombre\":\"Cliente Demo $i\",\"email\":\"cliente$i@example.com\",\"numero_identidad\":\"1-$(printf '%04d' "$i")-$(printf '%04d' $((i*73)))\"}" >/dev/null
  done
fi
echo "Seed validado: $(curl -ks "$BASE/api/catalog" | jq length) productos y $(curl -ks "$BASE/api/customers" | jq length) clientes."
