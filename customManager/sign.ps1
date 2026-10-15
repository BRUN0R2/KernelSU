param(
    [Parameter(Mandatory)][string]$inputApk,
    [Parameter(Mandatory)][string]$androidBuildToolsPath,
    [Parameter(Mandatory)][string]$javaHome,
    [Parameter(Mandatory)][string]$keystorePath,
    [Parameter(Mandatory)][string]$passwordFile,
    [Parameter(Mandatory)][string]$outputDirectory
)

$ErrorActionPreference = 'Stop'
$keyAlias = 'deviceAccess'
$inputApk = (Resolve-Path -LiteralPath $inputApk).Path
$keystorePath = (Resolve-Path -LiteralPath $keystorePath).Path
$metadata = Get-Content -LiteralPath (Join-Path (Split-Path $inputApk -Parent) 'buildMetadata.json') -Raw | ConvertFrom-Json
if ((Get-FileHash -LiteralPath $inputApk -Algorithm SHA256).Hash.ToLowerInvariant() -ne $metadata.unsignedApkSha256) {
    throw 'The unsigned APK differs from the artifact recorded by CI.'
}
$java = Join-Path $javaHome 'bin/java.exe'
$keytool = Join-Path $javaHome 'bin/keytool.exe'
$zipalign = Join-Path $androidBuildToolsPath 'zipalign.exe'
$aapt = Join-Path $androidBuildToolsPath 'aapt2.exe'
$apksigner = Join-Path $androidBuildToolsPath 'lib/apksigner.jar'
foreach ($requiredFile in @($java, $keytool, $zipalign, $aapt, $apksigner, $passwordFile)) {
    if (-not (Test-Path -LiteralPath $requiredFile -PathType Leaf)) {
        throw "Required file missing: $requiredFile"
    }
}

$localConfig = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'config.json') -Raw | ConvertFrom-Json
if ($metadata.packageName -ne $localConfig.packageName -or $metadata.kmi -ne $localConfig.kmi -or $metadata.abi -ne $localConfig.abi) {
    throw 'Build metadata differs from the local device configuration.'
}
$certificate = [System.Security.Cryptography.X509Certificates.X509Certificate2]::CreateFromPem([System.IO.File]::ReadAllText((Join-Path $PSScriptRoot 'certificate.pem')))
try {
    $expectedHash = $certificate.GetCertHashString([System.Security.Cryptography.HashAlgorithmName]::SHA256).ToLowerInvariant()
    if ($expectedHash -ne $metadata.certificateSha256 -or ('0x{0:x}' -f $certificate.RawData.Length) -ne $metadata.certificateSize) {
        throw 'Build metadata does not match the local public certificate.'
    }
} finally { $certificate.Dispose() }

$packageInfo = & $aapt dump badging $inputApk
if ($LASTEXITCODE -ne 0) { throw 'Cannot read APK manifest.' }
$packageLine = $packageInfo | Where-Object { $_ -match '^package:' } | Select-Object -First 1
if ($packageLine -notmatch "^package: name='([^']+)'" -or $Matches[1] -ne $metadata.packageName) {
    throw 'APK application ID differs from the build metadata.'
}

New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
$outputDirectory = (Resolve-Path -LiteralPath $outputDirectory).Path
$outputApk = Join-Path $outputDirectory 'deviceAccess.apk'
$alignedApk = Join-Path $outputDirectory 'deviceAccess-aligned.apk'
$exportedCertificate = Join-Path $outputDirectory 'signingCertificate.der'
if (Test-Path -LiteralPath $outputApk) { throw 'Output APK already exists. Preserve it or select a new directory.' }

$previousPassword = $env:deviceAccessSigningPassword
try {
    $securePassword = Import-Clixml -LiteralPath $passwordFile
    $credential = [System.Management.Automation.PSCredential]::new($keyAlias, $securePassword)
    $env:deviceAccessSigningPassword = $credential.GetNetworkCredential().Password
    & $keytool -exportcert -alias $keyAlias -keystore $keystorePath -storepass:env deviceAccessSigningPassword -file $exportedCertificate
    if ($LASTEXITCODE -ne 0) { throw 'Cannot export signing certificate.' }
    if ((Get-FileHash -LiteralPath $exportedCertificate -Algorithm SHA256).Hash.ToLowerInvariant() -ne $expectedHash) {
        throw 'The signing key differs from the certificate trusted by this kernel module.'
    }
    & $zipalign -f -P 16 4 $inputApk $alignedApk
    if ($LASTEXITCODE -ne 0) { throw 'APK alignment failed.' }
    & $java -jar $apksigner sign --ks $keystorePath --ks-key-alias $keyAlias `
        --ks-pass env:deviceAccessSigningPassword --key-pass env:deviceAccessSigningPassword `
        --v1-signing-enabled false --v2-signing-enabled true --v3-signing-enabled false `
        --v4-signing-enabled false --out $outputApk $alignedApk
    if ($LASTEXITCODE -ne 0) { throw 'APK signing failed.' }
    $verification = & $java -jar $apksigner verify --verbose --print-certs $outputApk
    if ($LASTEXITCODE -ne 0) { throw 'APK signature verification failed.' }
    if (-not ($verification -match 'Verified using v2 scheme .*: true$') -or ($verification -match 'Verified using v3.*: true$')) {
        throw 'APK Signature Scheme v2 must remain enabled for kernel verification.'
    }
    $certificatePattern = [regex]::Escape("certificate SHA-256 digest: $expectedHash")
    if (-not ($verification -match $certificatePattern)) {
        throw 'APK certificate identity differs from the configured certificate.'
    }
    & $zipalign -c -P 16 4 $outputApk
    if ($LASTEXITCODE -ne 0) { throw 'Signed APK alignment verification failed.' }
    $verification | Set-Content -LiteralPath (Join-Path $outputDirectory 'signatureVerification.txt') -Encoding utf8
    $signedHash = (Get-FileHash -LiteralPath $outputApk -Algorithm SHA256).Hash.ToLowerInvariant()
    $metadata | Add-Member -NotePropertyName signedApkSha256 -NotePropertyValue $signedHash -Force
    $metadata | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $outputDirectory 'buildMetadata.json') -Encoding utf8
    "$signedHash  deviceAccess.apk" | Set-Content -LiteralPath (Join-Path $outputDirectory 'sha256.txt') -Encoding ascii
    $verification
    "Signed APK: $outputApk"
} finally {
    $env:deviceAccessSigningPassword = $previousPassword
}
