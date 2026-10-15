# Device Access

[![Build](https://github.com/BRUN0R2/KernelSU/actions/workflows/customManager.yml/badge.svg?branch=main)](https://github.com/BRUN0R2/KernelSU/actions/workflows/customManager.yml)

[Portugues (Brasil)](docs/README_PT-BR.md#device-access)

A personal [KernelSU](https://github.com/diabl0w/KernelSU) Manager for temporary
root with [DFRoot](https://github.com/diabl0w/DFRoot). It uses a custom package
and signing identity, with the matching kernel module embedded in the APK.
Kernel authorization and application profiles keep their existing contracts.

## Purpose and branches

`main` maintains the Device Access variant. `customManager` contains its initial
implementation, integrated into `main`; new work starts from `main`.

The Manager and DFRoot have separate roles: Device Access manages root and
provides the kernel module; DFRoot loads it. One Manager is sufficient.
The diagnostic probe used during development is optional.

## Current target

| Setting | Value |
| --- | --- |
| Application | Device Access |
| Package | `dev.bruno.deviceaccess` |
| Architecture | `arm64-v8a` |
| Kernel interface (KMI) | `android13-5.15` |
| Update repository | `BRUN0R2/KernelSU` |
| Verified device | Redmi 15, Android 16, DFRoot 4.4 |

These inputs live in [`customManager/config.json`](customManager/config.json).
The KMI identifies the kernel interface, independently of the Android version.

## Use

1. Install an APK signed with this build's matching local key.
2. Select **Device Access** in DFRoot.
3. Restart Android when switching from another Manager's kernel, then let
   DFRoot activate root. Use its activation button if needed.
4. Confirm that Device Access recognizes the loaded kernel before removing
   the previous Manager.

DFRoot can activate root at boot. Temporary root depends on DFRoot loading the
module again after each restart.

## Build and maintenance

The **Device Access** workflow builds and lints this variant on changes to
build inputs in `main` and pull requests targeting `main`. It can also run
manually. The `customManagerUnsigned` artifact contains the unsigned APK,
public certificate, module and hashes; `customManagerLint` contains lint reports.
Sign the APK locally before installation. Build runs create Actions artifacts.

- [Configuration, signing and updates](customManager/README.md)
- [Device validation](customManager/README.md#validation)
- [Inherited KernelSU documentation](docs/README.md)

The inherited **Build Manager** workflow remains available for manual and
reusable builds. The automatic workflow for this fork is **Device Access**.

## Origin and license

Based on [diabl0w/KernelSU](https://github.com/diabl0w/KernelSU), which derives
from [tiann/KernelSU](https://github.com/tiann/KernelSU). Existing credits and
licenses remain in the [KernelSU documentation](docs/README.md#credits).
Kernel code is GPL-2.0-only; other components are GPL-3.0-or-later.
