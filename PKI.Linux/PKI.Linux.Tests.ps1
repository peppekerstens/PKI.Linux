#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.2.0' }

BeforeDiscovery {
    $script:onLinux = $IsLinux
}

Describe 'PKI.Linux module' -Skip:(-not $script:onLinux) {

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

    Context 'Module loads correctly' {
        It 'Should export New-SelfSignedCertificate' {
            Get-Command -Module PKI.Linux -Name New-SelfSignedCertificate | Should -Not -BeNullOrEmpty
        }
        It 'Should export Export-Certificate' {
            Get-Command -Module PKI.Linux -Name Export-Certificate | Should -Not -BeNullOrEmpty
        }
        It 'Should export Export-PfxCertificate' {
            Get-Command -Module PKI.Linux -Name Export-PfxCertificate | Should -Not -BeNullOrEmpty
        }
        It 'Should export Get-PfxData' {
            Get-Command -Module PKI.Linux -Name Get-PfxData | Should -Not -BeNullOrEmpty
        }
        It 'Should export Import-Certificate' {
            Get-Command -Module PKI.Linux -Name Import-Certificate | Should -Not -BeNullOrEmpty
        }
        It 'Should export Import-PfxCertificate' {
            Get-Command -Module PKI.Linux -Name Import-PfxCertificate | Should -Not -BeNullOrEmpty
        }
        It 'Should export Test-Certificate' {
            Get-Command -Module PKI.Linux -Name Test-Certificate | Should -Not -BeNullOrEmpty
        }
        It 'Should export stub Get-Certificate' {
            Get-Command -Module PKI.Linux -Name Get-Certificate | Should -Not -BeNullOrEmpty
        }
    }

    Context 'New-SelfSignedCertificate' {
        It 'Creates a self-signed RSA certificate' {
            $cert = New-SelfSignedCertificate -DnsName 'test.pki.linux'
            $cert | Should -Not -BeNullOrEmpty
            $cert.Subject | Should -BeLike '*test.pki.linux*'
            $cert.HasPrivateKey | Should -Be $true
        }

        It 'Creates a certificate with custom Subject' {
            $cert = New-SelfSignedCertificate -Subject 'CN=MyTest,O=TestOrg'
            $cert.Subject | Should -BeLike '*MyTest*'
        }

        It 'Creates an ECDSA certificate' {
            $cert = New-SelfSignedCertificate -DnsName 'ec.test.local' -KeyAlgorithm ECDSA
            $cert | Should -Not -BeNullOrEmpty
            $cert.HasPrivateKey | Should -Be $true
        }

        It 'Respects NotAfter date' {
            $future = (Get-Date).AddYears(3)
            $cert = New-SelfSignedCertificate -DnsName 'expire.test.local' -NotAfter $future
            $cert.NotAfter.Year | Should -Be $future.Year
        }

        It 'Returns X509Certificate2 type' {
            $cert = New-SelfSignedCertificate -DnsName 'type.test.local'
            $cert | Should -BeOfType [System.Security.Cryptography.X509Certificates.X509Certificate2]
        }
    }

    Context 'Export-Certificate and round-trip' {
        BeforeAll {
            $script:cert = New-SelfSignedCertificate -DnsName 'export.test.local'
            $script:tmpDir = [System.IO.Path]::GetTempPath()
        }

        It 'Exports DER file' {
            $path = Join-Path $script:tmpDir 'test-export.cer'
            Remove-Item $path -ErrorAction SilentlyContinue
            $file = Export-Certificate -Cert $script:cert -FilePath $path
            $file | Should -Not -BeNullOrEmpty
            Test-Path $path | Should -Be $true
            (Get-Item $path).Length | Should -BeGreaterThan 0
        }

        It 'Exports PEM file' {
            $path = Join-Path $script:tmpDir 'test-export.pem'
            Remove-Item $path -ErrorAction SilentlyContinue
            Export-Certificate -Cert $script:cert -FilePath $path -Type PEM
            $content = Get-Content $path -Raw
            $content | Should -BeLike '*BEGIN CERTIFICATE*'
        }

        It 'Does not overwrite without -Force' {
            $path = Join-Path $script:tmpDir 'test-nooverwrite.cer'
            Export-Certificate -Cert $script:cert -FilePath $path -Force
            { Export-Certificate -Cert $script:cert -FilePath $path -ErrorAction Stop } | Should -Throw
        }
    }

    Context 'Export-PfxCertificate and Get-PfxData' {
        BeforeAll {
            $script:pfxCert = New-SelfSignedCertificate -DnsName 'pfx.test.local'
            $script:pfxPw   = ConvertTo-SecureString 'T3stP@ssword!' -AsPlainText -Force
            $script:pfxPath = Join-Path ([System.IO.Path]::GetTempPath()) 'test-export.pfx'
            Remove-Item $script:pfxPath -ErrorAction SilentlyContinue
        }

        It 'Exports a PFX file' {
            $file = Export-PfxCertificate -Cert $script:pfxCert -FilePath $script:pfxPath -Password $script:pfxPw
            $file | Should -Not -BeNullOrEmpty
            Test-Path $script:pfxPath | Should -Be $true
            (Get-Item $script:pfxPath).Length | Should -BeGreaterThan 0
        }

        It 'Get-PfxData reads the PFX without importing' {
            $data = Get-PfxData -FilePath $script:pfxPath -Password $script:pfxPw
            $data | Should -Not -BeNullOrEmpty
            $data.EndEntityCertificates | Should -Not -BeNullOrEmpty
            $data.EndEntityCertificates[0] |
                Should -BeOfType [System.Security.Cryptography.X509Certificates.X509Certificate2]
        }
    }

    Context 'Import-Certificate' {
        BeforeAll {
            $script:importCert = New-SelfSignedCertificate -DnsName 'import.test.local'
            $script:derPath = Join-Path ([System.IO.Path]::GetTempPath()) 'import-test.cer'
            Export-Certificate -Cert $script:importCert -FilePath $script:derPath -Force
        }

        It 'Imports DER certificate into CurrentUser\My' {
            $imported = Import-Certificate -FilePath $script:derPath
            $imported | Should -Not -BeNullOrEmpty
            $imported | Should -BeOfType [System.Security.Cryptography.X509Certificates.X509Certificate2]
        }

        It 'Rejects LocalMachine store' {
            { Import-Certificate -FilePath $script:derPath -CertStoreLocation 'Cert:\LocalMachine\My' -ErrorAction Stop } |
                Should -Throw
        }
    }

    Context 'Import-PfxCertificate' {
        BeforeAll {
            $script:impPfxCert = New-SelfSignedCertificate -DnsName 'impfx.test.local'
            $script:impPfxPw   = ConvertTo-SecureString 'T3stP@ssword!' -AsPlainText -Force
            $script:impPfxPath = Join-Path ([System.IO.Path]::GetTempPath()) 'import-test.pfx'
            Remove-Item $script:impPfxPath -ErrorAction SilentlyContinue
            Export-PfxCertificate -Cert $script:impPfxCert -FilePath $script:impPfxPath -Password $script:impPfxPw
        }

        It 'Imports PFX into CurrentUser\My' {
            $imported = Import-PfxCertificate -FilePath $script:impPfxPath -Password $script:impPfxPw
            $imported | Should -Not -BeNullOrEmpty
            $imported.HasPrivateKey | Should -Be $true
        }
    }

    Context 'Test-Certificate' {
        It 'Returns $true for self-signed cert with AllowUntrustedRoot' {
            $cert = New-SelfSignedCertificate -DnsName 'validate.test.local'
            $result = Test-Certificate -Cert $cert -AllowUntrustedRoot
            $result | Should -Be $true
        }

        It 'Returns $false for self-signed cert without AllowUntrustedRoot' {
            $cert = New-SelfSignedCertificate -DnsName 'validate2.test.local'
            $result = Test-Certificate -Cert $cert
            $result | Should -Be $false
        }
    }

    Context 'Get-Certificate — LocalStore parameter set' {
        BeforeAll {
            # Create a cert, export to DER, then import into CurrentUser\My
            $script:gcCert = New-SelfSignedCertificate -DnsName 'get-cert-test.pki.linux' -Subject 'CN=GetCertTest'
            $derPath = Join-Path ([System.IO.Path]::GetTempPath()) 'get-cert-test.cer'
            Export-Certificate -Cert $script:gcCert -FilePath $derPath -Force
            Import-Certificate -FilePath $derPath
        }

        It 'Returns X509Certificate2 objects from CurrentUser\My' {
            $certs = Get-Certificate
            $certs | Should -Not -BeNullOrEmpty
            $certs[0] | Should -BeOfType [System.Security.Cryptography.X509Certificates.X509Certificate2]
        }

        It 'Filters by Thumbprint' {
            $thumbprint = $script:gcCert.Thumbprint
            $results = Get-Certificate -Thumbprint $thumbprint
            $results | Should -Not -BeNullOrEmpty
            $results[0].Thumbprint | Should -Be $thumbprint
        }

        It 'Filters by SubjectName (partial match)' {
            $results = Get-Certificate -SubjectName 'GetCertTest'
            $results | Should -Not -BeNullOrEmpty
            $results[0].Subject | Should -BeLike '*GetCertTest*'
        }

        It 'Filters by DnsName (SAN match)' {
            $results = Get-Certificate -DnsName 'get-cert-test.pki.linux'
            $results | Should -Not -BeNullOrEmpty
        }

        It 'Returns nothing for a thumbprint that does not exist' {
            $results = Get-Certificate -Thumbprint ('0' * 40)
            $results | Should -BeNullOrEmpty
        }
    }

    Context 'Get-Certificate — enrollment stubs throw terminating errors' {
        It 'SubmitRequest parameter set throws PlatformNotSupportedException' {
            { Get-Certificate -Template 'WebServer' -ErrorAction Stop } |
                Should -Throw -ExceptionType ([System.PlatformNotSupportedException])
        }

        It 'SubmitRequest error message mentions LocalStore' {
            try {
                Get-Certificate -Template 'WebServer' -ErrorAction Stop
            }
            catch {
                $_.Exception.Message | Should -BeLike '*LocalStore*'
            }
        }

        It 'PendingRetrieval parameter set throws PlatformNotSupportedException' {
            $fakeRequest = [PSCustomObject]@{ Dummy = 1 }
            { $fakeRequest | Get-Certificate -ErrorAction Stop } |
                Should -Throw -ExceptionType ([System.PlatformNotSupportedException])
        }
    }

    Context 'Stubs emit warnings' {
        It 'Switch-Certificate writes a warning' {
            $warns = $null
            Switch-Certificate -WarningVariable warns -WarningAction SilentlyContinue
            $warns | Should -Not -BeNullOrEmpty
        }
    }
}

Describe 'PKI.Linux throws on non-Linux' -Skip:$script:onLinux {
    It 'Module throws when loaded on Windows' {
        $modulePath = Join-Path $PSScriptRoot '..' 'PKI.Linux' 'PKI.Linux.psd1'
        { Import-Module (Resolve-Path $modulePath).Path -Force -ErrorAction Stop } | Should -Throw
    }
}
