function Get-Certificate {
    <#
    .Synopsis
        Reads certificates from the local store, or stubs Windows enrollment operations.
    .Description
        PKI.Linux partial implementation of Get-Certificate.

        The Windows Get-Certificate cmdlet has two parameter sets — both enrollment-only
        (SubmitRequest and PendingRetrieval). Neither is implementable on Linux because
        they require Active Directory Certificate Services and Windows enrollment
        infrastructure. Both emit a warning on Linux.

        PKI.Linux adds a third parameter set (LocalStore) that was not present in the
        Windows original. It reads and filters certificates from the CurrentUser\My
        store using the .NET X509Store API. This covers the common intent behind
        "Get-Certificate" — inspecting what certificates you have — using pure .NET
        with no enrollment server or CA required.

        Parameter support by condition:

          LocalStore parameter set (Linux-native, fully supported):
            -StoreName          — store to read from (default: My)
            -StoreLocation      — CurrentUser or LocalMachine (default: CurrentUser)
            -Thumbprint         — filter by exact thumbprint
            -SubjectName        — filter by subject name (partial match)
            -DnsName            — filter by SAN DNS name
            -Eku                — filter by Extended Key Usage OID

          SubmitRequest parameter set (STUB — requires Windows CA infrastructure):
            -Template           — WARNING: not supported on Linux
            -Url                — WARNING: not supported on Linux
            -SubjectName        — WARNING: not supported on Linux (in this parameter set)
            -DnsName            — WARNING: not supported on Linux (in this parameter set)
            -Credential         — WARNING: not supported on Linux
            -CertStoreLocation  — WARNING: not supported on Linux (in this parameter set)

          PendingRetrieval parameter set (STUB — requires Windows CA infrastructure):
            -Request            — WARNING: not supported on Linux
            -Credential         — WARNING: not supported on Linux
    .Parameter StoreName
        The X509 store name to read from. Default: My. Applies to LocalStore parameter set.
    .Parameter StoreLocation
        CurrentUser (default) or LocalMachine. Applies to LocalStore parameter set.
        Note: LocalMachine store on Linux is backed by /etc/ssl/certs, not a writable user store.
    .Parameter Thumbprint
        Filter certificates by exact SHA-1 thumbprint. Applies to LocalStore parameter set.
    .Parameter SubjectName
        Filter certificates by subject name (partial, case-insensitive match).
        Applies to LocalStore parameter set.
    .Parameter DnsName
        Filter certificates by Subject Alternative Name DNS entry (partial match).
        Applies to LocalStore parameter set.
    .Parameter Eku
        Filter certificates by Extended Key Usage OID (e.g. '1.3.6.1.5.5.7.3.1' for Server Auth).
        Applies to LocalStore parameter set.
    .Parameter Template
        Windows CA certificate template name or OID. NOT SUPPORTED on Linux.
        Emits a terminating error.
    .Parameter Url
        Windows enrollment policy server URL. NOT SUPPORTED on Linux.
        Emits a terminating error.
    .Parameter Credential
        Windows enrollment credential. NOT SUPPORTED on Linux.
        Emits a terminating error.
    .Parameter CertStoreLocation
        Windows enrollment target store path (Cert:\...). NOT SUPPORTED on Linux.
        Emits a terminating error.
    .Parameter Request
        Windows pending enrollment request object. NOT SUPPORTED on Linux.
        Emits a terminating error.
    .Example
        # List all certificates in CurrentUser\My
        Get-Certificate

    .Example
        # Find a certificate by thumbprint
        Get-Certificate -Thumbprint 'AB12CD34EF56...'

    .Example
        # Find certificates for a DNS name
        Get-Certificate -DnsName 'myserver.local'

    .Example
        # Find certificates by EKU (Server Authentication)
        Get-Certificate -Eku '1.3.6.1.5.5.7.3.1'

    .Example
        # Read from the LocalMachine store
        Get-Certificate -StoreLocation LocalMachine

    .Link
        https://learn.microsoft.com/powershell/module/pki/get-certificate
    #>
    [CmdletBinding(DefaultParameterSetName = 'LocalStore')]
    [OutputType([System.Security.Cryptography.X509Certificates.X509Certificate2],
        ParameterSetName = 'LocalStore')]
    [OutputType([PSCustomObject],
        ParameterSetName = 'SubmitRequest')]
    [OutputType([PSCustomObject],
        ParameterSetName = 'PendingRetrieval')]
    param(

        # ── LocalStore parameter set ──────────────────────────────────────────
        [Parameter(ParameterSetName = 'LocalStore')]
        [System.Security.Cryptography.X509Certificates.StoreName]
        $StoreName = [System.Security.Cryptography.X509Certificates.StoreName]::My,

        [Parameter(ParameterSetName = 'LocalStore')]
        [System.Security.Cryptography.X509Certificates.StoreLocation]
        $StoreLocation = [System.Security.Cryptography.X509Certificates.StoreLocation]::CurrentUser,

        [Parameter(ParameterSetName = 'LocalStore')]
        [string] $Thumbprint,

        [Parameter(ParameterSetName = 'LocalStore')]
        [Parameter(ParameterSetName = 'SubmitRequest')]
        [string] $SubjectName,

        [Parameter(ParameterSetName = 'LocalStore')]
        [Parameter(ParameterSetName = 'SubmitRequest')]
        [string[]] $DnsName,

        [Parameter(ParameterSetName = 'LocalStore')]
        [string] $Eku,

        # ── SubmitRequest parameter set (Windows enrollment stub) ─────────────
        [Parameter(Mandatory, ParameterSetName = 'SubmitRequest')]
        [string] $Template,

        [Parameter(ParameterSetName = 'SubmitRequest')]
        [Uri] $Url,

        [Parameter(ParameterSetName = 'SubmitRequest')]
        [Parameter(ParameterSetName = 'PendingRetrieval')]
        [object] $Credential,

        [Parameter(ParameterSetName = 'SubmitRequest')]
        [string] $CertStoreLocation,

        # ── PendingRetrieval parameter set (Windows enrollment stub) ──────────
        [Parameter(Mandatory, ParameterSetName = 'PendingRetrieval',
            ValueFromPipeline)]
        [object] $Request
    )

    # ── Windows-only parameter sets — terminating stub ────────────────────────
    if ($PSCmdlet.ParameterSetName -eq 'SubmitRequest') {
        $ex  = [System.PlatformNotSupportedException]::new(
            "Get-Certificate -Template (SubmitRequest parameter set) is not supported on Linux. " +
            "This parameter set requires Windows Active Directory Certificate Services and an " +
            "enrollment policy server. " +
            "Supported on Linux: Get-Certificate -StoreName, -Thumbprint, -SubjectName, -DnsName, -Eku " +
            "(LocalStore parameter set — reads from the local X509 certificate store)."
        )
        $err = [System.Management.Automation.ErrorRecord]::new(
            $ex,
            'Get-Certificate.SubmitRequestNotSupported',
            [System.Management.Automation.ErrorCategory]::NotImplemented,
            $Template
        )
        $PSCmdlet.ThrowTerminatingError($err)
    }

    if ($PSCmdlet.ParameterSetName -eq 'PendingRetrieval') {
        $ex  = [System.PlatformNotSupportedException]::new(
            "Get-Certificate -Request (PendingRetrieval parameter set) is not supported on Linux. " +
            "This parameter set requires a pending enrollment request from the Windows REQUEST " +
            "certificate store, which does not exist on Linux. " +
            "Supported on Linux: Get-Certificate -StoreName, -Thumbprint, -SubjectName, -DnsName, -Eku " +
            "(LocalStore parameter set — reads from the local X509 certificate store)."
        )
        $err = [System.Management.Automation.ErrorRecord]::new(
            $ex,
            'Get-Certificate.PendingRetrievalNotSupported',
            [System.Management.Automation.ErrorCategory]::NotImplemented,
            $Request
        )
        $PSCmdlet.ThrowTerminatingError($err)
    }

    # ── LocalStore parameter set — fully implemented ──────────────────────────
    $store = [System.Security.Cryptography.X509Certificates.X509Store]::new(
        $StoreName, $StoreLocation
    )

    try {
        $store.Open(
            [System.Security.Cryptography.X509Certificates.OpenFlags]::ReadOnly -bor
            [System.Security.Cryptography.X509Certificates.OpenFlags]::OpenExistingOnly
        )
    }
    catch [System.Security.Cryptography.CryptographicException] {
        $ex  = [System.Security.Cryptography.CryptographicException]::new(
            "Cannot open certificate store '$StoreName' ($StoreLocation). " +
            "On Linux, LocalMachine stores are backed by system CA directories and may not be " +
            "writable. Inner: $($_.Exception.Message)",
            $_.Exception
        )
        $err = [System.Management.Automation.ErrorRecord]::new(
            $ex,
            'Get-Certificate.StoreOpenFailed',
            [System.Management.Automation.ErrorCategory]::ResourceUnavailable,
            "$StoreLocation\$StoreName"
        )
        $PSCmdlet.ThrowTerminatingError($err)
    }

    try {
        $certs = $store.Certificates

        # Apply filters — each narrows the working set
        if ($Thumbprint) {
            $certs = $certs.Find(
                [System.Security.Cryptography.X509Certificates.X509FindType]::FindByThumbprint,
                $Thumbprint, $false
            )
        }

        if ($SubjectName) {
            $certs = $certs.Find(
                [System.Security.Cryptography.X509Certificates.X509FindType]::FindBySubjectName,
                $SubjectName, $false
            )
        }

        if ($Eku) {
            $certs = $certs.Find(
                [System.Security.Cryptography.X509Certificates.X509FindType]::FindByApplicationPolicy,
                $Eku, $false
            )
        }

        # DnsName filter — X509FindType has no DnsName variant; inspect SAN extension manually
        if ($DnsName) {
            $sanType = [System.Security.Cryptography.X509Certificates.X509SubjectAlternativeNameExtension]
            $filtered = foreach ($cert in $certs) {
                $sanExt = $cert.Extensions | Where-Object { $_ -is $sanType }
                if ($sanExt) {
                    # GetDnsNames() available on .NET 6+ (PS 7.2+)
                    $certDnsNames = $sanExt.EnumerateDnsNames()
                    $match = $false
                    foreach ($requestedName in $DnsName) {
                        foreach ($certName in $certDnsNames) {
                            if ($certName -like "*$requestedName*") {
                                $match = $true
                                break
                            }
                        }
                        if ($match) { break }
                    }
                    if ($match) { $cert }
                }
            }
            # Rebuild as X509Certificate2Collection for consistency
            $certs = [System.Security.Cryptography.X509Certificates.X509Certificate2Collection]::new()
            foreach ($c in $filtered) { $certs.Add($c) | Out-Null }
        }

        # Emit each matching certificate to the pipeline
        foreach ($cert in $certs) {
            $cert
        }
    }
    finally {
        $store.Dispose()
    }
}
