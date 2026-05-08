#
# Module manifest for module 'PKI.Linux'
#

@{
    RootModule        = 'PKI.Linux.psm1'
    ModuleVersion     = '0.1.0'
    GUID              = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
    Author            = 'Peppe Kerstens'
    CompanyName       = ''
    Copyright         = '(c) Peppe Kerstens. GPL-3.0 license.'
    Description       = 'PowerShell module for Linux providing cmdlet parity with the Windows PKIClient (pki) module. Implements New-SelfSignedCertificate, Export-Certificate, Export-PfxCertificate, Get-PfxData, Import-Certificate, Import-PfxCertificate, and Test-Certificate using .NET cryptography APIs. Windows-only enrollment cmdlets are stubs.'
    PowerShellVersion = '7.2'
    RequiredModules   = @()

    FunctionsToExport = @(
        # Fully implemented via .NET cryptography APIs
        'New-SelfSignedCertificate',
        'Export-Certificate',
        'Export-PfxCertificate',
        'Get-PfxData',
        'Import-Certificate',
        'Import-PfxCertificate',
        'Test-Certificate',
        # Stubs — Windows enrollment server / AD / Task Scheduler infrastructure
        'Get-Certificate',
        'Add-CertificateEnrollmentPolicyServer',
        'Get-CertificateAutoEnrollmentPolicy',
        'Get-CertificateEnrollmentPolicyServer',
        'Get-CertificateNotificationTask',
        'New-CertificateNotificationTask',
        'Remove-CertificateEnrollmentPolicyServer',
        'Remove-CertificateNotificationTask',
        'Set-CertificateAutoEnrollmentPolicy',
        'Switch-Certificate'
    )

    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()

    PrivateData = @{
        PSData = @{
            Tags         = @('Linux', 'PKI', 'Certificate', 'X509', 'Cryptography', 'CrossPlatform', 'Security')
            LicenseUri   = 'https://github.com/peppekerstens/PKI.Linux/blob/main/LICENSE'
            ProjectUri   = 'https://github.com/peppekerstens/PKI.Linux'
            ReleaseNotes = @'
0.1.0 - Initial release. New-SelfSignedCertificate, Export-Certificate, Export-PfxCertificate, Get-PfxData, Import-Certificate, Import-PfxCertificate, Test-Certificate implemented via .NET cryptography APIs. Enrollment-server cmdlets are stubs.
'@
        }
    }
}
