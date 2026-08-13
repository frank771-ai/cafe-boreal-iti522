#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
mkdir -p "$ROOT/backups"
POD=$(kubectl -n cafe-boreal get pod -l app=postgres -o jsonpath='{.items[0].metadata.name}')
kubectl -n cafe-boreal exec "$POD" -- sh -c 'PGPASSWORD="$POSTGRES_PASSWORD" pg_dump -U "$POSTGRES_USER" -d "$POSTGRES_DB" --clean --if-exists' | gzip > "$ROOT/backups/cafeboreal-$(date +%Y%m%d-%H%M%S).sql.gz"
gzip -t "$(ls -t "$ROOT"/backups/*.sql.gz | head -1)"
echo "Backup creado y validado."
