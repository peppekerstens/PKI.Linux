function Export-PfxCertificate {
    <#
    .Synopsis
        Exports a certificate and its private key to a PFX (PKCS#12) file.
    .Description
        Linux implementation of Export-PfxCertificate. Uses X509Certificate2.Export()
        to write a password-protected PFX file using .NET APIs. No openssl required.
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

    if ((Test-Path $FilePath) -and -not $Force) {
        Write-Error "File '$FilePath' already exists. Use -Force to overwrite."
        return
    }

    if (-not $Cert.HasPrivateKey) {
        Write-Error "The certificate does not have a private key. Cannot export as PFX."
        return
    }

    if ($PSCmdlet.ShouldProcess($FilePath, 'Export-PfxCertificate')) {
        # Convert SecureString to plain text for Export()
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
