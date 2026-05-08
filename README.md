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

**`Get-Certificate`** is partially implemented: the `LocalStore` parameter set (Linux-native) reads and filters certificates from the local X509 store using pure .NET. The Windows enrollment parameter sets (`SubmitRequest`, `PendingRetrieval`) emit a structured terminating error explaining what is supported instead.

Other Windows-only enrollment and Group Policy cmdlets (`Add-CertificateEnrollmentPolicyServer`, etc.) are exported as stubs that emit a `Write-Warning`.

---

## Requirements

- PowerShell 7.2+
- Linux (tested on Ubuntu 22.04, Debian 12)
- No external dependencies — uses `System.Security.Cryptography` from .NET

> **Note:** On Linux, `CurrentUser\My` maps to `~/.dotnet/corefx/cryptography/x509stores/my/`. The `LocalMachine` store is not supported on Linux and will produce a terminating error.

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

# Pipeline — validate every cert in the store
Get-ChildItem Cert:\CurrentUser\My | Test-Certificate
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
| `Get-Certificate` | ⚠️ Partial | `LocalStore` set: `X509Store.Find()` + SAN inspection. `SubmitRequest`/`PendingRetrieval` sets: structured terminating error |
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

This means PKI.Linux works anywhere PowerShell 7+ runs on Linux — no `openssl` package required, and no distro-specific CLI tool detection needed.

### LocalMachine store limitation

On Linux, `X509Store("My", LocalMachine)` throws a `CryptographicException`. The `CurrentUser\My` store works correctly and maps to `~/.dotnet/corefx/cryptography/x509stores/my/`. PKI.Linux handles this with a structured terminating error pointing to the supported alternative.

### SecureString on Linux

`SecureString` is used as the parameter type for `-Password` across `Export-PfxCertificate`, `Get-PfxData`, and `Import-PfxCertificate` for API parity with the Windows `PKI` module. **On Linux, `SecureString` does not encrypt memory at the OS level** — the protection mechanism only applies on Windows. The .NET team has marked `SecureString` as not recommended for new cross-platform development. PKI.Linux uses it anyway because:

1. The Windows `PKI` module uses it — matching the parameter type matters for script portability.
2. The BSTR interop pattern (`SecureStringToBSTR` → use → `ZeroFreeBSTR` in `finally`) minimises the time window during which the plaintext password exists in managed memory.

When .NET 9 becomes the minimum target, the plan is to migrate to `X509CertificateLoader` which accepts `ReadOnlySpan<char>` and eliminates the interop dance.

### Enrollment-server stubs

`Add-CertificateEnrollmentPolicyServer`, and the other enrollment cmdlets (excluding `Get-Certificate`) depend on Windows infrastructure: Active Directory Certificate Services, Windows Group Policy (GPO), and Windows Task Scheduler. These are stubs — they emit `Write-Warning` and do nothing. Contributions to implement SCEP/EST-based equivalents are welcome.

### Partial implementations

Some cmdlets have Windows parameter sets that require Windows-only infrastructure, but also have use cases that are implementable on Linux. PKI.Linux marks these as **⚠️ Partial** and implements what can be done via .NET, while the unsupported parameter sets emit a structured `ThrowTerminatingError` with a `PlatformNotSupportedException` that explains what is supported instead.

**`Get-Certificate`** is the first partial implementation:

| Parameter set | Status | Notes |
|---|---|---|
| `LocalStore` (Linux-native) | ✅ Supported | Reads and filters certs from `X509Store` using .NET APIs |
| `SubmitRequest` (Windows CA) | ❌ Not supported | Requires Active Directory Certificate Services |
| `PendingRetrieval` (Windows CA) | ❌ Not supported | Requires Windows REQUEST store |

**LocalStore parameters:**

| Parameter | Behaviour |
|---|---|
| `-StoreName` | X509 store name (default: `My`) |
| `-StoreLocation` | `CurrentUser` (default) or `LocalMachine` |
| `-Thumbprint` | Exact thumbprint match via `X509FindType.FindByThumbprint` |
| `-SubjectName` | Partial subject name match via `X509FindType.FindBySubjectName` |
| `-DnsName` | SAN DNS name partial match — iterates `X509SubjectAlternativeNameExtension.EnumerateDnsNames()` |
| `-Eku` | Extended Key Usage OID match via `X509FindType.FindByApplicationPolicy` |

The Windows `Get-Certificate` cmdlet has no equivalent of this parameter set — it is exclusively an enrollment cmdlet. PKI.Linux adds `LocalStore` to cover the common intent behind the name: "show me what certificates I have."

---

## How we built this

This module was built as part of the **Linux PowerShell Cmdlet Parity** project — a series of modules that bring Windows PowerShell cmdlets to Linux, one module at a time, assisted by AI.

### Why we built it this way

The first question was whether a Linux PKI module already existed. Research confirmed no: the Windows `PKIClient` module is a compiled `.dll` that cannot run on Linux, and the only community alternative (`szeidat/OpenSSL`, 14 stars, last updated 2021) wraps the `openssl` CLI with its own naming convention — not a parity module.

The second question was whether to wrap the `openssl` CLI or use .NET directly. The openssl CLI approach has a structural problem: the tool does not map cleanly onto the Windows PKI cmdlet model, its output format varies between OpenSSL 1.x and 3.x, and it may not be installed on minimal Linux images. .NET's `System.Security.Cryptography` namespace proved to be the right foundation: fully cross-platform since .NET Core 2.0, no external dependency, and semantically aligned with what the Windows cmdlets actually do.

### What we reviewed after v0.1.0

After the initial release we did a systematic review against three bodies of reference material, described below. The review found twelve issues across the seven implemented functions and drove the v0.2.0 changes.

---

### References and why they matter

#### PowerShell SDK Required Development Guidelines
**URL:** https://learn.microsoft.com/powershell/scripting/developer/cmdlet/required-development-guidelines

These are the guidelines Microsoft considers non-negotiable for production cmdlets. Key requirements that affected PKI.Linux:

- **RC04 — Declare OutputType:** Every function must declare `[OutputType(...)]`. Omitting it breaks pipeline type inference and IDE tab completion. All seven functions now declare accurate output types.
- **RC06 — Use ErrorRecord:** Non-terminating errors must use `WriteError(ErrorRecord)`, not bare `Write-Error "string"`. Terminating errors must use `ThrowTerminatingError(ErrorRecord)`. A bare string error produces `ErrorId = ""` and `Category = NotSpecified` — callers cannot filter or detect specific failures programmatically. v0.2.0 replaced all bare `Write-Error` calls with structured `ErrorRecord` objects.

#### PowerShell SDK Advisory Development Guidelines
**URL:** https://learn.microsoft.com/powershell/scripting/developer/cmdlet/advisory-development-guidelines

The "should follow" guidelines. Key items:

- **AC06 — Support Credential Parameters:** Confirms using `SecureString` for password parameters remains correct for compatibility, even though .NET recommends against it for new cross-platform code. This validated keeping `[System.Security.SecureString]` as the parameter type.
- **AD05 — Test cmdlets should return Boolean:** `Test-Certificate` already returned `[bool]` — this confirmed that was correct and that it should not emit objects or write to output when called in a pipeline context.

#### .NET SecureString documentation
**URL:** https://learn.microsoft.com/dotnet/api/system.security.securestring

The API page explicitly states: *"We don't recommend using SecureString for new development... The contents of the array are unencrypted on non-Windows platforms."* This was important for two reasons: it validated the BSTR interop pattern already in use (the correct way to extract the plaintext), and it informed the explanatory comments now added to every function that uses it. The finding is also documented in the Implementation Notes above so users understand the limitation.

#### .NET IDisposable / Dispose Pattern
**URL:** https://learn.microsoft.com/dotnet/standard/garbage-collection/implementing-dispose

The Dispose pattern documentation clarifies when objects holding unmanaged resources must be explicitly disposed rather than left to the GC finalizer. Three .NET types used in PKI.Linux implement `IDisposable` and hold unmanaged handles: `RSA`/`ECDsa` (OpenSSL key handles on Linux), `X509Store` (certificate store handle), and `X509Chain` (OpenSSL verification context). The GC finalizer will eventually clean these up but the timing is non-deterministic — in a loop or long-running session this becomes a real resource leak. v0.2.0 wraps all three in `try/finally` with explicit `.Dispose()` calls.

#### PowerShell Practice and Style Guide
**URL:** https://poshcode.gitbook.io/powershell-practice-and-style/

The community style guide for PowerShell script modules. The most impactful finding for PKI.Linux: the guide documents that `[Parameter(ValueFromPipeline)]` only works correctly when the function body is inside a `process {}` block. Without it, the body executes in an implicit `end {}` block and only the last piped object is processed — a silent data-loss bug. `Export-Certificate`, `Export-PfxCertificate`, and `Import-PfxCertificate` all had `ValueFromPipeline` declared but no `process {}` block. All three now wrap their logic in `process {}`.

#### PowerShell source code — C# cmdlet implementations
**URL:** https://github.com/PowerShell/PowerShell/tree/master/src/Microsoft.PowerShell.Commands.Management

Studying how the PowerShell team implements cmdlets in C# clarified the error handling model. In compiled cmdlets, `WriteError(new ErrorRecord(exception, errorId, category, targetObject))` is the standard non-terminating error path, and `ThrowTerminatingError(new ErrorRecord(...))` is the standard terminating path. The `errorId` string (e.g. `"FileNotFound"`, `"CertificateHasNoPrivateKey"`) is what callers use in `catch` blocks and `-ErrorVariable` filtering. Script advanced functions expose the identical API via `$PSCmdlet.WriteError(...)` and `$PSCmdlet.ThrowTerminatingError(...)`. v0.2.0 adopts this pattern throughout, with unique `"Cmdlet.ErrorId"` identifiers at every error site.

#### .NET X509Certificate2 and CertificateRequest API docs
**URLs:**
- https://learn.microsoft.com/dotnet/api/system.security.cryptography.x509certificates.certificaterequest
- https://learn.microsoft.com/dotnet/api/system.security.cryptography.x509certificates.x509certificate2

The `CertificateRequest` docs confirmed that `CreateSelfSigned()` copies the key into the resulting `X509Certificate2` — meaning the original `RSA`/`ECDsa` key object can be safely disposed immediately after `CreateSelfSigned()` returns. This was not obvious, and without confirmation we would have had to keep the key alive. The `X509Certificate2` docs confirmed that the constructor overloads used in `Import-Certificate` and `Import-PfxCertificate` are marked `[Obsolete]` in .NET 9 (superseded by `X509CertificateLoader`) — documented above under known constraints for a future v0.3.0.

---

### What the review found and what changed in v0.2.0

| Issue | Severity | Change |
|---|---|---|
| `X509Chain` not disposed per pipeline record in `Test-Certificate` | Critical | Wrapped in `try/finally { $chain.Dispose() }` |
| `RSA`/`ECDsa` key created before `ShouldProcess`, never disposed | Critical | Moved inside `ShouldProcess`; wrapped in `try/finally { $key.Dispose() }` |
| No `process {}` block on three pipeline-accepting functions | High | Added `process {}` to `Export-Certificate`, `Export-PfxCertificate`, `Import-PfxCertificate` |
| `X509Store` not in `try/finally` in three functions | High | Wrapped with `try/finally { $store.Dispose() }` in all three |
| Bare `Write-Error "string"` at every error site | High | Replaced with structured `ErrorRecord` using typed exceptions, error IDs, and `ErrorCategory` |
| `$cert` created before `ShouldProcess` in `Import-PfxCertificate` | High | Now disposed in the `else` branch when `ShouldProcess` returns false |
| `-TextExtension` silently ignored | Medium | Now emits `Write-Warning` when used |
| `-KeyLength` with `-KeyAlgorithm ECDSA` silently ignored | Medium | Now emits `Write-Warning` when used |
| `$KeyLength` accepts insecure values | Medium | Added `[ValidateRange(2048, 8192)]` |
| No exception wrapping around crypto operations | Medium | `CryptographicException` now caught and re-thrown as structured `ErrorRecord` with context |
| Manual `Test-Path` checks for input files | Low | Replaced with `[ValidateScript({ Test-Path $_ -PathType Leaf })]` |
| `$CertStoreLocation` unvalidated string | Low | `[ValidateSet('Cert:\CurrentUser\My', 'Cert:\LocalMachine\My')]` |
| `X509Certificate2` constructor overloads obsoleted in .NET 9 | Info | Documented; migration to `X509CertificateLoader` deferred to v0.3.0 |

---

## Version History

| Version | Date | Notes |
|---|---|---|
| 0.3.0 | 2026-05-08 | `Get-Certificate` partial implementation. `LocalStore` parameter set reads/filters from X509Store. `SubmitRequest`/`PendingRetrieval` emit structured terminating errors. Introduces partial implementation model. |
| 0.2.0 | 2026-05-08 | Security and correctness improvements based on PowerShell SDK and .NET best-practice review. Structured ErrorRecord, IDisposable fixes, process{} blocks, ValidateRange/ValidateSet/ValidateScript additions. |
| 0.1.0 | 2026-05-08 | Initial release. 7 cmdlets implemented, 10 stubs. |

---

## License

GPL-3.0 — see [LICENSE](LICENSE).
