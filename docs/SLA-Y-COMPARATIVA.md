# SLA interno y decisión de arquitectura

## SLO y presupuesto de error

Ventana móvil: 30 días. Horario cubierto: 24x7 para API; soporte humano de 07:00 a 19:00.

| Indicador | SLO | Medición | Presupuesto / alerta |
|---|---:|---|---|
| Disponibilidad | 99,5 % mensual | respuestas no-5xx / solicitudes totales | 3 h 36 min de indisponibilidad al mes; alerta al consumir 50 % |
| Latencia p95 | <= 450 ms en operación normal | histograma HTTP por ruta, excluye carga de imágenes | máximo 5 % de solicitudes por encima; alerta 10 min |
| Tasa de errores | < 1 % | 5xx / solicitudes | alerta si supera 2 % durante 5 min |
| MTTR | <= 60 min | desde alerta confirmada hasta recuperación | revisión si un incidente supera 60 min |

Si se consume 75 % del presupuesto, se congelan cambios no esenciales. Al 100 %, se prioriza confiabilidad y se realiza análisis causal.

Las pruebas de estrés intencionales (500/10 y 2000/50) produjeron p95 de 2269 ms y 3479 ms respectivamente, sin solicitudes fallidas. Esos perfiles saturan deliberadamente una VM de laboratorio y no representan el SLO de operación normal.

## Comparativa mensual para una MiPyME

Supuestos: carga baja/media, 3 servicios, 100 GB de datos, una persona operadora parcial. Valores orientativos en USD, sin impuestos y sujetos a proveedor, región y tipo de cambio.

| Alternativa | Infra mensual | Operación estimada | Ventajas | Riesgos |
|---|---:|---:|---|---|
| On-premise | $70 amortizados + energía | 24 h/mes | control y costo predecible | punto único, hardware, respaldo externo |
| IaaS | $120-$220 | 16 h/mes | flexibilidad y acceso remoto | parches, red, costos variables |
| PaaS | $180-$350 | 8 h/mes | backups, SLA y escalado gestionados | dependencia del proveedor y mayor costo base |
| Híbrido | $150-$280 | 14 h/mes | continuidad y migración gradual | mayor complejidad y sincronización |

## Conclusión

Para la etapa actual se recomienda PaaS administrado para base de datos y contenedores, con exportación de backups a una segunda ubicación. Reduce el riesgo operativo y el MTTR, que para una MiPyME suele costar más que la diferencia mensual. La VM local de este examen funciona como entorno de desarrollo, contingencia y demostración reproducible. Si el presupuesto inicial domina y la operación es estrictamente local, IaaS pequeña es la segunda opción, siempre que se automatice backup y monitoreo. La opción híbrida se reserva para una exigencia real de residencia de datos o conectividad intermitente.
