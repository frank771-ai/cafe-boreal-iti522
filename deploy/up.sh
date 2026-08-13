#!/usr/bin/env bash
set -Eeuo pipefail
umask 077
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export KUBECONFIG=${KUBECONFIG:-/etc/rancher/k3s/k3s.yaml}
command -v docker >/dev/null && command -v kubectl >/dev/null && command -v helm >/dev/null || { echo "Ejecute primero deploy/bootstrap-vm.sh"; exit 1; }
mkdir -p "$ROOT/deploy/tls" "$ROOT/evidence" "$ROOT/backups"
if [[ -n "${SUDO_USER:-}" ]]; then chown -R "$SUDO_USER":"$SUDO_USER" "$ROOT/evidence" "$ROOT/backups"; fi
[[ -s "$ROOT/deploy/.identity-key" ]] || openssl rand -base64 32 | tr '+/' '-_' > "$ROOT/deploy/.identity-key"
[[ -s "$ROOT/deploy/.grafana-password" ]] || openssl rand -base64 18 | tr -d '\n' > "$ROOT/deploy/.grafana-password"
[[ -s "$ROOT/deploy/.db-password" ]] || openssl rand -hex 18 | tr -d '\n' > "$ROOT/deploy/.db-password"
chmod 600 "$ROOT/deploy/.identity-key" "$ROOT/deploy/.grafana-password" "$ROOT/deploy/.db-password"
DB_PASSWORD=${DB_PASSWORD:-$(tr -d '\r\n' < "$ROOT/deploy/.db-password")}
IDENTITY_KEY=$(tr -d '\r\n' < "$ROOT/deploy/.identity-key")
GRAFANA_PASSWORD=$(tr -d '\r\n' < "$ROOT/deploy/.grafana-password")
docker build -t cafe-boreal-api:local "$ROOT/source/api"
docker build -t cafe-boreal-legacy:local "$ROOT/source/legacy"
docker save cafe-boreal-api:local | k3s ctr images import -
docker rm -f cafe-boreal-legacy >/dev/null 2>&1 || true
docker run -d --restart unless-stopped --name cafe-boreal-legacy -p 127.0.0.1:8081:80 cafe-boreal-legacy:local
kubectl apply -f "$ROOT/deploy/k8s/00-namespace-db.yaml"
kubectl -n cafe-boreal create secret generic database-secret --dry-run=client -o yaml \
  --from-literal=POSTGRES_DB=cafeboreal --from-literal=POSTGRES_USER=cafeboreal --from-literal=POSTGRES_PASSWORD="$DB_PASSWORD" | kubectl apply -f -
DATABASE_URL="postgresql://cafeboreal:${DB_PASSWORD}@postgres:5432/cafeboreal"
kubectl -n cafe-boreal create secret generic app-secret --dry-run=client -o yaml \
  --from-literal=database-url="$DATABASE_URL" --from-literal=identity-key="$IDENTITY_KEY" | kubectl apply -f -
kubectl apply -f "$ROOT/deploy/k8s/10-schema.yaml"
kubectl apply -f "$ROOT/deploy/k8s/20-services.yaml"
kubectl -n cafe-boreal wait --for=condition=complete job/database-schema-v1 --timeout=600s
kubectl -n cafe-boreal rollout status deploy/catalog --timeout=600s
kubectl -n cafe-boreal rollout status deploy/orders --timeout=600s
kubectl -n cafe-boreal rollout status deploy/customers --timeout=600s
openssl req -x509 -newkey rsa:3072 -sha256 -nodes -days 365 \
  -keyout "$ROOT/deploy/tls/cafe-boreal.key" -out "$ROOT/deploy/tls/cafe-boreal.crt" \
  -subj "/C=CR/O=Cafe Boreal SRL/CN=localhost" -addext "subjectAltName=DNS:localhost,IP:127.0.0.1"
install -d -m 755 /etc/nginx/tls /opt/cafe-boreal/frontend
install -m 600 "$ROOT/deploy/tls/cafe-boreal.key" /etc/nginx/tls/cafe-boreal.key
install -m 644 "$ROOT/deploy/tls/cafe-boreal.crt" /etc/nginx/tls/cafe-boreal.crt
cp -a "$ROOT/source/frontend/." /opt/cafe-boreal/frontend/
chmod -R a+rX /opt/cafe-boreal/frontend
install -m 644 "$ROOT/deploy/nginx/cafe-boreal.conf" /etc/nginx/sites-available/cafe-boreal
ln -sfn /etc/nginx/sites-available/cafe-boreal /etc/nginx/sites-enabled/cafe-boreal
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl reload nginx
helm upgrade --install monitoring prometheus-community/kube-prometheus-stack -n observability --create-namespace -f "$ROOT/deploy/observability/values-monitoring.yaml" \
  --set grafana.service.type=NodePort --set grafana.service.nodePort=30555 \
  --set grafana.adminPassword="$GRAFANA_PASSWORD" --set grafana.grafana.ini.server.http_port=3000
kubectl apply -f "$ROOT/deploy/observability/loki-promtail.yaml"
kubectl apply -f "$ROOT/deploy/observability/resources.yaml"
kubectl -n observability patch svc monitoring-grafana -p '{"spec":{"externalTrafficPolicy":"Cluster"}}' >/dev/null
"$ROOT/deploy/seed.sh"
echo "Despliegue completo: https://localhost | Grafana http://localhost:5555"
