#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"; mkdir -p "$ROOT/evidence"
ab -k -l -n 500 -c 10 https://localhost/api/catalog > "$ROOT/evidence/load-profile-1.txt" 2>&1
ab -k -l -n 2000 -c 50 https://localhost/api/catalog > "$ROOT/evidence/load-profile-2.txt" 2>&1
grep -E 'Requests per second|Failed requests|95%' "$ROOT/evidence"/load-profile-*.txt
