param()

# Example 03 — Validate a certificate chain
# Usage: pwsh -File 03-TestCertificate.ps1

if (-not $IsLinux) {
    Write-Error "This script requires Linux with the PKI.Linux module."
    exit 1
}

if (-not (Get-Module PKI.Linux)) { Import-Module PKI.Linux -ErrorAction Stop }

Write-Host "Creating a self-signed cert and validating it..."
$cert = New-SelfSignedCertificate -DnsName 'validate.example.local'

# Without AllowUntrustedRoot — will fail because it's self-signed
$result1 = Test-Certificate -Cert $cert
Write-Host "  Test without AllowUntrustedRoot: $result1  (expected: False)"

# With AllowUntrustedRoot — should pass
$result2 = Test-Certificate -Cert $cert -AllowUntrustedRoot
Write-Host "  Test with AllowUntrustedRoot   : $result2  (expected: True)"

# Pipeline example — validate all certs in CurrentUser\My
Write-Host ""
Write-Host "Validating all certs in CurrentUser\My (no revocation check)..."
$store = [System.Security.Cryptography.X509Certificates.X509Store]::new('My', 'CurrentUser')
$store.Open('ReadOnly')
$store.Certificates | ForEach-Object {
    $valid = Test-Certificate -Cert $_ -AllowUntrustedRoot
    Write-Host "  [$( if ($valid) { 'OK  ' } else { 'FAIL' } )] $($_.Subject)"
}
$store.Close()
