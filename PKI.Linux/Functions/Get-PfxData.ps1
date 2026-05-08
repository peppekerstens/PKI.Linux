function Get-PfxData {
    <#
    .Synopsis
        Reads a PFX file and returns its certificate chain without importing it.
    .Description
        Linux implementation of Get-PfxData. Loads a PKCS#12 file using
        X509Certificate2Collection and returns a PSCustomObject with EndEntityCertificates
        and OtherCertificates collections, matching the Windows output shape.

        The EphemeralKeySet flag is used so private key material is never written
        to disk during the inspection operation.

        Note: SecureString on Linux does not provide OS-level memory encryption.
        It is used here for API parity with the Windows PKI module.
    .Parameter FilePath
        Path to the PFX file.
    .Parameter Password
        SecureString password for the PFX.
    .Example
        $pw = ConvertTo-SecureString "P@ssword1" -AsPlainText -Force
        $pfxData = Get-PfxData -FilePath "/tmp/test.pfx" -Password $pw
        $pfxData.EndEntityCertificates
    .Link
        https://learn.microsoft.com/powershell/module/pki/get-pfxdata
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({ Test-Path $_ -PathType Leaf },
            ErrorMessage = "PFX file '{0}' was not found.")]
        [string] $FilePath,

        [System.Security.SecureString] $Password
    )

    $bstr = if ($Password) {
        [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password)
    }
    else { [IntPtr]::Zero }

    $collection = $null
    try {
        $plainPw = if ($bstr -ne [IntPtr]::Zero) {
            [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
        }
        else { $null }

        $pfxBytes   = [System.IO.File]::ReadAllBytes($FilePath)
        $collection = [System.Security.Cryptography.X509Certificates.X509Certificate2Collection]::new()

        try {
            if ($plainPw) {
                $collection.Import($pfxBytes, $plainPw,
                    [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::EphemeralKeySet)
            }
            else {
                $collection.Import($pfxBytes, [string]$null,
                    [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::EphemeralKeySet)
            }
        }
        catch [System.Security.Cryptography.CryptographicException] {
            $ex  = [System.Security.Cryptography.CryptographicException]::new(
                "Failed to load PFX '$FilePath'. Verify the password is correct. Inner: $($_.Exception.Message)",
                $_.Exception
            )
            $err = [System.Management.Automation.ErrorRecord]::new(
                $ex,
                'Get-PfxData.ImportFailed',
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

    # Classify: end-entity = has private key OR not a CA; others = CA certs
    $endEntity = $collection | Where-Object {
        $_.HasPrivateKey -or
        -not ($_.Extensions | Where-Object {
            $_ -is [System.Security.Cryptography.X509Certificates.X509BasicConstraintsExtension] -and
            $_.CertificateAuthority
        })
    }
    $others = $collection | Where-Object {
        -not $_.HasPrivateKey -and
        ($_.Extensions | Where-Object {
            $_ -is [System.Security.Cryptography.X509Certificates.X509BasicConstraintsExtension] -and
            $_.CertificateAuthority
        })
    }

    [PSCustomObject]@{
        EndEntityCertificates = @($endEntity)
        OtherCertificates     = @($others)
    }
}
