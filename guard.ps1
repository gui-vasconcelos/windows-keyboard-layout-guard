param([switch]$Force)
$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$log = Join-Path $root 'guard.log'
if ((Test-Path $log) -and (Get-Item $log).Length -gt 200000) { Move-Item $log "$log.old" -Force }
function Write-Log($text) { Add-Content -Path $log -Value "$(Get-Date -Format o) $text" -Encoding UTF8 }
Write-Log 'START'
try {
    $languages = Get-WinUserLanguageList
    if (-not (Test-Path (Join-Path $root 'original-languages.xml'))) {
        $languages | Export-Clixml (Join-Path $root 'original-languages.xml')
        foreach ($key in @('Keyboard Layout','Control Panel\International\User Profile')) {
            $name = ($key -replace '[\\ ]','_') + '.reg'
            & reg.exe export "HKCU\$key" (Join-Path $root $name) /y | Out-Null
            if ($LASTEXITCODE -ne 0) { throw "Backup failed: $key" }
        }
        Get-WinDefaultInputMethodOverride | Export-Clixml (Join-Path $root 'original-default.xml')
    }
    Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public static class KeyboardGuardNative {
 [DllImport("user32.dll")] public static extern int GetKeyboardLayoutList(int size, [Out] IntPtr[] layouts);
 [DllImport("user32.dll", SetLastError=true)] public static extern bool UnloadKeyboardLayout(IntPtr layout);
}
'@
    function Get-Layouts {
        $n = [KeyboardGuardNative]::GetKeyboardLayoutList(0, $null)
        $a = New-Object IntPtr[] $n
        $count = [KeyboardGuardNative]::GetKeyboardLayoutList($n, $a)
        for ($i=0; $i -lt $count; $i++) { $a[$i] }
    }
    # US International uses layout ID 0001; its loaded HKL begins F001.
    $loaded = @(Get-Layouts)
    $extras = @($loaded | Where-Object { (($_.ToInt64() -band 0xffffffffL) -shr 16) -ne 0xf001 })
    $tips = @(foreach ($language in $languages) { foreach ($tip in $language.InputMethodTips) { $tip } })
    if ($Force -or $extras.Count -gt 0 -or $languages.Count -ne 1 -or $languages[0].LanguageTag -ne 'pt-BR' -or $tips.Count -ne 1 -or $tips[0] -ne '0416:00020409') {
        $target = New-WinUserLanguageList 'pt-BR'
        $target[0].InputMethodTips.Clear()
        $target[0].InputMethodTips.Add('0416:00020409')
        Set-WinUserLanguageList -LanguageList $target -Force
        Write-Log 'Language list enforced: pt-BR / US International'
    }
    $default = Get-WinDefaultInputMethodOverride
    if ($default.InputMethodTip -ne '0416:00020409') { Set-WinDefaultInputMethodOverride -InputTip '0416:00020409' }
    # Keep the existing pt-BR preload alias but map it ONLY to International.
    $preload = 'HKCU:\Keyboard Layout\Preload'
    $subs = 'HKCU:\Keyboard Layout\Substitutes'
    foreach ($path in @($preload,$subs)) { if (-not (Test-Path $path)) { New-Item $path -Force | Out-Null } }
    $pk = Get-Item $preload
    foreach ($name in $pk.GetValueNames()) { if ($name -ne '1' -and $name -match '^\d+$') { Remove-ItemProperty $preload -Name $name } }
    if ((Get-Item $preload).GetValue('1') -ne '00000416') { New-ItemProperty $preload -Name '1' -Value '00000416' -PropertyType String -Force | Out-Null }
    $sk = Get-Item $subs
    foreach ($name in $sk.GetValueNames()) { if ($name -match '^[0-9A-Fa-f]{8}$' -and $name -ne '00000416') { Remove-ItemProperty $subs -Name $name } }
    if ((Get-Item $subs).GetValue('00000416') -ne '00020409') { New-ItemProperty $subs -Name '00000416' -Value '00020409' -PropertyType String -Force | Out-Null }
    foreach ($hkl in $extras) {
        $ok = [KeyboardGuardNative]::UnloadKeyboardLayout($hkl)
        Write-Log ('Unload {0:X8}: {1}' -f ($hkl.ToInt64() -band 0xffffffffL), $ok)
    }
    $actual = Get-WinUserLanguageList
    $actualTips = @(foreach ($language in $actual) { foreach ($tip in $language.InputMethodTips) { $tip } })
    if ($actual.Count -ne 1 -or $actual[0].LanguageTag -ne 'pt-BR' -or $actualTips.Count -ne 1 -or $actualTips[0] -ne '0416:00020409') { throw 'Language list verification failed' }
    $remaining = @((Get-Layouts) | ForEach-Object { '{0:X8}' -f ($_.ToInt64() -band 0xffffffffL) })
    Write-Log ('OK tips=' + ($actualTips -join ',') + ' loaded=' + ($remaining -join ','))
} catch { Write-Log ('ERROR ' + $_.Exception.Message); exit 1 }
