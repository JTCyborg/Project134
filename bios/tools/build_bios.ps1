[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$OutputDirectory,

    [string]$NasmExe = "nasm.exe",

    [int]$RomSize = 65536
)

$ErrorActionPreference = "Stop"

$biosDirectory = Split-Path -Parent $PSScriptRoot
$sourceDirectory = Join-Path $biosDirectory "src"
$sourcePath = Join-Path $sourceDirectory "reset.asm"
$includePath = $sourceDirectory + [System.IO.Path]::DirectorySeparatorChar
$validatorPath = Join-Path $PSScriptRoot "validate_rom.ps1"
$outputDirectory = [System.IO.Path]::GetFullPath($OutputDirectory)
$outputPath = Join-Path $outputDirectory "Project134.bin"

if (-not (Test-Path -LiteralPath $sourcePath -PathType Leaf)) {
    throw "BIOS source not found: $sourcePath"
}
if (-not (Test-Path -LiteralPath $validatorPath -PathType Leaf)) {
    throw "ROM validator not found: $validatorPath"
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

$nasmPath = Resolve-NasmExecutable -RequestedPath $NasmExe

Write-Host "Project134 BIOS build"
Write-Host "NASM:   $nasmPath"
Write-Host "Source: $sourcePath"
Write-Host "Include: $includePath"
Write-Host "Output: $outputPath"
Write-Host "Size:   $RomSize bytes"

New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null

& $nasmPath -f bin "-I$includePath" "-DROM_SIZE=$RomSize" -o $outputPath $sourcePath
if ($LASTEXITCODE -ne 0) {
    throw "NASM failed with exit code $LASTEXITCODE"
}
if (-not (Test-Path -LiteralPath $outputPath -PathType Leaf)) {
    throw "NASM returned success but did not create the ROM: $outputPath"
}

& $validatorPath -RomPath $outputPath -ExpectedSize $RomSize
if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) {
    throw "ROM validation failed with exit code $LASTEXITCODE"
}

$file = Get-Item -LiteralPath $outputPath
Write-Host ("BUILD SUCCESS: {0} ({1} bytes)" -f $file.FullName, $file.Length) -ForegroundColor Green
