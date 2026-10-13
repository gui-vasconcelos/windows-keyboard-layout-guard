Option Explicit
Dim sh, fs, root, script, powershell, command
Set sh = CreateObject("WScript.Shell")
Set fs = CreateObject("Scripting.FileSystemObject")
root = fs.GetParentFolderName(WScript.ScriptFullName)
script = fs.BuildPath(root, "guard.ps1")
powershell = sh.ExpandEnvironmentStrings("%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe")
command = """" & powershell & """ -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File """ & script & """"
WScript.Quit sh.Run(command, 0, True)
