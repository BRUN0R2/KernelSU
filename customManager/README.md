# Personal ARM64 build

This variant uses the existing custom application ID and manager-certificate
interfaces. It preserves kernel authorization and the app profile UAPI. The
Manager build configuration exposes `KSU_ABIS` to select the architectures to
package and `KSU_UPDATE_REPOSITORY` to select the release source. Both defaults
remain upstream-compatible. This variant queries its owner's fork for updates
so an upstream APK with a different package and certificate is not offered.

## Build plan

1. Keep the signing key local and export its public certificate.
2. Validate `config.json` and derive the certificate's SHA-256 and DER size.
3. Build the `android13-5.15` module with that identity and application ID.
4. Embed that module in the ARM64 daemon, then compile and lint the Manager.
5. Download the unsigned APK, align and sign it locally, and verify the
   manifest, certificate, native ABI and source metadata before installation.
6. Keep the original Manager recoverable until the replacement has loaded
   through DFRoot and the app-opening test has passed on the phone.

The `customManager` branch starts from `main` at
`b38f4096f33632ad5871dc3fff0ec426e23c9358`. Its push workflow creates build
artifacts, with no release publication or notification step. Only public
certificate material belongs in this directory. Never commit a private key,
password, device backup or application log.

## Configuration

`config.json` targets the verified Redmi 15 ARM64 KMI. `certificate.pem` is
the public certificate for this installation. Replacing it requires rebuilding
the kernel module and signing the APK with the matching private key.
Future update releases must keep that package and signing identity and follow
the upstream APK asset name pattern `_<versionCode>-release.apk`. This workflow
only creates artifacts; publication of a release is a separate action.

The DFRoot loader discovers Managers by their extracted `libksud.so` and passes
the selected package to `late-load --package-name`. Keep the Java namespace
`me.weishu.kernelsu` intact so its explicit activity and JNI contracts remain
compatible with the existing loader.

Run `python customManager/prepare.py` to validate the public inputs, including
the DER size limit read from the kernel's certificate verifier. The
`Custom ARM64 Manager` workflow builds the module, init binary, daemon, and
Manager. SDK setup installs the command-line tools and accepts SDK licenses;
Gradle installs the platform, build-tools, NDK and CMake versions required by
the project, avoiding a second platform-version declaration in the workflow.
The unsigned APK deliberately has no production signing credential
in CI. Use Android build-tools `zipalign` and `apksigner` locally; APK Signature
Scheme v2 must remain enabled because the kernel verifies that certificate.

On Windows with PowerShell 7, `customManager/sign.ps1` verifies the artifact
hash, package ID, public certificate and local key, aligns and signs the APK,
then verifies the v2 signature, certificate hash and alignment. Supply the
unsigned APK, Windows Android build-tools directory, JDK 21 directory, PKCS12
keystore, local `Export-Clixml` SecureString password file, and a fresh output
directory using its named parameters. Password decryption is bound to the
Windows account and computer that saved it; retain a separate secure backup
of the signing credentials if the build must survive migration to another PC.

## Validation status

Public configuration validation and workflow lint have passed. Compilation
and device validation are in progress. A successful
workflow does not by itself confirm that the Manager is recognized by the
currently loaded kernel or that application startup works after activation.
Record build and physical-device results before marking this variant ready.
