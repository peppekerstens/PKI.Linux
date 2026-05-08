function New-CertificateNotificationTask {
    <#
    .Synopsis
        Not implemented on Linux. Windows enrollment-server / AD / Task Scheduler dependency.
    .Description
        Creates a certificate notification task in Windows Task Scheduler. This cmdlet requires Windows infrastructure
        (Active Directory, Certificate Services, Task Scheduler, or Windows CNG) and cannot
        be implemented on Linux. This is a compatibility stub.
    .Notes
        This is a compatibility stub. On Linux a Write-Warning is emitted.
        Contributions welcome: https://github.com/peppekerstens/PKI.Linux
    .Link
        https://learn.microsoft.com/powershell/module/pki/new-certificatenotificationtask
    #>
    [CmdletBinding()]
    param()

    Write-Warning "New-CertificateNotificationTask is not implemented in PKI.Linux. This cmdlet requires Windows infrastructure (Active Directory, Certificate Services, or Task Scheduler). Contributions welcome: https://github.com/peppekerstens/PKI.Linux"
}
