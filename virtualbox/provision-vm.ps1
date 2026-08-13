param([string]$VmName = 'Cafe-Boreal-ITI522')
$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path "$PSScriptRoot\..").Path
$passwordFile = "$repo\.vm-password"
$password = Get-Content -Raw $passwordFile
$vbox = 'C:\Program Files\Oracle\VirtualBox\VBoxManage.exe'
$askpass = "$repo\.vm-askpass.cmd"
"@echo off`r`necho $password" | Set-Content -Encoding ascii $askpass
$env:SSH_ASKPASS = $askpass
$env:SSH_ASKPASS_REQUIRE = 'force'
$env:DISPLAY = 'virtualbox'
$sshOptions = @('-o','StrictHostKeyChecking=no','-o',"UserKnownHostsFile=$repo\.vm-known-hosts",'-o','ConnectTimeout=5','-p','2222')
try {
  $deadline = (Get-Date).AddMinutes(35)
  $ErrorActionPreference = 'SilentlyContinue'
  do {
    Start-Sleep -Seconds 15
    & ssh.exe @sshOptions boreal@127.0.0.1 'test -f /etc/os-release' 2>$null
    $ready = $LASTEXITCODE -eq 0
    if (!$ready) { Write-Host 'Esperando el primer arranque y OpenSSH...' }
  } until ($ready -or (Get-Date) -gt $deadline)
  $ErrorActionPreference = 'Stop'
  if (!$ready) { throw 'Ubuntu no habilitó SSH dentro del plazo.' }
  $shutdown = "echo '$password' | sudo -S shutdown -h now"
  & ssh.exe @sshOptions boreal@127.0.0.1 $shutdown
  $powerDeadline = (Get-Date).AddMinutes(3)
  do { Start-Sleep -Seconds 5; $state = (& $vbox showvminfo $VmName --machinereadable | Select-String '^VMState=').ToString() } until ($state -match 'poweroff' -or (Get-Date) -gt $powerDeadline)
  if ($state -notmatch 'poweroff') { throw 'La VM no se apagó para establecer los 4 vCPU finales.' }
  & $vbox modifyvm $VmName --memory 8192 --cpus 4 --audio-enabled off --boot1 disk --boot2 none --boot3 none --boot4 none
  & $vbox startvm $VmName --type headless
  $ErrorActionPreference = 'SilentlyContinue'
  do { Start-Sleep -Seconds 10; & ssh.exe @sshOptions boreal@127.0.0.1 'echo ready' 2>$null; $ready = $LASTEXITCODE -eq 0 } until ($ready)
  $ErrorActionPreference = 'Stop'
  & scp.exe @($sshOptions[0..3]) -P 2222 -r $repo boreal@127.0.0.1:/home/boreal/
  $command = "cd /home/boreal/cafe-boreal && chmod +x deploy/*.sh && echo '$password' | sudo -S ./deploy/bootstrap-vm.sh && echo '$password' | sudo -S ./deploy/up.sh"
  & ssh.exe @sshOptions boreal@127.0.0.1 $command
  if ($LASTEXITCODE -ne 0) { throw 'Falló el aprovisionamiento dentro de la VM.' }
  Write-Host 'Provisionamiento finalizado con 4 vCPU, 8 GB RAM y VDI dinámico de 80 GB. Abra https://localhost:8443'
} finally {
  Remove-Item -LiteralPath $askpass -Force -ErrorAction SilentlyContinue
}
