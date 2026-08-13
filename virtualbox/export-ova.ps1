param(
  [string]$VmName='Cafe-Boreal-ITI522',
  [string]$OutputDir="$PSScriptRoot\..\..\..\outputs",
  [string]$FileName='Cafe-Boreal-ITI522_Esteban-Molina_Franklin-Castillo.ova'
)
$ErrorActionPreference='Stop'
$vbox='C:\Program Files\Oracle\VirtualBox\VBoxManage.exe'
New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null
$state=& $vbox showvminfo $VmName --machinereadable | Select-String '^VMState=' | ForEach-Object {$_.ToString()}
if($state -match 'running'){
  & $vbox controlvm $VmName acpipowerbutton
  $deadline=(Get-Date).AddMinutes(4)
  do {
    Start-Sleep 5
    $state=& $vbox showvminfo $VmName --machinereadable | Select-String '^VMState=' | ForEach-Object {$_.ToString()}
  } until($state -match 'poweroff' -or (Get-Date) -gt $deadline)
}
if($state -notmatch 'poweroff'){ throw "La VM debe estar apagada antes de exportar. Estado: $state" }
$ova=Join-Path $OutputDir $FileName
if(Test-Path -LiteralPath $ova){ throw "Ya existe el destino y no se sobrescribirá: $ova" }
& $vbox export $VmName --output $ova --ovf20 --manifest --vsys 0 --description 'Café Boreal ITI-522 - Esteban Molina y Franklin Castillo'
if($LASTEXITCODE -ne 0 -or !(Test-Path -LiteralPath $ova)){ throw 'VirtualBox no produjo la OVA.' }
$hashName=[IO.Path]::GetFileNameWithoutExtension($FileName)+'.sha256.txt'
(Get-FileHash -Algorithm SHA256 -LiteralPath $ova).Hash.ToLowerInvariant() + "  $FileName" | Set-Content -Encoding ascii (Join-Path $OutputDir $hashName)
Write-Host "OVA exportada: $ova"
