[CmdletBinding()]
param(
    [string]$RomPath = (Join-Path $PSScriptRoot "..\ami486.bin"),
    [string]$Ndisasm = "ndisasm",
    [string]$OutputPath = (Join-Path $PSScriptRoot "..\analysis\disasm\ami486_full_linear.disasm.txt")
)

$ErrorActionPreference = "Stop"
$RomPath = [System.IO.Path]::GetFullPath($RomPath)
$OutputPath = [System.IO.Path]::GetFullPath($OutputPath)

if (-not (Test-Path -LiteralPath $RomPath -PathType Leaf)) {
    throw "ROM not found: $RomPath"
}
$rom = Get-Item -LiteralPath $RomPath
if ($rom.Length -ne 65536) {
    throw "Expected exactly 65536 bytes; got $($rom.Length)"
}

$ndisasmCommand = Get-Command $Ndisasm -ErrorAction Stop
$outDir = Split-Path -Parent $OutputPath
New-Item -ItemType Directory -Force -Path $outDir | Out-Null
$stderrPath = "$OutputPath.stderr.txt"
Remove-Item -LiteralPath $OutputPath,$stderrPath -Force -ErrorAction SilentlyContinue

# Linear 8086/80186-compatible 16-bit decode from ROM offset zero.
# This is a byte-complete linear decode, not proof that every byte is executable code.
& $ndisasmCommand.Source -b 16 -o 0x0 $RomPath 1> $OutputPath 2> $stderrPath
$exitCode = $LASTEXITCODE
if ($exitCode -ne 0) {
    throw "ndisasm failed with exit code $exitCode. See $stderrPath"
}

$lines = Get-Content -LiteralPath $OutputPath
if ($lines.Count -eq 0 -or $lines[0] -notmatch '^00000000\s') {
    throw "Unexpected listing start. First='$($lines[0])'"
}
$decodedBytes = 0
foreach ($line in $lines) {
    if ($line -match '^([0-9A-Fa-f]{8})\s+([0-9A-Fa-f]+)\s+') {
        $decodedBytes += [int]($Matches[2].Length / 2)
    } else {
        throw "Unrecognized ndisasm output line: $line"
    }
}
if ($decodedBytes -ne 65536) {
    throw "Listing accounts for $decodedBytes bytes, expected 65536"
}

$sha256 = (Get-FileHash -LiteralPath $RomPath -Algorithm SHA256).Hash.ToLowerInvariant()
$manifestPath = [System.IO.Path]::ChangeExtension($OutputPath, ".manifest.txt")
@(
    "AMI486 FULL LINEAR DISASSEMBLY"
    "ROM=$RomPath"
    "SIZE=$($rom.Length)"
    "SHA256=$sha256"
    "DISASSEMBLER=$($ndisasmCommand.Source)"
    "MODE=16-bit"
    "ORIGIN=0x0000"
    "FIRST_LINE=$($lines[0])"
    "LAST_LINE=$($lines[-1])"
    "LINE_COUNT=$($lines.Count)"
    "DECODED_BYTES=$decodedBytes"
    "NOTE=Linear decode only; overlapping entry points and code/data classification require separate analysis."
) | Set-Content -LiteralPath $manifestPath -Encoding ASCII

Write-Host "FULL LINEAR DISASSEMBLY GENERATED"
Write-Host "ROM:      $RomPath"
Write-Host "Size:     $($rom.Length) bytes"
Write-Host "SHA-256:  $sha256"
Write-Host "Listing:  $OutputPath"
Write-Host "Manifest: $manifestPath"
Write-Host "Lines:    $($lines.Count)"
