[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '', Justification = 'Example script uses a dummy password for illustration only')]
param()

# Example 04 — ECDSA certificate for a web server (TLS demo)
# Usage: pwsh -File 04-EcdsaWebServerCert.ps1

if (-not $IsLinux) {
    Write-Error "This script requires Linux with the PKI.Linux module."
    exit 1
}

if (-not (Get-Module PKI.Linux)) { Import-Module PKI.Linux -ErrorAction Stop }

Write-Host "Creating ECDSA P-256 certificate for web server..."
$cert = New-SelfSignedCertificate `
    -Subject 'CN=webserver.internal,O=InternalCA' `
    -DnsName 'webserver.internal', 'webserver', 'localhost' `
    -KeyAlgorithm ECDSA `
    -HashAlgorithm SHA256 `
    -NotAfter (Get-Date).AddMonths(6)

Write-Host "  Subject   : $($cert.Subject)"
Write-Host "  Thumbprint: $($cert.Thumbprint)"
Write-Host "  Algorithm : $($cert.PublicKey.Oid.FriendlyName)"
Write-Host "  Valid To  : $($cert.NotAfter)"

$pemPath = '/tmp/webserver.pem'
$pfxPath = '/tmp/webserver.pfx'
$pw = ConvertTo-SecureString 'WebServerPw1!' -AsPlainText -Force

Export-Certificate -Cert $cert -FilePath $pemPath -Type PEM -Force
Write-Host "Exported PEM cert : $pemPath"

Export-PfxCertificate -Cert $cert -FilePath $pfxPath -Password $pw -Force
Write-Host "Exported PFX bundle: $pfxPath"
Write-Host ""
Write-Host "Use with nginx or Apache: copy PEM cert + extract private key from PFX."
