#Requires -Version 7.2

# PKI.Linux.psm1
# Root module for PKI.Linux.
# Dot-sources all function files from the Functions\ subdirectory.

# Linux-only guard — this module wraps .NET cryptography APIs and must not be loaded on Windows.
# On Windows, use the built-in module:
#   Import-Module PKI
if (-not $IsLinux) {
    throw (
        "PKI.Linux cannot be loaded on Windows. " +
        "On Windows, use the built-in 'PKI' module.`n" +
        "PKI.Linux is a Linux-only peer module that wraps .NET cryptography APIs."
    )
}

$functionPath = Join-Path $PSScriptRoot 'Functions'
$functionFiles = Get-ChildItem -Path $functionPath -Filter '*.ps1' -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -notlike '*.Tests.ps1' }
foreach ($file in $functionFiles) {
    . $file.FullName
}
