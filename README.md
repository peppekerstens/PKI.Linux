# PKI.Linux

Linux parity module for the Windows **PKIClient** (`pki`) PowerShell module.

Implements certificate management cmdlets on Linux using **.NET cryptography APIs** — no `openssl` CLI required.

Part of the [Linux PowerShell Cmdlet Parity](https://peppekerstens.github.io) project.

---

## What it does

Provides Linux implementations of the most useful Windows PKI cmdlets:

| Cmdlet | What it does |
|---|---|
| `New-SelfSignedCertificate` | Creates a self-signed RSA or ECDSA certificate |
| `Export-Certificate` | Exports a certificate to DER or PEM format |
| `Export-PfxCertificate` | Exports a certificate + private key to a password-protected PFX |
| `Get-PfxData` | Reads a PFX file and returns its certs without importing |
| `Import-Certificate` | Imports a DER/PEM certificate into `CurrentUser\My` store |
| `Import-PfxCertificate` | Imports a PFX certificate + key into `CurrentUser\My` store |
| `Test-Certificate` | Validates a certificate chain using X509Chain |

Windows-only enrollment and Group Policy cmdlets (`Get-Certificate`, `Add-CertificateEnrollmentPolicyServer`, etc.) are exported as stubs that emit a `Write-Warning`.

---

## Requirements

- PowerShell 7.2+
- Linux (tested on Ubuntu 22.04, Debian 12)
- No external dependencies — uses `System.Security.Cryptography` from .NET

> **Note:** On Linux, `CurrentUser\My` maps to `~/.dotnet/corefx/cryptography/x509stores/my/`. The `LocalMachine` store is not supported on Linux and will produce an error.

---

## Installation

```powershell
# From source
git clone https://github.com/peppekerstens/PKI.Linux.git
Import-Module ./PKI.Linux/PKI.Linux/PKI.Linux.psd1

# From PowerShell Gallery (future)
Install-Module PKI.Linux
```

---

## Usage

```powershell
Import-Module PKI.Linux

# Create a self-signed RSA certificate
$cert = New-SelfSignedCertificate -DnsName 'myserver.local' -NotAfter (Get-Date).AddYears(2)

# Export to PEM (for web servers)
Export-Certificate -Cert $cert -FilePath '/tmp/myserver.pem' -Type PEM

# Export to DER binary
Export-Certificate -Cert $cert -FilePath '/tmp/myserver.cer'

# Export as PFX (with private key)
$pw = ConvertTo-SecureString 'MyP@ssword1' -AsPlainText -Force
Export-PfxCertificate -Cert $cert -FilePath '/tmp/myserver.pfx' -Password $pw

# Read PFX metadata without importing
$data = Get-PfxData -FilePath '/tmp/myserver.pfx' -Password $pw
$data.EndEntityCertificates[0].Subject

# Import into CurrentUser\My store
Import-PfxCertificate -FilePath '/tmp/myserver.pfx' -Password $pw

# Validate a certificate
Test-Certificate -Cert $cert -AllowUntrustedRoot
```

---

## Examples

See the [`Examples\`](Examples/) folder:

| Script | Description |
|---|---|
| `01-CreateSelfSignedCert.ps1` | Create RSA cert, export DER and PEM |
| `02-ExportImportPfx.ps1` | Export PFX, read with Get-PfxData, reimport |
| `03-TestCertificate.ps1` | Validate certificate chain |
| `04-EcdsaWebServerCert.ps1` | ECDSA P-256 cert for web server |

---

## Cmdlet Status

| Cmdlet | Status | Implementation |
|---|---|---|
| `New-SelfSignedCertificate` | ✅ Implemented | `CertificateRequest.CreateSelfSigned()` |
| `Export-Certificate` | ✅ Implemented | `X509Certificate2.Export()` + PEM conversion |
| `Export-PfxCertificate` | ✅ Implemented | `X509Certificate2.Export(Pkcs12)` |
| `Get-PfxData` | ✅ Implemented | `X509Certificate2Collection.Import()` |
| `Import-Certificate` | ✅ Implemented | `X509Store(CurrentUser\My).Add()` |
| `Import-PfxCertificate` | ✅ Implemented | `X509Certificate2` + `X509Store.Add()` |
| `Test-Certificate` | ✅ Implemented | `X509Chain.Build()` |
| `Get-Certificate` | 🔶 Stub | Windows enrollment server |
| `Add-CertificateEnrollmentPolicyServer` | 🔶 Stub | Windows AD/GPO |
| `Get-CertificateAutoEnrollmentPolicy` | 🔶 Stub | Windows AD/GPO |
| `Get-CertificateEnrollmentPolicyServer` | 🔶 Stub | Windows AD/GPO |
| `Get-CertificateNotificationTask` | 🔶 Stub | Windows Task Scheduler |
| `New-CertificateNotificationTask` | 🔶 Stub | Windows Task Scheduler |
| `Remove-CertificateEnrollmentPolicyServer` | 🔶 Stub | Windows AD/GPO |
| `Remove-CertificateNotificationTask` | 🔶 Stub | Windows Task Scheduler |
| `Set-CertificateAutoEnrollmentPolicy` | 🔶 Stub | Windows AD/GPO |
| `Switch-Certificate` | 🔶 Stub | Windows cert store concept |

---

## Implementation Notes

### Why .NET APIs and not openssl CLI?

The Windows `PKIClient` module is a compiled `.dll` that depends on Windows CNG/CryptoAPI. It has never been ported to Linux (GitHub issue #1865, opened 2016, closed 2023 with no activity).

Rather than wrapping `openssl` CLI commands (fragile, version-dependent, external dependency), PKI.Linux uses the same .NET cryptography APIs that run cross-platform:

- `System.Security.Cryptography.X509Certificates` — certificate creation, export, import, store management
- `System.Security.Cryptography.RSA` / `ECDsa` — key pair generation
- `CertificateRequest.CreateSelfSigned()` — self-signed certificate creation (available .NET Core 2.0+)

This means PKI.Linux works anywhere PowerShell 7+ runs on Linux — no `openssl` package required.

### LocalMachine store limitation

On Linux, `X509Store("My", LocalMachine)` throws a `CryptographicException`. The `CurrentUser\My` store works correctly and maps to `~/.dotnet/corefx/cryptography/x509stores/my/`. PKI.Linux handles this gracefully: if you specify a `LocalMachine` path, you get a clear error message.

### Enrollment-server stubs

`Get-Certificate`, `Add-CertificateEnrollmentPolicyServer`, and the other enrollment cmdlets depend on Windows infrastructure: Active Directory Certificate Services, Windows Group Policy (GPO), and Windows Task Scheduler. These are stubs — they emit `Write-Warning` and do nothing. Contributions to implement SCEP/EST-based equivalents are welcome.

---

## How we built this

This module was built as part of the **Linux PowerShell Cmdlet Parity** project — a series of modules that bring Windows PowerShell cmdlets to Linux, one module at a time, assisted by AI.

### Research phase

The first question was whether a Linux PKI module already existed. Research confirmed:

- No official Microsoft port of `PKIClient` for Linux — the module is a compiled `.dll` depending on Windows CNG/CryptoAPI. GitHub issue #1865 requesting `Cert:\` PSDrive on Linux was filed in 2016 and closed in 2023 with no implementation.
- The only community module (`szeidat/OpenSSL`, 14 stars) wraps `openssl` CLI and uses its own naming convention. Not a parity module.

### Implementation approach

All 17 Windows PKIClient cmdlets were mapped:

- 7 are implementable using .NET cryptography APIs that ship with .NET Core/.NET 5+ and run on Linux
- 10 depend on Windows-only infrastructure (AD, enrollment servers, Task Scheduler) and are stubs

The key insight: .NET's `System.Security.Cryptography` stack is fully cross-platform. `CertificateRequest.CreateSelfSigned()` was added in .NET Core 2.0. `X509Chain.Build()` on Linux uses the system OpenSSL library internally — but that's a library call, not a CLI invocation.

### Known constraints discovered

- `X509Store("My", LocalMachine)` throws on Linux — only `CurrentUser` store works
- `X509Certificate2.Export(Pkcs12)` works for single-cert PFX; for multi-cert bundles with separate key storage, `Pkcs12Builder` (available .NET 9+) would be needed
- `EphemeralKeySet` flag required when loading PFX just for reading (avoids writing key material to disk)

### Module structure and conventions

Follows the established conventions from the project's 7 prior modules:

- Linux-only guard at top of `.psm1`
- One `.ps1` per cmdlet in `Functions\`
- `Where-Object` instead of `-Filter` / `-Exclude`
- Stubs export all Windows cmdlets and warn on Linux
- `BeforeDiscovery` in all Pester test files for cross-platform compatibility
- `Examples\` folder with runnable scripts and `Examples.Tests.ps1`

---

## Version History

| Version | Date | Notes |
|---|---|---|
| 0.1.0 | 2026-05-08 | Initial release. 7 cmdlets implemented, 10 stubs. |

---

## License

GPL-3.0 — see [LICENSE](LICENSE).
