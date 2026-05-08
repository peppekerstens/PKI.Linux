function Import-Certificate {
    <#
    .Synopsis
        Imports a certificate file into the CurrentUser\My certificate store.
    .Description
        Linux implementation of Import-Certificate. Reads a DER or PEM certificate file
        and adds it to the X509 CurrentUser\My store (maps to ~/.dotnet/corefx/cryptography/x509stores/my/).
        LocalMachine store is not supported on Linux.
    .Parameter FilePath
        Path to the certificate file (.cer, .crt, or .pem).
    .Parameter CertStoreLocation
        Target store. Only 'Cert:\CurrentUser\My' is supported on Linux.
    .Example
        Import-Certificate -FilePath "/tmp/myca.cer" -CertStoreLocation "Cert:\CurrentUser\My"
    .Link
        https://learn.microsoft.com/powershell/module/pki/import-certificate
    #>
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([System.Security.Cryptography.X509Certificates.X509Certificate2])]
    param(
        [Parameter(Mandatory)]
        [string] $FilePath,

        [string] $CertStoreLocation = 'Cert:\CurrentUser\My'
    )

    if (-not (Test-Path $FilePath)) {
        Write-Error "File not found: $FilePath"
        return
    }

    if ($CertStoreLocation -match 'LocalMachine') {
        Write-Error "LocalMachine certificate store is not supported on Linux. Use 'Cert:\CurrentUser\My'."
        return
    }

    # Load cert — handles both DER and PEM automatically
    $cert = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new($FilePath)

    if ($PSCmdlet.ShouldProcess($cert.Subject, 'Import-Certificate')) {
        $store = [System.Security.Cryptography.X509Certificates.X509Store]::new(
            [System.Security.Cryptography.X509Certificates.StoreName]::My,
            [System.Security.Cryptography.X509Certificates.StoreLocation]::CurrentUser
        )
        $store.Open([System.Security.Cryptography.X509Certificates.OpenFlags]::ReadWrite)
        $store.Add($cert)
        $store.Close()
        Write-Verbose "Certificate '$($cert.Subject)' imported to CurrentUser\My."
        $cert
    }
}
