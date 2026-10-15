# Building Device Access

[Project overview](../README.md)

This directory holds the public configuration and local signer for the
Device Access variant maintained in `main`. Its implementation originated in
`customManager`, from upstream `main` at
`b38f4096f33632ad5871dc3fff0ec426e23c9358`.

## Files and configuration

| File | Purpose |
| --- | --- |
| [`config.json`](config.json) | Package, display name, update repository, KMI, DDK release and ABI. |
| [`certificate.pem`](certificate.pem) | Public certificate trusted by the compiled kernel module. |
| [`prepare.py`](prepare.py) | Validate inputs and derive the certificate size and SHA-256. |
| [`sign.ps1`](sign.ps1) | Verify, align and sign CI artifacts with the matching local key. |
| [Workflow](../.github/workflows/customManager.yml) | Build the matching kernel, init binary, daemon and Manager; run lint. |

`prepare.py` checks the certificate size against the kernel verifier's actual
limit. The current configuration is scoped to the verified ARM64 KMI.
Only public configuration belongs here. Keep private keys, passwords, device
backups and application logs outside the repository.

The Manager supports `KSU_PACKAGE_NAME`, `KSU_NAME`, `KSU_ABIS` and
`KSU_UPDATE_REPOSITORY` Gradle properties. The workflow reads their values from
`config.json`. Builds without these overrides retain the upstream defaults.

DFRoot discovers Managers through `ApplicationInfo.nativeLibraryDir/libksud.so`
and passes the selected package to `late-load --package-name`. Keep the Java
namespace `me.weishu.kernelsu` intact for the loader's activity and JNI contracts.

## Build

1. Clone the repository with its full Git history; versioning uses that history.
2. Run `python customManager/prepare.py` to validate public inputs.
3. Run **Device Access** from Actions on `main`, or open a pull request to `main`.
   Changes to build inputs also trigger it when pushed to `main`.
4. Download `customManagerUnsigned` and extract its files together. It includes
   `deviceAccess-unsigned.apk`, `buildMetadata.json`, the public certificate
   and the matching kernel module. Lint reports are in `customManagerLint`.
5. Sign locally, then follow the [activation steps](../README.md#use).

The workflow stages the daemon before Gradle. Gradle resolves the SDK, NDK,
build-tools and CMake versions declared by the project. CI needs the public
certificate; the production signing key stays local.

## Local signing

Use PowerShell 7, JDK 21, Windows Android build-tools, the matching PKCS12
keystore and an `Export-Clixml` SecureString password file:

```powershell
./customManager/sign.ps1 `
  -inputApk ./artifacts/deviceAccess-unsigned.apk `
  -androidBuildToolsPath /path/to/android/build-tools/version `
  -javaHome /path/to/jdk-21 `
  -keystorePath /private/deviceAccess.p12 `
  -passwordFile /private/signingPassword.clixml `
  -outputDirectory ./signed
```

Choose a fresh output directory. The script checks the unsigned APK hash,
package, local configuration and certificate; it aligns the APK and verifies
its final signature and hash. This fork's kernel accepts one v2 signing block
and APK-verity padding; its native reader rejects v3/v3.1. The signer enables
v2 and disables v1, v3 and v4. Check the installed daemon's `debug get-sign`
result before activating a newly signed Manager.

The password file is bound to the Windows account and computer that saved it.
Preserve a secure backup of the signing credentials for future updates.

## Updates and maintenance

- Keep the package ID and signing key for updates to an existing installation.
  The kernel module and APK must use the same certificate identity.
- Keep update checks on this fork. Published APK assets must follow the
  inherited `_<versionCode>-release.apk` name pattern. The custom workflow
  creates artifacts; publishing a release is a separate operation.
- Start new branches from `main`. Keep changes focused on public configuration
  and the existing Manager/kernel interfaces.
- `manager/app/lintBaseline.xml` records 325 inherited `MissingTranslation`
  errors. The custom workflow opts in with
  `-PmanagerLintBaseline=lintBaseline.xml`; new lint errors remain fatal.
  Remove entries as their translations are completed.

## Validation

[Build and lint passed](https://github.com/BRUN0R2/KernelSU/actions/runs/38793747955)
for source `0bef5f035fb64990caaada7379f49a8f8d9c83f0`. Local signing, alignment,
the native certificate reader and the embedded kernel's SHA-256 were verified.

On 2026-10-15, DFRoot loaded this build after a full reboot on the Redmi 15.
The kernel reported version 32694, UAPI 5 and late-load mode, recognized the
custom Manager and granted UID 0 to an authorized `su` request. The user
confirmed successful PicPay startup. Account operations were outside this test.
