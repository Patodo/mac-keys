# Build mac-keys.exe from mac-keys.ahk using the official Ahk2Exe compiler.
# - Locates AutoHotkey v2 (used as the base interpreter)
# - Downloads Ahk2Exe from its official GitHub release on first run (tools\ is gitignored)
# Usage: powershell -ExecutionPolicy Bypass -File build.ps1

$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot

# 1) locate AutoHotkey v2 x64
$ahk = @(
    "$env:ProgramFiles\AutoHotkey\v2\AutoHotkey64.exe",
    "${env:ProgramFiles(x86)}\AutoHotkey\v2\AutoHotkey64.exe",
    "$env:LOCALAPPDATA\Programs\AutoHotkey\v2\AutoHotkey64.exe"
) | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $ahk) { throw 'AutoHotkey v2 not found. Install it from https://www.autohotkey.com/' }
Write-Output "base: $ahk"

# 2) locate or download Ahk2Exe
$toolsDir = Join-Path $root 'tools'
$ahk2exe  = Join-Path $toolsDir 'Ahk2Exe.exe'
if (-not (Test-Path $ahk2exe)) {
    New-Item -ItemType Directory -Force -Path $toolsDir | Out-Null
    $rel = Invoke-RestMethod 'https://api.github.com/repos/AutoHotkey/Ahk2Exe/releases/latest'
    $url = @($rel.assets.browser_download_url)[0]
    if (-not $url) { throw 'No asset found in the latest Ahk2Exe release' }
    Write-Output "downloading compiler: $url"
    $zip = Join-Path $toolsDir 'Ahk2Exe.zip'
    Invoke-WebRequest -Uri $url -OutFile $zip
    Expand-Archive -Path $zip -DestinationPath $toolsDir -Force
    Remove-Item $zip
}
Write-Output "compiler: $ahk2exe"

# 3) compile
# NOTE: Start-Process does NOT quote arguments for you; paths with spaces
# (like C:\Program Files\...) must be quoted manually or /base gets split.
$in  = Join-Path $root 'mac-keys.ahk'
$out = Join-Path $root 'mac-keys.exe'
$argline = '/in "' + $in + '" /out "' + $out + '" /base "' + $ahk + '"'
$p = Start-Process -FilePath $ahk2exe -ArgumentList $argline -PassThru
$produced = $false
for ($i = 1; $i -le 40; $i++) {
    Start-Sleep -Seconds 1
    if (Test-Path $out) {
        if ((Get-Item $out).Length -gt 100KB) { $produced = $true; break }
    }
    if ($p.HasExited) { break }
}
if (-not $produced) { throw "compile failed (exit code $($p.ExitCode))" }
Write-Output ("built: " + $out + " (" + (Get-Item $out).Length + " bytes)")
