$ErrorActionPreference = 'Stop'
$task = Get-ScheduledTask -TaskName 'KeyboardLayoutGuard' -ErrorAction SilentlyContinue
if ($task) { Unregister-ScheduledTask -TaskName 'KeyboardLayoutGuard' -Confirm:$false }
Remove-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' -Name 'KeyboardLayoutGuard' -ErrorAction SilentlyContinue
Write-Output 'Automatic keyboard cleanup disabled. Current keyboard configuration and backups preserved.'
