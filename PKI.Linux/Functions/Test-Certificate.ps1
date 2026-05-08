function Test-Certificate {
    <#
    .Synopsis
        Verifies a certificate's chain of trust and optionally checks revocation.
    .Description
        Linux implementation of Test-Certificate. Uses X509Chain.Build() from .NET to
        validate the certificate chain. On Linux, .NET uses OpenSSL internally for
        chain building and revocation checks where available.
        Returns $true if the chain builds successfully, $false otherwise.

        The X509Chain object is disposed after each certificate is processed to
        release the underlying OpenSSL verification context.
    .Parameter Cert
        The X509Certificate2 object to validate.
    .Parameter Policy
        Revocation check mode:
          NoCheck     — skip revocation checks (default)
          Online      — check CRL/OCSP online
          Offline     — use cached CRL only
    .Parameter AllowUntrustedRoot
        If set, allow self-signed certificates with untrusted roots to pass validation.
    .Example
        $cert = New-SelfSignedCertificate -DnsName "test.local"
        Test-Certificate -Cert $cert -AllowUntrustedRoot
    .Example
        Get-ChildItem Cert:\CurrentUser\My | Test-Certificate
    .Link
        https://learn.microsoft.com/powershell/module/pki/test-certificate
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [System.Security.Cryptography.X509Certificates.X509Certificate2] $Cert,

        [ValidateSet('NoCheck', 'Online', 'Offline')]
        [string] $Policy = 'NoCheck',

        [switch] $AllowUntrustedRoot
    )

    process {
        # X509Chain holds an OpenSSL verification context on Linux — must be disposed
        # per certificate to avoid resource leaks in pipeline scenarios.
        $chain = [System.Security.Cryptography.X509Certificates.X509Chain]::new()
        try {
            $chain.ChainPolicy.RevocationMode = switch ($Policy) {
                'NoCheck' { [System.Security.Cryptography.X509Certificates.X509RevocationMode]::NoCheck }
                'Online'  { [System.Security.Cryptography.X509Certificates.X509RevocationMode]::Online }
                'Offline' { [System.Security.Cryptography.X509Certificates.X509RevocationMode]::Offline }
            }

            if ($AllowUntrustedRoot) {
                $chain.ChainPolicy.VerificationFlags =
                    [System.Security.Cryptography.X509Certificates.X509VerificationFlags]::AllowUnknownCertificateAuthority
            }

            $result = $chain.Build($Cert)

            if (-not $result) {
                $errors = $chain.ChainStatus | ForEach-Object { $_.StatusInformation.Trim() }
                Write-Verbose "Certificate validation failed: $($errors -join '; ')"
            }

            $result
        }
        finally {
            $chain.Dispose()
        }
    }
}
