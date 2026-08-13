# Arquitectura y despliegue

## Diagrama lógico

```mermaid
flowchart LR
  U[Panel Admin / PWA] --> N[Nginx HTTPS]
  N --> I[Ingress Nginx en k3s]
  N --> L[Apache + PHP + SQLite legado]
  I --> C[Catalog API]
  I --> O[Orders API]
  I --> K[Customers API]
  C --> P[(PostgreSQL)]
  O --> P
  K --> P
  K --> E[AES-256-GCM / Secret K8s]
  M[Prometheus] --> C
  M --> O
  M --> K
  T[Promtail] --> X[Loki]
  G[Grafana] --> M
  G --> X
```

## Despliegue físico

```mermaid
flowchart TB
  H[Equipo anfitrión / VirtualBox] --> V[VM Ubuntu Server: 4 vCPU, 8 GB, VDI dinámico 80 GB]
  V --> NG[Nginx host: 80/443]
  V --> AP[Contenedor legado: 8081 interno]
  V --> K3[k3s]
  K3 --> IN[Ingress NodePort 30080]
  K3 --> NS[Namespace cafe-boreal]
  NS --> APIs[3 pods API: 1 por servicio]
  NS --> DB[(PostgreSQL + PVC 5 GiB)]
  K3 --> OBS[Namespace observability]
  OBS --> PL[Prometheus / Grafana / Loki / Promtail]
```

Nginx es el único frontal público dentro de la VM y obliga HTTPS. El Ingress mantiene el enrutamiento Kubernetes. El legado permanece aislado en loopback y solo se alcanza mediante Nginx.

Prometheus obtiene las métricas de contenedores desde el endpoint cAdvisor integrado en el kubelet de k3s y las métricas HTTP desde `/metrics` de cada API mediante un `ServiceMonitor`.
