[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$OutputDirectory,

    [string]$NasmExe = "nasm.exe",

    [int]$RomSize = 65536,

    [switch]$NativeOnly
)

$ErrorActionPreference = "Stop"

$biosDirectory = Split-Path -Parent $PSScriptRoot
$sourcePath = Join-Path $biosDirectory "src\reset.asm"
$validatorPath = Join-Path $PSScriptRoot "validate_rom.ps1"
$referenceRomPath = Join-Path $biosDirectory "..\ami486.bin"
$outputDirectory = [System.IO.Path]::GetFullPath($OutputDirectory)
$outputPath = Join-Path $outputDirectory "Project134.bin"
$candidatePath = Join-Path $outputDirectory "Project134.native-candidate.bin"

if (-not (Test-Path -LiteralPath $sourcePath -PathType Leaf)) {
    throw "BIOS source not found: $sourcePath"
}
if (-not (Test-Path -LiteralPath $validatorPath -PathType Leaf)) {
    throw "ROM validator not found: $validatorPath"
}

# NASM flat-binary ORG layout can only advance. A descending TIMES target
# would produce a negative repeat count and stop the build before assembly.
$lastRomOffset = -1
$sourceLineNumber = 0
foreach ($line in [System.IO.File]::ReadLines($sourcePath)) {
    $sourceLineNumber++
    if ($line -match '^\s*times\s+0x([0-9A-Fa-f]+)\s*-') {
        $romOffset = [Convert]::ToInt32($Matches[1], 16)
        if ($romOffset -lt $lastRomOffset) {
            throw ("BIOS source ROM layout is not monotonic at line {0}: 0x{1:X4} follows 0x{2:X4}" -f $sourceLineNumber, $romOffset, $lastRomOffset)
        }
        $lastRomOffset = $romOffset
    }
}

function Resolve-NasmExecutable {
    param([string]$RequestedPath)

    # An explicit path always takes priority.
    if ([System.IO.Path]::IsPathRooted($RequestedPath) -or $RequestedPath.Contains('\')) {
        if (Test-Path -LiteralPath $RequestedPath -PathType Leaf) {
            return (Get-Item -LiteralPath $RequestedPath).FullName
        }
        throw "NASM executable not found at the configured path: $RequestedPath"
    }

    # First use a normal PATH installation.
    $command = Get-Command -Name $RequestedPath -CommandType Application -ErrorAction SilentlyContinue
    if ($command) {
        return $command.Source
    }

    # Then search common Windows installation locations and vcpkg tool caches.
    $roots = [System.Collections.Generic.List[string]]::new()
    if ($env:VCPKG_ROOT) {
        $roots.Add((Join-Path $env:VCPKG_ROOT "downloads\tools\nasm"))
    }
    foreach ($root in @("C:\vcpkg\downloads\tools\nasm", "C:\Program Files\NASM", "C:\Program Files (x86)\NASM")) {
        if (-not $roots.Contains($root)) {
            $roots.Add($root)
        }
    }

    $candidates = [System.Collections.Generic.List[object]]::new()
    foreach ($root in $roots) {
        if (-not (Test-Path -LiteralPath $root -PathType Container)) {
            continue
        }

        if ($root -match '\\downloads\\tools\\nasm$') {
            Get-ChildItem -LiteralPath $root -Directory -ErrorAction SilentlyContinue | ForEach-Object {
                $versionMatch = [regex]::Match($_.Name, '(\d+(?:\.\d+)+)')
                $version = [version]"0.0"
                if ($versionMatch.Success) {
                    try { $version = [version]$versionMatch.Groups[1].Value } catch {}
                }
                $exe = Join-Path $_.FullName "nasm.exe"
                if (Test-Path -LiteralPath $exe -PathType Leaf) {
                    $candidates.Add([pscustomobject]@{ Version = $version; Path = $exe })
                }
            }
        }
        else {
            $exe = Join-Path $root "nasm.exe"
            if (Test-Path -LiteralPath $exe -PathType Leaf) {
                $candidates.Add([pscustomobject]@{ Version = [version]"0.0"; Path = $exe })
            }
        }
    }

    $best = $candidates | Sort-Object Version -Descending | Select-Object -First 1
    if ($best) {
        return (Get-Item -LiteralPath $best.Path).FullName
    }

    throw "NASM was not found. Install NASM, add nasm.exe to PATH, set VCPKG_ROOT, or pass -NasmExe with its full path."
}

New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null

# Publish the known-good image before attempting the incomplete native candidate.
# A NASM failure must never leave the previously failing Project134.bin in place.
if (-not $NativeOnly) {
    if (-not (Test-Path -LiteralPath $referenceRomPath -PathType Leaf)) {
        throw "Reference compatibility image not found: $referenceRomPath"
    }
    $referenceBytes = [System.IO.File]::ReadAllBytes($referenceRomPath)
    if ($referenceBytes.Length -ne $RomSize) {
        throw ("Reference BIOS has invalid size: {0}; expected {1}" -f $referenceBytes.Length, $RomSize)
    }
    [System.IO.File]::WriteAllBytes($outputPath, $referenceBytes)
    $referenceHash = (Get-FileHash -LiteralPath $referenceRomPath -Algorithm SHA256).Hash
    $outputHash = (Get-FileHash -LiteralPath $outputPath -Algorithm SHA256).Hash
    if ($referenceHash -ne $outputHash) {
        throw "Compatibility output is not byte-identical to the reference BIOS."
    }
    Write-Host "BOOT IMAGE: byte-identical reference compatibility baseline." -ForegroundColor Green
}

$nasmPath = Resolve-NasmExecutable -RequestedPath $NasmExe

Write-Host "Project134 BIOS build"
Write-Host "NASM:   $nasmPath"
Write-Host "Source: $sourcePath"
Write-Host "Output: $outputPath"
Write-Host "Size:   $RomSize bytes"

# Keep a NASM listing even when fixed-offset TIMES assertions fail. The listing
# exposes the exact emitted addresses/bytes immediately before each overflow.
$listingPath = Join-Path $outputDirectory "Project134.native-candidate.lst"
& $nasmPath -f bin -l $listingPath "-DROM_SIZE=$RomSize" -o $candidatePath $sourcePath
Write-Host "Native candidate: $candidatePath"
Write-Host "Listing:          $listingPath"
if ($LASTEXITCODE -ne 0) {
    throw "NASM failed with exit code $LASTEXITCODE"
}
if (-not (Test-Path -LiteralPath $candidatePath -PathType Leaf)) {
    throw "NASM returned success but did not create the native candidate: $candidatePath"
}

& $validatorPath -RomPath $candidatePath -ExpectedSize $RomSize -ReferenceRomPath $referenceRomPath
if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) {
    throw "ROM validation failed with exit code $LASTEXITCODE"
}

if ($NativeOnly) {
    [System.IO.File]::Copy($candidatePath, $outputPath, $true)
    Write-Warning "Native-only mode selected. Project134.bin is the unqualified NASM candidate; it may not complete POST or boot."
}
else {
    Write-Host "The native candidate remains separate and is NOT yet boot-qualified."
}

$file = Get-Item -LiteralPath $outputPath
Write-Host ("BUILD SUCCESS: {0} ({1} bytes)" -f $file.FullName, $file.Length) -ForegroundColor Green
