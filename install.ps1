param([ValidateRange(1,1440)][int]$IntervalMinutes = 5)
$ErrorActionPreference = 'Stop'
$root = Join-Path $env:LOCALAPPDATA 'KeyboardLayoutGuard'
New-Item -ItemType Directory -Path $root -Force | Out-Null
foreach ($name in @('guard.ps1','run-hidden.vbs','disable.ps1')) {
    $source = Join-Path $PSScriptRoot $name
    $destination = Join-Path $root $name
    if ([IO.Path]::GetFullPath($source) -ne [IO.Path]::GetFullPath($destination)) { Copy-Item $source $destination -Force }
}
$powerShell = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
& $powerShell -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File (Join-Path $root 'guard.ps1') -Force
if ($LASTEXITCODE -ne 0) { throw 'Initial cleanup failed. See guard.log. No new task was registered.' }
$wscript = Join-Path $env:SystemRoot 'System32\wscript.exe'
$launcher = Join-Path $root 'run-hidden.vbs'
$command = '"' + $wscript + '" "' + $launcher + '"'
& schtasks.exe /Create /TN 'KeyboardLayoutGuard' /TR $command /SC MINUTE /MO $IntervalMinutes /F
if ($LASTEXITCODE -ne 0) { throw 'Could not register the task. Keyboard settings have already been cleaned.' }
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -MultipleInstances IgnoreNew -ExecutionTimeLimit (New-TimeSpan -Minutes 2)
Set-ScheduledTask -TaskName 'KeyboardLayoutGuard' -Settings $settings | Out-Null
$run = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
if (-not (Test-Path $run)) { New-Item $run -Force | Out-Null }
New-ItemProperty $run -Name 'KeyboardLayoutGuard' -Value $command -PropertyType String -Force | Out-Null
Start-ScheduledTask -TaskName 'KeyboardLayoutGuard'
Write-Output "Installed in $root; cleanup every $IntervalMinutes minute(s) and at sign-in."
