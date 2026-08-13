#!/usr/bin/env bash
set -Eeuo pipefail
if [[ $EUID -ne 0 ]]; then echo "Ejecute con sudo"; exit 1; fi
sed -i '/^[[:space:]]*deb[[:space:]].*\/cdrom/s/^/# disabled after unattended install: /' /etc/apt/sources.list
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y ca-certificates curl git jq openssl nginx apache2-utils docker.io ufw postgresql-client openssh-server
systemctl enable --now docker nginx
if ! command -v k3s >/dev/null; then curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--disable traefik --write-kubeconfig-mode 644" sh -; fi
if ! command -v helm >/dev/null; then curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash; fi
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx -n ingress-nginx --create-namespace \
  --set controller.service.type=NodePort \
  --set controller.service.nodePorts.http=30080 \
  --set controller.service.nodePorts.https=30443 \
  --set controller.metrics.enabled=true
ufw default deny incoming
ufw default allow outgoing
ufw allow OpenSSH
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 5555/tcp
ufw --force enable
echo "VM preparada. Ejecute sudo ./deploy/up.sh"
