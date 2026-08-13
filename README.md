# Café Boreal S.R.L. - Examen Integrador ITI-522

**Integrantes:** Esteban Molina y Franklin Castillo  
**Plataforma objetivo:** Ubuntu Server 22.04 LTS, 4 vCPU, 8 GB RAM y disco VDI dinámico de 80 GB.

Este repositorio implementa una solución local reproducible con tres microservicios, PostgreSQL, Kubernetes (k3s), un módulo legado PHP/Apache, Nginx con HTTPS, observabilidad y scripts de operación.

## Inicio rápido dentro de la VM

```bash
git clone https://github.com/frank771-ai/cafe-boreal-iti522.git cafe-boreal
cd cafe-boreal
sudo ./deploy/bootstrap-vm.sh
sudo ./deploy/up.sh
./deploy/smoke-test.sh
```

Al finalizar:

- Panel administrativo: `https://localhost/`
- APIs: `https://localhost/api/catalog`, `/api/orders`, `/api/customers`
- Legado: `https://localhost/legacy/inventory`
- Grafana: `http://localhost:5555` (`admin` / contraseña generada en `deploy/.grafana-password`)

El certificado es de laboratorio y está autofirmado. La primera visita mostrará una advertencia del navegador.

## Estructura

- `source/api/`: imagen común para Catalog, Orders y Customers API.
- `source/frontend/`: panel administrativo responsive.
- `source/legacy/`: Apache + PHP + SQLite; inventario de solo lectura.
- `deploy/k8s/`: manifiestos de aplicación, datos, Ingress y controles operativos.
- `deploy/observability/`: valores y dashboard para Prometheus, Grafana y Loki.
- `docs/`: arquitectura, runbook, seguridad, SLA, decisiones y bitácora.
- `evidence/`: salidas producidas por `collect-evidence.sh`.

## Flujo de Git requerido

```bash
git switch -c exam
git add . && git commit -m "feat: solución reproducible Café Boreal"
git tag -a v1-Infraestructura -m "Infraestructura base"
git tag -a v2-Datos -m "Esquema, semillas y respaldo"
git tag -a v3-Servicios -m "APIs, Services e Ingress"
git tag -a v4-Seguridad -m "TLS, cifrado y controles"
git tag -a v5-Observabilidad -m "Métricas, logs y carga"
git tag -a v6-Documentos -m "Documentación y entrega"
git switch main
git merge --no-ff exam
git push origin main exam --follow-tags
```

**Repositorio público:** https://github.com/frank771-ai/cafe-boreal-iti522

El nombre del profesor queda como campo por completar porque no fue proporcionado. La frase antifraude ya está incorporada en el panel, Nginx y la portada.

## Evidencias y cierre

```bash
./deploy/load-test.sh
./deploy/backup.sh
./deploy/restore-verify.sh
./deploy/collect-evidence.sh
sha256sum cafe-boreal.ova | tee evidence/vm-sha256.txt
```

La entrega incluye capturas reales de la VM, imagen OVA y archivo SHA-256. El video end-to-end grabado dentro de la VM queda diferido por solicitud de los autores; `docs/GUION-VIDEO.md` conserva el guion listo para completarlo después.
