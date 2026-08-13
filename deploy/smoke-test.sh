#!/usr/bin/env bash
set -Eeuo pipefail
BASE=${BASE_URL:-https://localhost}
for service in catalog orders customers; do
  RESULT=$(curl -ksS "$BASE/api/$service/healthz")
  jq -e '.status=="ok"' <<<"$RESULT" >/dev/null
  echo "OK /api/$service/healthz"
done
curl -ksS "$BASE/legacy/inventory?sku=CB-001" | jq -e '.sku=="CB-001"' >/dev/null
curl -sSI http://localhost | grep -qE '301|308'
curl -ksSI "$BASE" | grep -qi 'HTTP/.* 200'
echo "OK legado, HTTPS y redirección HTTP."
