#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKUP=${1:-$(ls -t "$ROOT"/backups/*.sql.gz | head -1)}
POD=$(kubectl -n cafe-boreal get pod -l app=postgres -o jsonpath='{.items[0].metadata.name}')
gunzip -c "$BACKUP" | kubectl -n cafe-boreal exec -i "$POD" -- sh -c 'PGPASSWORD="$POSTGRES_PASSWORD" psql -U "$POSTGRES_USER" -d postgres -v ON_ERROR_STOP=1 -c "DROP DATABASE IF EXISTS cafeboreal_restore;" -c "CREATE DATABASE cafeboreal_restore;" >/dev/null; PGPASSWORD="$POSTGRES_PASSWORD" psql -U "$POSTGRES_USER" -d cafeboreal_restore -v ON_ERROR_STOP=1'
kubectl -n cafe-boreal exec "$POD" -- sh -c 'PGPASSWORD="$POSTGRES_PASSWORD" psql -U "$POSTGRES_USER" -d cafeboreal_restore -tAc "SELECT count(*) FROM products"'
echo "Restore aislado verificado en cafeboreal_restore."
