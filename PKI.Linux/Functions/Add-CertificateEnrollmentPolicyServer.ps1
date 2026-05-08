function Add-CertificateEnrollmentPolicyServer {
    <#
    .Synopsis
        Not implemented on Linux. Windows enrollment-server / AD / Task Scheduler dependency.
    .Description
        Adds an enrollment policy server to the configuration. This cmdlet requires Windows infrastructure
        (Active Directory, Certificate Services, Task Scheduler, or Windows CNG) and cannot
        be implemented on Linux. This is a compatibility stub.
    .Notes
        This is a compatibility stub. On Linux a Write-Warning is emitted.
        Contributions welcome: https://github.com/peppekerstens/PKI.Linux
    .Link
        https://learn.microsoft.com/powershell/module/pki/add-certificateenrollmentpolicyserver
    #>
    [CmdletBinding()]
    param()

    Write-Warning "Add-CertificateEnrollmentPolicyServer is not implemented in PKI.Linux. This cmdlet requires Windows infrastructure (Active Directory, Certificate Services, or Task Scheduler). Contributions welcome: https://github.com/peppekerstens/PKI.Linux"
}
