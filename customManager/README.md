# Personal ARM64 build

This variant uses the existing custom application ID and manager-certificate
interfaces. It preserves kernel authorization and the app profile UAPI. The
only Manager code change exposes `KSU_ABIS` to select the architectures to
package; the default remains the upstream architecture list.

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

The DFRoot loader discovers Managers by their extracted `libksud.so` and passes
the selected package to `late-load --package-name`. Keep the Java namespace
`me.weishu.kernelsu` intact so its explicit activity and JNI contracts remain
compatible with the existing loader.

Run `python customManager/prepare.py` to validate the public inputs. The
`Custom ARM64 Manager` workflow builds the module, init binary, daemon, and
Manager. The unsigned APK deliberately has no production signing credential
in CI. Use Android build-tools `zipalign` and `apksigner` locally; APK Signature
Scheme v2 must remain enabled because the kernel verifies that certificate.

## Validation status

Public configuration and source preparation are in progress. A successful
workflow does not by itself confirm that the Manager is recognized by the
currently loaded kernel or that application startup works after activation.
Record build and physical-device results before marking this variant ready.
