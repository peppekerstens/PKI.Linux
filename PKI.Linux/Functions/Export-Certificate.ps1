function Export-Certificate {
    <#
    .Synopsis
        Exports a certificate to a file in DER or PEM format.
    .Description
        Linux implementation of Export-Certificate. Exports an X509Certificate2 object
        to a DER (.cer/.crt) or PEM (.pem) file using .NET APIs. No openssl required.
    .Parameter Cert
        The X509Certificate2 object to export.
    .Parameter FilePath
        Destination file path.
    .Parameter Type
        Output encoding: CERT (DER binary, default) or PEM (base64 ASCII).
    .Parameter Force
        Overwrite existing file.
    .Example
        $cert = New-SelfSignedCertificate -DnsName "test.local"
        Export-Certificate -Cert $cert -FilePath "/tmp/test.cer"
    .Example
        Export-Certificate -Cert $cert -FilePath "/tmp/test.pem" -Type PEM
    .Link
        https://learn.microsoft.com/powershell/module/pki/export-certificate
    #>
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([System.IO.FileInfo])]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [System.Security.Cryptography.X509Certificates.X509Certificate2] $Cert,

        [Parameter(Mandatory)]
        [string] $FilePath,

        [ValidateSet('CERT', 'PEM')]
        [string] $Type = 'CERT',

        [switch] $Force
    )

    if ((Test-Path $FilePath) -and -not $Force) {
        Write-Error "File '$FilePath' already exists. Use -Force to overwrite."
        return
    }

    if ($PSCmdlet.ShouldProcess($FilePath, 'Export-Certificate')) {
        if ($Type -eq 'PEM') {
            $derBytes = $Cert.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Cert)
            $b64 = [Convert]::ToBase64String($derBytes, [Base64FormattingOptions]::InsertLineBreaks)
            $pem = "-----BEGIN CERTIFICATE-----`n$b64`n-----END CERTIFICATE-----"
            [System.IO.File]::WriteAllText($FilePath, $pem)
        }
        else {
            $derBytes = $Cert.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Cert)
            [System.IO.File]::WriteAllBytes($FilePath, $derBytes)
        }

        Get-Item $FilePath
    }
}
