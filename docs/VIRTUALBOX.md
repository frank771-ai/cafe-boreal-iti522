# VirtualBox: creación, uso y entrega

## Parámetros

- Nombre: `Cafe-Boreal-ITI522`
- SO: Ubuntu Server 22.04.5 LTS
- CPU: 4 vCPU
- RAM: 8192 MB
- Disco: VDI dinámico, capacidad máxima 80 GB
- Red NAT: anfitrión `2222 -> 22`, `8080 -> 80`, `8443 -> 443`, `5555 -> 5555`

El disco dinámico no ocupa 80 GB inmediatamente: crece conforme se escriben datos hasta ese máximo.

Durante la instalación desatendida, `create-vm.ps1` usa temporalmente 1 vCPU para evitar bloqueos de Subiquity observados en algunos anfitriones. `provision-vm.ps1` apaga la VM, establece la configuración final de 4 vCPU y vuelve a iniciarla antes de desplegar la aplicación.

## Creación automática en Windows

```powershell
.\virtualbox\create-vm.ps1
.\virtualbox\provision-vm.ps1
```

## Acceso desde el anfitrión

- Panel: `https://localhost:8443`
- Redirección HTTP: `http://localhost:8080`
- Grafana: `http://localhost:5555`
- SSH: `ssh -p 2222 boreal@localhost`

## Exportación

Apague de forma limpia y ejecute:

```powershell
.\virtualbox\export-ova.ps1
```

El script crea `Cafe-Boreal-ITI522.ova` y su hash SHA-256. Para importar: VirtualBox > Archivo > Importar servicio virtualizado > seleccionar OVA > Importar. Conservar la MAC generada o renovar las reglas NAT si cambian.

## Video de tres minutos

1. Panel y About con frase antifraude.
2. HTTPS y redirección.
3. Productos, pedido, cliente e inventario legado.
4. `kubectl get pods -A` sin CrashLoopBackOff.
5. SELECT con identidad cifrada y API en claro.
6. carga, dashboard Grafana y consulta Loki.
7. backup/restore y hash de la OVA.
