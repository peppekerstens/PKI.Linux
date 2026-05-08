function Remove-CertificateNotificationTask {
    <#
    .Synopsis
        Not implemented on Linux. Windows enrollment-server / AD / Task Scheduler dependency.
    .Description
        Removes a certificate notification task from Windows Task Scheduler. This cmdlet requires Windows infrastructure
        (Active Directory, Certificate Services, Task Scheduler, or Windows CNG) and cannot
        be implemented on Linux. This is a compatibility stub.
    .Notes
        This is a compatibility stub. On Linux a Write-Warning is emitted.
        Contributions welcome: https://github.com/peppekerstens/PKI.Linux
    .Link
        https://learn.microsoft.com/powershell/module/pki/remove-certificatenotificationtask
    #>
    [CmdletBinding()]
    param()

    Write-Warning "Remove-CertificateNotificationTask is not implemented in PKI.Linux. This cmdlet requires Windows infrastructure (Active Directory, Certificate Services, or Task Scheduler). Contributions welcome: https://github.com/peppekerstens/PKI.Linux"
}
