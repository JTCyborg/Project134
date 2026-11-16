param(
    [Parameter(Mandatory = $true)]
    [string]$RomPath,

    [Parameter(Mandatory = $true)]
    [int]$ExpectedSize
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $RomPath -PathType Leaf)) {
    throw "BIOS output not found: $RomPath"
}

$bytes = [System.IO.File]::ReadAllBytes($RomPath)
if ($bytes.Length -ne $ExpectedSize) {
    throw ("Invalid ROM size: {0} bytes; expected {1}" -f $bytes.Length, $ExpectedSize)
}

if ($ExpectedSize -ne 65536) {
    throw "The bootstrap validator currently expects a 64 KiB ROM."
}

$expectedVector = [byte[]](0xEA, 0x00, 0xE0, 0x00, 0xF0)
for ($i = 0; $i -lt $expectedVector.Length; $i++) {
    if ($bytes[0xFFF0 + $i] -ne $expectedVector[$i]) {
        throw ("Invalid reset vector byte at ROM offset 0x{0:X4}: got 0x{1:X2}, expected 0x{2:X2}" -f (0xFFF0 + $i), $bytes[0xFFF0 + $i], $expectedVector[$i])
    }
}

Write-Host ("BIOS ROM validation PASS: {0} bytes; reset vector FFFF:0000 -> F000:E000" -f $bytes.Length) -ForegroundColor Green
