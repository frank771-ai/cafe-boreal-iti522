# Guion del video demostrativo — Café Boreal

**Autores:** Esteban Molina y Franklin Castillo  
**Curso:** ITI-522 — Práctica de Examen Integrador  
**Formato objetivo:** 1280 × 720, MP4 (H.264/AAC), duración máxima de 3 minutos  
**Estado:** guion preparado; la grabación end-to-end dentro de la VM quedó diferida por solicitud de los autores.

## Escena 1 — Portada

**Visual:** título Café Boreal, curso y nombres de los integrantes.

**Locución:**

> Presentamos Café Boreal, solución desarrollada para la práctica integradora de ITI quinientos veintidós. El trabajo fue realizado en pareja por Esteban Molina y Franklin Castillo. Esta demostración se ejecuta dentro del entorno construido en VirtualBox.

## Escena 2 — Entorno VirtualBox

**Visual:** ficha técnica de la máquina virtual y flujo de componentes.

**Locución:**

> La solución se ejecuta dentro de una máquina VirtualBox con Ubuntu veintidós cero cuatro. Se asignaron cuatro CPU virtuales y ocho gigabytes de memoria, conservando recursos para el equipo anfitrión. El almacenamiento usa un disco VDI dinámico de ochenta gigabytes, por lo que el archivo crece solamente cuando los datos lo requieren.

## Escena 3 — Arquitectura

**Visual:** capas de acceso, aplicación, datos y observabilidad.

**Locución:**

> La arquitectura separa las responsabilidades en tres microservicios: catálogo, pedidos y clientes. Kubernetes ligero, mediante K tres S, administra los contenedores; PostgreSQL mantiene los datos transaccionales. Nginx publica el panel, aplica redirección a HTTPS y enruta cada API, mientras el inventario heredado continúa disponible como módulo PHP.

## Escena 4 — Catálogo y PWA

**Visual:** captura del panel en la sección Productos.

**Locución:**

> El panel web es responsive y funciona como aplicación web progresiva. La vista de productos consume el servicio de catálogo y muestra los datos cargados en la base. La semilla de demostración contiene cincuenta productos, cumpliendo el volumen mínimo solicitado y dejando las operaciones preparadas para altas, consultas, cambios y eliminaciones.

## Escena 5 — Clientes y cifrado

**Visual:** captura del panel de clientes y ejemplo de valor cifrado.

**Locución:**

> El módulo de clientes se desplegó como un servicio independiente. Para la demostración se registraron diez clientes. La identidad sensible no se almacena en texto legible: se protege con AES de doscientos cincuenta y seis bits en modo GCM, utiliza un nonce único y conserva la versión de la llave para facilitar una rotación controlada.

## Escena 6 — Autoría y control de cambios

**Visual:** sección Acerca de / evidencia de autoría.

**Locución:**

> La sección de autoría identifica a Esteban Molina y Franklin Castillo. El repositorio organiza el trabajo en las ramas principal y examen, con una bitácora de decisiones, historial de cambios y etiquetas anotadas por cada etapa: infraestructura, servicios, seguridad, observabilidad, pruebas y documentación.

## Escena 7 — Kubernetes

**Visual:** resumen de cargas de trabajo en ejecución.

**Locución:**

> La evidencia de Kubernetes confirma el nodo operativo y las cargas principales en estado Running. Catálogo, clientes, pedidos y PostgreSQL están disponibles, junto con el controlador de ingreso. En el espacio de observabilidad se ejecutan Prometheus, Grafana, Loki, Promtail, Alertmanager y los exportadores necesarios para métricas y registros.

## Escena 8 — Observabilidad

**Visual:** captura del tablero Café Boreal Operación en Grafana.

**Locución:**

> El tablero de Grafana centraliza la supervisión operativa. Prometheus recolecta métricas del clúster y de los servicios; Loki recibe los registros enviados por Promtail. La combinación permite revisar salud, disponibilidad y comportamiento durante las pruebas, y deja una base documentada para alertas y diagnóstico.

## Escena 9 — Pruebas, seguridad y recuperación

**Visual:** resultados de salud, carga y controles de seguridad.

**Locución:**

> Las pruebas de humo validaron los tres endpoints de salud, el inventario heredado, HTTPS y la redirección desde HTTP. En carga, el primer perfil completó quinientas solicitudes y el segundo dos mil, ambos con cero fallos. También se comprobó el respaldo de PostgreSQL y una restauración aislada con los cincuenta productos disponibles.

## Escena 10 — Cierre

**Visual:** lista de componentes de la entrega y nombres de los autores.

**Locución:**

> Café Boreal integra aplicación, datos, seguridad, observabilidad y procedimientos operativos dentro de una máquina virtual reproducible. El código, la documentación, las capturas, las evidencias y las instrucciones de importación quedan organizados para la entrega. Proyecto elaborado por Esteban Molina y Franklin Castillo. Gracias por revisar nuestra demostración.

## Secuencia para la grabación dentro de la VM

Si se requiere una demostración estrictamente en vivo, importar la OVA y grabar esta secuencia:

1. Mostrar los recursos asignados en VirtualBox.
2. Iniciar sesión en Ubuntu y ejecutar la prueba de humo.
3. Abrir el catálogo, clientes, pedidos y el módulo heredado.
4. Consultar el valor cifrado directamente en PostgreSQL.
5. Mostrar los pods de Kubernetes y el tablero de Grafana.
6. Ejecutar respaldo y restauración aislada.
7. Cerrar con el repositorio, las etiquetas y el hash de la imagen virtual.
