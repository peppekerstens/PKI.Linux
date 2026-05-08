function Import-PfxCertificate {
    <#
    .Synopsis
        Imports a PFX (PKCS#12) certificate with its private key into the CurrentUser\My store.
    .Description
        Linux implementation of Import-PfxCertificate. Reads a password-protected PFX file
        and adds the certificate (with private key) to the X509 CurrentUser\My store.
        LocalMachine store is not supported on Linux.

        Note: SecureString on Linux does not provide OS-level memory encryption.
        It is used here for API parity with the Windows PKI module and to minimise
        the time window during which the plaintext password exists in managed memory.
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
        [ValidateScript({ Test-Path $_ -PathType Leaf },
            ErrorMessage = "PFX file '{0}' was not found.")]
        [string] $FilePath,

        [System.Security.SecureString] $Password,

        [ValidateSet('Cert:\CurrentUser\My', 'Cert:\LocalMachine\My')]
        [string] $CertStoreLocation = 'Cert:\CurrentUser\My',

        [switch] $Exportable
    )

    if ($CertStoreLocation -match 'LocalMachine') {
        $ex  = [System.PlatformNotSupportedException]::new(
            "LocalMachine certificate store is not supported on Linux. Use 'Cert:\CurrentUser\My'."
        )
        $err = [System.Management.Automation.ErrorRecord]::new(
            $ex,
            'Import-PfxCertificate.LocalMachineStoreNotSupported',
            [System.Management.Automation.ErrorCategory]::NotImplemented,
            $CertStoreLocation
        )
        $PSCmdlet.ThrowTerminatingError($err)
    }

    # Decrypt the BSTR immediately and zero it after use.
    # Note: on Linux, SecureString does not encrypt memory at the OS level —
    # it is used here for API parity and to minimise plaintext lifetime.
    $bstr = if ($Password) {
        [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password)
    }
    else { [IntPtr]::Zero }

    $cert = $null
    try {
        $plainPw = if ($bstr -ne [IntPtr]::Zero) {
            [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
        }
        else { $null }

        $flags = [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::PersistKeySet
        if ($Exportable) {
            $flags = $flags -bor [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::Exportable
        }

        try {
            $cert = if ($plainPw) {
                [System.Security.Cryptography.X509Certificates.X509Certificate2]::new(
                    $FilePath, $plainPw, $flags)
            }
            else {
                [System.Security.Cryptography.X509Certificates.X509Certificate2]::new(
                    $FilePath, [string]$null, $flags)
            }
        }
        catch [System.Security.Cryptography.CryptographicException] {
            $ex  = [System.Security.Cryptography.CryptographicException]::new(
                "Failed to load PFX '$FilePath'. Verify the password is correct. Inner: $($_.Exception.Message)",
                $_.Exception
            )
            $err = [System.Management.Automation.ErrorRecord]::new(
                $ex,
                'Import-PfxCertificate.LoadFailed',
                [System.Management.Automation.ErrorCategory]::SecurityError,
                $FilePath
            )
            $PSCmdlet.ThrowTerminatingError($err)
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
        try {
            $store.Add($cert)
            Write-Verbose "PFX certificate '$($cert.Subject)' imported to CurrentUser\My."
        }
        finally {
            $store.Dispose()
        }
        $cert
    }
    else {
        # ShouldProcess returned false (-WhatIf / -Confirm declined) — dispose the cert
        # to release the private key material that was already decrypted
        $cert.Dispose()
    }
}
