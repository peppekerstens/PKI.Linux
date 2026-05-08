function Export-PfxCertificate {
    <#
    .Synopsis
        Exports a certificate and its private key to a PFX (PKCS#12) file.
    .Description
        Linux implementation of Export-PfxCertificate. Uses X509Certificate2.Export()
        to write a password-protected PFX file using .NET APIs. No openssl required.
        Supports pipeline input — multiple certificates can be piped when exporting to
        separate files.

        Note: SecureString on Linux does not provide OS-level memory encryption.
        It is used here for API parity with the Windows PKI module and to minimise
        the time window during which the plaintext password exists in managed memory.
    .Parameter Cert
        The X509Certificate2 object to export. Must include a private key.
    .Parameter FilePath
        Destination PFX file path.
    .Parameter Password
        SecureString password to protect the PFX. Required.
    .Parameter Force
        Overwrite existing file.
    .Example
        $cert = New-SelfSignedCertificate -DnsName "test.local"
        $pw = ConvertTo-SecureString "P@ssword1" -AsPlainText -Force
        Export-PfxCertificate -Cert $cert -FilePath "/tmp/test.pfx" -Password $pw
    .Link
        https://learn.microsoft.com/powershell/module/pki/export-pfxcertificate
    #>
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([System.IO.FileInfo])]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [System.Security.Cryptography.X509Certificates.X509Certificate2] $Cert,

        [Parameter(Mandatory)]
        [string] $FilePath,

        [Parameter(Mandatory)]
        [System.Security.SecureString] $Password,

        [switch] $Force
    )

    process {
        if ((Test-Path $FilePath) -and -not $Force) {
            $ex  = [System.IO.IOException]::new("File '$FilePath' already exists. Use -Force to overwrite.")
            $err = [System.Management.Automation.ErrorRecord]::new(
                $ex,
                'Export-PfxCertificate.FileAlreadyExists',
                [System.Management.Automation.ErrorCategory]::ResourceExists,
                $FilePath
            )
            $PSCmdlet.WriteError($err)
            return
        }

        if (-not $Cert.HasPrivateKey) {
            $ex  = [System.InvalidOperationException]::new(
                "The certificate '$($Cert.Subject)' does not have a private key and cannot be exported as PFX."
            )
            $err = [System.Management.Automation.ErrorRecord]::new(
                $ex,
                'Export-PfxCertificate.NoPrivateKey',
                [System.Management.Automation.ErrorCategory]::InvalidArgument,
                $Cert
            )
            $PSCmdlet.ThrowTerminatingError($err)
        }

        if ($PSCmdlet.ShouldProcess($FilePath, 'Export-PfxCertificate')) {
            # Convert SecureString to BSTR and immediately zero it after use.
            # Note: on Linux, SecureString does not encrypt memory at the OS level —
            # it is used here for API parity and to minimise plaintext lifetime.
            $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password)
            try {
                $plainPw = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
                $pfxBytes = $Cert.Export(
                    [System.Security.Cryptography.X509Certificates.X509ContentType]::Pkcs12,
                    $plainPw
                )
            }
            finally {
                [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
            }

            [System.IO.File]::WriteAllBytes($FilePath, $pfxBytes)
            Get-Item $FilePath
        }
    }
}
