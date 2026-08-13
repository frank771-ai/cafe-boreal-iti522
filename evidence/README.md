# Evidencias

Ejecute `deploy/collect-evidence.sh` dentro de la VM. Después agregue capturas PNG legibles de:

1. panel responsive y página About;
2. certificado HTTPS y redirección;
3. `kubectl get nodes` y `kubectl get pods -A`;
4. Grafana: CPU/memoria por pod y métricas HTTP;
5. Loki: consulta `{namespace="cafe-boreal"}`;
6. SELECT directo con `identity_ciphertext` y respuesta API en claro;
7. resultados de ambos perfiles de carga;
8. backup y restore verificados.

No incluya claves, contraseñas ni el contenido decodificado de Secrets.
