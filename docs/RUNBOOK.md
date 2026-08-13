# Runbook de operación

## Arranque

1. Iniciar `Cafe-Boreal-ITI522` en VirtualBox.
2. Esperar dos minutos.
3. Abrir `https://localhost:8443` desde el anfitrión.
4. Si un componente no inicia: `sudo /home/boreal/cafe-boreal/deploy/up.sh`.

## Salud

```bash
kubectl get nodes
kubectl get pods -A
./deploy/smoke-test.sh
curl -k https://localhost/api/catalog/healthz
```

No debe aparecer `CrashLoopBackOff`. Los tres endpoints deben responder `status: ok`.

## Backup y restauración

```bash
./deploy/backup.sh
./deploy/restore-verify.sh backups/<archivo>.sql.gz
```

La restauración se valida en la base aislada `cafeboreal_restore`; no sobrescribe producción.

## Usuarios y roles

- `boreal`: operador de la VM; usa `sudo` solo para administración.
- `cafeboreal`: usuario de aplicación PostgreSQL, almacenado en Secret.
- `admin` de Grafana: contraseña local en `deploy/.grafana-password`.
- Los contenedores API se ejecutan como UID no-root 10001.

## Incidentes

1. Confirmar espacio (`df -h`) y memoria (`free -h`).
2. Revisar pods y eventos (`kubectl get pods -A`; `kubectl describe pod ...`).
3. Consultar logs en Grafana/Loki o con `kubectl logs`.
4. Reiniciar solo el despliegue afectado: `kubectl rollout restart deploy/<nombre> -n cafe-boreal`.
5. Si hay corrupción de datos, conservar evidencia, crear backup y ejecutar restore verificado.

## Rotación de clave de identidad

1. Crear una clave AES nueva de 32 bytes y un Secret versión 2.
2. Mantener temporalmente v1 y v2 disponibles.
3. Ejecutar un job que descifre cada fila con v1 y vuelva a cifrar con v2 dentro de una transacción, cambiando `key_version=2`.
4. Verificar API y `SELECT` cifrado.
5. Reiniciar Customers API y retirar v1 después del periodo de reversión.
