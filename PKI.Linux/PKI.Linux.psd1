#
# Module manifest for module 'PKI.Linux'
#

@{
    RootModule        = 'PKI.Linux.psm1'
    ModuleVersion     = '0.3.1'
    GUID              = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
    Author            = 'Peppe Kerstens'
    CompanyName       = ''
    Copyright         = '(c) Peppe Kerstens. GPL-3.0 license.'
    Description       = 'PowerShell module for Linux providing cmdlet parity with the Windows PKIClient (pki) module. Implements New-SelfSignedCertificate, Export-Certificate, Export-PfxCertificate, Get-PfxData, Import-Certificate, Import-PfxCertificate, Test-Certificate, and Get-Certificate (LocalStore parameter set) using .NET cryptography APIs. Windows-only enrollment cmdlets are stubs.'
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
        # Partially implemented — LocalStore parameter set works; SubmitRequest and PendingRetrieval stub with terminating error
        'Get-Certificate',
        # Stubs — Windows enrollment server / AD / Task Scheduler infrastructure
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
0.3.1 - Fix ECDsa::Create() on Linux: use no-arg overload (defaults to P-256) instead of Create(ECCurve) which returns null on .NET 8. Fix CertificateRequest constructor overload resolution by adding explicit [ECDsa] cast. Fix example scripts to skip Import-Module if module already loaded in session.
0.3.0 - Get-Certificate partial implementation. New LocalStore parameter set (Linux-native) reads and filters certificates from X509Store using .NET APIs. Supports -Thumbprint, -SubjectName, -DnsName (SAN inspection via X509SubjectAlternativeNameExtension.EnumerateDnsNames()), -Eku (FindByApplicationPolicy), -StoreName, -StoreLocation. SubmitRequest and PendingRetrieval parameter sets (Windows CA enrollment) emit structured terminating errors with PlatformNotSupportedException pointing to the supported LocalStore alternative. Introduces the "partial implementation" model for cmdlets where some parameter sets are implementable on Linux and others are not.
0.2.0 - Security and correctness improvements based on PowerShell SDK and .NET best-practice review. X509Chain now disposed per pipeline record. RSA/ECDsa keys disposed after CreateSelfSigned. X509Store wrapped in try/finally. process{} blocks added to Export-Certificate, Export-PfxCertificate, Import-PfxCertificate. Structured ErrorRecord used throughout. ValidateRange on KeyLength. ValidateSet on CertStoreLocation. ValidateScript on FilePath inputs. CryptographicException wrapped with user-friendly context. TextExtension and ECDSA+KeyLength mismatches now emit warnings.
0.1.0 - Initial release. New-SelfSignedCertificate, Export-Certificate, Export-PfxCertificate, Get-PfxData, Import-Certificate, Import-PfxCertificate, Test-Certificate implemented via .NET cryptography APIs. Enrollment-server cmdlets are stubs.
'@
        }
    }
}
