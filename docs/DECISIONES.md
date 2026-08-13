# Decisiones, supuestos y trade-offs

1. **k3s sobre minikube:** consume menos recursos y se comporta como servicio del sistema. Se deshabilita Traefik para usar Ingress Nginx explícito.
2. **PostgreSQL:** ofrece integridad transaccional para pedidos y consultas directas claras para demostrar cifrado.
3. **Imagen API compartida:** reduce tiempo de construcción, pero cada Deployment establece `SERVICE_NAME` y solo atiende su dominio.
4. **AES-256-GCM en aplicación:** asegura confidencialidad e integridad y mantiene la clave fuera de PostgreSQL. Impide búsquedas directas por identidad, una decisión aceptable porque no son requeridas.
5. **Nginx en el host de la VM:** conserva un único punto HTTPS y enruta al Ingress o al legado. El servicio PHP solo escucha en loopback.
6. **Una réplica por API:** cabe de forma estable en la VM de 4 vCPU/8 GB; las probes permiten recuperación automática. PostgreSQL también es único por limitación de una sola VM.
7. **Certificado autofirmado:** adecuado para laboratorio; producción requiere CA pública o corporativa.
8. **Credenciales locales iniciales:** se entregan separadas del repositorio y deben cambiarse antes de cualquier exposición fuera del laboratorio.

Supuestos: la VM tiene salida a Internet durante el primer despliegue; el anfitrión dispone de al menos 10 GB libres y 10 GB de RAM física; no se procesa pago real; no hay integración con registro civil; las cifras de costo son aproximaciones para decisión académica.
