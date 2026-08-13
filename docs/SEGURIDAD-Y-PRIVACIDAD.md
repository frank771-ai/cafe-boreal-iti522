# Seguridad, privacidad y cumplimiento

## Clasificación de datos y controles

| Nivel | Ejemplos | Controles mínimos |
|---|---|---|
| Público | catálogo, imágenes, descripción | HTTPS, integridad en Git, cache controlada |
| Interno | stock, pedidos, métricas, logs técnicos | red local, RBAC de Kubernetes, respaldo y acceso limitado a la VM |
| Confidencial | nombre, correo, historial de compra | mínimo privilegio, TLS y respaldo protegido |
| Restringido | número de identidad, claves y Secrets | AES-256-GCM en almacenamiento, Secret K8s, sin logs y rotación; Customers API es la única que usa la clave para identidades |

El número de identidad nunca se escribe en logs. PostgreSQL solo guarda `identity_ciphertext` (nonce de 12 bytes + ciphertext/tag, todo en Base64) y `key_version`. La clave de 32 bytes se inyecta desde `app-secret`; no forma parte de la imagen ni del repositorio. El panel es una demostración local sin autenticación de aplicación y no debe publicarse en Internet sin agregar OIDC/MFA y autorización por roles.

## STRIDE

| Amenaza | Escenario | Mitigación | Evidencia |
|---|---|---|---|
| Spoofing | suplantar API o administrador | TLS, usuarios separados, futura OIDC/MFA | certificado y headers HTTPS |
| Tampering | modificar pedido o imagen | validación Pydantic, transacciones, restricciones SQL, Git tags | pruebas API y esquema |
| Repudiation | negar una operación | logs con pod, ruta, código y hora; bitácora Git | consulta Loki |
| Information disclosure | leer identidad en BD o logs | AES-256-GCM, Secret, no registrar payload sensible | SELECT muestra ciphertext |
| Denial of service | carga agota CPU/memoria | limits/requests, probes, body limitado y UFW | YAML y pruebas de carga |
| Elevation of privilege | escape de contenedor | non-root, seccomp, filesystem de solo lectura, capabilities eliminadas | securityContext |

## Hardening

- UFW deniega entrada por defecto; expone solo SSH, 80 y 443. Grafana queda local.
- API ejecutada como UID 10001 no-root, sin escalamiento y sin capabilities Linux.
- TLS 1.2/1.3, redirección obligatoria y headers defensivos.
- PostgreSQL no usa NodePort; solo es visible en el namespace.
- Secrets se generan en la VM y están excluidos de Git.
- Los archivos locales de claves y contraseñas usan permisos `0600`.
- Backups comprimidos, validados y restaurados en una base aislada.
- Actualizaciones: `sudo apt update && sudo apt upgrade`, después de snapshot y backup.

## Evidencia de cifrado

```bash
kubectl -n cafe-boreal exec statefulset/postgres -- sh -c \
  'PGPASSWORD="$POSTGRES_PASSWORD" psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" \
  -c "SELECT id,nombre,email,identity_ciphertext,key_version FROM customers LIMIT 10"'
kubectl -n cafe-boreal get secret app-secret -o yaml
curl -k https://localhost/api/customers
```

La primera orden muestra ciphertext; la API devuelve identidad en claro. No se debe imprimir el valor decodificado del Secret en la evidencia pública.

## Rotación simulada

La versión de clave se registra por fila. El procedimiento seguro es introducir v2, desplegar un job transaccional de recifrado, verificar, reiniciar Customers y retirar v1 tras el periodo de reversión. Nunca se cambia una clave sin conservar temporalmente la anterior, pues los registros serían irrecuperables.
