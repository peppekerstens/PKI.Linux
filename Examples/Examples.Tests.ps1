#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.2.0' }

BeforeDiscovery {
    $script:onLinux = $IsLinux
}

Describe 'PKI.Linux Examples' -Skip:(-not $script:onLinux) {

    BeforeAll {
        if ($IsLinux) {
            $modulePath = Join-Path $PSScriptRoot '..' 'PKI.Linux' 'PKI.Linux.psd1'
            Import-Module (Resolve-Path $modulePath).Path -Force
        }
    }

    AfterAll {
        if ($IsLinux) {
            Remove-Module PKI.Linux -ErrorAction SilentlyContinue
        }
    }

    It '01-CreateSelfSignedCert.ps1 runs without error' {
        $scriptPath = Join-Path $PSScriptRoot '01-CreateSelfSignedCert.ps1'
        { & $scriptPath } | Should -Not -Throw
        Test-Path '/tmp/myserver.pem' | Should -Be $true
        Test-Path '/tmp/myserver.cer' | Should -Be $true
    }

    It '02-ExportImportPfx.ps1 runs without error' {
        $scriptPath = Join-Path $PSScriptRoot '02-ExportImportPfx.ps1'
        { & $scriptPath } | Should -Not -Throw
        Test-Path '/tmp/mycert.pfx' | Should -Be $true
    }

    It '03-TestCertificate.ps1 runs without error' {
        $scriptPath = Join-Path $PSScriptRoot '03-TestCertificate.ps1'
        { & $scriptPath } | Should -Not -Throw
    }

    It '04-EcdsaWebServerCert.ps1 runs without error' {
        $scriptPath = Join-Path $PSScriptRoot '04-EcdsaWebServerCert.ps1'
        { & $scriptPath } | Should -Not -Throw
        Test-Path '/tmp/webserver.pem' | Should -Be $true
        Test-Path '/tmp/webserver.pfx' | Should -Be $true
    }
}
