function Import-PfxCertificate {
    <#
    .Synopsis
        Imports a PFX (PKCS#12) certificate with its private key into the CurrentUser\My store.
    .Description
        Linux implementation of Import-PfxCertificate. Reads a password-protected PFX file
        and adds the certificate (with private key) to the X509 CurrentUser\My store.
        LocalMachine store is not supported on Linux.
    .Parameter FilePath
        Path to the PFX file.
    .Parameter Password
        SecureString password for the PFX.
    .Parameter CertStoreLocation
        Target store. Only 'Cert:\CurrentUser\My' is supported on Linux.
    .Parameter Exportable
        If set, marks the private key as exportable. Accepted for Windows compat; on Linux
        the key is always stored on disk so this flag has no additional effect.
    .Example
        $pw = ConvertTo-SecureString "P@ssword1" -AsPlainText -Force
        Import-PfxCertificate -FilePath "/tmp/test.pfx" -Password $pw
    .Link
        https://learn.microsoft.com/powershell/module/pki/import-pfxcertificate
    #>
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([System.Security.Cryptography.X509Certificates.X509Certificate2])]
    param(
        [Parameter(Mandatory)]
        [string] $FilePath,

        [System.Security.SecureString] $Password,

        [string] $CertStoreLocation = 'Cert:\CurrentUser\My',

        [switch] $Exportable
    )

    if (-not (Test-Path $FilePath)) {
        Write-Error "File not found: $FilePath"
        return
    }

    if ($CertStoreLocation -match 'LocalMachine') {
        Write-Error "LocalMachine certificate store is not supported on Linux. Use 'Cert:\CurrentUser\My'."
        return
    }

    $bstr = if ($Password) {
        [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password)
    }
    else { [IntPtr]::Zero }

    try {
        $plainPw = if ($bstr -ne [IntPtr]::Zero) {
            [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
        }
        else { $null }

        $flags = [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::PersistKeySet
        if ($Exportable) {
            $flags = $flags -bor [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::Exportable
        }

        $cert = if ($plainPw) {
            [System.Security.Cryptography.X509Certificates.X509Certificate2]::new($FilePath, $plainPw, $flags)
        }
        else {
            [System.Security.Cryptography.X509Certificates.X509Certificate2]::new($FilePath, [string]$null, $flags)
        }
    }
    finally {
        if ($bstr -ne [IntPtr]::Zero) {
            [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
        }
    }

    if ($PSCmdlet.ShouldProcess($cert.Subject, 'Import-PfxCertificate')) {
        $store = [System.Security.Cryptography.X509Certificates.X509Store]::new(
            [System.Security.Cryptography.X509Certificates.StoreName]::My,
            [System.Security.Cryptography.X509Certificates.StoreLocation]::CurrentUser
        )
        $store.Open([System.Security.Cryptography.X509Certificates.OpenFlags]::ReadWrite)
        $store.Add($cert)
        $store.Close()
        Write-Verbose "PFX certificate '$($cert.Subject)' imported to CurrentUser\My."
        $cert
    }
}
