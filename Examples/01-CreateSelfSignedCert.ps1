param()

# Example 01 — Create a self-signed RSA certificate and export to PEM
# Usage: pwsh -File 01-CreateSelfSignedCert.ps1

if (-not $IsLinux) {
    Write-Error "This script requires Linux with the PKI.Linux module."
    exit 1
}

Import-Module PKI.Linux -ErrorAction Stop

Write-Host "Creating self-signed certificate for 'myserver.example.com'..."
$cert = New-SelfSignedCertificate `
    -Subject 'CN=myserver.example.com,O=ExampleOrg' `
    -DnsName 'myserver.example.com', 'localhost' `
    -NotAfter (Get-Date).AddYears(2)

Write-Host "Certificate created:"
Write-Host "  Subject   : $($cert.Subject)"
Write-Host "  Thumbprint: $($cert.Thumbprint)"
Write-Host "  Valid To  : $($cert.NotAfter)"

# Export to PEM
$pemPath = '/tmp/myserver.pem'
Export-Certificate -Cert $cert -FilePath $pemPath -Type PEM -Force
Write-Host "Exported PEM: $pemPath"

# Export to DER
$derPath = '/tmp/myserver.cer'
Export-Certificate -Cert $cert -FilePath $derPath -Force
Write-Host "Exported DER: $derPath"
