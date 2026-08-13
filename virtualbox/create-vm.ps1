param(
  [string]$IsoPath = "$PSScriptRoot\..\..\ubuntu-22.04.5-live-server-amd64.iso",
  [string]$VmName = "Cafe-Boreal-ITI522",
  [string]$VmRoot = "$PSScriptRoot\..\..\VirtualBoxVMs"
)
$ErrorActionPreference = 'Stop'
$vbox = 'C:\Program Files\Oracle\VirtualBox\VBoxManage.exe'
if (!(Test-Path -LiteralPath $vbox)) { throw 'VirtualBox no está instalado.' }
if (!(Test-Path -LiteralPath $IsoPath)) { throw "No se encontró la ISO: $IsoPath" }
$IsoPath = (Resolve-Path -LiteralPath $IsoPath).Path
$VmRoot = [IO.Path]::GetFullPath($VmRoot)
New-Item -ItemType Directory -Force -Path $VmRoot | Out-Null
$existing = & $vbox list vms
if ($existing -match [regex]::Escape('"' + $VmName + '"')) { throw "Ya existe la VM $VmName. No se sobrescribió." }
& $vbox createvm --name $VmName --ostype Ubuntu_64 --basefolder $VmRoot --register
# Se instala temporalmente con 1 vCPU para evitar un soft-lockup conocido de Subiquity en algunos anfitriones.
# provision-vm.ps1 establece los 4 vCPU finales antes de desplegar la aplicación.
& $vbox modifyvm $VmName --memory 8192 --cpus 1 --vram 32 --graphicscontroller vmsvga --ioapic on --rtc-use-utc on --boot1 dvd --boot2 disk --boot3 none --boot4 none --nic1 nat
& $vbox modifyvm $VmName --natpf1 'ssh,tcp,127.0.0.1,2222,,22' --natpf1 'http,tcp,127.0.0.1,8080,,80' --natpf1 'https,tcp,127.0.0.1,8443,,443' --natpf1 'grafana,tcp,127.0.0.1,5555,,5555'
& $vbox storagectl $VmName --name SATA --add sata --controller IntelAhci --portcount 4 --bootable on
$disk = Join-Path $VmRoot "$VmName\$VmName.vdi"
& $vbox createmedium disk --filename $disk --size 81920 --format VDI --variant Standard
& $vbox storageattach $VmName --storagectl SATA --port 0 --device 0 --type hdd --medium $disk
$credentialDir = Split-Path -Parent $PSScriptRoot
$passwordFile = Join-Path $credentialDir '.vm-password'
if (!(Test-Path -LiteralPath $passwordFile)) {
  throw "Cree $passwordFile con una contraseña temporal de la VM antes de ejecutar este script. El archivo está excluido de Git."
}
$template = Join-Path $PSScriptRoot 'ubuntu-autoinstall-user-data'
& $vbox unattended install $VmName --iso=$IsoPath --user=boreal --user-password-file=$passwordFile --admin-password-file=$passwordFile --full-user-name='Esteban Molina y Franklin Castillo' --hostname=cafe-boreal.local --locale=es_CR --country=CR --time-zone=America/Costa_Rica --script-template=$template --no-install-additions --start-vm=headless
Write-Host "Instalación desatendida iniciada temporalmente con 1 vCPU. provision-vm.ps1 establecerá la configuración final: 4 vCPU, 8 GB RAM y VDI dinámico de 80 GB."
Write-Host "Usuario: boreal. Puertos: SSH 2222, HTTP 8080, HTTPS 8443, Grafana 5555."
