function New-SelfSignedCertificate {
    <#
    .Synopsis
        Creates a new self-signed certificate using .NET cryptography APIs.
    .Description
        Linux implementation of New-SelfSignedCertificate. Uses CertificateRequest and
        X509SignatureGenerator from System.Security.Cryptography.X509Certificates.
        The certificate is returned as an X509Certificate2 object.
        Optionally stores it in the CurrentUser\My store.
    .Parameter Subject
        The subject distinguished name, e.g. "CN=MyServer" or "CN=MyServer,O=MyOrg".
    .Parameter DnsName
        One or more DNS SANs (Subject Alternative Names). If only one value is provided
        it is also used as the CN when Subject is omitted.
    .Parameter KeyAlgorithm
        Key algorithm: RSA (default) or ECDSA.
    .Parameter KeyLength
        RSA key length in bits. Default 2048. Ignored for ECDSA.
    .Parameter HashAlgorithm
        Hash algorithm for the signature. Default SHA256.
    .Parameter NotBefore
        Certificate validity start. Defaults to now.
    .Parameter NotAfter
        Certificate validity end. Defaults to now + 1 year.
    .Parameter CertStoreLocation
        Where to store the certificate. Accepts 'Cert:\CurrentUser\My'.
        LocalMachine store is not supported on Linux.
    .Parameter KeyUsage
        Key usage flags. Default: DigitalSignature, KeyEncipherment.
    .Parameter TextExtension
        Raw text extensions (ignored on Linux; placeholder for Windows compat).
    .Example
        New-SelfSignedCertificate -DnsName "myserver.local"
    .Example
        New-SelfSignedCertificate -Subject "CN=Test" -NotAfter (Get-Date).AddYears(5)
    .Link
        https://learn.microsoft.com/powershell/module/pki/new-selfsignedcertificate
    #>
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([System.Security.Cryptography.X509Certificates.X509Certificate2])]
    param(
        [string] $Subject,

        [string[]] $DnsName,

        [ValidateSet('RSA', 'ECDSA')]
        [string] $KeyAlgorithm = 'RSA',

        [int] $KeyLength = 2048,

        [ValidateSet('SHA256', 'SHA384', 'SHA512')]
        [string] $HashAlgorithm = 'SHA256',

        [datetime] $NotBefore = [datetime]::Now,

        [datetime] $NotAfter = [datetime]::Now.AddYears(1),

        [string] $CertStoreLocation,

        [System.Security.Cryptography.X509Certificates.X509KeyUsageFlags]
        $KeyUsage = (
            [System.Security.Cryptography.X509Certificates.X509KeyUsageFlags]::DigitalSignature -bor
            [System.Security.Cryptography.X509Certificates.X509KeyUsageFlags]::KeyEncipherment
        ),

        [string[]] $TextExtension
    )

    # Build subject DN
    if (-not $Subject) {
        if ($DnsName) { $Subject = "CN=$($DnsName[0])" }
        else           { $Subject = "CN=SelfSigned" }
    }

    $dn = [System.Security.Cryptography.X509Certificates.X500DistinguishedName]::new($Subject)

    # Create the key pair
    if ($KeyAlgorithm -eq 'ECDSA') {
        $key = [System.Security.Cryptography.ECDsa]::Create(
            [System.Security.Cryptography.ECCurve]::NamedCurves.nistP256
        )
        $hashAlg = switch ($HashAlgorithm) {
            'SHA256' { [System.Security.Cryptography.HashAlgorithmName]::SHA256 }
            'SHA384' { [System.Security.Cryptography.HashAlgorithmName]::SHA384 }
            'SHA512' { [System.Security.Cryptography.HashAlgorithmName]::SHA512 }
        }
        $padding = $null
        $req = [System.Security.Cryptography.X509Certificates.CertificateRequest]::new(
            $dn, $key, $hashAlg
        )
    }
    else {
        $key = [System.Security.Cryptography.RSA]::Create($KeyLength)
        $hashAlg = switch ($HashAlgorithm) {
            'SHA256' { [System.Security.Cryptography.HashAlgorithmName]::SHA256 }
            'SHA384' { [System.Security.Cryptography.HashAlgorithmName]::SHA384 }
            'SHA512' { [System.Security.Cryptography.HashAlgorithmName]::SHA512 }
        }
        $padding = [System.Security.Cryptography.RSASignaturePadding]::Pkcs1
        $req = [System.Security.Cryptography.X509Certificates.CertificateRequest]::new(
            $dn, $key, $hashAlg, $padding
        )
    }

    # Key Usage extension
    $req.CertificateExtensions.Add(
        [System.Security.Cryptography.X509Certificates.X509KeyUsageExtension]::new($KeyUsage, $false)
    )

    # Basic Constraints — not a CA
    $req.CertificateExtensions.Add(
        [System.Security.Cryptography.X509Certificates.X509BasicConstraintsExtension]::new($false, $false, 0, $false)
    )

    # Subject Key Identifier
    $req.CertificateExtensions.Add(
        [System.Security.Cryptography.X509Certificates.X509SubjectKeyIdentifierExtension]::new($req.PublicKey, $false)
    )

    # Subject Alternative Names
    if ($DnsName) {
        $sanBuilder = [System.Security.Cryptography.X509Certificates.SubjectAlternativeNameBuilder]::new()
        foreach ($name in $DnsName) { $sanBuilder.AddDnsName($name) }
        $req.CertificateExtensions.Add($sanBuilder.Build())
    }

    # Create self-signed cert
    $notBeforeOffset = [System.DateTimeOffset]::new($NotBefore)
    $notAfterOffset  = [System.DateTimeOffset]::new($NotAfter)

    if ($PSCmdlet.ShouldProcess($Subject, 'New-SelfSignedCertificate')) {
        $cert = $req.CreateSelfSigned($notBeforeOffset, $notAfterOffset)

        # Optionally store in CurrentUser\My
        if ($CertStoreLocation -and $CertStoreLocation -match 'CurrentUser') {
            $store = [System.Security.Cryptography.X509Certificates.X509Store]::new(
                [System.Security.Cryptography.X509Certificates.StoreName]::My,
                [System.Security.Cryptography.X509Certificates.StoreLocation]::CurrentUser
            )
            $store.Open([System.Security.Cryptography.X509Certificates.OpenFlags]::ReadWrite)
            $store.Add($cert)
            $store.Close()
            Write-Verbose "Certificate added to CurrentUser\My store."
        }
        elseif ($CertStoreLocation -and $CertStoreLocation -match 'LocalMachine') {
            Write-Warning "LocalMachine certificate store is not supported on Linux. Certificate created but not stored."
        }

        $cert
    }
}
