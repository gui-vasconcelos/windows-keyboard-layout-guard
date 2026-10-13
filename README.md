# Windows Keyboard Layout Guard

Keeps **Portuguese (Brazil) + United States-International** as the only input configuration on the current Windows account. For people who type Portuguese and English on the same US International keyboard and do not want ABNT or standard US layouts returning.

> **This is intentionally opinionated, not a general-purpose keyboard manager.** It replaces the current user's language list with `pt-BR` and input method `0416:00020409`. Do not install it if you need other input languages, keyboards, or IMEs. This can affect language-dependent Windows features; it does not install or uninstall display language packs.

## Install

Download this repository or clone it, inspect the scripts, then run in **Windows PowerShell** as the account whose keyboards should be cleaned:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\install.ps1
```

Administrator privileges are normally not needed. Managed computers may restrict task registration or script execution. Windows PowerShell 5.1 and Task Scheduler are required; the native cleanup has been exercised on Windows 11.

The installer:

- Copies the scripts to `%LOCALAPPDATA%\KeyboardLayoutGuard`.
- Backs up the initial language list, default-input override, and relevant per-user registry keys before the first cleanup.
- Sets US International as the default input method and removes extra preload/substitute entries.
- Attempts to unload other keyboard layouts in the current session.
- Registers `KeyboardLayoutGuard` to run every **5 minutes**, including on battery power.
- Adds a current-user startup entry to run at sign-in.
- Uses a hidden VBScript launcher so periodic runs do not flash a terminal window.

Choose a different interval:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\install.ps1 -IntervalMinutes 15
```

Installing again replaces the scripts and updates the task; existing initial backups are preserved. The installer and launcher use account-relative paths, not a hard-coded username.

## Check it

```powershell
Get-WinUserLanguageList
Get-WinDefaultInputMethodOverride
Get-ScheduledTaskInfo -TaskName KeyboardLayoutGuard
Get-Content "$env:LOCALAPPDATA\KeyboardLayoutGuard\guard.log" -Tail 20
```

Expect input method `0416:00020409`, task result `0`, and an `OK` log entry. The log records every execution, including runs that had nothing to change, and rotates at approximately 200 KB.

## Disable automatic cleanup

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$env:LOCALAPPDATA\KeyboardLayoutGuard\disable.ps1"
```

This removes the scheduled task and startup entry. **It does not restore old keyboard settings or delete backups.** Change the language list in Windows Settings afterward if desired. The `.reg` and `original-*.xml` files are recovery material for manual restoration, not a tested automatic rollback tool.

## Limitations and safety

- This is periodic enforcement, not a guarantee that Windows will never create another layout. An extra layout can exist until the next run.
- Windows may refuse to unload a layout in use by another application; the log records the result. Signing out and back in may be needed to clear stale application state.
- The cleanup is for the current account only. It does not modify system-wide keyboard definitions or the sign-in screen.
- Do not run it under a different account or with alternate administrator credentials.
- It does not disable Microsoft account synchronization or lock registry permissions.
- The code is fixed to this particular keyboard preference. It is not suitable for other layouts without changes.
- No network requests or telemetry are made by the scripts.

## Files

| File | Purpose |
| --- | --- |
| `guard.ps1` | Backup, enforce the input configuration, unload extras, verify and log |
| `install.ps1` | Install scripts, scheduled task, and sign-in entry |
| `run-hidden.vbs` | Execute the guard invisibly and propagate its exit status |
| `disable.ps1` | Remove automation without changing the current keyboard configuration |

Personal logs, registry exports, backup files, and credentials are excluded from version control.

---

## Resumo em português

Mantém apenas **Português (Brasil) — Estados Unidos (internacional)**. Limpa layouts extras a cada cinco minutos e ao entrar no Windows, sem abrir janelas. É uma correção automática recorrente: não bloqueia definitivamente a criação de layouts pelo Windows.

**Atenção:** substitui a lista de idiomas de entrada do usuário por `pt-BR`. Não use se você precisa de outros idiomas de entrada, layouts ou IMEs. O comando de desativação acima remove a automação, mas não restaura a configuração anterior.
