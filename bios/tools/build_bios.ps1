[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$OutputDirectory,

    [string]$NasmExe = "nasm.exe",

    [int]$RomSize = 65536
)

$ErrorActionPreference = "Stop"

$biosDirectory = Split-Path -Parent $PSScriptRoot
$sourcePath = Join-Path $biosDirectory "src\reset.asm"
$validatorPath = Join-Path $PSScriptRoot "validate_rom.ps1"
$outputDirectory = [System.IO.Path]::GetFullPath($OutputDirectory)
$outputPath = Join-Path $outputDirectory "Project134.bin"

if (-not (Test-Path -LiteralPath $sourcePath -PathType Leaf)) {
    throw "BIOS source not found: $sourcePath"
}
if (-not (Test-Path -LiteralPath $validatorPath -PathType Leaf)) {
    throw "ROM validator not found: $validatorPath"
}

$nasm = Get-Command -Name $NasmExe -CommandType Application -ErrorAction Stop
$nasmPath = $nasm.Source

Write-Host "Project134 BIOS build"
Write-Host "NASM:   $nasmPath"
Write-Host "Source: $sourcePath"
Write-Host "Output: $outputPath"
Write-Host "Size:   $RomSize bytes"

New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null

& $nasmPath -f bin "-DROM_SIZE=$RomSize" -o $outputPath $sourcePath
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
