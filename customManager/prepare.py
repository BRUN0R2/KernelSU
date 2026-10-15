"""Validate public build inputs and export the manager's certificate identity."""

import hashlib
import json
import os
from pathlib import Path
import re
import ssl


def prepare():
    projectRoot = Path(__file__).resolve().parent
    config = json.loads((projectRoot / "config.json").read_text(encoding="utf-8"))
    if not re.fullmatch(r"[a-z][a-z0-9]*(?:\.[a-z][a-z0-9]*){2,}", config["packageName"]):
        raise ValueError("packageName must be a valid lower-case application ID")
    if not re.fullmatch(r"[A-Za-z0-9 ]{1,40}", config["displayName"]):
        raise ValueError("displayName must contain 1 to 40 letters, digits or spaces")
    if config["kmi"] != "android13-5.15" or config["abi"] != "arm64-v8a":
        raise ValueError("This build is scoped to the verified Redmi 15 KMI and ABI")
    if not re.fullmatch(r"\d{8}", config["ddkRelease"]):
        raise ValueError("ddkRelease must use YYYYMMDD")

    certificate = ssl.PEM_cert_to_DER_cert(
        (projectRoot / "certificate.pem").read_text(encoding="ascii")
    )
    metadata = {
        **config,
        "certificateSize": hex(len(certificate)),
        "certificateSha256": hashlib.sha256(certificate).hexdigest(),
    }
    print(json.dumps(metadata, indent=2))
    if outputPath := os.environ.get("GITHUB_OUTPUT"):
        with open(outputPath, "a", encoding="utf-8") as output:
            for name, value in metadata.items():
                output.write(f"{name}={value}\n")
    return metadata


if __name__ == "__main__":
    prepare()
