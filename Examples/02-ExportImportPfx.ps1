[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '', Justification = 'Example script uses a dummy password for illustration only')]
param()

# Example 02 — Export and reimport a PFX certificate
# Usage: pwsh -File 02-ExportImportPfx.ps1

if (-not $IsLinux) {
    Write-Error "This script requires Linux with the PKI.Linux module."
    exit 1
}

if (-not (Get-Module PKI.Linux)) { Import-Module PKI.Linux -ErrorAction Stop }

$password = ConvertTo-SecureString 'MySecureP@ssword1' -AsPlainText -Force
$pfxPath  = '/tmp/mycert.pfx'

Write-Host "Creating self-signed certificate..."
$cert = New-SelfSignedCertificate -DnsName 'pfx-demo.local' -KeyLength 4096

Write-Host "Exporting to PFX: $pfxPath"
Export-PfxCertificate -Cert $cert -FilePath $pfxPath -Password $password -Force

Write-Host "Reading PFX metadata with Get-PfxData (no import)..."
$pfxData = Get-PfxData -FilePath $pfxPath -Password $password
Write-Host "  End-entity subject: $($pfxData.EndEntityCertificates[0].Subject)"
Write-Host "  Other certs (CAs) : $($pfxData.OtherCertificates.Count)"

Write-Host "Importing PFX into CurrentUser\My store..."
$imported = Import-PfxCertificate -FilePath $pfxPath -Password $password
Write-Host "  Imported: $($imported.Subject) (has private key: $($imported.HasPrivateKey))"
